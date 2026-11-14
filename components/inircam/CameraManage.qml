import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import "Brands.js" as Brands
import qs.services

// The camera list: every camera you have, with what to do to it.
Item {
    id: root

    required property var cameras
    property var pinnedIds: []

    signal add()
    signal edited(var camera)
    signal deleted(var camera)
    signal pinToggled(string id)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: Translation.tr("Cameras")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            RippleButton {
                buttonText: Translation.tr("Add camera")
                onClicked: root.add()
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.cameras.length === 0
            text: Translation.tr("No cameras yet")
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.normal
            horizontalAlignment: Text.AlignHCenter
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.cameras
            delegate: Rectangle {
                id: entry
                required property var modelData
                required property int index
                readonly property bool pinned: root.pinnedIds.indexOf(modelData.id) !== -1

                width: ListView.view.width
                height: 64
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2
                border.color: entry.pinned ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        StyledText {
                            Layout.fillWidth: true
                            text: `${entry.index + 1}. ${entry.modelData.name || Translation.tr("Camera")}`
                            color: Appearance.colors.colOnLayer2
                            font.pixelSize: Appearance.font.pixelSize.normal
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Brands.redact(Brands.streamUrl(entry.modelData, "main")) || entry.modelData.host || ""
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            elide: Text.ElideRight
                        }
                    }

                    RippleButton {
                        buttonText: entry.pinned ? Translation.tr("Unpin") : Translation.tr("Pin")
                        toggled: entry.pinned
                        onClicked: root.pinToggled(entry.modelData.id)
                    }
                    RippleButton {
                        buttonText: Translation.tr("Edit")
                        onClicked: root.edited(entry.modelData)
                    }
                    RippleButton {
                        buttonText: Translation.tr("Delete")
                        onClicked: root.deleted(entry.modelData)
                    }
                }
            }
        }
    }
}