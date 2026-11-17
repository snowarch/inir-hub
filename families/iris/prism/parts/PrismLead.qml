import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.preview
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A page's first group as its wide folder (`.claude/ref/iris-prism/studio/b-carpeta.html`): the page's art as a band,
// the way back and forward with where it stands, the page's name big at the right; the front sheet's tab carries the
// group's name, its rows at the left, its picture an inset card at the right with its parts pinned, a figure at the foot.
Item {
    id: root
    property var page: null
    property string eyebrow: ""
    property string title: ""
    // The first group ({ title, rows, glyph }), its picture and the page's groups as the pins name them.
    property var section: null
    property var figure: null
    property var groups: []
    property string flashPath: ""
    property bool active: true
    property real viewTop: 0
    property real viewHeight: 0
    property int restorable: 0
    property var lead: []
    property alias tools: toolSlot.data
    // Room at the top right for the side column's key, which stands over the page there.
    property real keyRoom: 0
    signal restore()
    signal goGroup(string title)

    readonly property string tint: String(root.page?.tint ?? "grey")
    readonly property real radius: PrismTheme.dp(30)
    readonly property real sheetTop: PrismTheme.dp(128)
    readonly property real rise: PrismTheme.dp(58)
    readonly property real pad: PrismTheme.dp(26)
    readonly property real inner: root.width - root.pad * 2
    readonly property bool keys: Boolean(root.figure?.keys)
    readonly property bool scened: root.figure !== null && root.figure !== undefined && !root.keys && root.section !== null
    readonly property bool beside: root.scened && root.inner >= PrismTheme.dp(700)
    readonly property real wellW: root.beside ? Math.round(Math.max(PrismTheme.dp(300), Math.min(PrismTheme.dp(400), root.inner * 0.4))) : root.inner
    readonly property real wellH: Math.round(Math.min(PrismTheme.dp(270), root.wellW * 0.67))
    readonly property real rowsW: root.beside ? root.inner - root.wellW - PrismTheme.dp(26) : root.inner
    readonly property var stats: root.lead.slice(0, 2).map(entry => entry.fact ? { say: String(entry.say), label: String(entry.label) }
        : { say: String(PrismModel.sayNow(entry) ?? ""), label: Translation.tr(entry.label) }).filter(entry => entry.say.length > 0)
    readonly property string glance: root.section ? String(PrismModel.glanceOf({ title: root.section.title, rows: root.section.rows }).say ?? "") : ""

    // Inside the sheet: the tab's words, then rows and picture, then the foot.
    readonly property real colsY: root.rise + PrismTheme.dp(20)
    readonly property real wellY: root.beside ? root.colsY - PrismTheme.dp(54) : root.colsY
    readonly property real rowsY: root.beside || !root.scened ? root.colsY : root.colsY + root.wellH + PrismTheme.dp(18)
    readonly property real colsEnd: Math.max(root.rowsY + rows.implicitHeight, root.scened ? root.wellY + root.wellH + PrismTheme.dp(28) : 0)
    readonly property real sheetHeight: root.colsEnd + (foot.visible ? foot.height + PrismTheme.dp(16) : 0) + PrismTheme.dp(22)
    implicitHeight: root.sheetTop + root.sheetHeight

    // The art band, round at the top; the sheet covers it from its tab down.
    PrismFlow {
        width: root.width
        height: root.sheetTop + root.rise + root.radius
        tint: root.tint
        seed: PrismModel.index(String(root.page?.pageId ?? "")) * 1.9 + 0.7
        centre: Qt.point(0.42, 0.62)
        thickness: 0.7
        topLeftRadius: root.radius
        topRightRadius: root.radius
        bottomLeftRadius: 0
        bottomRightRadius: 0
    }

    // The way back and forward, and where the page stands, printed small.
    Row {
        x: PrismTheme.dp(22)
        y: PrismTheme.dp(20)
        spacing: PrismTheme.dp(8)
        PrismRound { glyph: "arrow_back"; overArt: true; smoked: true; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
        PrismRound { glyph: "arrow_forward"; overArt: true; smoked: true; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        Item { width: PrismTheme.dp(8); height: 1 }
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.eyebrow.toUpperCase()
            mono: true
            color: PrismTheme.paper
            opacity: 0.75
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
        }
    }

    // The page's name big at the right, what it sets under it in a quieter ink.
    Column {
        id: head
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28) + root.keyRoom
        y: PrismTheme.dp(22)
        PrismText {
            anchors.right: parent.right
            width: Math.min(implicitWidth, root.width * 0.5)
            horizontalAlignment: Text.AlignRight
            text: root.title
            color: PrismTheme.paper
            font.pixelSize: PrismTheme.title + PrismTheme.dp(2)
            font.weight: Font.Bold
            font.letterSpacing: -1
        }
    }

    // What the page offers: Restore, its own tools, its show; under the name, clear of the picture.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28)
        y: Math.max(head.y + head.height + PrismTheme.dp(10), PrismTheme.dp(20))
        visible: !root.beside || y + height < root.sheetTop + root.wellY - PrismTheme.dp(8)
        spacing: PrismTheme.dp(8)
        PrismPill {
            visible: root.restorable > 0
            tone: "dark"
            glyph: "restart_alt"
            text: Translation.tr("Restore defaults")
            onClicked: root.restore()
        }
        Row { id: toolSlot; spacing: PrismTheme.dp(8) }
        PrismPill {
            visible: Boolean(root.page?.show)
            tone: "art"
            glyph: "play_arrow"
            text: Translation.tr(String(root.page?.show?.label ?? ""))
            onClicked: PrismModel.runShow(root.page)
        }
    }

    // The front sheet: a tab at its left, a soft step down to the front's edge.
    Item {
        id: sheet
        y: root.sheetTop
        width: root.width
        height: root.sheetHeight
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: PrismTheme.card
                strokeColor: "transparent"
                strokeWidth: -1
                PathSvg {
                    readonly property real w: sheet.width
                    readonly property real h: sheet.height
                    readonly property real r: root.radius
                    readonly property real t: Math.min(Math.max(PrismTheme.dp(214), tabTitle.implicitWidth + root.pad * 2), sheet.width * 0.5)
                    readonly property real s: PrismTheme.dp(78)
                    readonly property real k: root.rise
                    path: `M 0 ${r} Q 0 0 ${r} 0 L ${t - s * 0.15} 0 C ${t + s * 0.35} 0 ${t + s * 0.45} ${k} ${t + s} ${k} `
                        + `L ${w - r} ${k} Q ${w} ${k} ${w} ${k + r} L ${w} ${h - r} Q ${w} ${h} ${w - r} ${h} `
                        + `L ${r} ${h} Q 0 ${h} 0 ${h - r} Z`
                }
            }
        }

        PrismText {
            id: tabTitle
            x: root.pad
            y: PrismTheme.dp(16)
            text: Translation.tr(String(root.section?.title ?? ""))
            font.pixelSize: PrismTheme.head + PrismTheme.dp(4)
            font.weight: Font.Bold
            font.letterSpacing: -0.5
        }
        PrismText {
            x: root.pad
            y: tabTitle.y + tabTitle.height + PrismTheme.dp(1)
            width: Math.min(implicitWidth, root.rowsW)
            visible: root.glance.length > 0
            text: root.glance
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.head - PrismTheme.dp(1)
        }

        PrismSection {
            id: rows
            bare: true
            x: root.pad
            y: root.rowsY
            width: root.rowsW
            title: String(root.section?.title ?? "")
            rows: root.section?.rows ?? []
            figure: root.keys ? root.figure : null
            groups: root.groups
            entry: String(root.section?.title ?? "")
            tint: root.tint
            active: root.active
            flashPath: root.flashPath
            onGoGroup: title => root.goGroup(title)
        }

        // The picture, an inset card of night with its parts pinned.
        ClippingRectangle {
            id: well
            visible: root.scened
            x: root.beside ? root.width - root.pad - root.wellW : root.pad
            y: root.wellY
            width: root.wellW
            height: root.wellH
            radius: PrismTheme.dp(20)
            color: PrismTheme.night
            IrisGroupPreview {
                id: scene
                anchors.fill: parent
                radius: well.radius
                framed: false
                captionOutside: true
                holdsStill: true
                playing: root.active && root.viewTop < root.implicitHeight
                section: String(root.figure?.section ?? "")
                group: String(root.figure?.group ?? "")
                niriValue: (section, key) => CompositorConfig.value(IrisOptions.settings.find(spec => spec.comp === section && spec.key === key) ?? { comp: section, key: key })
                niriRevision: CompositorConfig.revision
            }
            PrismSpots {
                id: marks
                property string hovering: ""
                anchors.fill: parent
                radius: well.radius
                spots: scene.spots
                groups: root.groups
                pointed: marks.hovering
                picked: String(root.section?.title ?? "")
                sayOf: title => PrismModel.glanceOf(root.groups.find(group => String(group.title) === title)).say
                onPoint: title => marks.hovering = title
                onPick: title => { if (title.length > 0) root.goGroup(title) }
            }
        }
        PrismText {
            visible: root.scened && text.length > 0
            x: well.x
            y: well.y + well.height + PrismTheme.dp(8)
            width: well.width
            text: scene.caption
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.small
            elide: Text.ElideRight
        }

        // The foot: the page's figure big at the left, where it stands at the right.
        Item {
            id: foot
            visible: root.stats.length > 0
            x: root.pad
            y: root.colsEnd + PrismTheme.dp(4)
            width: root.inner
            height: big.height
            PrismText {
                id: big
                text: root.stats[0]?.say ?? ""
                figures: true
                font.pixelSize: PrismTheme.poster
                font.weight: Font.Bold
                font.letterSpacing: -2
            }
            PrismText {
                anchors.left: big.right
                anchors.leftMargin: PrismTheme.dp(8)
                anchors.baseline: big.baseline
                text: root.stats[0]?.label ?? ""
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.head - PrismTheme.dp(1)
            }
            // The page's second fact, its value and its name, at the foot's right.
            Row {
                visible: root.stats.length > 1
                anchors.right: parent.right
                anchors.baseline: big.baseline
                spacing: PrismTheme.dp(6)
                PrismText {
                    anchors.baseline: parent.baseline
                    text: root.stats[1]?.say ?? ""
                    figures: true
                    font.pixelSize: PrismTheme.head + PrismTheme.dp(2)
                    font.weight: Font.Bold
                }
                PrismText {
                    anchors.baseline: parent.baseline
                    text: root.stats[1]?.label ?? ""
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.body
                }
            }
        }
    }
}
