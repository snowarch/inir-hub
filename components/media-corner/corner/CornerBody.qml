pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.style
import "../state"

// The Media Corner's body, laid out as iRiS's Settings in the style worn (CornerSkin).
// Prism: the places on the left, the page under ‹ › and the window keys, and Yours with what plays on a right rail
// when there is room. Folio: the places down the whole left side; over the page ‹ ›, the search, and on the right the
// style switch and the window keys. Classic: the places on a card with the search; over the page ‹ ›, its name, and
// the switch as glyphs. Without the rail, what plays rides at the foot of the page.
// A window too narrow for both holds the places, then the page pushed over them.
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

    // Classic names the page over it, as Settings does: the place, the open title's kind, a search or Watch.
    readonly property string pageTitle: {
        if (CornerState.sheet) return Translation.tr("Watch")
        const show = CornerState.show
        if (show) return Translation.tr(show.kind === "anime" ? "Anime" : show.kind === "series" ? "Series" : "Movie")
        if (CornerState.query.length > 0) return CornerState.place.includes(":search") ? Translation.tr("Search")
            : Translation.tr("Results for “%1”").arg(CornerState.query)
        const genre = root.section.match(/:genre:(.+)$/)
        if (genre) return Translation.tr(genre[1])
        const place = root.places.find(item => item.id === root.section)
        return place ? Translation.tr(place.title) : ""
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
        onActivated: {
            if (!CornerSkin.folio) { root.pushed = false; nav.search.focusField() }
            else topSearch.focusField()
        }
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
            // The column is narrow for the long hint; the field over the page (Folio) has room for it.
            hint: Translation.tr("Search titles")
            radius: root.paneRadius
            outerRadius: frame.radius
            pad: root.panePad
            x: root.paneInset
            y: root.column ? topBar.y + topBar.height + Math.round(6 * root.d) : root.paneInset
            width: root.column ? frame.width - 2 * root.paneInset
                : CornerSkin.prism ? Math.round(Math.min(Math.max(220 * root.d, frame.width * 0.18), 256 * root.d))
                : CornerSkin.classic ? Math.round(Math.min(Math.max(236 * root.d, frame.width * 0.18), 260 * root.d))
                : Math.round(Math.min(Math.max(244 * root.d, frame.width * 0.19), 300 * root.d))
            height: frame.height - y - root.paneInset
            onPicked: id => root.pick(id)
            onSubmitted: root.pushed = true
        }

        // ‹ › and the window keys over the page, as Settings has them; in Classic and Folio the style too, and
        // Folio's search or Classic's page name.
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
                IrisText {
                    visible: CornerSkin.classic
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: Math.round(8 * root.d)
                    width: Math.min(implicitWidth, topBar.width - keys.width - Math.round(110 * root.d))
                    text: root.pageTitle
                    textFormat: Text.PlainText
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
                CornerSearch {
                    id: topSearch
                    visible: CornerSkin.folio
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Math.round(320 * root.d * Math.max(1, IrisStyle.typeScale)), topBar.width - keys.width - Math.round(100 * root.d))
                    implicitHeight: Math.round(36 * root.d)
                    hint: root.searchHint
                    outerRadius: frame.radius
                    onSubmitted: root.pushed = true
                }
            }
            Row {
                id: keys
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(6 * root.d)
                StyleSwitch { visible: !CornerSkin.prism && !root.column; glyphOnly: CornerSkin.classic }
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
            visible: CornerSkin.prism && !root.column && frame.width >= Math.round(1080 * root.d)
            x: frame.width - width - root.paneInset
            y: root.paneInset
            width: Math.round(Math.min(320 * root.d, Math.max(280 * root.d, frame.width * 0.22)))
            height: frame.height - 2 * root.paneInset
            onSourcesRequested: root.pick("sources")
        }
    }

    // A round key of the window's chrome, with its name on hover: bare in Prism, on a quiet plate in Classic and Folio.
    component ChromeKey: IrisButton {
        id: key
        required property string glyph
        required property string name
        implicitWidth: Math.round(36 * root.d)
        implicitHeight: Math.round(36 * root.d)
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        colBackground: CornerSkin.prism ? "transparent" : IrisStyle.fillQuiet
        colBackgroundHover: IrisStyle.fillHover
        opacity: key.enabled ? 1 : 0.38
        Accessible.name: key.name
        MaterialSymbol { anchors.centerIn: parent; text: key.glyph; iconSize: Math.round(18 * root.d); color: IrisStyle.text }
        StyledToolTip { text: key.name; extraVisibleCondition: key.buttonHovered }
    }
    // Settings' layout switch, for the Corner's two styles.
    component StyleSwitch: Rectangle {
        id: styles
        // Classic shows the glyphs alone, Folio their names too.
        property bool glyphOnly: false
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: lookRow.implicitWidth + Math.round(6 * root.d)
        implicitHeight: Math.round(36 * root.d)
        radius: height / 2
        color: "transparent"
        border.width: 1
        border.color: IrisStyle.hairline
        Row {
            id: lookRow
            anchors.centerIn: parent
            spacing: Math.round(2 * root.d)
            Repeater {
                model: CornerSkin.looks
                IrisButton {
                    id: look
                    required property var modelData
                    readonly property bool on: CornerSkin.look === look.modelData.id
                    implicitHeight: Math.round(30 * root.d)
                    implicitWidth: styles.glyphOnly ? Math.round(34 * root.d) : lookLabel.implicitWidth + Math.round(24 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    colBackground: look.on ? IrisStyle.fill : "transparent"
                    colBackgroundHover: look.on ? IrisStyle.fill : IrisStyle.fillQuiet
                    Accessible.name: Translation.tr(look.modelData.label)
                    StyledToolTip { text: Translation.tr(look.modelData.label); extraVisibleCondition: styles.glyphOnly && look.buttonHovered }
                    onClicked: CornerState.set("style", look.modelData.id)
                    Row {
                        id: lookLabel
                        anchors.centerIn: parent
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol { anchors.verticalCenter: parent.verticalCenter; text: look.modelData.glyph; iconSize: Math.round(16 * root.d); color: look.on ? IrisStyle.text : IrisStyle.muted }
                        IrisText {
                            visible: !styles.glyphOnly
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(look.modelData.label)
                            color: look.on ? IrisStyle.text : IrisStyle.muted
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(Font.Medium)
                        }
                    }
                }
            }
        }
    }
}
