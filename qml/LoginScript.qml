import QtQuick

// What Velum does inside pages for passwords. Everything here runs in a world of its
// own: the page's code cannot call it, read its variables or reach its channel to Velum.
QtObject {
    // the visible name field that belongs to a password field
    readonly property string helpers: `
        const shown = e => {
            const r = e.getBoundingClientRect(), s = getComputedStyle(e);
            return r.width > 2 && r.height > 2 && s.visibility !== 'hidden' && Number(s.opacity) > 0.05 && !e.disabled && !e.readOnly;
        };
        const nameField = field => {
            const all = [...(field.form || document).querySelectorAll('input')];
            const before = all.slice(0, all.indexOf(field)).filter(e => ['text', 'email', 'tel'].includes(e.type) && shown(e));
            return before.find(e => /username|email/.test(e.autocomplete)) || before[before.length - 1] || null;
        };`

    // notices login forms, and logins being sent, on secure pages only
    readonly property string watch: `(() => {
        const local = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
        if (location.protocol !== 'https:' && !(location.protocol === 'http:' && local)) return;
        if (typeof qt === 'undefined' || !qt.webChannelTransport) return;
        ` + helpers + `
        let velum = null, had = false, last = '', lastTime = 0, waiting = 0;
        const look = () => {
            waiting = 0;
            const has = [...document.querySelectorAll('input[type=password]')].some(shown);
            if (velum && has !== had) { had = has; velum.form(location.origin, has) }
        };
        const soon = () => { if (!waiting) waiting = setTimeout(look, 400) };
        new QWebChannel(qt.webChannelTransport, channel => { velum = channel.objects.velum; look() });
        const start = () => {
            new MutationObserver(soon).observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ['type', 'style', 'class', 'hidden'] });
            soon();
        };
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();

        const send = scope => {
            if (!velum || !scope || !scope.querySelectorAll) return;
            // a form sent by the page on its own is not a login you made
            if (navigator.userActivation && !navigator.userActivation.isActive) return;
            const fields = [...scope.querySelectorAll('input[type=password]')].filter(e => e.value);
            if (!fields.length) return;
            // with "old, new, new again" the last one is what will be valid
            const secret = fields[fields.length - 1].value;
            const named = nameField(fields[0]) || document.querySelector('input[autocomplete~=username]');
            const user = named ? named.value.trim() : '';
            const key = user + String.fromCharCode(10) + secret, now = Date.now();
            if (key === last && now - lastTime < 5000) return;
            last = key; lastTime = now;
            if (user.length <= 200 && secret.length <= 1000) velum.offer(location.origin, user, secret);
        };
        document.addEventListener('submit', e => { if (e.isTrusted) send(e.target) }, true);
        document.addEventListener('keydown', e => {
            if (e.isTrusted && e.key === 'Enter' && e.target.type === 'password') send(e.target.form || document);
        }, true);
        document.addEventListener('click', e => {
            const button = e.isTrusted && e.target.closest && e.target.closest('button, input[type=submit], [role=button]');
            if (button) send(button.form || document);
        }, true);
    })()`

    // fills the first visible login form, only if the page is still the one asked about
    function fill(origin, user, password) {
        return "((origin, user, password) => {" + helpers + `
            if (location.origin !== origin) return false;
            const field = [...document.querySelectorAll('input[type=password]')].find(shown);
            if (!field) return false;
            const put = (e, v) => {
                Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set.call(e, v);
                e.dispatchEvent(new Event('input', { bubbles: true }));
                e.dispatchEvent(new Event('change', { bubbles: true }));
            };
            const named = nameField(field);
            if (named && user) put(named, user);
            put(field, password);
            return true;
        })(` + [origin, user, password].map(v => JSON.stringify(String(v))).join(",") + ")"
    }
}
