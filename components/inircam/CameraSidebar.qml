import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// The camera list, down the side of the panel: one row per camera, with a live
// picture. Picking a row shows that camera on its own; the footer manages the list.
Item {
    id: root

    required property var cameras
    required property string selectedId
    property var pinnedIds: []

    signal cameraSelected(string id)
    signal manageRequested()
    signal addRequested()

    // A row is a picture and a name; the whole list keeps to this width.
    readonly property real uiScale: Appearance.fontSizeScale > 0 ? Appearance.fontSizeScale : 1

    implicitWidth: Math.round(252 * root.uiScale)

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: root.cameras.length === 1
                ? Translation.tr("%1 camera").replace("%1", String(root.cameras.length))
                : Translation.tr("%1 cameras").replace("%1", String(root.cameras.length))
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.smaller
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.cameras
            ScrollBar.vertical: StyledScrollBar {}

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                readonly property bool current: modelData.id === root.selectedId
                readonly property bool pinned: root.pinnedIds.indexOf(modelData.id) !== -1

                width: list.width
                height: Math.round(56 * root.uiScale)
                radius: Appearance.rounding.small
                color: row.current ? Appearance.colors.colSecondaryContainer
                     : hover.hovered ? Appearance.colors.colLayer1
                     : "transparent"
                border.width: row.current ? 1 : 0
                border.color: Appearance.colors.colPrimary
                Behavior on color {
                    enabled: Appearance.animationsEnabled
                    ColorAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                    }
                }

                HoverHandler { id: hover }
                TapHandler { onTapped: root.cameraSelected(row.modelData.id) }

                // The bar that marks the camera being shown.
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    visible: row.current
                    color: Appearance.colors.colPrimary
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    anchors.leftMargin: row.current ? 9 : 6
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: Math.round(76 * root.uiScale)
                        Layout.preferredHeight: Math.round(43 * root.uiScale)
                        Layout.alignment: Qt.AlignVCenter
                        radius: Appearance.rounding.small
                        color: Appearance.colors.colLayer2
                        clip: true

                        CameraFeed {
                            anchors.fill: parent
                            camera: row.modelData
                            quality: "sub"
                            muted: true
                            active: row.visible
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: row.modelData.name || Translation.tr("Camera")
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }

                    MaterialSymbol {
                        visible: row.pinned
                        text: "push_pin"
                        iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colPrimary
                    }
                }
            }
        }

        RippleButton {
            Layout.fillWidth: true
            buttonText: Translation.tr("Manage cameras")
            onClicked: root.manageRequested()
        }
        RippleButton {
            Layout.fillWidth: true
            buttonText: Translation.tr("Add camera")
            onClicked: root.addRequested()
        }
    }
}
