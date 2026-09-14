pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    required property var context
    focus: true

    readonly property string wallpaperPath: Config.options?.background?.wallpaperPath ?? ""
    readonly property string wallpaperLower: root.wallpaperPath.toLowerCase()
    readonly property bool animatedWallpaper: wallpaperLower.endsWith(".gif")
        || wallpaperLower.endsWith(".mp4") || wallpaperLower.endsWith(".webm")
        || wallpaperLower.endsWith(".mkv") || wallpaperLower.endsWith(".avi")
        || wallpaperLower.endsWith(".mov")
    readonly property string lockWallpaperPath: root.animatedWallpaper
        ? (Config.options?.background?.thumbnailPath ?? "") : root.wallpaperPath

    function wakeIfNeeded(): bool {
        if (!Brightness.asleep) return false
        Brightness.restoreAfterWake()
        return true
    }

    function focusPassword(): void {
        Qt.callLater(() => passwordInput.forceActiveFocus())
    }

    Component.onCompleted: root.focusPassword()
    Connections {
        target: root.context
        function onShouldReFocus(): void { root.focusPassword() }
    }

    Keys.onPressed: event => {
        if (root.wakeIfNeeded()) {
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Escape) {
            root.context.clearText()
            event.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: IrisStyle.canvas
    }

    Image {
        anchors.fill: parent
        visible: root.lockWallpaperPath.length > 0
        source: root.lockWallpaperPath.startsWith("file://")
            ? root.lockWallpaperPath : "file://" + root.lockWallpaperPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        color: Appearance.m3colors.m3scrim
        opacity: 0.34
    }

    IrisSurface {
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 460 * IrisStyle.density)
        height: lockContent.implicitHeight + IrisStyle.panelPadding * 2
        raised: true
        radius: IrisStyle.radius

        ColumnLayout {
            id: lockContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: IrisStyle.panelPadding
            anchors.rightMargin: IrisStyle.panelPadding
            spacing: 12 * IrisStyle.density

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: IrisStyle.headerHeight

                IrisSectionHeader {
                    id: lockHeader
                    anchors.fill: parent
                    icon: "lock"
                    eyebrow: "IRIS / LOCK"
                    title: Translation.tr("Welcome back")
                    subtitle: DateTime.date
                    indexText: root.context.fingerprintsConfigured ? "BIO" : "PASS"
                }
            }

            IrisText {
                Layout.topMargin: 2 * IrisStyle.density
                text: DateTime.timeDisplay
                font.family: IrisStyle.fontNumbers
                font.pixelSize: 46 * IrisStyle.typeScale
                font.weight: Font.Bold
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                Rectangle {
                    Layout.preferredWidth: 3 * IrisStyle.density
                    Layout.preferredHeight: 34 * IrisStyle.density
                    radius: width / 2
                    color: root.context.showFailure ? IrisStyle.danger : IrisStyle.accent
                }

                IrisField {
                    id: passwordInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48 * IrisStyle.density
                    echoMode: TextInput.Password
                    placeholderText: root.context.fingerprintsConfigured
                        ? Translation.tr("Password or use fingerprint")
                        : Translation.tr("Enter password")
                    enabled: !root.context.unlockInProgress
                    text: root.context.currentText
                    onTextChanged: {
                        if (root.context.currentText !== text)
                            root.context.currentText = text
                    }
                    onAccepted: {
                        if (!root.wakeIfNeeded() && text.length > 0)
                            root.context.tryUnlock()
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                IrisText {
                    Layout.fillWidth: true
                    text: root.context.unlockInProgress
                        ? Translation.tr("Unlocking…")
                        : root.context.showFailure
                            ? Translation.tr("Try again")
                            : root.context.fingerprintsConfigured
                                ? Translation.tr("Password or fingerprint")
                                : Translation.tr("Enter password")
                    color: root.context.showFailure ? IrisStyle.danger : IrisStyle.subtext
                    role: IrisText.Meta
                }
                IrisKey { key: "ENTER" }
                IrisButton {
                    implicitWidth: 94 * IrisStyle.density
                    implicitHeight: 36 * IrisStyle.density
                    emphasized: true
                    onClicked: {
                        if (!root.wakeIfNeeded() && root.context.currentText.length > 0)
                            root.context.tryUnlock()
                    }
                    text: Translation.tr("Unlock")
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            if (!root.wakeIfNeeded()) root.focusPassword()
        }
        onPositionChanged: root.wakeIfNeeded()
    }
}
