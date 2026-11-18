pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.widgets

// Prism worn as every widget's design (`nihil.widgets.design` = prism; each widget's face is the part
// `widgetPrism.<face>`). One body for all of them (`PrismBody`, his 11-16 "un cuerpo, mismo lenguaje"): a slab of
// smoked frosted glass in dark, white frost in light, its material and opacity the widget's own (`nihil.material`,
// `nihil.opacity`), no rim and no art on it. Its head is a mark and a name with the one fact at the right end; the data
// is drawn in white, the one live mark in the widget's colour. What differs is each widget's form, drawn by its face
// inside the slab (`.claude/ref/prism-widgets/README.md`).
// Measures are per size (176 x 176 small, 368 x 176 medium, 368 x 368 large).
IrisWidgetFace {
    id: root
    ownBody: true
    padding: 0

    function pick(small: real, medium: real, large: real): real { return root.dp(root.small ? small : root.medium ? medium : large) }
    function type(small: real, medium: real, large: real): real { return root.small ? small : root.medium ? medium : large }

    // The slab's corners: a face may round itself further (the clock's lens).
    property real slabRadius: root.radius

    // What the head says: a mark and a name, the one fact at the right end.
    property string tabGlyph: ""
    property string tabText: ""
    property string flapText: ""
    // Raised small beside the fact (a 12-hour clock's AM/PM, a unit).
    property string flapSuffix: ""
    property string flapGlyph: ""
    property bool head: true
    // The face's one quick action, a key at the head's right end (the month back to today, copy the palette).
    property bool capInteractive: false
    property string capGlyph: ""
    property string capName: ""
    signal capClicked()

    // The widget's colour: the head's mark and fact, the one mark that is live.
    property color shelf: root.nothing ? root.signal : root.accent
    readonly property color inkOnShelf: root.onFill(root.shelf)
    // Where the white light meets the glass, and how much passes: on the slab's rim near its top right. A face moves it
    // onto its live thing.
    property point prism: Qt.point(root.width - root.pick(28, 40, 48), root.pick(2, 2, 4))
    property real lightPass: 1

    // The places every face fills: the head over `paneTop`, the middle to `paneBottom`, the foot to `footBottom`.
    readonly property real inset: root.pick(16, 22, 26)
    readonly property real innerWidth: Math.max(1, root.width - 2 * root.inset)
    readonly property real paneTop: root.pick(44, 42, 79)
    readonly property real paneBottom: root.pick(112, 120, 200)
    readonly property real paneHeight: Math.max(1, root.paneBottom - root.paneTop)
    readonly property real paneMiddle: Math.round((root.paneTop + root.paneBottom) / 2)
    readonly property real footTop: root.paneBottom
    readonly property real footBottom: root.height - root.pick(6, 8, 10)
    readonly property real footHeight: Math.max(1, root.footBottom - root.footTop)
    readonly property real headY: Math.round(root.paneTop * 0.52)
    readonly property bool label: root.nothing

    PrismBody {
        id: body
        anchors.fill: parent
        face: root
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
        slab: true
        slabRadius: root.slabRadius
        beamPass: 0
    }

    // ── the head: a mark and a name ──
    MaterialSymbol {
        id: tabMark
        visible: root.head && root.tabGlyph.length > 0
        x: root.inset
        y: Math.round(root.headY - height / 2)
        text: root.tabGlyph
        fill: 1
        iconSize: root.px(root.type(14, 15, 18))
        color: root.label ? root.ink : root.shelf
    }
    FaceText {
        id: tabName
        visible: root.head
        face: root
        x: tabMark.visible ? tabMark.x + tabMark.width + root.pick(5, 6, 7) : tabMark.x
        y: Math.round(root.headY - height / 2)
        width: Math.max(0, headEnd.x - x - root.pick(8, 10, 12))
        text: root.label ? root.tabText.toUpperCase() : root.tabText
        color: root.label ? root.inkSecondary : root.ink
        size: root.label ? root.type(9.5, 10.5, 12) : root.type(12, 13, 15)
        weight: Font.Bold
        font.family: root.label ? root.fontLabel : root.fontMain
        // Caps take more room: a Nothing label spaces its letters only where the tab has the room for it, and shrinks
        // before it would cut a word ("NOVEMBER" on a small tab).
        font.letterSpacing: root.label ? (root.small ? root.px(10) * 0.03 : root.px(12) * 0.08) : -root.px(root.type(12, 13, 15)) * 0.02
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(root.label ? root.type(7.5, 9, 11) : root.type(9, 10, 11))
    }

    // ── the head ends on its one fact, in the widget's colour, and the face's quick action ──
    Row {
        id: headEnd
        visible: root.head
        x: root.width - root.inset - width
        y: Math.round(root.headY - height / 2)
        spacing: root.dp(6)
        Row {
            visible: quietFigure.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
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
        // The quick action: a round key of the glass's own fill, its glyph white; pointed, it brightens.
        Rectangle {
            id: capKey
            visible: root.capInteractive && root.capGlyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: root.pick(24, 24, 28)
            height: width
            radius: 0
            color: capArea.pressed ? root.fillActive : capArea.containsMouse ? root.fillHover : root.fill
            Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.capGlyph
                fill: 1
                iconSize: Math.round(capKey.width * 0.58)
                color: root.ink
            }
            MouseArea {
                id: capArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.capClicked()
            }
            Accessible.role: Accessible.Button
            Accessible.name: root.capName
        }
    }
}
