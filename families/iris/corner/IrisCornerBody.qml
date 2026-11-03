pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.style
import qs.modules.iris.state

// A Corner's body (the Anime and Movie Corners): Settings' body, in the layout Settings is in and on the host it opens
// on (over the desktop or in a window), so the Corners read as part of the same shell. It draws the frame and the places;
// the Corner puts its pages in it (they fill `pageArea`).
//   Classic — the sidebar beside the page, 1240 wide, in the middle of the room the Island and the Dock leave;
//   Folio   — a sheet of 1480×900 with an index of ink glyphs;
//   Pocket  — a column at the room's right edge: the places, then the page pushed over them (‹ goes back);
//   Drawer  — risen from the screen's foot across the room, the places as tabs; its grip raises it to the top.
// In a window the body fills it; a narrow one reads as Pocket.
Item {
    id: root
    property bool windowed: false
    property bool open: false
    property var places: []
    property string section: ""
    property var badges: ({})
    property string searchHint: ""
    // A page over the page (a show open): Escape and ‹ step out of it first.
    property bool deeper: false
    default property alias pages: pageArea.data
    readonly property alias frame: frame
    readonly property alias nav: nav
    readonly property alias pageArea: pageArea
    readonly property real d: IrisStyle.density
    signal closeRequested()
    signal picked(string id)
    signal searched(string text)
    signal stepOut()

    // ── Settings' choices, read and written as Settings' own (LayoutSwitch talks to this).
    readonly property var layouts: ({ folio: "Folio", pocket: "Pocket", drawer: "Drawer" })
    readonly property string chosenLayout: {
        const wanted = String(Config.options?.iris?.appearance?.settingsLayout ?? "classic")
        return wanted === "classic" || root.layouts[wanted] ? wanted : "classic"
    }
    function setLayout(name: string): void {
        if (name !== root.chosenLayout) Config.setNestedValue("iris.appearance.settingsLayout", name)
    }
    function switchHost(): void {
        Config.setNestedValue("iris.appearance.settingsHost", root.windowed ? "overlay" : "window")
    }
    // How it is drawn here: a narrow window holds one column.
    readonly property string layout: root.windowed && frame.width > 0 && frame.width < Math.round(700 * root.d) ? "pocket" : root.chosenLayout
    readonly property bool column: root.layout === "pocket"
    // Pocket: the places, or the page pushed over them.
    property bool pushed: false
    readonly property bool showsPage: !root.column || root.pushed
    property bool tall: false
    onLayoutChanged: { root.pushed = false; root.tall = false }
    onOpenChanged: if (!root.open) { root.pushed = false; root.tall = false }

    function pick(id: string): void { root.pushed = true; root.picked(id) }
    function back(): void {
        if (root.deeper) root.stepOut()
        else if (root.column && root.pushed) root.pushed = false
        else root.closeRequested()
    }

    // The same free box Settings opens in, so both are one size on this screen.
    readonly property bool workspaceEmpty: {
        const out = Window.window?.screen?.name ?? ""
        if (root.windowed || out === "" || !CompositorService.isNiri) return false
        const active = (NiriService.allWorkspaces ?? []).find(ws => ws.output === out && ws.is_active)
        return active !== undefined && !(NiriService.windows ?? []).some(w => w.workspace_id === active.id)
    }
    readonly property var room: {
        const gap = Math.round(14 * root.d)
        const side = edge => Math.max(0, IrisFrame.safeInset(edge) - IrisFrame.band,
            root.workspaceEmpty ? IrisFrame.emptyDepth(edge) + IrisFrame.musicReach(edge) : 0) + gap
        const left = side("left"), right = side("right"), top = side("top"), bottom = side("bottom")
        return { x: left, y: top, width: Math.max(0, root.width - left - right), height: Math.max(0, root.height - top - bottom) }
    }
    readonly property int paneInset: Math.round(8 * root.d)
    readonly property int paneRadius: IrisStyle.concentric(frame.radius, root.paneInset, IrisStyle.radiusTile)
    readonly property int panePad: IrisStyle.concentricPad(root.paneRadius, 10 * root.d)

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.back()
    }
    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.open
        onActivated: { if (root.column) root.pushed = false; nav.search.focusField() }
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.open && !root.windowed
        onClicked: root.closeRequested()
    }

    IrisMorphSurface {
        id: frame
        open: root.windowed || root.open
        motionSurface: "settings"
        settles: true
        windowOffset: Qt.point(IrisFrame.band, IrisFrame.band)
        ownField: !root.windowed
        overlay: !root.windowed
        glass: !root.windowed || IrisStyle.glassCompositor
        compositorBlurred: true
        color: IrisStyle.surface
        light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
        radius: root.windowed ? 0 : IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel)

        // Settings' geometry for each layout (settings/IrisSettings.qml, frame.goal*).
        readonly property string place: root.windowed ? "" : root.chosenLayout
        readonly property int footGap: Math.round(14 * root.d)
        readonly property real drawerRoom: root.height - root.room.y - frame.footGap
        Behavior on y { enabled: frame.place === "drawer"; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        Behavior on height { enabled: frame.place === "drawer"; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        width: root.windowed ? root.width
            : frame.place === "pocket" ? Math.round(Math.min(root.room.width, 500 * root.d))
            : frame.place === "drawer" ? Math.round(root.room.width)
            : frame.place === "folio" ? Math.round(Math.min(root.room.width, 1480 * root.d))
            : Math.round(Math.min(root.room.width, 1240 * root.d))
        height: root.windowed ? root.height
            : frame.place === "pocket" ? Math.round(root.room.height)
            : frame.place === "drawer" ? Math.round(root.tall ? frame.drawerRoom : Math.min(frame.drawerRoom, Math.max(440 * root.d, frame.drawerRoom * 0.46)))
            : frame.place === "folio" ? Math.round(Math.min(root.room.height, 900 * root.d))
            : Math.round(Math.min(root.room.height, Math.max(720 * root.d, nav.need + 2 * root.paneInset)))
        x: root.windowed ? 0
            : frame.place === "pocket" ? Math.round(root.room.x + root.room.width - width)
            : frame.place === "drawer" ? Math.round(root.room.x)
            : Math.round(root.room.x + (root.room.width - width) / 2)
        y: root.windowed ? 0
            : frame.place === "pocket" ? Math.round(root.room.y)
            : frame.place === "drawer" ? Math.round(root.height - frame.footGap - height)
            : Math.round(root.room.y + (root.room.height - height) / 2)
        MouseArea { anchors.fill: parent }

        // Drawer's grip: a click raises or lowers it, a pull up or down says which.
        MouseArea {
            id: grip
            visible: frame.place === "drawer"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            width: Math.round(120 * root.d)
            height: Math.round(16 * root.d)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: root.tall ? Translation.tr("Lower") : Translation.tr("Raise")
            property real from: 0
            property bool pulled: false
            onPressed: mouse => { grip.from = mouse.y; grip.pulled = false }
            onPositionChanged: mouse => {
                if (!grip.pressed || grip.pulled || Math.abs(mouse.y - grip.from) < Math.round(12 * root.d)) return
                grip.pulled = true
                root.tall = mouse.y < grip.from
            }
            onClicked: if (!grip.pulled) root.tall = !root.tall
            Rectangle {
                anchors.centerIn: parent
                width: Math.round((grip.containsMouse ? 52 : 44) * root.d)
                height: Math.round(5 * root.d)
                radius: height / 2
                color: grip.containsMouse ? IrisStyle.textTertiary : IrisStyle.hairlineStrong
            }
        }

        IrisCornerNav {
            id: nav
            host: root
            look: root.layout === "drawer" ? "tabs" : root.layout === "folio" ? "index" : root.column ? "list" : "sidebar"
            visible: !root.column || !root.pushed
            places: root.places
            section: root.section
            badges: root.badges
            hint: root.searchHint
            radius: root.paneRadius
            outerRadius: frame.radius
            pad: root.panePad
            x: root.paneInset
            y: root.column ? Math.round(52 * root.d) : root.paneInset + (grip.visible ? grip.height : 0)
            width: nav.look === "tabs" || root.column ? frame.width - 2 * root.paneInset
                : nav.look === "index" ? Math.round(Math.min(Math.max(216 * root.d, frame.width * 0.17), 260 * root.d))
                : Math.round(Math.min(Math.max(240 * root.d, frame.width * 0.22), 290 * root.d))
            height: nav.look === "tabs" ? nav.need : frame.height - y - root.paneInset
            onPicked: id => root.pick(id)
            onSearched: text => { if (text.length > 0) root.pushed = true; root.searched(text) }
        }

        Item {
            id: pageArea
            visible: root.showsPage
            x: nav.look === "tabs" || root.column ? root.paneInset + Math.round(12 * root.d) : nav.x + nav.width + Math.round(20 * root.d)
            y: nav.look === "tabs" ? nav.y + nav.height + Math.round(4 * root.d)
                : root.column ? Math.round(52 * root.d)
                : IrisStyle.concentricPad(frame.radius, 16 * root.d)
            width: frame.width - x - IrisStyle.concentricPad(frame.radius, 18 * root.d)
            height: frame.height - y - Math.round(8 * root.d)
        }

        // Pocket's way back to the places.
        IrisIconButton {
            visible: root.column && root.pushed
            x: root.paneInset + Math.round(6 * root.d)
            y: Math.round(10 * root.d)
            materialIcon: "chevron_left"
            Accessible.name: Translation.tr("Back")
            onClicked: root.back()
        }
        IrisIconButton {
            visible: !root.windowed
            anchors.right: parent.right
            anchors.rightMargin: IrisStyle.concentricPad(frame.radius, 10 * root.d)
            y: nav.look === "tabs" ? pageArea.y : IrisStyle.concentricPad(frame.radius, 10 * root.d)
            z: 2
            materialIcon: "close"
            Accessible.name: Translation.tr("Close")
            onClicked: root.closeRequested()
        }
    }
}
