import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// One container row: status, name/state, then CPU and memory bars.

Rectangle {
    id: root

    property string name: ""
    property string statusText: ""
    property string statusIcon: "circle"
    property color statusColor: "white"
    property string cpuText: "—"
    property real cpuPercent: 0
    property color cpuColor: "white"
    property string memText: "—"
    property real memPercent: 0
    property color memColor: "white"
    property bool selected: false
    property real scaleFactor: 1
    property color ink: "white"
    property string numbersFamily: ""

    signal clicked()

    height: Math.round(42 * root.scaleFactor)
    radius: Math.round(6 * root.scaleFactor)
    color: root.selected ? ColorUtils.applyAlpha(root.ink, 0.12) : "transparent"

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(6 * root.scaleFactor)
        anchors.rightMargin: Math.round(6 * root.scaleFactor)
        spacing: Math.round(7 * root.scaleFactor)

        MaterialSymbol {
            text: root.statusIcon
            fill: 1
            iconSize: Math.round(15 * root.scaleFactor)
            color: root.statusColor
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                Layout.fillWidth: true
                text: root.name
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: root.ink
            }
            StyledText {
                Layout.fillWidth: true
                text: root.statusText
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.ink, 0.52)
            }
        }
        ColumnLayout {
            Layout.preferredWidth: Math.round(70 * root.scaleFactor)
            spacing: 1
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: Translation.tr("CPU")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.48)
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: root.cpuText
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.7)
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: Math.max(2, Math.round(3 * root.scaleFactor))
                radius: height / 2
                color: ColorUtils.applyAlpha(root.ink, 0.12)
                Rectangle {
                    width: parent.width * (root.cpuPercent / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.cpuColor
                }
            }
        }
        ColumnLayout {
            Layout.preferredWidth: Math.round(78 * root.scaleFactor)
            spacing: 1
            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: Translation.tr("MEM")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.48)
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: root.memText
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.ink, 0.7)
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: Math.max(2, Math.round(3 * root.scaleFactor))
                radius: height / 2
                color: ColorUtils.applyAlpha(root.ink, 0.12)
                Rectangle {
                    width: parent.width * (root.memPercent / 100)
                    height: parent.height
                    radius: parent.radius
                    color: root.memColor
                }
            }
        }
    }
}
