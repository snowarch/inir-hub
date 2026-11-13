import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

// A container tile for the grid layout: CPU ring, memory bar and state.

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
    property color accent: "white"
    property string numbersFamily: ""

    signal clicked()

    implicitWidth: Math.round(190 * root.scaleFactor)
    implicitHeight: Math.round(138 * root.scaleFactor)
    radius: Math.round(12 * root.scaleFactor)
    color: root.selected
        ? ColorUtils.applyAlpha(root.accent, 0.13)
        : ColorUtils.applyAlpha(root.ink, 0.045)
    border.width: root.selected ? 1 : 1
    border.color: root.selected
        ? ColorUtils.applyAlpha(root.accent, 0.55)
        : ColorUtils.applyAlpha(root.ink, 0.1)

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(10 * root.scaleFactor)
        spacing: Math.round(5 * root.scaleFactor)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(5 * root.scaleFactor)
            MaterialSymbol {
                text: root.statusIcon
                fill: 1
                iconSize: Math.round(14 * root.scaleFactor)
                color: root.statusColor
            }
            StyledText {
                Layout.fillWidth: true
                text: root.name
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                font.weight: Font.DemiBold
                color: root.ink
            }
            StyledText {
                text: root.statusText
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.ink, 0.5)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Math.round(8 * root.scaleFactor)

            DockerRing {
                value: root.cpuPercent
                accent: root.cpuColor
                track: ColorUtils.applyAlpha(root.ink, 0.12)
                ink: root.ink
                label: Translation.tr("CPU")
                detail: root.cpuText
                numbersFamily: root.numbersFamily
                scaleFactor: root.scaleFactor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(3 * root.scaleFactor)
                StyledText {
                    text: Translation.tr("MEMORY")
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: ColorUtils.applyAlpha(root.ink, 0.45)
                }
                StyledText {
                    text: root.memText
                    font.family: root.numbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                    font.weight: Font.DemiBold
                    color: root.ink
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: Math.max(3, Math.round(4 * root.scaleFactor))
                    radius: height / 2
                    color: ColorUtils.applyAlpha(root.ink, 0.12)
                    Rectangle {
                        width: parent.width * (Math.max(0, Math.min(100, root.memPercent)) / 100)
                        height: parent.height
                        radius: parent.radius
                        color: root.memColor
                    }
                }
            }
        }
    }
}
