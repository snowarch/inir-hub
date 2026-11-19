pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The dash: pinned and running apps on a strip of glass, and the key to the app grid.
NGlass {
    id: root

    required property string output
    // The room along its edge, for fitting the icons when their size is left to the dash.
    property real room: 1000
    signal menuAsked(var app, point at)

    readonly property var options: Config.options?.nihil?.dash
    // Size and glass; the desktop dock passes its own block.
    property var look: root.options
    // The overview follows `dash.position`; the desktop dock sets its own edge.
    property string position: root.options?.position ?? "left"
    readonly property bool vertical: root.position === "left" || root.position === "right"
    readonly property string showApps: (Config.options?.nihil?.modules?.appGrid ?? true) ? (root.options?.showApps ?? "end") : "hidden"
    readonly property var activeWorkspace: NihilState.workspacesOn(root.output).find(ws => ws.is_active)
    readonly property var apps: (TaskbarApps.apps ?? []).filter(app => {
        if (app.appId === "SEPARATOR") return false
        if (!(root.options?.isolateWorkspace ?? false)) return true
        return NihilState.windowsOn(root.activeWorkspace?.id).some(win => win.app_id === app.appId)
    })
    readonly property int keys: root.apps.length + (root.showApps === "hidden" ? 0 : 1)
    readonly property real iconSize: {
        const asked = root.look?.iconSize ?? 48
        if (asked > 0) return NihilStyle.s(asked)
        return NihilStyle.clamp((root.room - NihilStyle.s(12)) / Math.max(1, root.keys) - NihilStyle.s(12), NihilStyle.s(24), NihilStyle.s(64))
    }
    // The room around each icon grows with it, so a small dash stays small.
    readonly property real inset: NihilStyle.clamp(root.iconSize * 0.2, NihilStyle.s(5), NihilStyle.s(12))
    readonly property real cell: root.iconSize + root.inset
    readonly property real along: root.keys * root.cell + root.inset
    readonly property real across: root.cell + root.inset
    readonly property string tone: root.look?.tone ?? "default"

    implicitWidth: root.vertical ? root.across : root.along
    implicitHeight: root.vertical ? root.along : root.across
    radius: Math.min(root.look?.radius ?? 20, root.across / 2)
    tint: Qt.alpha(root.tone === "light" ? "#FFFFFF" : root.tone === "dark" ? "#000000" : NihilStyle.void_, root.look?.opacity ?? 0.2)
    tracks: true

    function windowsOf(app: var): var { return (NiriService.windows ?? []).filter(win => win.app_id === app.appId) }
    function launch(app: var): void {
        const entry = AppSearch.lookupDesktopEntry(app.appId)
        if (entry) AppSearch.launchEntry(entry)
        NihilState.closeOverview()
    }
    function press(app: var): void {
        const windows = root.windowsOf(app)
        const mode = root.options?.click ?? "activate"
        if (windows.length === 0 || mode === "newWindow") { root.launch(app); return }
        const here = windows.filter(win => win.workspace_id === root.activeWorkspace?.id)
        if (mode === "workspaceFirst" && here.length === 0) {
            NiriService.switchToWorkspaceById(windows[0].workspace_id)
            return
        }
        const recent = NiriService.mruWindowIds ?? []
        const pool = mode === "preferCurrent" && here.length > 0 ? here : windows
        const best = pool.slice().sort((a, b) => {
            const rank = id => { const at = recent.indexOf(id); return at < 0 ? recent.length : at }
            return rank(a.id) - rank(b.id)
        })[0]
        NiriService.focusWindow(best.id)
        NihilState.closeOverview()
    }
    // The wheel over an icon walks through that app's windows.
    function cycle(app: var, by: int): void {
        const everywhere = (root.options?.scroll ?? "workspace") === "cycleWindowsAll"
        const windows = root.windowsOf(app).filter(win => everywhere || win.workspace_id === root.activeWorkspace?.id)
        if (windows.length === 0) return
        const at = windows.findIndex(win => win.is_focused)
        NiriService.focusWindow(windows[(at + by + windows.length) % windows.length].id)
    }

    Component {
        id: appsKey
        NButton {
            width: root.cell
            height: root.cell
            radius: NihilStyle.rCard
            tone: "transparent"
            icon: "apps"
            iconSize: root.iconSize * 0.6
            lit: NihilState.view === "apps"
            Accessible.name: Translation.tr("Show apps")
            onClicked: NihilState.toggleOverview("apps")
        }
    }

    WheelHandler {
        enabled: (root.options?.scroll ?? "workspace") === "workspace"
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => NihilState.stepWorkspace(root.output, event.angleDelta.y > 0 ? -1 : 1)
    }

    Grid {
        anchors.centerIn: parent
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1

        Loader { active: root.showApps === "start"; visible: active; sourceComponent: appsKey }

        Repeater {
            model: root.apps
            NButton {
                id: key
                required property var modelData
                readonly property int running: root.windowsOf(key.modelData).length
                readonly property bool urgent: root.windowsOf(key.modelData).some(win => win.is_urgent)
                width: root.cell
                height: root.cell
                radius: NihilStyle.rCard
                tone: key.urgent ? NihilStyle.pieceRaised : "transparent"
                Accessible.name: AppSearch.lookupDesktopEntry(key.modelData.appId)?.name ?? key.modelData.appId
                onClicked: mouse => {
                    if (mouse?.button === Qt.MiddleButton) root.launch(key.modelData)
                    else if (mouse?.button === Qt.RightButton) root.menuAsked(key.modelData, key.mapToItem(null, mouse.x, mouse.y))
                    else root.press(key.modelData)
                }
                onWheel: wheel => {
                    const mode = root.options?.scroll ?? "workspace"
                    if (mode === "cycleWindows" || mode === "cycleWindowsAll") root.cycle(key.modelData, wheel.angleDelta.y > 0 ? -1 : 1)
                    else wheel.accepted = false
                }
                NAppIcon {
                    anchors.centerIn: parent
                    appId: key.modelData.appId
                    size: root.iconSize
                    scale: key.containsMouse ? 1.1 : 1
                    Behavior on scale { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutBack } }
                }
                Row {
                    visible: (root.options?.runningDots ?? true) && key.running > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(1)
                    spacing: NihilStyle.s(3)
                    Repeater {
                        model: (root.options?.runningStyle ?? "dot") === "line" ? 1 : Math.min(key.running, 4)
                        Rectangle {
                            width: (root.options?.runningStyle ?? "dot") === "line" ? root.iconSize * 0.5 : NihilStyle.s(4)
                            height: NihilStyle.s((root.options?.runningStyle ?? "dot") === "line" ? 3 : 4)
                            radius: height / 2
                            color: NihilStyle.accent
                        }
                    }
                }
            }
        }

        Loader { active: root.showApps === "end"; visible: active; sourceComponent: appsKey }
    }
}
