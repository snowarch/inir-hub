import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// The grid: every camera as a live picture, in the columns the person picked.
Item {
    id: root

    required property var cameras
    property var pinnedIds: []
    property int columns: 2

    signal cameraClicked(string id)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            visible: root.cameras.length === 0
            text: Translation.tr("No cameras yet")
            color: Appearance.colors.colOnSurface
            font.pixelSize: Appearance.font.pixelSize.large
            horizontalAlignment: Text.AlignHCenter
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.cameras.length === 0
            text: Translation.tr("Add a camera to see it here")
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
            horizontalAlignment: Text.AlignHCenter
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.columns
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.cameras
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool pinned: root.pinnedIds.indexOf(modelData.id) !== -1

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Math.round(160 * Appearance.fontSizeScale)
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colSurfaceContainerHighest
                    border.color: pinned ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                    border.width: 1
                    clip: true

                    CameraFeed {
                        anchors.fill: parent
                        camera: tile.modelData
                        quality: "sub"
                        muted: true
                        active: tile.visible
                    }

                    // The name, over the picture.
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 28
                        color: Appearance.colors.colLayer0
                        opacity: 0.75

                        StyledText {
                            anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                            text: `${tile.index + 1}. ${tile.modelData.name || Translation.tr("Camera")}`
                            color: Appearance.colors.colOnLayer0
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            elide: Text.ElideRight
                        }
                    }

                    // The pin mark, over the picture.
                    Rectangle {
                        anchors { right: parent.right; top: parent.top; margins: 6 }
                        visible: tile.pinned
                        width: pinGlyph.implicitWidth + 10
                        height: 20
                        radius: Appearance.rounding.verysmall
                        color: Appearance.colors.colPrimary

                        MaterialSymbol {
                            id: pinGlyph
                            anchors.centerIn: parent
                            text: "keep"
                            iconSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnPrimary
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
}