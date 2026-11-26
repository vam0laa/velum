import QtQuick

// Reading mode: picks the article out of a page and lays it over the page in Velum's
// colours. The scripts run in a world of their own that the page's code cannot reach.
QtObject {
    // true when the page looks like it has an article worth reading
    readonly property string probe: `(() => {
        let long = 0, total = 0;
        for (const p of document.querySelectorAll('p')) {
            const n = p.textContent.trim().length;
            if (n > 120) { long++; total += n }
        }
        return long >= 3 && total >= 900;
    })()`

    readonly property string leave: `(() => {
        const host = document.getElementById('velum-reader');
        if (!host) return;
        document.documentElement.style.overflow = host.dataset.overflow || '';
        host.remove();
    })()`

    function resize(size) {
        return "document.getElementById('velum-reader')?.style.setProperty('--size', '" + Number(size) + "px')"
    }

    // look: { size, dark, colors: { back, text, dim, accent, card, line }, minutes }
    function enter(look) { return "(" + body + ")(" + JSON.stringify(look) + ")" }

    readonly property string body: `(look) => {
        if (document.getElementById('velum-reader')) return true;
        const junk = /comment|footer|sidebar|side-bar|navbar|breadcrumb|menu|promo|share|social|related|recommend|newsletter|subscribe|cookie|popup|advert|banner/i;
        const named = e => (e.getAttribute('class') || '') + ' ' + (e.id || '');
        const inJunk = e => {
            for (; e && e !== document.body; e = e.parentElement)
                if (e.matches('nav,aside,footer') || (junk.test(named(e)) && !e.matches('article,main'))) return true;
            return false;
        };

        // the element whose own and grandchildren paragraphs hold the most text wins
        const score = new Map();
        const give = (e, n) => { if (e && e !== document.documentElement) score.set(e, (score.get(e) || 0) + n) };
        for (const p of document.querySelectorAll('p, pre')) {
            const n = p.textContent.trim().length;
            if (n < 60 || inJunk(p.parentElement)) continue;
            give(p.parentElement, n);
            give(p.parentElement && p.parentElement.parentElement, n * 0.6);
        }
        let best = null, top = 0;
        for (const [e, n] of score) {
            const value = e.matches('article,[itemprop=articleBody]') ? n * 1.4 : n;
            if (value > top) { best = e; top = value }
        }
        if (!best || top < 500) return false;

        const keep = new Set('P H1 H2 H3 H4 H5 H6 UL OL LI BLOCKQUOTE PRE CODE EM STRONG B I A IMG FIGURE FIGCAPTION TABLE THEAD TBODY TR TH TD BR HR SUP SUB DIV'.split(' '));
        const drop = new Set('SCRIPT STYLE NOSCRIPT TEMPLATE NAV ASIDE FOOTER FORM BUTTON INPUT SELECT TEXTAREA IFRAME OBJECT EMBED SVG CANVAS VIDEO AUDIO DIALOG'.split(' '));
        const address = value => {
            try {
                const u = new URL(value, location.href);
                return u.protocol === 'https:' || u.protocol === 'http:' ? u.href : '';
            } catch (e) { return '' }
        };
        // New elements are made and only text, links and pictures are carried over.
        const copy = (from, into, depth) => {
            for (const node of from.childNodes) {
                if (node.nodeType === 3) { into.appendChild(document.createTextNode(node.nodeValue)); continue }
                if (node.nodeType !== 1 || depth > 60) continue;
                const tag = node.tagName.toUpperCase();
                if (drop.has(tag) || node.hidden || node.getAttribute('aria-hidden') === 'true') continue;
                if (getComputedStyle(node).display === 'none') continue;
                if (junk.test(named(node)) && !node.matches('p,pre,code,h1,h2,h3,article,main')) continue;
                if (node.matches('div,ul,ol,section')) {
                    const all = node.textContent.trim().length;
                    let linked = 0;
                    for (const a of node.querySelectorAll('a')) linked += a.textContent.trim().length;
                    if (all > 0 && all < 600 && linked / all > 0.6) continue;
                }
                if (!keep.has(tag)) { copy(node, into, depth + 1); continue }
                const made = document.createElement(tag.toLowerCase());
                if (tag === 'A') {
                    const href = address(node.getAttribute('href') || '');
                    if (href) made.href = href;
                }
                if (tag === 'IMG') {
                    const src = address(node.getAttribute('data-src') || node.currentSrc || node.getAttribute('src') || '');
                    if (!src || (node.naturalWidth > 0 && node.naturalWidth < 60)) continue;
                    made.src = src;
                    made.alt = node.alt || '';
                }
                copy(node, made, depth + 1);
                if (!made.firstChild && !made.matches('img,br,hr,td,th')) continue;
                into.appendChild(made);
            }
        };

        const host = document.createElement('velum-reader');
        host.id = 'velum-reader';
        for (const [k, v] of [['all', 'initial'], ['position', 'fixed'], ['inset', '0'], ['z-index', '2147483647'], ['display', 'block'], ['overflow', 'auto']])
            host.style.setProperty(k, v, 'important');
        host.style.setProperty('--size', look.size + 'px');
        host.style.setProperty('color-scheme', look.dark ? 'dark' : 'light', 'important');     // for the scroll bar
        host.dataset.overflow = document.documentElement.style.overflow;
        const root = host.attachShadow({ mode: 'open' });
        const c = look.colors;
        const sheet = new CSSStyleSheet();
        sheet.replaceSync(
            '.page{min-height:100%;background:' + c.back + ';color:' + c.text + ';font:var(--size)/1.7 "Inter","Noto Sans",system-ui,sans-serif;padding:48px 24px 120px;box-sizing:border-box}' +
            '.text{max-width:34em;margin:0 auto;overflow-wrap:break-word}' +
            'header{border-bottom:2px solid ' + c.line + ';margin-bottom:1.6em;padding-bottom:1em}' +
            '.title{font-size:2em;line-height:1.15;letter-spacing:-.02em;margin:0 0 .4em}' +
            '.meta{color:' + c.dim + ';font-size:.8em}' +
            'a{color:' + c.accent + '}img{max-width:100%;height:auto;border-radius:12px}figure{margin:1.4em 0}figcaption{color:' + c.dim + ';font-size:.8em}' +
            'h1,h2,h3,h4{line-height:1.25;margin:1.6em 0 .6em}blockquote{margin:1.2em 0;padding:.2em 1.2em;border-left:4px solid ' + c.accent + ';color:' + c.dim + '}' +
            'pre,code{font-family:"JetBrains Mono",monospace;background:' + c.card + ';border-radius:8px}code{padding:.1em .35em;font-size:.9em}' +
            'pre{padding:1em;overflow:auto;font-size:.85em;line-height:1.5}pre code{padding:0;font-size:1em}' +
            'table{border-collapse:collapse;display:block;overflow:auto}td,th{border:1px solid ' + c.line + ';padding:.4em .7em}hr{border:0;border-top:1px solid ' + c.line + '}');
        root.adoptedStyleSheets = [sheet];

        const page = document.createElement('div');
        page.className = 'page';
        const text = document.createElement('article');
        text.className = 'text';
        copy(best, text, 0);

        // the headline goes on top, once
        const heading = best.querySelector('h1') || document.querySelector('h1');
        const og = document.querySelector('meta[property="og:title"]');
        const name = ((heading && heading.textContent) || (og && og.content) || document.title).trim();
        for (const h of text.querySelectorAll('h1'))
            if (h.textContent.trim() === name) h.remove();
        const words = text.textContent.split(/\\s+/).filter(Boolean).length;
        const header = document.createElement('header');
        const title = document.createElement('h1');
        title.className = 'title';
        title.textContent = name;
        const meta = document.createElement('div');
        meta.className = 'meta';
        meta.textContent = location.hostname + ' · ' + Math.max(1, Math.round(words / 220)) + ' ' + look.minutes;
        header.append(title, meta);
        text.prepend(header);
        page.appendChild(text);
        root.appendChild(page);
        document.documentElement.style.overflow = 'hidden';
        document.documentElement.appendChild(host);
        return true;
    }`
}
