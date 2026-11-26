//! A thin C interface over Brave's adblock library, for Velum.
//!
//! Every function catches panics: a bad filter list must never take the browser down.

use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
use adblock::resources::{PermissionMask, Resource};
use adblock::Engine;
use std::ffi::{c_char, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};

/// Collects filter lists before the engine is built.
pub struct Builder {
    filters: FilterSet,
    resources: Vec<Resource>,
}

fn text<'a>(ptr: *const u8, len: usize) -> &'a str {
    if ptr.is_null() {
        return "";
    }
    // SAFETY: the caller passes a buffer of `len` bytes that lives for the whole call.
    std::str::from_utf8(unsafe { std::slice::from_raw_parts(ptr, len) }).unwrap_or("")
}

#[no_mangle]
pub extern "C" fn velumblock_builder() -> *mut Builder {
    Box::into_raw(Box::new(Builder { filters: FilterSet::new(false), resources: Vec::new() }))
}

/// Adds one filter list. `trusted` lists (uBlock Origin's own) may use the stronger scriptlets.
///
/// # Safety
/// `b` comes from `velumblock_builder` and has not been built yet.
#[no_mangle]
pub unsafe extern "C" fn velumblock_add_list(b: *mut Builder, list: *const u8, len: usize, trusted: bool) {
    let Some(b) = b.as_mut() else { return };
    let options = ParseOptions {
        permissions: PermissionMask::from_bits(if trusted { 1 } else { 0 }),
        ..Default::default()
    };
    let _ = catch_unwind(AssertUnwindSafe(|| {
        b.filters.add_filter_list(text(list, len).to_string(), options);
    }));
}

/// Adds the scripts that filter rules can inject (Brave's resources.json).
///
/// # Safety
/// `b` comes from `velumblock_builder` and has not been built yet.
#[no_mangle]
pub unsafe extern "C" fn velumblock_add_resources(b: *mut Builder, json: *const u8, len: usize) -> bool {
    let Some(b) = b.as_mut() else { return false };
    match serde_json::from_str::<Vec<Resource>>(text(json, len)) {
        Ok(mut resources) => {
            b.resources.append(&mut resources);
            true
        }
        Err(_) => false,
    }
}

/// Turns the builder into an engine. The builder is used up. Returns null on failure.
///
/// # Safety
/// `b` comes from `velumblock_builder` and is not used again.
#[no_mangle]
pub unsafe extern "C" fn velumblock_build(b: *mut Builder) -> *mut Engine {
    if b.is_null() {
        return std::ptr::null_mut();
    }
    let b = Box::from_raw(b);
    catch_unwind(AssertUnwindSafe(move || {
        let mut engine = Engine::new_with_filter_set(b.filters);
        engine.use_resources(b.resources);
        Box::into_raw(Box::new(engine))
    }))
    .unwrap_or(std::ptr::null_mut())
}

/// Should the request be stopped?
///
/// # Safety
/// `e` comes from `velumblock_build`; the pointers describe valid buffers.
#[no_mangle]
pub unsafe extern "C" fn velumblock_check(
    e: *const Engine,
    url: *const u8, url_len: usize,
    source: *const u8, source_len: usize,
    kind: *const u8, kind_len: usize,
) -> bool {
    let Some(engine) = e.as_ref() else { return false };
    catch_unwind(AssertUnwindSafe(|| {
        match Request::new(text(url, url_len), text(source, source_len), text(kind, kind_len), "GET") {
            Ok(request) => engine.check_network_request(&request).should_block(),
            Err(_) => false,
        }
    }))
    .unwrap_or(false)
}

/// What to hide and which scripts to run on a page, as JSON {"hide": [...], "script": "..."}.
/// Free the result with `velumblock_string_free`.
///
/// # Safety
/// `e` comes from `velumblock_build`; the pointer describes a valid buffer.
#[no_mangle]
pub unsafe extern "C" fn velumblock_cosmetic(e: *const Engine, url: *const u8, url_len: usize) -> *mut c_char {
    let Some(engine) = e.as_ref() else { return std::ptr::null_mut() };
    catch_unwind(AssertUnwindSafe(|| {
        let found = engine.url_cosmetic_resources(text(url, url_len));
        let mut hide: Vec<&String> = found.hide_selectors.iter().collect();
        hide.sort();
        let json = serde_json::json!({ "hide": hide, "script": found.injected_script });
        CString::new(json.to_string()).map(CString::into_raw).unwrap_or(std::ptr::null_mut())
    }))
    .unwrap_or(std::ptr::null_mut())
}

/// # Safety
/// `s` comes from `velumblock_cosmetic`.
#[no_mangle]
pub unsafe extern "C" fn velumblock_string_free(s: *mut c_char) {
    if !s.is_null() {
        drop(CString::from_raw(s));
    }
}

/// # Safety
/// `e` comes from `velumblock_build` and is not used again.
#[no_mangle]
pub unsafe extern "C" fn velumblock_free(e: *mut Engine) {
    if !e.is_null() {
        drop(Box::from_raw(e));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::CStr;

    fn build(list: &str) -> *mut Engine {
        unsafe {
            let b = velumblock_builder();
            velumblock_add_list(b, list.as_ptr(), list.len(), false);
            velumblock_build(b)
        }
    }

    fn blocked(e: *mut Engine, url: &str, source: &str, kind: &str) -> bool {
        unsafe { velumblock_check(e, url.as_ptr(), url.len(), source.as_ptr(), source.len(), kind.as_ptr(), kind.len()) }
    }

    #[test]
    fn blocks_and_allows() {
        let e = build("||ads.example^\n||tracker.example^$third-party\n@@||ads.example/fine.js\n");
        assert!(blocked(e, "https://ads.example/a.js", "https://site.test/", "script"));
        assert!(!blocked(e, "https://ads.example/fine.js", "https://site.test/", "script"));
        assert!(blocked(e, "https://tracker.example/p.gif", "https://site.test/", "image"));
        assert!(!blocked(e, "https://tracker.example/p.gif", "https://tracker.example/", "image"));
        assert!(!blocked(e, "not a url", "https://site.test/", "image"));
        unsafe { velumblock_free(e) }
    }

    #[test]
    fn hides_elements() {
        let e = build("site.test##.banner\n");
        let url = "https://site.test/page";
        let raw = unsafe { velumblock_cosmetic(e, url.as_ptr(), url.len()) };
        let json = unsafe { CStr::from_ptr(raw) }.to_str().unwrap().to_string();
        assert!(json.contains(".banner"), "{json}");
        unsafe {
            velumblock_string_free(raw);
            velumblock_free(e);
        }
    }

    #[test]
    fn null_and_garbage_are_harmless() {
        unsafe {
            assert!(velumblock_build(std::ptr::null_mut()).is_null());
            assert!(!velumblock_check(std::ptr::null(), std::ptr::null(), 0, std::ptr::null(), 0, std::ptr::null(), 0));
            let b = velumblock_builder();
            assert!(!velumblock_add_resources(b, b"{oops".as_ptr(), 5));
            velumblock_free(velumblock_build(b));
        }
    }
}
