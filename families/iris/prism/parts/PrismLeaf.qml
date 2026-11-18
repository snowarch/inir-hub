pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// The page card (the B · Carpeta study, `~/inir-harness/ref/iris-prism/studio/b-carpeta.html`, his 11-17 pick): the
// page's art across its top with the way back and forward, where the page lives and its name; under it one dark sheet
// whose tab carries the page's first group, that group's rows, and the page's picture on an inset card where the page
// has one (the screen on Displays, the keyboard on Keyboard). A figure the page is about stands large at its foot.
Item {
    id: root
    property var page: null
    // The first group: { title, rows }.
    property var lead: null
    // Where the rest of the page is, for the picture's pins.
    property var groups: []
    property string flashPath: ""
    property int restorable: 0
    property bool railFits: false
    property bool railOpen: false
    // What stands in the sheet over the rows, full width (Home's tiles, the wallpapers).
    property Component extra: null
    signal pickGroup(string title)
    signal restore()
    signal toggleRail()

    readonly property string pageId: String(root.page?.pageId ?? "")
    readonly property real pad: PrismTheme.dp(26)
    readonly property real inner: root.width - 2 * root.pad
    readonly property real corner: PrismTheme.dp(30)
    readonly property real artHeight: PrismTheme.dp(190)
    readonly property real sheetY: PrismTheme.dp(128)
    readonly property real rise: PrismTheme.dp(58)

    // ── What the page shows besides its rows.
    readonly property var output: { const _ = CompositorConfig.revision; return root.pageId === "display" ? CompositorConfig.output : null }
    readonly property bool monitor: root.pageId === "display" && root.output !== null
    readonly property bool keys: root.pageId === "keyboard" && CompositorConfig.has("input", "keyboard.layout")
    readonly property bool sideWell: root.monitor && root.inner >= PrismTheme.dp(640)
    readonly property real wellWidth: root.sideWell ? Math.min(PrismTheme.dp(392), Math.round(root.inner * 0.42)) : root.inner
    readonly property real wellHeight: root.monitor ? PrismTheme.dp(262) : keysMap.item ? keysMap.item.implicitHeight : 0
    // The name under the page's: the screen it changes on Displays.
    readonly property string subtitle: {
        if (root.monitor) {
            const make = String(root.output.make ?? "").split(" ")[0]
            const said = [make, String(root.output.model ?? "")].filter(part => part.length > 0 && part !== "Unknown").join(" ")
            return said.length > 0 ? said : String(root.output.name ?? "")
        }
        return ""
    }
    // The figure at the foot: a choice the page is about, said large, its choices a press away (Displays: the rate).
    readonly property var figureRow: root.monitor ? (Array.from(root.lead?.rows ?? []).find(row => row.spec?.comp === "display" && row.spec?.key === "rate") ?? null) : null
    readonly property string figureSaid: { const _ = PrismModel.revision; return root.figureRow ? String(PrismModel.sayNow(root.figureRow)) : "" }
    readonly property bool hasFigure: root.figureSaid.length > 0 && /^[0-9]/.test(root.figureSaid)
    readonly property var leadRows: Array.from(root.lead?.rows ?? []).filter(row => !root.hasFigure || row !== root.figureRow)
    readonly property var glance: root.lead ? PrismModel.glanceOf(root.lead) : null
    readonly property string leadLine: {
        if (!root.glance) return ""
        const say = String(root.glance.say ?? ""), label = String(root.glance.label ?? "")
        return say.length > 0 && label.length > 0 ? say + " · " + label : say.length > 0 ? say : label
    }
    // Pins on the screen's parts, each a group of the page.
    readonly property var pins: {
        const at = { "Screen": [0.2, 0.62], "Colour": [0.9, 0.14], "Night Light": [0.7, 0.42], "Workspaces": [0.5, 0.9], "Comfort": [0.4, 0.3], "Screens": [0.86, 0.72] }
        return root.groups.filter(group => at[group.title]).map(group => ({ group: group.title, x: at[group.title][0], y: at[group.title][1] }))
    }

    // ── Where things stand.
    readonly property real tabTextY: root.sheetY + PrismTheme.dp(16)
    readonly property real contentY: root.tabTextY + tabText.implicitHeight + PrismTheme.dp(20)
    readonly property real wellY: root.sideWell ? root.sheetY + root.rise - PrismTheme.dp(24) : root.contentY
    readonly property real extraY: root.contentY + (root.sideWell || root.wellHeight === 0 ? 0 : root.wellHeight + PrismTheme.dp(20))
    readonly property real rowsY: root.extraY + (extraBox.item ? extraBox.item.implicitHeight + (root.leadRows.length > 0 ? PrismTheme.dp(20) : 0) : 0)
    readonly property real rowsBottom: root.rowsY + (root.leadRows.length > 0 ? rows.implicitHeight : 0)
    readonly property real wellBottom: root.sideWell ? root.wellY + root.wellHeight + PrismTheme.dp(30) : 0
    readonly property bool hasFoot: root.hasFigure || root.monitor
    readonly property real footY: Math.max(root.rowsBottom, root.wellBottom) + PrismTheme.dp(14)

    implicitHeight: root.hasFoot ? root.footY + foot.height + PrismTheme.dp(18) : Math.max(root.rowsBottom, root.wellBottom) + PrismTheme.dp(24)

    Rectangle {
        anchors.fill: parent
        radius: root.corner
        color: PrismTheme.card
    }
    // The art: the page's colours, held quiet and nearly grey (his 11-17: "menos colorcitos locos").
    PrismFlow {
        width: root.width
        height: root.artHeight
        tint: String(root.page?.tint ?? "grey")
        seed: 0.61 + PrismModel.index(root.pageId) * 0.137
        centre: Qt.point(0.46, 0.6)
        thickness: 0.7
        strength: PrismTheme.light ? 0.6 : 0.72
        mute: 0.5
        topLeftRadius: root.corner
        topRightRadius: root.corner
        bottomLeftRadius: 0
        bottomRightRadius: 0
    }

    // Back, forward, and where the page lives.
    Row {
        x: PrismTheme.dp(22)
        y: PrismTheme.dp(20)
        spacing: PrismTheme.dp(8)
        PrismRound { overArt: true; smoked: true; glyph: "arrow_back"; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
        PrismRound { overArt: true; smoked: true; glyph: "arrow_forward"; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: PrismTheme.dp(8)
            mono: true
            text: [String(root.page?.group ?? ""), String(root.page?.name ?? "")].filter(part => part.length > 0).map(part => Translation.tr(part)).join(" · ").toUpperCase()
            color: PrismTheme.light ? PrismTheme.ink2 : PrismTheme.spotInk2
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.09
        }
    }
    // The page's name, and the thing it changes.
    Column {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28)
        y: PrismTheme.dp(22)
        PrismText {
            anchors.right: parent.right
            text: Translation.tr(String(root.page?.name ?? ""))
            font.pixelSize: PrismTheme.display
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.display * 0.035
            lineHeight: 1.02
        }
        PrismText {
            anchors.right: parent.right
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: PrismTheme.light ? PrismTheme.ink2 : Qt.rgba(1, 1, 1, 0.55) // iris-literal: the second name, white on the art
            font.pixelSize: PrismTheme.display
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.display * 0.035
            lineHeight: 1.02
        }
    }
    // The page's own keys, at the art's right under its name.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28)
        y: root.sheetY + root.rise - PrismTheme.dp(32) - PrismTheme.dp(12) - (root.sideWell ? PrismTheme.dp(24) : 0)
        spacing: PrismTheme.dp(8)
        PrismPill {
            visible: root.restorable > 0
            tone: "dark"
            glyph: "restart_alt"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }
        PrismRound {
            visible: root.railFits
            overArt: true
            smoked: true
            glyph: root.railOpen ? "right_panel_close" : "right_panel_open"
            Accessible.role: Accessible.Button
            Accessible.name: root.railOpen ? Translation.tr("Hide the side column") : Translation.tr("Show the side column")
            onClicked: root.toggleRail()
        }
    }

    // The sheet: its tab carries the first group.
    PrismSheet {
        y: root.sheetY
        width: root.width
        height: root.height - root.sheetY
        tab: Math.max(PrismTheme.dp(214), Math.min(root.width * 0.5, tabText.implicitWidth + 2 * root.pad))
        rise: root.rise
        slope: PrismTheme.dp(78)
        radius: root.corner
        fill: PrismTheme.card
    }
    Column {
        id: tabText
        x: root.pad
        y: root.tabTextY
        PrismText {
            text: Translation.tr(String(root.lead?.title ?? root.page?.name ?? ""))
            font.pixelSize: PrismTheme.dp(22)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(22) * 0.025
        }
        PrismText {
            visible: root.leadLine.length > 0
            width: Math.min(implicitWidth, root.width * 0.5 - 2 * root.pad)
            text: root.leadLine
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.dp(17)
            elide: Text.ElideRight
        }
    }

    // The picture's inset card.
    Rectangle {
        visible: root.wellHeight > 0
        x: root.pad + root.inner - root.wellWidth
        y: root.wellY
        width: root.wellWidth
        height: root.wellHeight
        radius: PrismTheme.dp(20)
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
        PrismText {
            visible: root.monitor
            x: PrismTheme.dp(16)
            y: PrismTheme.dp(12)
            mono: true
            text: String(root.output?.name ?? "").toUpperCase()
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.09
        }
        PrismText {
            visible: root.monitor
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(16)
            y: PrismTheme.dp(12)
            mono: true
            text: CompositorConfig.umbriel ? "UMBRIEL" : "NIRI"
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.09
        }
        PrismMonitor {
            visible: root.monitor
            x: PrismTheme.dp(16)
            y: PrismTheme.dp(34)
            width: parent.width - 2 * x
            height: parent.height - y - PrismTheme.dp(30)
            pins: root.pins
            onPick: group => root.pickGroup(group)
        }
        PrismText {
            visible: root.monitor && root.pins.length > 0
            x: PrismTheme.dp(16)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(10)
            mono: true
            text: Translation.tr("Pick a part to change it").toUpperCase()
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.09
        }
        // Keyboard: the keyboard itself, live; Super, Ctrl, Alt or Shift held shows what each key does.
        Loader {
            id: keysMap
            active: root.keys
            x: PrismTheme.dp(18)
            y: PrismTheme.dp(18)
            width: parent.width - 2 * x
            sourceComponent: Item {
                implicitHeight: map.implicitHeight + 2 * PrismTheme.dp(18)
                IrisKeyboardMap { id: map; width: parent.width }
            }
        }
    }

    Loader {
        id: extraBox
        active: root.extra !== null
        x: root.pad
        y: root.extraY
        width: root.inner
        sourceComponent: root.extra
    }

    PrismSection {
        id: rows
        visible: root.leadRows.length > 0
        bare: true
        x: root.pad
        y: root.rowsY
        width: root.sideWell ? root.inner - root.wellWidth - PrismTheme.dp(26) : root.inner
        title: String(root.lead?.title ?? "")
        rows: root.leadRows
        flashPath: root.flashPath
    }

    // The foot: the figure large at the left, the screen's name at the right.
    Item {
        id: foot
        visible: root.hasFoot
        x: root.pad
        y: root.footY
        width: root.inner
        height: figure.height + (figureChips.visible ? figureChips.implicitHeight + PrismTheme.dp(12) : 0)
        property bool open: false
        Row {
            id: figure
            visible: root.hasFigure
            spacing: PrismTheme.dp(8)
            height: PrismTheme.dp(56)
            PrismText {
                id: big
                anchors.bottom: parent.bottom
                text: root.figureSaid.split(" ")[0]
                figures: true
                font.pixelSize: PrismTheme.dp(52)
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.dp(52) * 0.04
            }
            PrismText {
                anchors.baseline: big.baseline
                text: root.figureSaid.split(" ").slice(1).join(" ")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.dp(17)
            }
            PrismGlyph {
                anchors.verticalCenter: big.verticalCenter
                text: foot.open ? "unfold_less" : "unfold_more"
                iconSize: PrismTheme.dp(18)
                color: figureArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
            }
        }
        MouseArea {
            id: figureArea
            visible: root.hasFigure
            width: figure.width
            height: figure.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr(String(root.figureRow?.label ?? ""))
            onClicked: foot.open = !foot.open
        }
        PrismChips {
            id: figureChips
            visible: foot.open && root.hasFigure
            y: figure.height + PrismTheme.dp(12)
            width: parent.width
            choices: root.figureRow ? PrismModel.choicesOf(root.figureRow) : []
            current: root.figureRow ? PrismModel.read(root.figureRow) : undefined
            onPicked: value => { PrismModel.write(root.figureRow, value); foot.open = false }
        }
        Row {
            visible: root.monitor
            anchors.right: parent.right
            anchors.bottom: figure.bottom
            anchors.bottomMargin: PrismTheme.dp(4)
            spacing: PrismTheme.dp(6)
            PrismText {
                text: String(root.output?.name ?? "")
                font.pixelSize: PrismTheme.dp(17)
                font.weight: Font.DemiBold
            }
            PrismText {
                text: Quickshell.screens.length > 1 ? Translation.tr("Main screen") : Translation.tr("Only screen")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.dp(17)
            }
        }
    }
}
