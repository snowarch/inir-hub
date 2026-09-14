pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
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
    readonly property var desktopEntry: AppSearch.lookupDesktopEntry(root.appId)

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

    readonly property string appName: root.desktopEntry?.name ?? (root.appId.length > 0 ? root.appId : Translation.tr("this app"))

    // Island: a centred alert — app icon, question, context, two equal buttons.
    IrisSurface {
        visible: IrisStyle.island
        anchors.centerIn: parent
        width: Math.min(300 * IrisStyle.density, parent.width - 40)
        implicitHeight: alert.implicitHeight + 40 * IrisStyle.density
        radius: Math.round(22 * IrisStyle.density)
        raised: true
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: alert
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20 * IrisStyle.density
            anchors.rightMargin: 20 * IrisStyle.density
            spacing: 0

            SmartAppIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: root.desktopEntry?.icon ?? root.appId
                fallback: "application-x-executable"
                iconSize: Math.round(52 * IrisStyle.density)
            }
            IrisText {
                Layout.fillWidth: true
                Layout.topMargin: 14 * IrisStyle.density
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Close “%1”?").arg(root.appName)
                font.pixelSize: 15 * IrisStyle.typeScale
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }
            IrisText {
                Layout.fillWidth: true
                Layout.topMargin: 6 * IrisStyle.density
                horizontalAlignment: Text.AlignHCenter
                text: root.titleText.length > 0
                    ? Translation.tr("“%1” will close. Unsaved changes may be lost.").arg(root.titleText)
                    : Translation.tr("Unsaved changes may be lost.")
                color: IrisStyle.subtext
                font.pixelSize: 12 * IrisStyle.typeScale
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 18 * IrisStyle.density
                spacing: 8 * IrisStyle.density
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * IrisStyle.density)
                    buttonRadius: Math.round(10 * IrisStyle.density)
                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
                    text: Translation.tr("Cancel")
                    onClicked: root.cancel()
                }
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(32 * IrisStyle.density)
                    buttonRadius: Math.round(10 * IrisStyle.density)
                    emphasized: true
                    danger: true
                    text: Translation.tr("Close")
                    onClicked: root.confirm()
                }
            }
        }
    }

    IrisSurface {
        visible: !IrisStyle.island
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
                visible: !IrisStyle.island
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? IrisStyle.headerHeight : 0

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

            ColumnLayout {
                visible: IrisStyle.island
                Layout.fillWidth: true
                spacing: 2 * IrisStyle.density

                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Close this window?")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: 18 * IrisStyle.typeScale
                    font.weight: Font.DemiBold
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.titleText.length > 0 ? root.titleText : root.appId
                    role: IrisText.Meta
                    color: IrisStyle.subtext
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * IrisStyle.density

                Rectangle {
                    visible: !IrisStyle.island
                    Layout.preferredWidth: 3 * IrisStyle.density
                    Layout.preferredHeight: 32 * IrisStyle.density
                    radius: width / 2
                    color: IrisStyle.danger
                }

                SmartAppIcon {
                    icon: root.desktopEntry?.icon ?? root.appId
                    fallback: "application-x-executable"
                    iconSize: 28 * IrisStyle.density
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    IrisText {
                        Layout.fillWidth: true
                        text: root.appId.length > 0
                            ? (IrisStyle.island ? root.appId : root.appId.toUpperCase())
                            : Translation.tr("Application")
                        role: IrisStyle.island ? IrisText.Body : IrisText.Eyebrow
                        font.weight: Font.DemiBold
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
                IrisKey { visible: !IrisStyle.island; key: "ESC" }
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
