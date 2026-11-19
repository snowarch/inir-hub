pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The dock's strip of glass: the pinned apps, a hairline, the running ones, the key to the app grid. Icons swell under
// the pointer, a pinned icon dragged along the strip takes a new place, an app clicked without a window bounces until
// its window comes. Running apps carry dots on the side towards the screen's edge; the focused one a line in the accent.
NGlass {
    id: root

    required property string output
    required property string edge
    property var options: Config.options?.nihil?.dock
    signal menuAsked(var app, point at)
    // The app under the pointer and its key, or null when the pointer leaves.
    signal pointed(var app, var key)

    readonly property bool vertical: root.edge !== "bottom"
    readonly property var dash: Config.options?.nihil?.dash
    readonly property var activeWorkspace: NihilState.workspacesOn(root.output).find(ws => ws.is_active)
    // Pinned apps, a separator, the running ones; a separator only between two groups.
    readonly property var entries: {
        const list = (TaskbarApps.apps ?? []).filter(app => app.appId !== "SEPARATOR")
        const pinned = list.filter(app => app.pinned)
        const running = list.filter(app => !app.pinned)
        return pinned.length > 0 && running.length > 0 ? [...pinned, { appId: "SEPARATOR" }, ...running] : [...pinned, ...running]
    }
    readonly property var pinnedIds: (TaskbarApps.apps ?? []).filter(app => app.pinned).map(app => app.appId)
    readonly property bool gridKey: (Config.options?.nihil?.modules?.appGrid ?? true) && (root.options?.appGrid ?? true)

    readonly property real iconSize: NihilStyle.s(root.options?.iconSize ?? 44)
    readonly property real magnify: NihilStyle.clamp(Number(root.options?.magnify ?? 0.35), 0, 1)
    readonly property real inset: NihilStyle.clamp(root.iconSize * 0.2, NihilStyle.s(6), NihilStyle.s(12))
    readonly property real cell: root.iconSize + root.inset
    readonly property real across: root.cell + root.inset
    // How far a swollen icon reaches past the glass.
    readonly property real reach: root.iconSize * root.magnify
    readonly property string tone: root.options?.tone ?? "default"

    implicitWidth: root.vertical ? root.across : row.implicitWidth + root.inset
    implicitHeight: root.vertical ? row.implicitHeight + root.inset : root.across
    radius: Math.min(NihilStyle.s(root.options?.radius ?? 22), root.across / 2)
    tint: Qt.alpha(root.tone === "light" ? "#FFFFFF" : root.tone === "dark" ? "#000000" : NihilStyle.background, root.options?.opacity ?? 0.6)
    followPointer: true

    // Where the pointer is along the strip, -1 while it is away.
    property real pointer: -1
    HoverHandler {
        onPointChanged: root.pointer = hovered ? (root.vertical ? point.position.y : point.position.x) : -1
        onHoveredChanged: if (!hovered) root.pointer = -1
    }
    function swell(center: real): real {
        if (root.pointer < 0 || root.magnify <= 0 || drag.key) return 1
        const d = Math.abs(center - root.pointer) / (root.cell * 2.4)
        return d >= 1 ? 1 : 1 + root.magnify * (Math.cos(d * Math.PI) + 1) / 2
    }

    function windowsOf(app: var): var { return (NiriService.windows ?? []).filter(win => win.app_id === app.appId) }
    function launch(app: var): void {
        const entry = AppSearch.lookupDesktopEntry(app.appId)
        if (!entry) return
        AppSearch.launchEntry(entry)
        root.starting = Object.assign({}, root.starting, { [app.appId]: Date.now() })
        settle.restart()
    }
    function press(app: var): void {
        const windows = root.windowsOf(app)
        const mode = root.dash?.click ?? "activate"
        if (windows.length === 0 || mode === "newWindow") { root.launch(app); return }
        const here = windows.filter(win => win.workspace_id === root.activeWorkspace?.id)
        if (mode === "workspaceFirst" && here.length === 0) {
            NiriService.switchToWorkspaceById(windows[0].workspace_id)
            return
        }
        const recent = NiriService.mruWindowIds ?? []
        const pool = mode === "preferCurrent" && here.length > 0 ? here : windows
        const rank = id => { const at = recent.indexOf(id); return at < 0 ? recent.length : at }
        const best = pool.slice().sort((a, b) => rank(a.id) - rank(b.id))[0]
        // A click on the app already in front sends its window away, the way a dock does.
        if (best.is_focused && pool.length === 1 && (root.options?.clickMinimizes ?? true)) NihilState.windowAction("minimize", best)
        else NiriService.focusWindow(best.id)
    }
    function cycle(app: var, by: int): void {
        const windows = root.windowsOf(app)
        if (windows.length === 0) return
        const at = windows.findIndex(win => win.is_focused)
        NiriService.focusWindow(windows[(at + by + windows.length) % windows.length].id)
    }

    // Apps asked to start, by id, with when they were asked; each one leaves once its window shows or after a while.
    property var starting: ({})
    Timer {
        id: settle
        interval: 500
        repeat: true
        running: Object.keys(root.starting).length > 0
        onTriggered: {
            const now = Date.now()
            const next = {}
            for (const id in root.starting)
                if (now - root.starting[id] < 8000 && !(NiriService.windows ?? []).some(win => win.app_id === id)) next[id] = root.starting[id]
            root.starting = next
        }
    }

    // A pinned icon being dragged, and the place it would take.
    QtObject {
        id: drag
        property var key: null
        property int target: -1
        function finish(): void {
            if (drag.key && drag.target >= 0) {
                const ids = root.pinnedIds.slice()
                const from = ids.indexOf(drag.key.app.appId)
                if (from >= 0 && from !== drag.target) {
                    ids.splice(drag.target, 0, ids.splice(from, 1)[0])
                    const stored = Config.options?.apps?.pinned ?? []
                    Config.setNestedValue(["apps", "pinned"], ids.map(id =>
                        stored.find(p => String(p).toLowerCase() === id) ?? id))
                }
            }
            drag.key = null
            drag.target = -1
        }
    }

    Grid {
        id: row
        anchors.centerIn: parent
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1

        Repeater {
            model: root.entries
            Item {
                id: slot
                required property var modelData
                required property int index
                readonly property bool separator: slot.modelData.appId === "SEPARATOR"
                width: root.vertical ? root.cell : slot.separator ? root.inset * 2 : root.cell
                height: root.vertical ? (slot.separator ? root.inset * 2 : root.cell) : root.cell

                Rectangle {
                    visible: slot.separator
                    anchors.centerIn: parent
                    width: root.vertical ? root.iconSize * 0.6 : 1
                    height: root.vertical ? 1 : root.iconSize * 0.6
                    color: NihilStyle.border
                }

                MouseArea {
                    id: key
                    readonly property var app: slot.modelData
                    readonly property var windows: root.windowsOf(key.app)
                    readonly property bool focused: key.windows.some(win => win.is_focused)
                    readonly property bool urgent: key.windows.some(win => win.is_urgent)
                    readonly property bool launching: !!root.starting[key.app.appId]
                    readonly property real center: (root.vertical ? slot.y : slot.x) + (root.vertical ? slot.height : slot.width) / 2
                    readonly property bool dragged: drag.key === key
                    property real pressAt: 0
                    property real shift: 0
                    property bool moved: false

                    visible: !slot.separator
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    Accessible.role: Accessible.Button
                    Accessible.name: AppSearch.lookupDesktopEntry(key.app.appId)?.name ?? key.app.appId
                    onContainsMouseChanged: root.pointed(key.containsMouse ? key.app : null, key)
                    onPressed: mouse => {
                        key.pressAt = root.vertical ? mouse.y : mouse.x
                        key.moved = false
                        root.pointed(null, key)
                    }
                    onPositionChanged: mouse => {
                        if (!key.pressed || !(mouse.buttons & Qt.LeftButton) || !key.app.pinned) return
                        const moved = (root.vertical ? mouse.y : mouse.x) - key.pressAt
                        if (!key.dragged && Math.abs(moved) < NihilStyle.s(8)) return
                        drag.key = key
                        key.moved = true
                        key.shift = moved
                        const at = Math.round((key.center + moved - root.inset / 2 - root.cell / 2) / root.cell)
                        drag.target = NihilStyle.clamp(at, 0, root.pinnedIds.length - 1)
                    }
                    onReleased: {
                        if (key.dragged) {
                            key.shift = 0
                            drag.finish()
                        }
                    }
                    onClicked: mouse => {
                        if (key.moved) return
                        if (mouse.button === Qt.MiddleButton) root.launch(key.app)
                        else if (mouse.button === Qt.RightButton) root.menuAsked(key.app, key.mapToItem(null, mouse.x, mouse.y))
                        else root.press(key.app)
                    }
                    onWheel: wheel => {
                        if ((root.dash?.scroll ?? "workspace") === "workspace") NihilState.stepWorkspace(root.output, wheel.angleDelta.y > 0 ? -1 : 1)
                        else root.cycle(key.app, wheel.angleDelta.y > 0 ? -1 : 1)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: root.inset / 4
                        radius: NihilStyle.r(14)
                        color: key.urgent ? Qt.alpha(NihilStyle.accent, 0.22) : "transparent"
                    }

                    NAppIcon {
                        id: icon
                        readonly property real grow: key.dragged ? 1.08 : root.swell(key.center)
                        anchors.centerIn: parent
                        appId: key.app.appId
                        size: root.iconSize
                        opacity: key.dragged ? 0.85 : 1
                        transformOrigin: root.edge === "left" ? Item.Left : root.edge === "right" ? Item.Right : Item.Bottom
                        scale: icon.grow * (key.pressed && !key.dragged ? 0.92 : 1)
                        // A pinned icon follows the hand while dragged; a starting app hops away from the edge.
                        transform: Translate {
                            id: lift
                            x: root.vertical ? (root.edge === "left" ? hop.offset : -hop.offset) : key.shift
                            y: root.vertical ? key.shift : -hop.offset
                        }
                        Behavior on scale { enabled: root.pointer < 0; NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
                    }
                    QtObject {
                        id: hop
                        property real offset: 0
                    }
                    SequentialAnimation {
                        running: key.launching && root.visible
                        loops: Animation.Infinite
                        onStopped: hop.offset = 0
                        NumberAnimation { target: hop; property: "offset"; to: root.iconSize * 0.28; duration: 260; easing.type: Easing.OutQuad }
                        NumberAnimation { target: hop; property: "offset"; to: 0; duration: 340; easing.type: Easing.OutBounce }
                        PauseAnimation { duration: 180 }
                    }

                    // Running marks, on the side towards the edge of the screen.
                    Grid {
                        visible: key.windows.length > 0 && !key.dragged
                        rows: root.vertical ? -1 : 1
                        columns: root.vertical ? 1 : -1
                        spacing: NihilStyle.s(3)
                        x: root.vertical ? (root.edge === "left" ? NihilStyle.s(1) : parent.width - width - NihilStyle.s(1)) : (parent.width - width) / 2
                        y: root.vertical ? (parent.height - height) / 2 : parent.height - height - NihilStyle.s(1)
                        Repeater {
                            model: key.focused ? 1 : Math.min(key.windows.length, 3)
                            Rectangle {
                                readonly property real long_: key.focused ? root.iconSize * 0.42 : NihilStyle.s(4)
                                width: root.vertical ? NihilStyle.s(4) : long_
                                height: root.vertical ? long_ : NihilStyle.s(4)
                                radius: NihilStyle.s(2)
                                color: key.focused ? NihilStyle.accent : Qt.alpha(NihilStyle.text, 0.62)
                            }
                        }
                    }
                }

                // Where a dragged icon would land.
                Rectangle {
                    visible: drag.key !== null && drag.key !== key && !slot.separator && root.pinnedIds[drag.target] === slot.modelData.appId
                    width: root.vertical ? root.iconSize * 0.7 : NihilStyle.s(3)
                    height: root.vertical ? NihilStyle.s(3) : root.iconSize * 0.7
                    radius: NihilStyle.s(2)
                    color: NihilStyle.accent
                    readonly property bool after: drag.target > root.pinnedIds.indexOf(drag.key?.app?.appId ?? "")
                    x: root.vertical ? (parent.width - width) / 2 : (after ? parent.width - width : 0)
                    y: root.vertical ? (after ? parent.height - height : 0) : (parent.height - height) / 2
                }
            }
        }

        Item {
            visible: root.gridKey && root.entries.length > 0
            width: root.vertical ? root.cell : root.inset * 2
            height: root.vertical ? root.inset * 2 : root.cell
            Rectangle {
                anchors.centerIn: parent
                width: root.vertical ? root.iconSize * 0.6 : 1
                height: root.vertical ? 1 : root.iconSize * 0.6
                color: NihilStyle.border
            }
        }
        NButton {
            visible: root.gridKey
            width: root.cell
            height: root.cell
            tone: "transparent"
            icon: "apps"
            iconSize: root.iconSize * 0.56
            Accessible.name: Translation.tr("Show apps")
            onClicked: {
                NihilState.askedOn = root.output
                NihilState.toggleOverview("apps")
            }
        }
    }
}
