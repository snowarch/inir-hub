pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// Prism worn as every widget's design (`iris.widgets.design` = prism; each widget's face is the part
// `widgetPrism.<face>`): the folder of frosted glass Now Playing's Prism stands on, one grammar on every widget. The
// dark tab names what the widget is about, the flap lit in its colour holds one fact, the clear pane across the folder
// holds the thing itself (a figure or its drawing) and the foot what comes with it. Each widget fills those four places;
// the measures are the folder's, per size (176 x 176 small, 368 x 176 medium, 368 x 368 large, as Now Playing's).
IrisWidgetFace {
    id: root
    ownBody: true
    padding: 0

    function pick(small: real, medium: real, large: real): real { return root.dp(root.small ? small : root.medium ? medium : large) }
    function type(small: real, medium: real, large: real): real { return root.small ? small : root.medium ? medium : large }

    // What the four places say.
    property string tabGlyph: ""
    property string tabText: ""
    property string flapText: ""
    // Raised small beside the flap's text (a 12-hour clock's AM/PM, a unit).
    property string flapSuffix: ""
    property string flapGlyph: ""
    // The widget's colour: the flap, the tab's name, the one mark that is live.
    property color shelf: root.nothing ? root.signal : root.accent
    readonly property color inkOnShelf: root.onFill(root.shelf)
    // The beam breaks here and passes this much light. By default at the pane's foot, just before what the pane holds:
    // the white core stays off the figure and the spectrum fans out behind it (a core across the figure washed it out).
    property point prism: Qt.point(Math.round(root.inset * 0.5), root.paneBottom - root.pick(10, 10, 16))
    property real lightPass: 1

    // The folder.
    readonly property real tabRight: root.pick(98, 196, 214)
    readonly property real lean: root.pick(22, 22, 40)
    readonly property real flapTop: root.pick(12, 14, 29)
    readonly property real flapRight: root.width - root.pick(14, 30, 26)
    readonly property real paneTop: root.pick(44, 42, 79)
    readonly property real paneBottom: root.pick(112, 120, 200)
    readonly property real paneMiddle: Math.round((root.paneTop + root.paneBottom) / 2)
    readonly property real headY: Math.round(root.paneTop * 0.52)
    // Content's side margin, and where the foot's lines sit.
    readonly property real inset: root.pick(16, 22, 26)
    readonly property real innerWidth: root.width - 2 * root.inset
    readonly property real footTop: root.paneBottom
    readonly property real footHeight: root.height - root.paneBottom
    readonly property real flapMiddle: Math.round((root.flapTop + root.paneTop) / 2)
    readonly property real flapLeft: folder.edgeAt(root.flapMiddle)
    readonly property bool label: root.nothing

    PrismBody {
        id: folder
        anchors.fill: parent
        face: root
        tabRight: root.tabRight
        lean: root.lean
        tabRadius: root.pick(16, 20, 26)
        flapTop: root.flapTop
        flapRight: root.flapRight
        flapRadius: root.pick(18, 22, 30)
        paneTop: root.paneTop
        paneBottom: root.paneBottom
        paneRadius: root.pick(13, 14, 16)
        prism: root.prism
        entry: root.small ? Qt.point(-root.width * 0.3, root.height * 1.05)
            : root.medium ? Qt.point(-root.width * 0.2, root.height * 1.15) : Qt.point(-root.width * 0.16, root.height * 0.9)
        fanAngle: root.small ? -0.55 : root.medium ? -0.4 : -0.46
        fanSpread: root.small ? 0.34 : root.medium ? 0.28 : 0.3
        lightPass: root.lightPass
        shelf: root.shelf
        white: root.label
    }

    // ── the tab: a mark and a name, in the widget's colour ──
    MaterialSymbol {
        id: tabMark
        visible: root.tabGlyph.length > 0
        x: root.pick(14, 22, 30)
        y: Math.round(root.headY - height / 2)
        text: root.tabGlyph
        fill: 1
        iconSize: root.px(root.type(17, 20, 28))
        color: root.label ? root.ink : root.shelf
    }
    FaceText {
        face: root
        x: tabMark.visible ? tabMark.x + tabMark.width + root.pick(5, 7, 9) : tabMark.x
        y: Math.round(root.headY - height / 2)
        width: Math.max(0, folder.edgeAt(y) - x - root.pick(8, 10, 12))
        text: root.label ? root.tabText.toUpperCase() : root.tabText
        color: root.label ? root.ink : root.shelf
        size: root.label ? root.type(10, 12, 14) : root.type(13, 16, 21)
        weight: Font.Bold
        font.family: root.label ? root.fontLabel : root.fontMain
        // Caps take more room: a Nothing label spaces its letters only where the tab has the room for it, and shrinks
        // before it would cut a word ("NOVEMBER" on a small tab).
        font.letterSpacing: root.label ? (root.small ? root.px(10) * 0.03 : root.px(12) * 0.08) : -root.px(root.type(13, 16, 21)) * 0.02
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(root.label ? root.type(7.5, 9, 11) : root.type(10, 12, 14))
    }

    // ── the flap: one fact, on the widget's colour ──
    Row {
        id: flapRow
        readonly property real room: root.flapRight - root.flapLeft - root.pick(10, 14, 18)
        x: Math.round((root.flapLeft + root.flapRight) / 2 + root.dp(3) - width / 2)
        y: Math.round(root.flapMiddle - flapFigure.height / 2)
        spacing: root.dp(3)
        MaterialSymbol {
            visible: root.flapGlyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.flapGlyph
            fill: 1
            iconSize: root.px(root.type(12, 13, 17))
            color: root.inkOnShelf
        }
        FaceText {
            id: flapFigure
            face: root
            width: Math.min(Math.ceil(implicitWidth), flapRow.room - (root.flapGlyph.length > 0 ? root.px(16) : 0) - (flapUnit.visible ? flapUnit.width + root.dp(2) : 0))
            text: root.flapText
            color: root.inkOnShelf
            size: root.type(12, 13, 17)
            weight: Font.Bold
            font.family: root.fontNumbers
            font.features: ({ "tnum": 1 })
        }
        FaceText {
            id: flapUnit
            visible: text.length > 0
            face: root
            y: Math.round(flapFigure.height * 0.06)
            text: root.flapSuffix
            color: root.inkOnShelf
            size: root.type(7, 7.5, 9)
            weight: Font.Bold
        }
    }
}
