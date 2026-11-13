import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// One camera, large: the picture, and what you can do with it.
Item {
    id: root

    required property var camera
    property bool pinned: false

    signal previous()
    signal next()
    signal pinToggled()
    signal edited(var camera)

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: root.camera ? (root.camera.name || Translation.tr("Camera")) : Translation.tr("Camera not found")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            RippleButton {
                buttonText: Translation.tr("Previous")
                onClicked: root.previous()
            }
            RippleButton {
                buttonText: Translation.tr("Next")
                onClicked: root.next()
            }
            RippleButton {
                buttonText: root.pinned ? Translation.tr("Unpin") : Translation.tr("Pin to desktop")
                toggled: root.pinned
                onClicked: root.pinToggled()
            }
            RippleButton {
                buttonText: Translation.tr("Edit")
                enabled: root.camera !== null
                onClicked: if (root.camera) root.edited(root.camera)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Appearance.rounding.normal
            color: Appearance.colors.colSurfaceContainerHighest
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1
            clip: true

            CameraFeed {
                id: feed
                anchors.fill: parent
                camera: root.camera
                quality: "main"
                muted: true
                active: parent.visible && root.camera !== null
                onSnapshotSaved: path => root.snapshotTaken(path)
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.camera === null
                text: Translation.tr("Camera not found")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.normal
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButton {
                buttonText: Translation.tr("Snapshot")
                enabled: feed.status === "live"
                onClicked: feed.takeSnapshot()
            }
            RippleButton {
                buttonText: feed.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
                onClicked: feed.muted = !feed.muted
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: Translation.tr("A pinned camera stays on the desktop while the panel is closed")
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.smaller
            }
        }
    }

    signal snapshotTaken(string path)
}