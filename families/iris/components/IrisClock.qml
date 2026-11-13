pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.widgets

Row {
    id: root

    property string text: DateTime.timeDisplay
    property real pixelSize: IrisStyle.typeHeadline
    property int weight: IrisStyle.figureWeight
    property color color: IrisStyle.text
    property color separatorColor: IrisStyle.secondaryAccent
    property string family: IrisStyle.figureFace(root.pixelSize)
    property real minorScale: 0.58
    // AM/PM beside Dot digits reads in the Label voice, not as more dots.
    property string minorFamily: root.family

    readonly property var parts: IrisFaceData.clockParts(root.text)
    // Under Nothing, a large clock is Nothing OS's dot matrix (Settings › Colour › Look › Figures); AM/PM stays a word.
    readonly property bool matrixed: IrisStyle.nothingDots && root.pixelSize >= IrisStyle.typeDotS && IrisStyle.wearsNothing(root)
    readonly property string matrixText: root.parts.hours + (root.parts.minutes.length > 0 ? ":" + root.parts.minutes : "")

    spacing: 0
    transform: IrisDesign.figureLean !== 0 ? [lean] : []
    readonly property int glyphs: IrisDesign.figureLean !== 0 ? IrisStyle.leanGlyphs : Text.NativeRendering
    Matrix4x4 {
        id: lean
        matrix: Qt.matrix4x4(1, -IrisDesign.figureLean, 0, IrisDesign.figureLean * root.height / 2, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    }

    component Figure: Text {
        id: figure
        width: Math.ceil(implicitWidth)
        transform: Translate { x: Math.round(figure.x) - figure.x; y: Math.round(figure.y) - figure.y }
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.family === IrisStyle.fontDot ? IrisStyle.figureWeight : root.weight
        font.features: ({ "tnum": 1 })
        font.letterSpacing: Math.round(-root.pixelSize * 0.02)
        color: root.color
        renderType: root.glyphs
    }

    component Minor: Text {
        id: minor
        width: Math.ceil(implicitWidth)
        transform: Translate { x: Math.round(minor.x) - minor.x; y: Math.round(minor.y) - minor.y }
        font.family: root.minorFamily
        font.pixelSize: Math.round(root.pixelSize * root.minorScale)
        font.weight: root.minorFamily === IrisStyle.fontDot ? IrisStyle.figureWeight : IrisStyle.weight(Font.DemiBold)
        font.features: ({ "tnum": 1 })
        color: IrisStyle.secondaryOf(root.color)
        renderType: root.glyphs
    }

    component Count: IrisNumber {
        renderType: root.glyphs
        family: root.family
        pixelSize: root.pixelSize
        weight: root.weight
        letterSpacing: Math.round(-root.pixelSize * 0.02)
        color: root.color
    }

    IrisDotMatrix {
        id: matrix
        visible: root.matrixed
        text: root.matrixed ? root.matrixText : ""
        pixelSize: Math.round(root.pixelSize * 0.74)
        color: root.color
        width: implicitWidth
        height: implicitHeight
        anchors.verticalCenter: parent.verticalCenter
    }
    Count { id: hoursText; text: root.parts.hours; visible: !root.matrixed }
    Figure {
        text: ":"
        visible: root.parts.minutes.length > 0 && !root.matrixed
        color: root.separatorColor
        anchors.baseline: hoursText.baseline
        anchors.baselineOffset: -Math.round(root.pixelSize * 0.06)
        leftPadding: Math.round(root.pixelSize * 0.03)
        rightPadding: Math.round(root.pixelSize * 0.03)
    }
    Count { text: root.parts.minutes; anchors.baseline: hoursText.baseline; visible: !root.matrixed }
    Item {
        visible: root.parts.seconds.length > 0 && !root.matrixed
        implicitWidth: Math.ceil(secondsText.implicitWidth + root.pixelSize * 0.12)
        implicitHeight: secondsText.implicitHeight
        baselineOffset: secondsText.baselineOffset
        anchors.baseline: hoursText.baseline
        IrisNumber {
            id: secondsText
            anchors.right: parent.right
            text: root.parts.seconds
            family: root.family
            pixelSize: Math.round(root.pixelSize * root.minorScale)
            weight: Font.DemiBold
            color: IrisStyle.secondaryOf(root.color)
        }
    }
    // The period sits on the figures' baseline, or on the dot matrix's foot; one per case, since switching one item's
    // anchor between baseline and bottom set both for a moment.
    Minor {
        visible: root.parts.period.length > 0 && !root.matrixed
        text: root.parts.period
        leftPadding: Math.round(root.pixelSize * 0.16)
        anchors.baseline: hoursText.baseline
    }
    Minor {
        visible: root.parts.period.length > 0 && root.matrixed
        text: root.parts.period
        leftPadding: Math.round(root.pixelSize * 0.16)
        anchors.bottom: matrix.bottom
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
