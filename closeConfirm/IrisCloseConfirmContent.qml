pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    focus: true

    required property var targetWindow
    signal confirm()
    signal cancel()

    readonly property string appId: String(targetWindow?.app_id ?? "")
    readonly property string titleText: String(targetWindow?.title ?? "")

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.cancel()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.confirm()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: IrisStyle.scrim
        MouseArea { anchors.fill: parent; onClicked: root.cancel() }
    }

    IrisSurface {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 40)
        implicitHeight: content.implicitHeight + IrisStyle.spaceLarge * 2
        raised: true

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: IrisStyle.spaceLarge
            spacing: IrisStyle.spaceMedium

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: IrisStyle.headerHeight

                IrisSectionHeader {
                    id: closeHeader
                    anchors.fill: parent
                    icon: "close"
                    eyebrow: "IRIS / WINDOW"
                    title: Translation.tr("Close this window?")
                    subtitle: root.titleText.length > 0 ? root.titleText : root.appId
                    indexText: "ESC"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * IrisStyle.density

                Rectangle {
                    Layout.preferredWidth: 3 * IrisStyle.density
                    Layout.preferredHeight: 32 * IrisStyle.density
                    radius: width / 2
                    color: IrisStyle.danger
                }

                SmartAppIcon {
                    icon: root.appId
                    fallback: "application-x-executable"
                    iconSize: 28 * IrisStyle.density
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    IrisText {
                        Layout.fillWidth: true
                        text: root.appId.length > 0 ? root.appId.toUpperCase() : Translation.tr("APPLICATION")
                        role: IrisText.Eyebrow
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: Translation.tr("Unsaved changes may be lost.")
                        role: IrisText.Meta
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: IrisStyle.spaceSmall
                Item { Layout.fillWidth: true }
                IrisKey { key: "ESC" }
                IrisButton { text: Translation.tr("Cancel"); quiet: true; onClicked: root.cancel() }
                IrisButton {
                    text: Translation.tr("Close")
                    emphasized: true
                    danger: true
                    onClicked: root.confirm()
                }
            }
        }
    }
}
