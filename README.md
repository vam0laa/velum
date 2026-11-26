# Velum

A calm, private web browser on the open source Qt WebEngine (Chromium).

**Status: stage 1.** Not ready to be your daily browser.

Measured memory use is in [docs/olcum.md](docs/olcum.md).

## Build and run

Needs Qt 6.9 or newer (base with the SQLite driver, declarative, webengine, webchannel), libsecret, OpenSSL, CMake, Ninja and Rust (cargo).

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build
./build/velum
```

Install for your user: `cmake --install build --prefix ~/.local`

## Keys

| Key | Action |
|---|---|
| Ctrl+T / Ctrl+W | command box for a new tab / close tab |
| Ctrl+K | command box: address, search, open tabs, commands |
| Ctrl+Shift+T | reopen the closed tab |
| Ctrl+Shift+P | pin or unpin the tab (pinned tabs return at the next start) |
| Ctrl+D | add or remove a bookmark (the first ten show on the start page) |
| Ctrl+H | history; type to search, Shift+Delete removes an entry |
| Ctrl+J | downloads |
| Shift+Esc | resources: memory and processor use per tab |
| Ctrl+F | find in page (Enter, Shift+Enter, Esc) |
| Ctrl+, | settings |
| Ctrl+\ | split view: two tabs side by side (also in the tab menu) |
| Ctrl+Shift+O | bookmark manager: folders, search, edit, reorder, undo |
| Ctrl+Shift+L | fill in a saved password |
| Alt+R | reading mode: the article alone, in Velum's colours (button in the title bar on article pages) |
| Alt+P | the video in a small window that stays on top (button in the title bar while a page plays sound) |
| Alt+1…6 | workspaces: separate sets of tabs (pinned tabs and logins are shared) |
| Ctrl+Tab, Ctrl+Shift+Tab | next / previous tab |
| Ctrl+L | edit the address |
| Ctrl+R, F5 | reload |
| Alt+Left / Right | back / forward |
| Ctrl+B | narrow or wide side bar |
| Ctrl + / - / 0 | zoom |
| F11 | full screen |
| Ctrl+Q | quit |

Passwords are kept in the system keyring (Secret Service: GNOME Keyring, KeePassXC and the like), never in a file of Velum's. Velum asks before saving, and fills a form only when you ask, on https pages whose address matches exactly. Forms inside frames are not filled.

Extensions (Settings > Extensions) install from a Chrome Web Store address ("add to Velum" in the title bar on a store page), a zip or a folder, after you agree. A store package is fetched from Google and installed only if it is signed with the key its id is made from. Only Manifest V3 extensions load, the engine does not offer every Chrome API, and the store's own "Add to Chrome" button does not work.

Import in the bookmark manager takes bookmarks (with folders) and the last 90 days of history from Firefox, Zen, LibreWolf, Chromium, Chrome, Brave, Helium, Vivaldi or Edge. Only when you ask, from copies of their files; passwords and cookies are not touched.

## What it does not do yet

- **Video ads on YouTube are not blocked yet** (see below).
- The download list lasts until Velum closes. Interrupted downloads cannot be resumed.
- Screen sharing is refused.

## Protection

Ads and trackers are blocked with Brave's [adblock-rust](https://github.com/brave/adblock-rust) engine and the EasyList, EasyPrivacy and uBlock Origin filter lists. Plain `http` addresses of public sites are opened over `https`, and a Global Privacy Control header is sent. The shield button shows the count for the page and switches blocking off per site.

Third party cookies are blocked (a site you switch protection off for may set them). Camera, microphone, location, notifications, clipboard and pointer lock are asked about, and the answer lasts until Velum closes. WebRTC does not reveal local network addresses. "Forget cookies on exit" and "Delete cookies and cache" are in the shield panel (Ctrl+Shift+Delete). Deleting covers cookies and the cache, not other site storage.

History stays in an SQLite file on this computer (readable only by you), is kept for 90 days, and is cleared by "forget on exit" and by deleting browsing data. Downloads go to your downloads folder and are never opened automatically.

Velum downloads the lists from easylist.to and GitHub on the first start and again when they are older than four days. This is the one connection it makes by itself.

Limit: filters that need uBlock Origin's page scripts (among them the ones for YouTube video ads) have no effect yet, because only Brave's own script collection is loaded.

## Tabs, links and problems

Open tabs come back at the next start and load when first looked at (a command turns this off; "forget on exit" turns it off too). There is one Velum at a time: starting it again with an address opens a tab in the running window. To make it the default browser: `xdg-settings set default-web-browser velum.desktop`. A site that cannot be opened, a bad certificate (which cannot be skipped) and a crashed tab each show an explanation with a retry button.

Allowed notifications are shown by the desktop, with the real site name under the message. Frozen or discarded tabs cannot notify; pin a tab to keep it awake. The right click menu offers what applies to the link, image, text or field clicked.

## Sleeping tabs

A tab you have not looked at is frozen after 2 minutes and discarded after 10, when the engine says that is safe ("relaxed" in the resource panel makes it 5 and 20, "off" turns it off). Pinned tabs and tabs playing sound stay awake. A discarded tab loads again when you open it, so text typed into a form on it may be lost; automatic sleeping can be switched off in the resource panel.

## Settings

Ctrl+, opens the settings: language (system, Turkish, English), search engine (DuckDuckGo, Brave Search, Startpage, Google), downloads folder, tab restoring and sleeping, and the privacy switches.

## Look

Webcore: square windows with blue striped title bars, pixel lettering, folder-shaped tabs along the top (or down the side), and a start page with a glitching clock over a sky, scan lines and twinkling stars, with small windows for search, bookmarks and, if wanted, what the shield blocked, your most visited places and a note. The sky is drawn for Velum; nothing on the start page asks the network for anything. By default the cybercore blue follows the clock: bright from 07:00 to 19:00, a calm night blue after that (either can be fixed in the settings); Catppuccin, Rosé Pine, Everforest, Gruvbox, Nord, Tokyo Night and the desktop theme change the colours. Glass (see-through) and motion can be switched. The first start asks for language, theme, layout and search engine; the settings are a tab of their own (Ctrl+,). The bundled font VT323 is under the SIL Open Font License (see `data/fonts`).

## Laptops with two graphics cards

With an NVIDIA card next to an AMD or Intel one, Velum hides the NVIDIA Vulkan driver from the engine so that the page and the window use the same card (otherwise pages can stay black). Set `VELUM_USE_NVIDIA=1` to turn this off.

## Netflix and other protected video

Velum uses the Widevine module already on your computer (for example the one Chromium downloads). It is Google's closed software and is not shipped with Velum.
