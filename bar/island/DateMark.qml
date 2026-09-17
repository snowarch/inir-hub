pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Row {
    id: dateMark
    property real pixelSize: 12 * IrisStyle.typeScale
    property color dayColor: IrisStyle.secondaryAccent
    spacing: Math.round(dateMark.pixelSize * 0.3)
    IrisText {
        id: weekdayText
        text: Qt.locale().toString(DateTime.clock.date, "ddd").replace(/\.$/, "")
        color: IrisStyle.muted
        font.pixelSize: dateMark.pixelSize * 0.92
        font.weight: Font.Medium
    }
    IrisText {
        anchors.baseline: weekdayText.baseline
        text: Qt.locale().toString(DateTime.clock.date, "d")
        color: dateMark.dayColor
        font.pixelSize: dateMark.pixelSize
        font.family: IrisStyle.fontNumbers
        font.weight: Font.Bold
        font.features: ({ "tnum": 1 })
    }
}
