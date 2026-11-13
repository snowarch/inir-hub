import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// Three monitoring cards: running/total, CPU with history, memory.

RowLayout {
    id: root

    property real scaleFactor: 1
    property color ink: "white"
    property color accent: "white"
    property string numbersFamily: ""
    property int runningCount: 0
    property int totalCount: 0
    property real runningShare: 0
    property string cpuText: "0.0%"
    property string memText: "0 B"
    property real memPercent: 0
    property var cpuHistory: []
    property real cpuChartMax: 10
    property bool showSparkline: true

    spacing: Math.round(8 * root.scaleFactor)
    implicitHeight: Math.round(70 * root.scaleFactor)

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.implicitHeight
        radius: Math.round(10 * root.scaleFactor)
        color: ColorUtils.applyAlpha(root.ink, 0.045)
        border.width: 1
        border.color: ColorUtils.applyAlpha(root.ink, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(8 * root.scaleFactor)
            spacing: Math.round(2 * root.scaleFactor)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * root.scaleFactor)
                MaterialSymbol {
                    text: "play_circle"
                    fill: 1
                    iconSize: Math.round(13 * root.scaleFactor)
                    color: root.accent
                }
                StyledText {
                    text: Translation.tr("RUNNING")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: ColorUtils.applyAlpha(root.ink, 0.5)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.runningCount + "/" + root.totalCount
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: root.ink
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Math.round(root.runningShare * 100) + "%"
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.55)
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: Math.max(3, Math.round(3 * root.scaleFactor))
                radius: height / 2
                color: ColorUtils.applyAlpha(root.ink, 0.12)
                Rectangle {
                    width: parent.width * root.runningShare
                    height: parent.height
                    radius: parent.radius
                    color: root.accent
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.implicitHeight
        radius: Math.round(10 * root.scaleFactor)
        color: ColorUtils.applyAlpha(root.ink, 0.045)
        border.width: 1
        border.color: ColorUtils.applyAlpha(root.ink, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(8 * root.scaleFactor)
            spacing: Math.round(1 * root.scaleFactor)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * root.scaleFactor)
                MaterialSymbol {
                    text: "monitoring"
                    fill: 1
                    iconSize: Math.round(13 * root.scaleFactor)
                    color: root.accent
                }
                StyledText {
                    text: Translation.tr("CPU")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: ColorUtils.applyAlpha(root.ink, 0.5)
                }
            }
            StyledText {
                text: root.cpuText
                font.family: root.numbersFamily
                font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                font.weight: Font.DemiBold
                color: root.ink
            }
            Canvas {
                id: chart
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(20 * root.scaleFactor)
                visible: root.showSparkline
                property var points: root.cpuHistory
                property real chartMax: root.cpuChartMax
                onPointsChanged: requestPaint()
                onChartMaxChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    const w = width
                    const h = height
                    if (w <= 0 || h <= 0) return
                    ctx.clearRect(0, 0, w, h)
                    ctx.strokeStyle = ColorUtils.applyAlpha(root.ink, 0.12)
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(0, h - 1)
                    ctx.lineTo(w, h - 1)
                    ctx.stroke()
                    if (points.length < 2) return
                    const max = Math.max(10, chartMax)
                    ctx.beginPath()
                    for (let i = 0; i < points.length; i++) {
                        const x = (i / (points.length - 1)) * w
                        const y = h - 2 - (points[i] / max) * Math.max(1, h - 4)
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = root.accent
                    ctx.lineWidth = Math.max(1.5, 2 * root.scaleFactor)
                    ctx.stroke()
                    ctx.lineTo(w, h)
                    ctx.lineTo(0, h)
                    ctx.closePath()
                    ctx.fillStyle = ColorUtils.applyAlpha(root.accent, 0.12)
                    ctx.fill()
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: root.implicitHeight
        radius: Math.round(10 * root.scaleFactor)
        color: ColorUtils.applyAlpha(root.ink, 0.045)
        border.width: 1
        border.color: ColorUtils.applyAlpha(root.ink, 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(8 * root.scaleFactor)
            spacing: Math.round(1 * root.scaleFactor)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(4 * root.scaleFactor)
                MaterialSymbol {
                    text: "memory"
                    fill: 1
                    iconSize: Math.round(13 * root.scaleFactor)
                    color: root.accent
                }
                StyledText {
                    text: Translation.tr("MEM")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: ColorUtils.applyAlpha(root.ink, 0.5)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: root.memText
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: root.ink
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: root.memPercent > 0 && root.memPercent < 1 ? "<1%" : Math.round(root.memPercent) + "%"
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.55)
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: Math.max(3, Math.round(3 * root.scaleFactor))
                radius: height / 2
                color: ColorUtils.applyAlpha(root.ink, 0.12)
                Rectangle {
                    width: parent.width * (root.memPercent / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.memPercent >= 85 ? Appearance.colors.colError : root.accent
                }
            }
        }
    }
}
