pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// Prism worn as every widget's design (`iris.widgets.design` = prism; each widget's face is the part
// `widgetPrism.<face>`). Each widget picks how much of Prism it wears (its `iris.prism` option, his 11-07 "que sea
// configurable", "más minimalistas"):
//   quiet (the factory): one slab of smoked frosted glass; a quiet head (mark and name, its one fact at the right end);
//     the spectrum only where the face draws its data, and the rim splitting the light near the thing that matters;
//   beam: the same slab with the white beam entering from outside and fanning at that thing;
//   folder: Now Playing's folder (dark tab, flap lit in the widget's colour, clear pane, foot).
// Each face fills the same places (head, fact, the middle, the foot); the measures are per size (176 x 176 small,
// 368 x 176 medium, 368 x 368 large, as Now Playing's).
IrisWidgetFace {
    id: root
    ownBody: true
    padding: 0

    function pick(small: real, medium: real, large: real): real { return root.dp(root.small ? small : root.medium ? medium : large) }
    function type(small: real, medium: real, large: real): real { return root.small ? small : root.medium ? medium : large }

    // How much of Prism this widget wears.
    property string defaultForm: "quiet"
    readonly property string form: String(root.widget.familyOption("prism", root.defaultForm))
    readonly property bool folded: root.form === "folder"
    // A slab's corners: a face may round itself further (a lens).
    property real slabRadius: root.radius

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
    // A slab catches it on its rim near the top right, where light from above meets the glass.
    property point prism: root.folded ? Qt.point(Math.round(root.inset * 0.5), root.paneBottom - root.pick(10, 10, 16))
        : Qt.point(root.width - root.pick(28, 40, 48), root.pick(2, 2, 4))
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
    readonly property real flapLeft: root.folded ? folder.edgeAt(root.flapMiddle) : root.inset
    readonly property bool label: root.nothing

    PrismBody {
        id: folder
        visible: !root.welded
        opacity: 1 - root.weldCover
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
        slab: !root.folded
        slabRadius: root.slabRadius
        beamPass: root.form === "beam" ? 0.8 : 0
    }

    // ── the tab: a mark and a name, in the widget's colour ──
    MaterialSymbol {
        id: tabMark
        visible: root.tabGlyph.length > 0
        x: root.folded ? root.pick(14, 22, 30) : root.inset
        y: Math.round(root.headY - height / 2)
        text: root.tabGlyph
        fill: 1
        iconSize: root.px(root.folded ? root.type(17, 20, 28) : root.type(14, 15, 18))
        color: root.label ? root.ink : root.shelf
    }
    FaceText {
        id: tabName
        face: root
        x: tabMark.visible ? tabMark.x + tabMark.width + root.pick(5, 6, 7) : tabMark.x
        y: Math.round(root.headY - height / 2)
        width: Math.max(0, (root.folded ? folder.edgeAt(y) : quietFact.x) - x - root.pick(8, 10, 12))
        text: root.label ? root.tabText.toUpperCase() : root.tabText
        color: root.folded ? (root.label ? root.ink : root.shelf) : root.label ? root.inkSecondary : root.ink
        size: root.folded ? (root.label ? root.type(10, 12, 14) : root.type(13, 16, 21))
            : root.label ? root.type(9.5, 10.5, 12) : root.type(12, 13, 15)
        weight: Font.Bold
        font.family: root.label ? root.fontLabel : root.fontMain
        // Caps take more room: a Nothing label spaces its letters only where the tab has the room for it, and shrinks
        // before it would cut a word ("NOVEMBER" on a small tab).
        font.letterSpacing: root.label ? (root.small ? root.px(10) * 0.03 : root.px(12) * 0.08) : -root.px(root.type(13, 16, 21)) * 0.02
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(root.label ? root.type(7.5, 9, 11) : root.type(10, 12, 14))
    }

    // ── a slab's head ends on its one fact, in the widget's colour ──
    Row {
        id: quietFact
        visible: !root.folded && quietFigure.text.length > 0
        x: root.width - root.inset - width
        y: Math.round(root.headY - quietFigure.height / 2)
        spacing: root.dp(2)
        MaterialSymbol {
            visible: root.flapGlyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.flapGlyph
            fill: 1
            iconSize: root.px(root.type(12, 13, 15))
            color: root.label ? root.ink : root.shelf
        }
        FaceText {
            id: quietFigure
            face: root
            width: Math.min(Math.ceil(implicitWidth), root.innerWidth * 0.5)
            text: root.label ? root.flapText.toUpperCase() : root.flapText
            color: root.label ? root.ink : root.shelf
            size: root.label ? root.type(9.5, 10.5, 12) : root.type(12, 13, 15)
            weight: Font.Bold
            font.family: root.label ? root.fontLabel : root.fontNumbers
            font.features: ({ "tnum": 1 })
        }
        FaceText {
            visible: text.length > 0
            face: root
            y: Math.round(quietFigure.height * 0.06)
            text: root.flapSuffix
            color: root.label ? root.ink : root.shelf
            size: root.type(7, 7.5, 9)
            weight: Font.Bold
        }
    }

    // ── the flap: one fact, on the widget's colour ──
    Row {
        id: flapRow
        visible: root.folded
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
