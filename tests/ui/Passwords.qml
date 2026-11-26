pragma Singleton
import QtQuick
// Stand-in for the keyring, which has its own test: kept in memory, answering at once.
QtObject {
    property var store: []
    function origin(url) { const m = String(url).match(/^https:\/\/[^\/?#]+/); return m ? m[0] : "" }
    function accounts(origin, done) { done(store.filter(a => origin === "" || a.origin === origin).map(a => ({ origin: a.origin, user: a.user }))) }
    function check(origin, user, password, done) {
        const mine = store.filter(a => a.origin === origin && (a.user === user || user === ""))
        done(mine.some(a => a.password === password) ? "same" : mine.some(a => a.user === user) ? "changed" : "new")
    }
    function save(origin, user, password, done) { store = store.filter(a => a.origin !== origin || a.user !== user).concat([{ origin: origin, user: user, password: password }]); done(true) }
    function password(origin, user, done) { const a = store.find(x => x.origin === origin && x.user === user); done(a ? a.password : null) }
    function remove(origin, user, done) { store = store.filter(a => a.origin !== origin || a.user !== user); done(true) }
    function copy(origin, user, done) { done(true) }
    function generate(length) { return "Aa2!".repeat(8).slice(0, length) }
    function importCsv(file, done) { save("https://csv.example", "u", "p", () => {}); done(1) }
    function exportCsv(file, done) { done(store.length) }
}
