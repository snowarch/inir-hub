pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.functions
import qs.modules.iris.style

// The iRiS time figure: heavy tabular hours and minutes, a separator tinted
// with the family accent, and seconds / AM-PM set smaller and quieter so the
// glance lands on the hour. Splits the shell's own formatted time, so the
// user's 12/24 h and seconds preferences stay authoritative.
Row {
    id: root

    property string text: DateTime.timeDisplay
    property real pixelSize: 15 * IrisStyle.typeScale
    property int weight: IrisStyle.figureWeight
    property color color: IrisStyle.text
    property color separatorColor: IrisStyle.secondaryAccent
    property string family: IrisStyle.fontNumbers
    // Size of seconds and the day-period suffix relative to the figure.
    property real minorScale: 0.58

    readonly property var parts: {
        const raw = String(root.text ?? "").trim()
        const period = raw.match(/\s*([^\d:.\s]+)$/)
        const figure = period ? raw.slice(0, period.index) : raw
        const pieces = figure.split(/[:.]/)
        return {
            hours: pieces[0] ?? "",
            minutes: pieces[1] ?? "",
            seconds: pieces[2] ?? "",
            period: period ? period[1] : ""
        }
    }

    spacing: 0

    component Figure: Text {
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.features: ({ "tnum": 1 })
        font.letterSpacing: -root.pixelSize * 0.02
        color: root.color
        renderType: Text.NativeRendering
    }

    component Minor: Text {
        font.family: root.family
        font.pixelSize: Math.round(root.pixelSize * root.minorScale)
        font.weight: Font.DemiBold
        font.features: ({ "tnum": 1 })
        color: ColorUtils.applyAlpha(root.color, 0.55)
        renderType: Text.NativeRendering
    }

    component Count: IrisNumber {
        family: root.family
        pixelSize: root.pixelSize
        weight: root.weight
        letterSpacing: -root.pixelSize * 0.02
        color: root.color
    }

    // Hours, minutes and seconds count; the separator and period stay put.
    Count { id: hoursText; text: root.parts.hours }
    Figure {
        text: ":"
        visible: root.parts.minutes.length > 0
        color: root.separatorColor
        anchors.baseline: hoursText.baseline
        // Optical centring: a colon sits low in most faces.
        anchors.baselineOffset: -root.pixelSize * 0.06
        leftPadding: root.pixelSize * 0.03
        rightPadding: root.pixelSize * 0.03
    }
    Count { text: root.parts.minutes; anchors.baseline: hoursText.baseline }
    Item {
        visible: root.parts.seconds.length > 0
        implicitWidth: secondsText.implicitWidth + root.pixelSize * 0.12
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
            color: ColorUtils.applyAlpha(root.color, 0.55)
        }
    }
    Minor {
        visible: root.parts.period.length > 0
        text: root.parts.period
        leftPadding: root.pixelSize * 0.16
        anchors.baseline: hoursText.baseline
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: root.text
}
