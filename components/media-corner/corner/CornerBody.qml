pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.style
import "../state"

// The Media Corner's body: a sheet in the middle of the room the shell leaves, or the whole of its window. It draws the
// frame and the places; the Corner puts its pages in it. A window too narrow for both holds the places, then the page
// pushed over them.
Item {
    id: root
    property bool windowed: false
    property bool open: false
    property var places: []
    property string section: ""
    property string searchHint: ""
    default property alias pages: pageArea.data
    readonly property alias frame: frame
    readonly property alias nav: nav
    readonly property real d: IrisStyle.density
    signal closeRequested()

    readonly property bool column: root.windowed && root.width > 0 && root.width < Math.round(700 * root.d)
    property bool pushed: CornerState.place !== "home" || CornerState.query.length > 0 || CornerState.show !== null
    Connections {
        target: CornerState
        function onTrailChanged(): void { if (CornerState.show !== null) root.pushed = true }
        function onPlaceChanged(): void { if (CornerState.place !== "home") root.pushed = true }
    }

    function pick(id: string): void { CornerState.pick(id); root.pushed = true }
    function back(): void {
        if (CornerState.back()) return
        if (root.column && root.pushed) root.pushed = false
        else root.closeRequested()
    }

    readonly property int paneInset: Math.round(8 * root.d)
    readonly property int paneRadius: IrisStyle.concentric(frame.radius, root.paneInset, IrisStyle.radiusTile)
    readonly property int panePad: IrisStyle.concentricPad(root.paneRadius, 10 * root.d)
    // The box the bars and the dock leave free.
    readonly property var room: {
        const gap = Math.round(14 * root.d)
        const side = edge => Math.max(0, IrisFrame.safeInset(edge) - IrisFrame.band) + gap
        const left = side("left"), top = side("top")
        return { x: left, y: top, width: Math.max(0, root.width - left - side("right")), height: Math.max(0, root.height - top - side("bottom")) }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.back()
    }
    Shortcut {
        sequence: "Ctrl+F"
        enabled: root.open
        onActivated: { root.pushed = false; nav.search.focusField() }
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
        // A window never samples the wallpaper: its glass would show what is not behind it. An item may not draw into
        // the shell's blur field, so the overlay's glass is the wallpaper's.
        glass: !root.windowed
        color: IrisStyle.surface
        light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
        radius: root.windowed ? 0 : IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel)
        width: root.windowed ? root.width : Math.round(Math.min(root.room.width, 1360 * root.d))
        height: root.windowed ? root.height : Math.round(Math.min(root.room.height, 860 * root.d))
        x: root.windowed ? 0 : Math.round(root.room.x + (root.room.width - width) / 2)
        y: root.windowed ? 0 : Math.round(root.room.y + (root.room.height - height) / 2)
        MouseArea { anchors.fill: parent }

        CornerNav {
            id: nav
            narrow: root.column
            visible: !root.column || !root.pushed
            places: root.places
            section: root.section
            hint: root.searchHint
            windowed: root.windowed
            radius: root.paneRadius
            outerRadius: frame.radius
            pad: root.panePad
            x: root.paneInset
            y: root.column ? Math.round(52 * root.d) : root.paneInset
            width: root.column ? frame.width - 2 * root.paneInset : Math.round(Math.min(Math.max(216 * root.d, frame.width * 0.17), 260 * root.d))
            height: frame.height - y - root.paneInset
            onPicked: id => root.pick(id)
            onSubmitted: root.pushed = true
            onSwitchHost: {
                CornerState.dropCallers()
                CornerState.set("windowed", !root.windowed)
            }
        }

        Item {
            id: pageArea
            visible: !root.column || root.pushed
            x: root.column ? root.paneInset + Math.round(12 * root.d) : nav.x + nav.width + Math.round(20 * root.d)
            y: root.column ? Math.round(52 * root.d) : IrisStyle.concentricPad(frame.radius, 16 * root.d)
            width: frame.width - x - IrisStyle.concentricPad(frame.radius, 18 * root.d)
            height: frame.height - y - Math.round(8 * root.d)
        }

        // The narrow window's way back to the places.
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
            y: IrisStyle.concentricPad(frame.radius, 10 * root.d)
            z: 2
            materialIcon: "close"
            Accessible.name: Translation.tr("Close")
            onClicked: root.closeRequested()
        }
    }
}
