pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "stats.js" as Stats

// The one account every face shows. It holds what was fetched and fetches again when a face asks
// for it; the timers that ask live in the faces, so nothing runs while no face is on screen.
Singleton {
    id: root

    // ── Where the helper script is (it sits beside this file in the widget's folder) ──
    readonly property var entry: CustomWidgets.widgets.find(widget => widget.id === "dev-stats") ?? null
    readonly property string folder: root.entry && root.entry.dirPath ? String(root.entry.dirPath) : ""
    readonly property bool installed: root.folder.length > 0

    // ── What the person keeps ──
    readonly property string accountText: String(CustomWidgets.getConfigValue("dev-stats", "account", ""))
    readonly property bool discover: CustomWidgets.getConfigValue("dev-stats", "discover", true) !== false
    readonly property int weeks: Math.max(4, Math.min(53, Number(CustomWidgets.getConfigValue("dev-stats", "weeks", 26)) || 26))
    readonly property int refreshMinutes: Math.max(5, Math.min(240, Number(CustomWidgets.getConfigValue("dev-stats", "refreshMinutes", 30)) || 30))
    readonly property int refreshInterval: root.refreshMinutes * 60000

    // ── What the helper answered ──
    property var discovered: []
    property var days: null
    property string fetchedKey: ""
    property double fetchedAt: 0
    property var fetchedOn: new Date()

    // ── What is happening now ──
    property bool loading: false
    property string error: ""
    property bool _accountsDone: false
    property bool _accountsRunning: false
    property bool _fetchRunning: false
    property var _target: null

    readonly property var account: Stats.account(root.accountText, root.discovered)
    readonly property string accountKey: Stats.key(root.account)
    readonly property bool hasData: root.days !== null && root.fetchedKey === root.accountKey
    readonly property bool stale: !root.hasData || Date.now() - root.fetchedAt >= root.refreshInterval
    readonly property var summary: Stats.summary(root.hasData ? root.days : null, root.weeks, root.fetchedOn)
    readonly property bool busy: root.loading || root._accountsRunning || root._fetchRunning

    // No account, no data yet, or the numbers are old: fetch. Every face calls this while it shows.
    function refresh(force): void {
        if (!root.installed) {
            root.error = Stats.errorWord("no-helper")
            return
        }
        if (root._fetchRunning || root._accountsRunning)
            return
        const shown = root.account
        if (!shown) {
            if (root.discover && !root._accountsDone)
                root.loadAccounts()
            return
        }
        if (!force && root.hasData && !root.stale)
            return
        root.fetch(shown)
    }

    function loadAccounts(): void {
        if (root._accountsRunning || !root.installed)
            return
        root._accountsRunning = true
        root._target = null
        accountsProc.running = true
    }

    function fetch(shown): void {
        root._target = shown
        root.error = ""
        root.loading = true
        root._fetchRunning = true
        fetchProc.running = true
    }

    // The words a face shows when there is nothing to draw.
    readonly property string emptyWords: !root.installed ? Translation.tr(Stats.errorWord("no-helper"))
        : root.error.length > 0 ? root.error
        : root.account ? Translation.tr("Fetching your contributions…")
        : Translation.tr("Add an account in this widget's settings: host/user, like github.com/you")

    Process {
        id: accountsProc
        command: ["bash", root.folder + "/dev-stats.sh", "accounts"]
        stdout: StdioCollector {
            id: accountsOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: accountsErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            root._accountsRunning = false
            root._accountsDone = true
            const text = String(accountsOut.text ?? "").trim()
            try {
                const list = text.length > 0 ? JSON.parse(text) : []
                root.discovered = Array.isArray(list) ? list.filter(one => one && one.provider && one.host && one.user) : []
                root.error = ""
            } catch (failure) {
                root.discovered = []
                root.error = Translation.tr(Stats.errorWord(String(accountsErr.text ?? "").trim()))
            }
            // An account turned up: its numbers are the next thing to get.
            if (root.account && !root.hasData)
                root.refresh(false)
        }
    }

    Process {
        id: fetchProc
        command: root._target ? ["bash", root.folder + "/dev-stats.sh", "fetch",
            String(root._target.provider), String(root._target.host), String(root._target.user)] : []
        stdout: StdioCollector {
            id: fetchOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: fetchErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            root._fetchRunning = false
            root.loading = false
            const wanted = root._target
            if (!wanted)
                return
            if (code !== 0) {
                root.error = Translation.tr(Stats.errorWord(String(fetchErr.text ?? "").trim()))
                return
            }
            try {
                const answer = JSON.parse(String(fetchOut.text ?? "").trim())
                if (!answer || typeof answer.days !== "object" || answer.days === null)
                    throw new Error("no days")
                root.days = answer.days
                root.fetchedKey = root.accountKey
                root.fetchedAt = Date.now()
                root.fetchedOn = new Date()
                root.error = ""
            } catch (failure) {
                root.error = Translation.tr(Stats.errorWord("request-failed"))
            }
        }
    }
}
