import QtQuick
import QtQuick.Window
import QtWebEngine

// A small window that stays on top and shows one tab's video. The tab's page itself is
// moved in here, so playback goes on without a reload; closing the window moves it back.
Window {
    id: mini
    property WebEngineView page: null
    property alias stage: stage
    property bool paused: false
    signal backRequested()

    // Finds the biggest playing video and lets it fill the page. Returns its size, or null.
    readonly property string enterScript: `(() => {
        const found = [...document.querySelectorAll('video')].filter(v => v.readyState > 0 && v.videoWidth > 0);
        if (!found.length) return null;
        const area = v => { const r = v.getBoundingClientRect(); return r.width * r.height };
        found.sort((a, b) => (a.paused - b.paused) || (area(b) - area(a)));
        const video = found[0];
        video.setAttribute('data-velum-mini', '');
        for (let e = video.parentElement; e; e = e.parentElement) e.setAttribute('data-velum-path', '');
        const style = document.createElement('style');
        style.id = 'velum-mini';
        style.textContent =
            'html,body{overflow:hidden!important;background:#000!important}' +
            'body *{visibility:hidden!important}' +
            '[data-velum-path]{transform:none!important;translate:none!important;scale:none!important;filter:none!important;' +
            'backdrop-filter:none!important;perspective:none!important;contain:none!important;container-type:normal!important;' +
            'will-change:auto!important;opacity:1!important;clip-path:none!important;mask:none!important;animation:none!important;z-index:2147483647!important}' +
            'video[data-velum-mini]{visibility:visible!important;position:fixed!important;inset:0!important;width:100vw!important;' +
            'height:100vh!important;max-width:none!important;max-height:none!important;margin:0!important;padding:0!important;' +
            'transform:none!important;object-fit:contain!important;background:#000!important;opacity:1!important;z-index:2147483647!important}';
        document.documentElement.appendChild(style);
        return { width: video.videoWidth, height: video.videoHeight, paused: video.paused };
    })()`

    // puts the page back as it was
    readonly property string leaveScript: `(() => {
        document.getElementById('velum-mini')?.remove();
        for (const name of ['data-velum-mini', 'data-velum-path'])
            for (const e of document.querySelectorAll('[' + name + ']')) e.removeAttribute(name);
    })()`

    function togglePlay() {
        page?.runJavaScript(`(() => {
            const v = document.querySelector('video[data-velum-mini]');
            if (!v) return false;
            if (v.paused) { v.play(); return false }
            v.pause(); return true;
        })()`, WebEngineScript.ApplicationWorld, result => mini.paused = result === true)
    }

    // Compositors recognise this title (Firefox uses it) and float and pin the window.
    title: "Picture-in-Picture"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    color: "black"
    width: 480
    height: 270
    minimumWidth: 240
    minimumHeight: 135
    onClosing: close => { close.accepted = false; mini.backRequested() }

    Item { id: stage; anchors.fill: parent }

    // controls appear while the pointer is over the window
    Item {
        anchors.fill: parent
        z: 2
        HoverHandler { id: over }
        MouseArea {
            anchors.fill: parent
            onPressed: mini.startSystemMove()
        }
        Rectangle {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
            width: controls.implicitWidth + 12
            height: 40
            radius: Theme.radius
            color: Qt.alpha(Theme.window, 0.92)
            border.color: Theme.line
            opacity: over.hovered ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.quick } }
            Row {
                id: controls
                anchors.centerIn: parent
                spacing: 4
                IconButton { symbol: mini.paused ? "play" : "pause"; hint: mini.paused ? Lang.t("Oynat", "Play") : Lang.t("Duraklat", "Pause"); onClicked: mini.togglePlay() }
                IconButton { symbol: "pip"; hint: Lang.t("Sekmeye geri al", "Back to the tab"); onClicked: mini.backRequested() }
            }
        }
    }
}
