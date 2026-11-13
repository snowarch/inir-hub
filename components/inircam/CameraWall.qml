import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Every camera at once, as a wall of pictures.
Item {
    id: root

    required property var cameras
    property int columns: 2

    signal cameraClicked(string id)

    GridLayout {
        anchors.fill: parent
        columns: root.columns
        columnSpacing: 8
        rowSpacing: 8

        StyledText {
            Layout.fillWidth: true
            Layout.columnSpan: root.columns
            visible: root.cameras.length === 0
            text: Translation.tr("No cameras yet")
            color: Appearance.colors.colOnSurface
            font.pixelSize: Appearance.font.pixelSize.large
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: root.cameras
            delegate: Rectangle {
                id: tile
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: Math.round(160 * Appearance.fontSizeScale)
                radius: Appearance.rounding.normal
                color: Appearance.colors.colSurfaceContainerHighest
                border.color: Appearance.colors.colOutlineVariant
                border.width: 1
                clip: true

                CameraFeed {
                    anchors.fill: parent
                    camera: tile.modelData
                    quality: "main"
                    muted: true
                    active: tile.visible
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 26
                    color: Appearance.colors.colLayer0
                    opacity: 0.75

                    StyledText {
                        anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: tile.modelData.name || Translation.tr("Camera")
                        color: Appearance.colors.colOnLayer0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cameraClicked(tile.modelData.id)
                }
            }
        }
    }
}