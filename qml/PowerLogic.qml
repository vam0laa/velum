import QtQuick
import QtWebEngine

// Putting tabs to sleep: by time, by mode and to stay under the memory limit.
// "app" is the window these belong to.
QtObject {
    property var app

    function setPowerMode(mode) {
        app.powerMode = ["game", "saver"].includes(mode) ? mode : "balanced"
        app.say(app.powerMode === "game" ? Lang.t("Oyun modu: arka sekmeler birkaç saniyede donar.", "Game mode: background tabs freeze within seconds.")
          : app.powerMode === "saver" ? Lang.t("Tasarruf modu: arka sekmeler çabuk uyur.", "Saver mode: background tabs sleep quickly.")
          : Lang.t("Dengeli mod.", "Balanced mode."))
    }

    // Which tabs to put away so that `used` comes down to `limit`: the ones unseen the
    // longest first. `candidates`: [{ index, mb, since }].
    function pickToSleep(candidates, used, limit) {
        const chosen = []
        for (const c of candidates.slice().sort((a, b) => a.since - b.since)) {
            if (used <= limit)
                break
            chosen.push(c.index)
            used -= c.mb
        }
        return chosen
    }

    function keepUnderLimit() {
        const pages = []
        for (let i = 0; i < app.tabs.count; i++)
            pages.push(app.views.itemAt(i) as WebEngineView)
        const pids = pages.map(p => p && p.lifecycleState !== WebEngineView.LifecycleState.Discarded ? p.renderProcessPid : 0)
        const found = Resources.sample(pids)
        app.memoryUsed = Math.round(found.total.memory)
        if (app.memoryLimit <= 0 || app.memoryUsed <= app.memoryLimit)
            return
        const candidates = []
        pages.forEach((page, i) => {
            if (!page || page.visible || page === app.miniPage || page.hiddenSince === 0 || pids[i] <= 0 || app.tabs.get(i).pinned || page.recentlyAudible
                    || page.loading || page.recommendedState === WebEngineView.LifecycleState.Active)
                return
            // tabs of one site may share a process: each counts its part
            const sharing = pids.filter(p => p === pids[i]).length
            candidates.push({ index: i, mb: (found[String(pids[i])]?.memory ?? 0) / sharing, since: page.hiddenSince })
        })
        for (const i of app.pickToSleep(candidates, app.memoryUsed, app.memoryLimit))
            (app.views.itemAt(i) as WebEngineView).lifecycleState = WebEngineView.LifecycleState.Discarded
    }

    // How far a tab that has not been seen for `idle` ms may be put to sleep:
    // `advice` is what the engine says is safe (it knows about sound, downloads, open connections).
    function sleepTarget(idle, advice, pinned, audible, loading) {
        if (pinned || audible || loading)
            return WebEngineView.LifecycleState.Active
        if (idle >= app.discardAfter && advice === WebEngineView.LifecycleState.Discarded)
            return WebEngineView.LifecycleState.Discarded
        if (idle >= app.freezeAfter && advice !== WebEngineView.LifecycleState.Active)
            return WebEngineView.LifecycleState.Frozen
        return WebEngineView.LifecycleState.Active
    }

    function sleepIdleTabs(now) {
        for (let i = 0; i < app.tabs.count; i++) {
            const page = app.views.itemAt(i) as WebEngineView
            if (!page || page === app.view || page.hiddenSince === 0)
                continue
            const target = app.sleepTarget(now - page.hiddenSince, page.recommendedState, app.tabs.get(i).pinned, page.recentlyAudible, page.loading)
            if (target > page.lifecycleState)        // only ever deeper; looking at it wakes it
                page.lifecycleState = target
        }
    }

    function sleepState(index) { return index >= 0 && index < app.tabs.count ? app.tabs.get(index).asleep : -1 }

    // asked for by hand: as deep as the engine allows
    function sleepTab(index) {
        const page = app.views.itemAt(index) as WebEngineView
        if (page && page !== app.view && !page.visible && page.url.toString() !== "" && !page.loading)
            page.lifecycleState = WebEngineView.LifecycleState.Discarded
    }

    function wakeTab(index) {
        const page = app.views.itemAt(index) as WebEngineView
        if (page) {
            page.lifecycleState = WebEngineView.LifecycleState.Active
            page.hiddenSince = Date.now()
        }
    }

    function sleepOthers() {
        for (let i = 0; i < app.tabs.count; i++)
            if (!app.tabs.get(i).pinned)
                app.sleepTab(i)
    }

    function measure() {
        const pages = []
        for (let i = 0; i < app.tabs.count; i++)
            pages.push(app.views.itemAt(i) as WebEngineView)
        const found = Resources.sample(pages.map(p => p ? p.renderProcessPid : 0))
        const users = {}
        for (const p of pages)
            if (p && p.renderProcessPid > 0)
                users[p.renderProcessPid] = (users[p.renderProcessPid] ?? 0) + 1
        app.resources.rows = pages.map((p, i) => {
            const use = p ? found[String(p.renderProcessPid)] : undefined
            return { index: i, title: app.tabs.get(i).title || Lang.t("Yeni sekme", "New tab"), memory: use?.memory ?? 0, cpu: use?.cpu ?? 0,
                     state: app.tabs.get(i).asleep, shared: p ? users[p.renderProcessPid] > 1 : false, current: p === app.view }
        }).sort((a, b) => b.memory - a.memory)
        app.resources.total = found.total
    }
}
