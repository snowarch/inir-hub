import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "docker.js" as Docker

// Docker state, polling, lifecycle actions and parsing. No drawing: the
// desktop card and any future family sidebar host share this one backend.

Item {
    id: root
    visible: false
    width: 0
    height: 0

    // Set by the surface that is showing: the desktop card or a sidebar host.
    property bool active: false

    property var snapshot: null
    property string error: ""
    property bool loading: false
    property string selectedId: ""
    property string pendingAction: ""
    property string actionNotice: ""
    property string actionError: ""
    property var cpuHistory: []

    readonly property int refreshSeconds: Math.max(1, Math.min(60,
        Number(CustomWidgets.getConfigValue("inir-docker", "refreshSeconds", 3))))
    readonly property int maxContainers: Math.max(1, Math.min(20,
        Number(CustomWidgets.getConfigValue("inir-docker", "maxContainers", 6))))
    readonly property bool showStopped: Boolean(CustomWidgets.getConfigValue("inir-docker", "showStopped", true))
    readonly property bool showSummary: Boolean(CustomWidgets.getConfigValue("inir-docker", "showSummary", true))
    readonly property bool showSparkline: Boolean(CustomWidgets.getConfigValue("inir-docker", "showSparkline", true))
    readonly property string filterText: String(CustomWidgets.getConfigValue("inir-docker", "filter", ""))
    readonly property string layout: {
        const value = String(CustomWidgets.getConfigValue("inir-docker", "layout", "dashboard"))
        return ["dashboard", "compact", "tiles"].includes(value) ? value : "dashboard"
    }

    readonly property var containers: (root.snapshot && root.snapshot.containers) ? root.snapshot.containers : []
    readonly property var filtered: {
        const list = Docker.visibleContainers(root.containers, root.filterText, "all", "", false)
        return root.showStopped ? list : list.filter(container => container.status === "running")
    }
    readonly property var shown: root.filtered.slice(0, root.maxContainers)
    readonly property int hiddenCount: Math.max(0, root.filtered.length - root.shown.length)
    readonly property var selected: {
        const id = root.selectedId
        if (id.length === 0) return null
        return root.containers.find(container => container.fullId === id || container.name === id) ?? null
    }
    readonly property string targetLabel: (root.snapshot && root.snapshot.target)
        ? Docker.targetLabel(root.snapshot.target) : ""
    readonly property bool available: Boolean(root.snapshot && root.snapshot.dockerAvailable)
    readonly property bool hasData: root.snapshot !== null
    readonly property bool busy: snapshotProc.running || actionProc.running

    readonly property int runningCount: root.filtered.filter(container => container.status === "running").length
    readonly property int totalCount: root.filtered.length
    readonly property real runningShare: root.totalCount > 0 ? root.runningCount / root.totalCount : 0
    readonly property real totalCpu: root.filtered.reduce((sum, container) => {
        const value = parseFloat(String(container.cpuPercent ?? "").replace("%", ""))
        return sum + (isFinite(value) ? value : 0)
    }, 0)
    readonly property real totalMemBytes: root.filtered.reduce((sum, container) => {
        const value = Number(container.memUsageBytes ?? 0)
        return sum + (isFinite(value) ? value : 0)
    }, 0)
    readonly property real hostMemBytes: Number(root.snapshot?.hostMemBytes ?? 0)
    readonly property real memPercent: root.hostMemBytes > 0
        ? Math.min(100, (root.totalMemBytes / root.hostMemBytes) * 100) : 0
    readonly property real cpuChartMax: root.cpuHistory.reduce((max, value) => Math.max(max, value), 10)

    Process {
        id: snapshotProc
        command: Docker.snapshotCommand
        stdout: StdioCollector {
            id: snapshotOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: snapshotErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            root.loading = false
            if (code === 0) {
                try {
                    const next = Docker.parseSnapshot(snapshotOut.text)
                    if (next && next.dockerAvailable) {
                        root.snapshot = next
                        root._recordHistory(next)
                        root.error = ""
                    } else {
                        root.error = Translation.tr("Docker is not reachable")
                    }
                } catch (e) {
                    root.error = Translation.tr("Could not read Docker: ") + String(e)
                }
            } else {
                const line = String(snapshotErr.text ?? "").trim().split("\n")[0]
                root.error = line.length > 0 ? line : Translation.tr("Docker did not answer")
            }
        }
    }

    Process {
        id: actionProc
        stderr: StdioCollector {
            id: actionErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            if (code === 0) {
                root.actionNotice = Translation.tr("%1 complete").arg(root.actionLabel(root.pendingAction))
                root.actionError = ""
            } else {
                const line = String(actionErr.text ?? "").trim().split("\n")[0]
                root.actionError = line.length > 0 ? line : Translation.tr("Docker exited with code %1").arg(code)
            }
            root.pendingAction = ""
            root.refresh()
        }
    }

    Timer {
        id: pollTimer
        interval: root.refreshSeconds * 1000
        repeat: true
        triggeredOnStart: true
        running: root.active
        onTriggered: root.refresh()
    }

    function refresh(): void {
        if (snapshotProc.running) return
        root.loading = true
        snapshotProc.running = true
    }

    function _recordHistory(next): void {
        const list = Docker.visibleContainers(next.containers ?? [], root.filterText, "all", "", false)
            .filter(container => root.showStopped || container.status === "running")
        const cpu = list.reduce((sum, container) => {
            const value = parseFloat(String(container.cpuPercent ?? "").replace("%", ""))
            return sum + (isFinite(value) ? value : 0)
        }, 0)
        const history = root.cpuHistory.slice(-29)
        history.push(cpu)
        root.cpuHistory = history
    }

    function selectContainer(container): void {
        root.selectedId = container.fullId
        root.pendingAction = ""
        root.actionError = ""
        root.actionNotice = ""
    }

    function requestAction(action): void {
        if (!root.selected || !Docker.canContainerAction(action, root.selected)) return
        root.pendingAction = action
        root.actionNotice = ""
        root.actionError = ""
    }

    function confirmAction(): void {
        if (!root.selected || root.pendingAction.length === 0 || !root.snapshot) return
        const command = Docker.containerActionCommand(root.snapshot.target, root.pendingAction, root.selected)
        if (command.length === 0) {
            root.actionError = Translation.tr("Docker target unavailable")
            root.pendingAction = ""
            return
        }
        actionProc.command = command
        actionProc.running = true
    }

    function cancelAction(): void {
        root.pendingAction = ""
    }

    function openLogs(follow): void {
        if (!root.selected || !root.snapshot) return
        const command = Docker.logsCommand(root.snapshot.target, root.selected, follow === true)
        if (command.length > 0) Quickshell.execDetached(command)
    }

    function actionLabel(action): string {
        if (action === "start") return Translation.tr("Start")
        if (action === "stop") return Translation.tr("Stop")
        if (action === "restart") return Translation.tr("Restart")
        return action
    }

    function statusLabel(status): string {
        const labels = {
            running: Translation.tr("running"),
            exited: Translation.tr("exited"),
            created: Translation.tr("created"),
            paused: Translation.tr("paused"),
            restarting: Translation.tr("restarting"),
            dead: Translation.tr("dead"),
            removing: Translation.tr("removing")
        }
        return labels[status] ?? status
    }

    function statusIcon(status): string {
        if (status === "running") return "play_circle"
        if (status === "exited") return "stop_circle"
        if (status === "paused") return "pause_circle"
        if (status === "restarting") return "restart_alt"
        return "circle"
    }

    function percentOf(text): real {
        const value = parseFloat(String(text ?? "").replace("%", ""))
        return isFinite(value) ? Math.max(0, Math.min(100, value)) : 0
    }
}
