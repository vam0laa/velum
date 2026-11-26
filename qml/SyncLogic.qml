import QtQuick

// Synchronisation without a server: a locked file in a folder you choose (one that another
// program carries between your computers). Bookmarks of both sides are put together, and
// what you removed stays removed.
// "app" is the window these belong to.
QtObject {
    id: sync
    property var app
    readonly property string fileName: "velum-sync.velumbackup"
    readonly property string keyringName: "velum://sync"      // where the password is kept
    property string secret: ""
    property string status: ""          // a sentence for the settings
    property bool working: false

    function on() { return app.syncFolder !== "" }
    function file() { return Files.toUrl(app.syncFolder + "/" + fileName) }

    // the parts that travel and are compared
    function essence(d) { return JSON.stringify([d.bookmarks ?? [], d.removed ?? []]) }

    function run() {
        if (!on() || working || app.secondary)
            return
        if (secret === "") {
            Passwords.password(keyringName, "sync", found => {
                if (found === null) {
                    sync.status = Lang.t("Eşitleme parolası anahtarlıkta bulunamadı. Eşitlemeyi yeniden başlat.", "The password is not in the keyring. Start synchronising again.")
                    return
                }
                sync.secret = found
                sync.run()
            })
            return
        }
        working = true
        const read = Library.readLocked(file(), secret)
        if (read.found && !read.opened) {
            // never written over: it may be another password's, or half copied
            status = Lang.t("Eşitleme dosyası açılamadı: parola yanlış ya da dosya henüz tam kopyalanmamış.", "The file did not open: wrong password, or not fully copied yet.")
            working = false
            return
        }
        let theirs = null
        if (read.opened) {
            if (!app.backup.apply(read.text, false)) {
                status = Lang.t("Klasördeki dosya bir Velum dosyası değil.", "The file in the folder is not Velum's.")
                working = false
                return
            }
            theirs = JSON.parse(read.text)
        }
        const mine = app.backup.collect()
        delete mine.look
        if (theirs === null || essence(theirs) !== essence(mine)) {
            if (!Library.writeLocked(file(), JSON.stringify(mine), secret)) {
                status = Lang.t("Klasöre yazılamadı.", "The folder could not be written to.")
                working = false
                return
            }
        }
        status = Lang.t("Eşitlendi: ", "Synchronised: ") + Qt.formatTime(new Date(), "HH:mm") + " · " + mine.bookmarks.length + Lang.t(" yer imi", " bookmarks")
        working = false
    }

    // `done` is told true once the password is safely in the keyring
    function start(folder, password) {
        if (folder === "" || password.length < 8) {
            status = Lang.t("Bir klasör ve en az 8 karakterlik bir parola gerekli.", "A folder and a password of at least 8 characters are needed.")
            return
        }
        Passwords.save(keyringName, "sync", password, ok => {
            if (!ok) {
                sync.status = Lang.t("Parola anahtarlığa kaydedilemedi.", "The password could not be kept in the keyring.")
                return
            }
            sync.secret = password
            sync.app.syncFolder = folder
            sync.run()
        })
    }
    function stop() {
        app.syncFolder = ""
        secret = ""
        status = Lang.t("Eşitleme kapatıldı. Klasördeki dosya duruyor.", "Synchronising is off. The file in the folder stays.")
        Passwords.remove(keyringName, "sync", () => {})
    }

    property Timer regular: Timer { interval: 5 * 60 * 1000; repeat: true; running: sync.app !== undefined && sync.app.syncFolder !== "" && !sync.app.secondary; onTriggered: sync.run() }
    // a little after the start, and a little after bookmarks change
    property Timer soon: Timer { interval: 4000; onTriggered: sync.run() }
    function changed() { if (on() && !working) soon.restart() }
}
