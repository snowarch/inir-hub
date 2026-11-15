pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.style
import "../state"

// The Media Corner's body, laid out as iRiS's Settings: the places on the left, the page in the middle under its ‹ ›
// and the window keys, and Yours with what plays on the right when there is room. Normal and Prism share it whole; the
// skin (CornerSkin) is all that tells them apart. A window too narrow for both holds the places, then the page pushed
// over them; without the rail, what plays rides at the foot of the page.
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
    // In a narrow window: the page is over the places. Set by what opens a page and by stepping back, never bound.
    property bool pushed: false
    Component.onCompleted: root.pushed = CornerState.place !== "home" || CornerState.query.length > 0 || CornerState.show !== null
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
    function switchHost(): void {
        CornerState.dropCallers()
        CornerState.set("windowed", !root.windowed)
    }

    readonly property int paneInset: Math.round(8 * root.d)
    readonly property int paneRadius: IrisStyle.concentric(frame.radius, root.paneInset, IrisStyle.radiusTile)
    readonly property int panePad: IrisStyle.concentricPad(root.paneRadius, 10 * root.d)
    readonly property int gap: Math.round(20 * root.d)
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
        sequence: "Alt+Left"
        enabled: root.open
        onActivated: root.back()
    }
    Shortcut {
        sequence: "Alt+Right"
        enabled: root.open
        onActivated: CornerState.forward()
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
        // the shell's blur field, so the overlay's glass is the wallpaper's. Prism is opaque, as Settings is.
        glass: !root.windowed && !CornerSkin.prism
        color: CornerSkin.page
        light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
        radius: root.windowed ? 0 : IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel)
        width: root.windowed ? root.width : Math.round(Math.min(root.room.width, 1360 * root.d))
        height: root.windowed ? root.height : Math.round(Math.min(root.room.height, 860 * root.d))
        x: root.windowed ? 0 : Math.round(root.room.x + (root.room.width - width) / 2)
        y: root.windowed ? 0 : Math.round(root.room.y + (root.room.height - height) / 2)
        MouseArea { anchors.fill: parent }

        CornerNav {
            id: nav
            railVisible: rail.visible
            narrow: root.column
            visible: !root.column || !root.pushed
            places: root.places
            section: root.section
            hint: root.searchHint
            radius: root.paneRadius
            outerRadius: frame.radius
            pad: root.panePad
            x: root.paneInset
            y: root.column ? topBar.y + topBar.height + Math.round(6 * root.d) : root.paneInset
            width: root.column ? frame.width - 2 * root.paneInset : Math.round(Math.min(Math.max(220 * root.d, frame.width * 0.18), 256 * root.d))
            height: frame.height - y - root.paneInset
            onPicked: id => root.pick(id)
            onSubmitted: root.pushed = true
        }

        // ‹ › and the window keys over the page, as Settings has them.
        Item {
            id: topBar
            readonly property real start: root.column ? root.paneInset : nav.x + nav.width + root.gap
            x: topBar.start
            y: IrisStyle.concentricPad(frame.radius, 10 * root.d)
            width: (rail.visible ? rail.x - root.gap : frame.width - IrisStyle.concentricPad(frame.radius, 12 * root.d)) - topBar.start
            height: Math.round(36 * root.d)
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(6 * root.d)
                ChromeKey {
                    glyph: "chevron_left"
                    name: Translation.tr("Back")
                    enabled: CornerState.canGoBack || (root.column && root.pushed)
                    onClicked: root.back()
                }
                ChromeKey {
                    glyph: "chevron_right"
                    name: Translation.tr("Forward")
                    enabled: CornerState.canGoForward
                    onClicked: CornerState.forward()
                }
            }
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(6 * root.d)
                ChromeKey {
                    glyph: root.windowed ? "layers" : "open_in_new"
                    name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
                    onClicked: root.switchHost()
                }
                ChromeKey {
                    visible: !root.windowed
                    glyph: "close"
                    name: Translation.tr("Close")
                    onClicked: root.closeRequested()
                }
            }
        }

        Item {
            id: pageArea
            visible: !root.column || root.pushed
            x: root.column ? root.paneInset + Math.round(12 * root.d) : topBar.x
            y: topBar.y + topBar.height + Math.round(10 * root.d)
            width: (rail.visible ? rail.x - root.gap : frame.width - IrisStyle.concentricPad(frame.radius, 18 * root.d)) - x
            height: frame.height - y - Math.round(8 * root.d) - (mini.visible ? mini.height + Math.round(10 * root.d) : 0)
        }
        // What plays, at the foot of the page while the rail isn't there to hold it.
        PlaybackCard {
            id: mini
            large: false
            extras: false
            playingOnly: true
            visible: !rail.visible && (!root.column || root.pushed) && CornerWatch.current !== null
            x: pageArea.x
            width: pageArea.width
            y: frame.height - height - root.paneInset
        }
        CornerRail {
            id: rail
            visible: !root.column && frame.width >= Math.round(1080 * root.d)
            x: frame.width - width - root.paneInset
            y: root.paneInset
            width: Math.round(Math.min(320 * root.d, Math.max(280 * root.d, frame.width * 0.22)))
            height: frame.height - 2 * root.paneInset
            onSourcesRequested: root.pick("sources")
        }
    }

    // A round key of the window's chrome, with its name on hover.
    component ChromeKey: IrisIconButton {
        id: key
        required property string glyph
        required property string name
        materialIcon: key.glyph
        opacity: key.enabled ? 1 : 0.38
        Accessible.name: key.name
        StyledToolTip { text: key.name; extraVisibleCondition: key.buttonHovered }
    }
}
