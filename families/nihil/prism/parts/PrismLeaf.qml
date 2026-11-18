pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.settings
import qs.modules.nihil.prism.core
import qs.modules.nihil.prism.model
import qs.modules.nihil.prism.fx
import qs.modules.nihil.prism.controls

// The page card (B · Carpeta, his 11-17 pick, in Technical Minimalism): the page's art across its top, cut along the
// sheet's edge so the two meet without a seam, with the way back and forward, where the page lives, its name and its
// keys; under it one sheet whose tab carries the page's first group. Its rows stand at the left and the page's graph at
// the right, a plate of a technical drawing of what the page changes; rows that need the whole width (lists, pieces,
// designs) run under both. With no short rows to stand there, the left holds the page at a glance, group by group.
Item {
    id: root
    property var page: null
    // The first group: { title, rows }.
    property var lead: null
    // Every group of the page, for the glance.
    property var groups: []
    property string flashPath: ""
    property int restorable: 0
    property bool railFits: false
    property bool railOpen: false
    // What stands in the sheet under the head, full width (the wallpapers).
    property Component extra: null
    // What stands by the graph instead of the first group's rows (Home's everyday tiles), and the tab's own words.
    property Component side: null
    property string tabTitle: ""
    property string tabLine: ""
    signal pickGroup(string title)
    signal restore()
    signal toggleRail()

    readonly property string pageId: String(root.page?.pageId ?? "")
    readonly property real pad: PrismTheme.dp(26)
    readonly property real inner: root.width - 2 * root.pad
    readonly property real corner: PrismTheme.dp(30)
    readonly property real sheetY: PrismTheme.dp(132)
    readonly property real rise: PrismTheme.dp(58)
    readonly property real slope: PrismTheme.dp(78)
    readonly property real tab: Math.max(PrismTheme.dp(230), Math.min(root.width * 0.5, tabText.implicitWidth + 2 * root.pad))
    readonly property real gutter: PrismTheme.dp(28)

    // ── What the page shows besides its rows.
    readonly property var output: { const _ = CompositorConfig.revision; return root.pageId === "display" ? CompositorConfig.output : null }
    readonly property bool monitor: root.pageId === "display" && root.output !== null
    readonly property bool keys: root.pageId === "keyboard" && CompositorConfig.has("input", "keyboard.layout")
    // The graph stands beside the rows where the sheet is wide enough for both; the keyboard's own map takes its place.
    readonly property bool sideWell: !root.keys && root.inner >= PrismTheme.dp(640)
    readonly property real wellWidth: Math.min(PrismTheme.dp(420), Math.round(root.inner * 0.44))
    readonly property real wellHeight: Math.round(root.wellWidth * 0.7)
    readonly property string subtitle: {
        if (root.monitor) {
            const make = String(root.output.make ?? "").split(" ")[0]
            const said = [make, String(root.output.model ?? "")].filter(part => part.length > 0 && part !== "Unknown").join(" ")
            return said.length > 0 ? said : String(root.output.name ?? "")
        }
        return ""
    }
    readonly property var graphValues: {
        if (!root.monitor) return {}
        const size = String(root.output.current_resolution ?? "").split("x")
        return { output: String(root.output.name ?? ""), mode: CompositorConfig.umbriel ? "UMBRIEL" : "NIRI",
            width: size[0] ?? "", height: size[1] ?? "" }
    }

    // The figure at the foot: a choice the page is about, said large (Displays: the rate).
    readonly property var figureRow: root.monitor ? (Array.from(root.lead?.rows ?? []).find(row => row.spec?.comp === "display" && row.spec?.key === "rate") ?? null) : null
    readonly property string figureSaid: { const _ = PrismModel.revision; return root.figureRow ? String(PrismModel.sayNow(root.figureRow)) : "" }
    readonly property bool hasFigure: root.figureSaid.length > 0 && /^[0-9]/.test(root.figureSaid)
    readonly property var leadRows: Array.from(root.lead?.rows ?? []).filter(row => !root.hasFigure || row !== root.figureRow)
    // A row that lays something out under its line needs the sheet's whole width.
    function wide(row: var): bool {
        const kind = String(row?.kind ?? ""), spec = row?.spec ?? {}
        return kind === "pieces" || Boolean(spec.flags) || kind === "designs" || (kind === "list" && Boolean(spec.view))
            || ["icon", "curve", "niriMotion", "widgets", "themes"].includes(kind) || (kind === "choice" && spec.cards === "island")
    }
    // Short rows stand by the graph, in their order; the wide ones run under both, in theirs.
    readonly property var headRows: root.sideWell ? root.leadRows.filter(row => !root.wide(row)) : []
    readonly property var tailRows: root.sideWell ? root.leadRows.filter(row => root.wide(row)) : root.leadRows
    // Nothing short to stand by the graph: the page at a glance instead.
    readonly property bool siding: root.sideWell && root.side !== null
    readonly property bool glancing: root.sideWell && !root.siding && root.headRows.length === 0
    readonly property var glanceRows: root.groups.slice(0, 7).map((group, i) => ({ title: String(group.title), n: i + 1, glance: PrismModel.glanceOf(group) }))
    readonly property var glance: root.lead ? PrismModel.glanceOf(root.lead) : null
    readonly property string leadLine: {
        if (root.tabLine.length > 0) return root.tabLine
        if (root.monitor) return String(root.output.current_resolution ?? "").replace("x", " × ") + " · " + Translation.tr("Resolution")
        if (!root.glance) return ""
        const say = String(root.glance.say ?? ""), label = String(root.glance.label ?? "")
        return say.length > 0 && label.length > 0 ? say + " · " + label : say.length > 0 ? say : label
    }

    // ── Where things stand.
    readonly property real tabTextY: root.sheetY + PrismTheme.dp(14)
    readonly property real contentY: root.sheetY + root.rise + PrismTheme.dp(22)
    readonly property real wellY: root.contentY
    readonly property real headBottom: root.siding ? root.contentY + (sideBox.item ? sideBox.item.implicitHeight : 0)
        : root.glancing ? root.contentY + glanceList.implicitHeight
        : root.contentY + (root.headRows.length > 0 ? headSection.implicitHeight : 0)
    readonly property real wellBottom: root.sideWell ? root.wellY + root.wellHeight : root.keys ? root.wellY + keysWell.height : root.contentY - PrismTheme.dp(20)
    readonly property real upper: Math.max(root.headBottom, root.wellBottom)
    readonly property real extraY: root.upper + PrismTheme.dp(22)
    readonly property real tailY: root.extraY + (extraBox.item ? extraBox.item.implicitHeight + PrismTheme.dp(22) : 0)
    readonly property real tailBottom: root.tailY + (root.tailRows.length > 0 ? tailSection.implicitHeight : -PrismTheme.dp(22))
    readonly property bool hasFoot: root.hasFigure || root.monitor
    readonly property real footY: root.tailBottom + PrismTheme.dp(18)

    implicitHeight: (root.hasFoot ? root.footY + foot.height : root.tailBottom) + PrismTheme.dp(26)

    // The art, drawn once offscreen and worn by the top of the card down to the sheet's edge.
    PrismFlow {
        id: art
        visible: false
        layer.enabled: true
        width: root.width
        height: root.sheetY + root.rise + root.corner + 2
        tint: String(root.page?.tint ?? "grey")
        seed: 0.61 + PrismModel.index(root.pageId) * 0.137
        centre: Qt.point(0.5, 0.36)
        thickness: 0.9
        strength: PrismTheme.light ? 0.6 : 0.72
        mute: 0.5
    }
    Shape {
        width: root.width
        height: art.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillItem: art
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg {
                readonly property real w: root.width
                readonly property real q: root.corner
                readonly property real r: root.corner
                readonly property real rr: Math.min(root.corner, root.rise + 2)
                readonly property real y0: root.sheetY
                readonly property real k: root.rise
                readonly property real s: root.slope
                readonly property real t: root.tab
                // The art's foot is the sheet's top, followed from the right corner back to the left (PrismSheet).
                path: `M 0 ${q} Q 0 0 ${q} 0 L ${w - q} 0 Q ${w} 0 ${w} ${q} L ${w} ${y0 + k + r} Q ${w} ${y0 + k} ${w - r} ${y0 + k} `
                    + `L ${t + s} ${y0 + k} C ${t + s * 0.45} ${y0 + k} ${t + s * 0.35} ${y0} ${t - s * 0.15} ${y0} `
                    + `L ${rr} ${y0} Q 0 ${y0} 0 ${y0 + rr} Z`
            }
        }
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
            text: [String(root.page?.group ?? ""), String(root.page?.name ?? "")].filter(part => part.length > 0).map(part => Translation.tr(part)).join("  /  ").toUpperCase()
            color: PrismTheme.light ? PrismTheme.ink2 : PrismTheme.spotInk2
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.1
        }
    }
    // The page's name, and the thing it changes.
    Column {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28)
        y: PrismTheme.dp(20)
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
    // The page's own keys, on the art just over the sheet's lower edge.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(22)
        y: root.sheetY + root.rise - height - PrismTheme.dp(12)
        height: PrismTheme.dp(32)
        spacing: PrismTheme.dp(8)
        PrismPill {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.restorable > 0
            tone: "dark"
            glyph: "restart_alt"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }
        PrismRound {
            anchors.verticalCenter: parent.verticalCenter
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
        tab: root.tab
        rise: root.rise
        slope: root.slope
        radius: root.corner
        fill: PrismTheme.card
    }
    Column {
        id: tabText
        x: root.pad
        y: root.tabTextY
        spacing: PrismTheme.dp(2)
        PrismText {
            text: root.tabTitle.length > 0 ? root.tabTitle : Translation.tr(String(root.lead?.title ?? root.page?.name ?? ""))
            font.pixelSize: PrismTheme.dp(20)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(20) * 0.025
        }
        PrismText {
            visible: root.leadLine.length > 0
            width: Math.min(implicitWidth, root.width * 0.5 - 2 * root.pad)
            text: root.leadLine
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.dp(13)
            elide: Text.ElideRight
        }
    }
    // The graph's inset card.
    Rectangle {
        visible: root.sideWell
        x: root.pad + root.inner - root.wellWidth
        y: root.wellY
        width: root.wellWidth
        height: root.wellHeight
        radius: 0
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
        PrismGraph {
            anchors.fill: parent
            pageId: root.pageId
            pageName: String(root.page?.name ?? "")
            number: PrismModel.index(root.pageId) + 1
            values: root.graphValues
        }
    }
    // Keyboard: the keyboard itself, live, across the sheet; Super, Ctrl, Alt or Shift held shows what each key does.
    Rectangle {
        id: keysWell
        visible: root.keys
        x: root.pad
        y: root.wellY
        width: root.inner
        height: keysMap.item ? keysMap.item.implicitHeight : 0
        radius: 0
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
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
        id: sideBox
        active: root.siding
        x: root.pad
        y: root.contentY
        width: root.inner - root.wellWidth - root.gutter
        sourceComponent: root.side
    }
    // The rows beside the graph.
    PrismSection {
        id: headSection
        visible: !root.siding && !root.glancing && root.headRows.length > 0
        bare: true
        x: root.pad
        y: root.contentY
        width: root.sideWell ? root.inner - root.wellWidth - root.gutter : root.inner
        title: String(root.lead?.title ?? "")
        rows: root.sideWell ? root.headRows : []
        flashPath: root.flashPath
    }
    // Or the page at a glance: every group, numbered, what it holds now; a press goes to it.
    Column {
        id: glanceList
        visible: root.glancing
        x: root.pad
        y: root.contentY
        width: root.inner - root.wellWidth - root.gutter
        Repeater {
            model: root.glancing ? root.glanceRows : []
            delegate: Item {
                id: entry
                required property var modelData
                width: glanceList.width
                height: PrismTheme.dp(44)
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -PrismTheme.dp(10)
                    anchors.rightMargin: -PrismTheme.dp(10)
                    radius: 0
                    color: hit.containsMouse ? PrismTheme.fill : "transparent"
                }
                Rectangle {
                    visible: entry.modelData.n > 1
                    width: parent.width
                    height: 1
                    color: PrismTheme.line
                }
                PrismText {
                    id: n
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(30)
                    mono: true
                    text: String(entry.modelData.n).padStart(2, "0")
                    color: PrismTheme.ink3
                    font.pixelSize: PrismTheme.dp(10)
                }
                PrismText {
                    anchors.left: n.right
                    anchors.right: say.left
                    anchors.rightMargin: PrismTheme.dp(12)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr(entry.modelData.title)
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.Medium
                }
                PrismText {
                    id: say
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, glanceList.width * 0.45)
                    horizontalAlignment: Text.AlignRight
                    text: String(entry.modelData.glance?.say ?? "") || String(entry.modelData.glance?.label ?? "") || String(entry.modelData.glance?.names ?? "")
                    elide: Text.ElideRight
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.body
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Link
                    Accessible.name: Translation.tr(entry.modelData.title)
                    onClicked: root.pickGroup(entry.modelData.title)
                }
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

    // The rows that need the whole width (or every row, where the graph has no room).
    PrismSection {
        id: tailSection
        visible: root.tailRows.length > 0
        bare: true
        x: root.pad
        y: root.tailY
        width: root.inner
        title: String(root.lead?.title ?? "")
        rows: root.tailRows
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
        Rectangle { width: parent.width; height: 1; color: PrismTheme.line }
        Row {
            id: figure
            visible: root.hasFigure
            spacing: PrismTheme.dp(8)
            height: PrismTheme.dp(64)
            PrismText {
                id: big
                anchors.bottom: parent.bottom
                text: root.figureSaid.split(" ")[0]
                figures: true
                font.pixelSize: PrismTheme.dp(48)
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.dp(48) * 0.04
            }
            PrismText {
                anchors.baseline: big.baseline
                text: root.figureSaid.split(" ").slice(1).join(" ")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.dp(15)
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
        Column {
            visible: root.monitor
            anchors.right: parent.right
            anchors.bottom: figure.bottom
            anchors.bottomMargin: PrismTheme.dp(6)
            PrismText {
                anchors.right: parent.right
                mono: true
                text: (Quickshell.screens.length > 1 ? Translation.tr("Main screen") : Translation.tr("Only screen")).toUpperCase()
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.dp(9.5)
                font.letterSpacing: PrismTheme.dp(9.5) * 0.1
            }
            PrismText {
                anchors.right: parent.right
                text: String(root.output?.name ?? "")
                font.pixelSize: PrismTheme.dp(17)
                font.weight: Font.DemiBold
            }
        }
    }
}
