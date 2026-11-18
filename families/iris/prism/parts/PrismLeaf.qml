pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// The page card (B · Carpeta, his 11-17 pick, in Technical Minimalism): the page's art across its top, cut along the
// sheet's edge so the two meet without a seam, with the way back and forward, where the page lives, its name and its
// keys; under it one sheet whose tab carries the page's first group. Its rows stand at the left and the page's graph at
// the right, a plate of a technical drawing of what the page changes; rows that need the whole width (lists, pieces,
// designs) run under both. With no short rows, every row of the first group stands there; a page that shows
// something across the sheet (the wallpapers) gives the graph up. A choice the page is about is said large under the
// rows (Displays: the rate), and the screen's name under the graph.
Item {
    id: root
    property var page: null
    // The first group: { title, rows }.
    property var lead: null
    // The poster's own words at its top right, when the page is not named there (Home: the day).
    property string posterTitle: ""
    property string posterLine: ""
    property string flashPath: ""
    property int restorable: 0
    // What stands in the sheet under the head, full width (the wallpapers).
    property Component extra: null
    // What stands by the graph instead of the first group's rows (Home's everyday tiles), and the tab's own words.
    property Component side: null
    property string tabTitle: ""
    property string tabLine: ""
    // A page drawn to its own measure (Colour's palette, Type's specimen, Lock's screen): it takes the sheet's whole
    // width under the head, and every group of the page stands on the shelf below.
    property Component hero: null
    // The page's own keys on the art: [{ id, glyph, text, solid }].
    property var actions: []
    // What the head wears: the page's light ("flow"), or on Home the person's wallpaper or accent.
    property string artKind: "flow"
    signal restore()
    signal action(string id)

    readonly property string pageId: String(root.page?.pageId ?? "")
    readonly property real pad: PrismTheme.dp(26)
    readonly property real inner: root.width - 2 * root.pad
    readonly property real corner: PrismTheme.dp(30)
    readonly property real sheetY: PrismTheme.dp(132)
    readonly property real rise: PrismTheme.dp(58)
    readonly property real slope: PrismTheme.dp(78)
    // The tab is as long as its words: the first group's name (and its switch) or the line under it, whichever is
    // longer, so neither is cut; never into the page's keys on the art at the right.
    readonly property real tabRoom: root.width - root.slope - keysRow.width - PrismTheme.dp(48)
    readonly property real tab: Math.max(PrismTheme.dp(250), Math.min(root.tabRoom, root.width * 0.62,
        Math.max(tabMetrics.advanceWidth + (leadHead.masterSwitch && !root.ownTab ? PrismTheme.dp(64) : 0), lineMetrics.advanceWidth) + 2 * root.pad))
    // The tab says the page's own words (Home's greeting, a page drawn to its measure) or its first group's head.
    readonly property bool ownTab: root.tabTitle.length > 0 || root.lead === null
    readonly property string tabSaid: root.tabTitle.length > 0 ? root.tabTitle : root.lead === null ? Translation.tr(String(root.page?.name ?? "")) : Translation.tr(String(root.lead?.title ?? ""))
    TextMetrics { id: tabMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.dp(22); font.weight: Font.Bold; text: root.tabSaid }
    TextMetrics { id: lineMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.dp(14); text: root.leadLine }
    readonly property real gutter: PrismTheme.dp(28)

    // ── What the page shows besides its rows.
    readonly property var output: { const _ = CompositorConfig.revision; return root.pageId === "display" ? CompositorConfig.output : null }
    readonly property bool monitor: root.pageId === "display" && root.output !== null
    readonly property bool keys: root.pageId === "keyboard" && CompositorConfig.has("input", "keyboard.layout")
    // The graph stands beside the rows where the sheet is wide enough for both; the keyboard's own map takes its place.
    readonly property bool roomy: !root.keys && root.hero === null && root.inner >= PrismTheme.dp(640)
    readonly property var shortRows: root.leadRows.filter(row => !root.wide(row))
    readonly property bool sideWell: root.roomy && (root.side !== null || root.shortRows.length > 0 || root.extra === null)
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
    readonly property var leadRows: Array.from(leadHead.bodyRows ?? []).filter(row => !root.hasFigure || row !== root.figureRow)
    // A row that lays something out under its line needs the sheet's whole width.
    function wide(row: var): bool {
        const kind = String(row?.kind ?? ""), spec = row?.spec ?? {}
        return kind === "pieces" || Boolean(spec.flags) || kind === "designs" || (kind === "list" && Boolean(spec.view))
            || ["icon", "curve", "niriMotion", "widgets", "themes"].includes(kind) || (kind === "choice" && spec.cards === "island")
    }
    // Short rows stand by the graph, in their order, the wide ones under both; with none short, all of them by it.
    readonly property var headRows: !root.sideWell ? [] : root.shortRows.length > 0 ? root.shortRows : root.leadRows
    readonly property var tailRows: !root.sideWell ? root.leadRows : root.shortRows.length > 0 ? root.leadRows.filter(row => root.wide(row)) : []
    readonly property bool siding: root.sideWell && root.side !== null
    // Under the page's name: what the page is about (the area's own line), or what it shows now (the screen).
    readonly property string leadLine: {
        if (root.tabLine.length > 0) return root.tabLine
        if (!root.ownTab) return leadHead.line
        if (root.monitor) return [root.subtitle, String(root.output.current_resolution ?? "").replace("x", " × ")].filter(part => part.length > 0).join("  ·  ")
        return Translation.tr(String(root.page?.subtitle ?? ""))
    }
    // The first group's own head, on the sheet: the page's name is the tab's.
    readonly property bool leadHeadShown: false
    readonly property real leadHeadHeight: 0

    // ── Where things stand.
    readonly property real tabTextY: root.sheetY + PrismTheme.dp(14)
    readonly property real contentY: root.sheetY + root.rise + PrismTheme.dp(22)
    readonly property real wellY: root.contentY + (root.keys ? root.leadHeadHeight : 0)
    readonly property real rowsBottom: root.contentY + root.leadHeadHeight + (root.headRows.length > 0 ? headSection.implicitHeight : 0)
    readonly property real figureY: root.rowsBottom + (root.headRows.length > 0 ? PrismTheme.dp(8) : 0)
    readonly property real headBottom: root.hero !== null ? root.contentY + (heroBox.item ? heroBox.item.implicitHeight : 0)
        : root.siding ? root.contentY + (sideBox.item ? sideBox.item.implicitHeight : 0)
        : root.hasFigure ? root.figureY + figureBox.height
        : root.rowsBottom
    readonly property real wellBottom: root.sideWell ? root.wellY + root.wellHeight + (root.monitor ? PrismTheme.dp(14) + screenName.height : 0)
        : root.keys ? root.wellY + keysWell.height : root.contentY - PrismTheme.dp(20)
    readonly property real upper: Math.max(root.headBottom, root.wellBottom)
    readonly property real extraY: root.upper + PrismTheme.dp(22)
    readonly property real tailY: root.extraY + (extraBox.item ? extraBox.item.implicitHeight + PrismTheme.dp(22) : 0)
    // The first group's head over its wide rows when nothing short stood beside the graph.
    readonly property real tailHead: 0
    readonly property real tailBottom: root.tailY + root.tailHead + (root.tailRows.length > 0 ? tailSection.implicitHeight : -PrismTheme.dp(22))
    implicitHeight: root.tailBottom + PrismTheme.dp(26)

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
        thickness: 0.95
        strength: PrismTheme.light ? 0.75 : 0.95
        mute: 0.12
    }
    Image {
        id: wallArt
        visible: false
        layer.enabled: root.artKind === "wallpaper"
        width: art.width
        height: art.height
        source: root.artKind === "wallpaper" ? Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? "")) : ""
        sourceSize.width: Math.round(art.width)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // A step of smoke so the names on it read over a bright picture.
        Rectangle { anchors.fill: parent; color: PrismTheme.night; opacity: 0.22 }
    }
    Rectangle {
        id: tintArt
        visible: false
        layer.enabled: root.artKind === "accent"
        width: art.width
        height: art.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: PrismTheme.accent }
            GradientStop { position: 1; color: Qt.darker(PrismTheme.accent, 1.9) }
        }
    }
    Shape {
        width: root.width
        height: art.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillItem: root.artKind === "wallpaper" && wallArt.status === Image.Ready ? wallArt : root.artKind === "accent" ? tintArt : art
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
        // Where the page lives, in words, quiet on the art.
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: PrismTheme.dp(8)
            visible: text.length > 0
            text: Translation.tr(String(root.page?.group ?? ""))
            color: PrismTheme.light ? PrismTheme.ink2 : PrismTheme.spotInk2
            font.pixelSize: PrismTheme.small
            font.weight: Font.Medium
        }
    }
    // The page's name on the poster, at its top right, in two tones (B · Carpeta: "Display", then the screen's name).
    Column {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(26)
        y: PrismTheme.dp(20)
        spacing: 0
        readonly property color onArt: PrismTheme.light && root.artKind === "flow" ? PrismTheme.ink : PrismTheme.paper
        PrismText {
            anchors.right: parent.right
            text: root.posterTitle.length > 0 ? root.posterTitle : Translation.tr(String(root.page?.name ?? ""))
            color: parent.onArt
            font.pixelSize: PrismTheme.dp(30)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(30) * 0.03
        }
        PrismText {
            anchors.right: parent.right
            visible: text.length > 0
            width: Math.min(implicitWidth, root.width * 0.42)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: root.posterLine.length > 0 ? root.posterLine : root.subtitle
            color: ColorUtils.applyAlpha(parent.onArt, 0.62) // iris-literal: the poster's second tone
            font.pixelSize: PrismTheme.dp(30)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(30) * 0.03
        }
    }

    // The page's own keys, on the art just over the sheet's lower edge.
    Row {
        id: keysRow
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(22)
        y: root.sheetY + root.rise - height - PrismTheme.dp(12)
        height: PrismTheme.dp(32)
        spacing: PrismTheme.dp(8)
        Repeater {
            model: root.actions
            delegate: PrismPill {
                required property var modelData
                tone: modelData.solid ? "solid" : "dark"
                glyph: String(modelData.glyph ?? "")
                text: Translation.tr(String(modelData.text ?? ""))
                onClicked: root.action(String(modelData.id))
            }
        }
        PrismPill {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.restorable > 0
            tone: "dark"
            glyph: "restart_alt"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
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
    // The tab: its words in the tab's own size (B · Carpeta: "Screen", then what it draws), the first group's master
    // switch at the tab's end.
    Column {
        id: tabText
        x: root.pad
        y: root.tabTextY
        width: root.tab - 2 * root.pad - (leadHead.masterSwitch && !root.ownTab ? PrismTheme.dp(56) : 0)
        spacing: PrismTheme.dp(1)
        PrismText {
            width: parent.width
            text: root.tabSaid
            elide: Text.ElideRight
            font.pixelSize: PrismTheme.dp(22)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(22) * 0.025
        }
        PrismText {
            visible: root.leadLine.length > 0
            width: Math.min(implicitWidth, root.tab - 2 * root.pad)
            text: root.leadLine
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.dp(14)
            elide: Text.ElideRight
        }
    }
    PrismSwitch {
        visible: leadHead.masterSwitch && !root.ownTab
        x: root.tab - root.pad - width
        y: root.tabTextY + PrismTheme.dp(3)
        checked: leadHead.on
        enabled: leadHead.masterSwitch && !PrismModel.locked(leadHead.master)
        onToggled: value => PrismModel.write(leadHead.master, value)
    }
    // Home's well: the desktop as it stands, its picture with the Island over it and the three colours iRiS takes
    // from it; a press opens Wallpaper. Every other page: the graph's inset card.
    ClippingRectangle {
        id: deskWell
        visible: root.sideWell && root.pageId === "general"
        x: root.pad + root.inner - root.wellWidth
        y: root.wellY
        width: root.wellWidth
        height: root.wellHeight
        radius: PrismTheme.dp(20)
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
        Image {
            anchors.fill: parent
            source: deskWell.visible ? Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? "")) : ""
            sourceSize.width: Math.round(deskWell.width * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        // The Island, where it sits on the screen.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.round(parent.height * 0.045)
            width: Math.round(parent.width * 0.2)
            height: Math.round(parent.height * 0.062)
            radius: height / 2
            color: PrismTheme.night
        }
        // A step of smoke at the foot so the words read over any picture.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.round(parent.height * 0.42)
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 1; color: ColorUtils.applyAlpha(PrismTheme.night, 0.62) } // iris-literal: smoke under the desktop's words
            }
        }
        Column {
            x: PrismTheme.dp(18)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(16)
            width: parent.width - colourDots.width - PrismTheme.dp(48)
            spacing: PrismTheme.dp(1)
            PrismText {
                width: parent.width
                text: Translation.tr("Your desktop")
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.dp(17)
                font.weight: Font.Bold
                elide: Text.ElideRight
            }
            PrismText {
                width: parent.width
                text: String(Wallpapers.effectiveWallpaperPath ?? "").split("/").pop().replace(/\.[^.]+$/, "").replace(/[-_]+/g, " ")
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.small
                elide: Text.ElideRight
            }
        }
        Row {
            id: colourDots
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(18)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(20)
            spacing: -PrismTheme.dp(6)
            Repeater {
                model: [IrisStyle.accent, IrisStyle.secondaryAccent, IrisStyle.signal]
                delegate: Rectangle {
                    required property color modelData
                    width: PrismTheme.dp(22)
                    height: width
                    radius: width / 2
                    color: modelData
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: PrismTheme.paper
            opacity: deskHit.pressed ? 0.1 : deskHit.containsMouse ? 0.05 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        }
        MouseArea {
            id: deskHit
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: PrismState.go("wallpaper")
        }
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("Your desktop")
    }
    Rectangle {
        visible: root.sideWell && root.pageId !== "general"
        x: root.pad + root.inner - root.wellWidth
        y: root.wellY
        width: root.wellWidth
        height: root.wellHeight
        radius: PrismTheme.dp(20)
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
        PrismGraph {
            anchors.fill: parent
            chrome: false
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
        radius: PrismTheme.dp(20)
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
    // The page's own drawing, to its measure.
    Loader {
        id: heroBox
        active: root.hero !== null
        x: root.pad
        y: root.contentY
        width: root.inner
        sourceComponent: root.hero
    }
    // The first group's head: its name, what it is for, its master switch.
    PrismGroupHead {
        id: leadHead
        visible: false
        x: root.pad
        y: root.contentY
        width: root.sideWell ? root.inner - root.wellWidth - root.gutter : root.inner
        entry: root.lead ?? ({ title: "", rows: [] })
    }
    // The rows beside the graph.
    PrismSection {
        id: headSection
        visible: !root.siding && root.headRows.length > 0
        bare: true
        x: root.pad
        y: root.contentY + root.leadHeadHeight
        headlessKey: leadHead.headlessKey
        width: root.sideWell ? root.inner - root.wellWidth - root.gutter : root.inner
        title: String(root.lead?.title ?? "")
        // Off, the group still shows what it holds, dimmed and still: the page never stands empty, and turning it on
        // changes nothing of where things sit.
        rows: root.sideWell ? root.headRows : []
        enabled: leadHead.on
        opacity: leadHead.on ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        flashPath: root.flashPath
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
        y: root.tailY + root.tailHead
        width: root.inner
        headlessKey: leadHead.headlessKey
        title: String(root.lead?.title ?? "")
        rows: root.tailRows
        enabled: leadHead.on
        opacity: leadHead.on ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        flashPath: root.flashPath
    }

    // The figure: the choice the page is about, said large under the rows; a press unfolds its choices.
    Item {
        id: figureBox
        visible: root.hasFigure && root.hero === null && !root.siding
        x: root.pad
        y: root.figureY
        width: root.sideWell ? root.inner - root.wellWidth - root.gutter : root.inner
        height: figure.height + (figureChips.visible ? figureChips.implicitHeight + PrismTheme.dp(12) : 0)
        property bool open: false
        Row {
            id: figure
            spacing: PrismTheme.dp(8)
            height: PrismTheme.dp(64)
            PrismText {
                id: big
                anchors.bottom: parent.bottom
                text: root.figureSaid.split(" ")[0]
                figures: true
                font.pixelSize: PrismTheme.dp(52)
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.dp(52) * 0.045
            }
            PrismText {
                anchors.baseline: big.baseline
                text: root.figureSaid.split(" ").slice(1).join(" ")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.dp(16)
            }
            PrismGlyph {
                anchors.verticalCenter: big.verticalCenter
                text: figureBox.open ? "unfold_less" : "unfold_more"
                iconSize: PrismTheme.dp(18)
                color: figureArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                opacity: figureArea.containsMouse || figureBox.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
            }
        }
        MouseArea {
            id: figureArea
            width: figure.width
            height: figure.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr(String(root.figureRow?.label ?? ""))
            onClicked: figureBox.open = !figureBox.open
        }
        PrismChips {
            id: figureChips
            visible: figureBox.open
            y: figure.height + PrismTheme.dp(12)
            width: parent.width
            choices: root.figureRow ? PrismModel.choicesOf(root.figureRow) : []
            current: root.figureRow ? PrismModel.read(root.figureRow) : undefined
            onPicked: value => { PrismModel.write(root.figureRow, value); figureBox.open = false }
        }
    }
    // The screen's name under its drawing: its connector, then what it is to the desktop.
    Row {
        id: screenName
        visible: root.monitor && root.sideWell
        anchors.right: parent.right
        anchors.rightMargin: root.pad
        y: root.wellY + root.wellHeight + PrismTheme.dp(14)
        spacing: PrismTheme.dp(6)
        PrismText {
            text: String(root.output?.name ?? "")
            font.pixelSize: PrismTheme.dp(17)
            font.weight: Font.Bold
        }
        PrismText {
            text: Quickshell.screens.length > 1 ? Translation.tr("Main screen") : Translation.tr("Only screen")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.dp(17)
        }
    }
}
