pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    required property var context
    focus: true

    readonly property real d: IrisStyle.density
    readonly property string wallpaperPath: Config.options?.background?.wallpaperPath ?? ""
    readonly property string wallpaperLower: root.wallpaperPath.toLowerCase()
    readonly property bool animatedWallpaper: wallpaperLower.endsWith(".gif")
        || wallpaperLower.endsWith(".mp4") || wallpaperLower.endsWith(".webm")
        || wallpaperLower.endsWith(".mkv") || wallpaperLower.endsWith(".avi")
        || wallpaperLower.endsWith(".mov")
    readonly property string lockWallpaperPath: root.animatedWallpaper
        ? (Config.options?.background?.thumbnailPath ?? "") : root.wallpaperPath
    readonly property string wallpaperSource: root.lockWallpaperPath.length === 0 ? ""
        : root.lockWallpaperPath.startsWith("file://") ? root.lockWallpaperPath : "file://" + root.lockWallpaperPath
    readonly property bool blurEnabled: Config.options?.lock?.blur?.enable ?? true

    function wakeIfNeeded(): bool {
        if (!Brightness.asleep) return false
        Brightness.restoreAfterWake()
        return true
    }

    function focusPassword(): void {
        Qt.callLater(() => {
            const input = islandLoader.item?.input
            input?.forceActiveFocus()
        })
    }

    function submit(): void {
        if (!root.wakeIfNeeded() && root.context.currentText.length > 0 && !root.context.unlockInProgress)
            root.context.tryUnlock()
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
        color: "#000000"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (!root.wakeIfNeeded()) root.focusPassword()
        }
        onPositionChanged: root.wakeIfNeeded()
    }

    Loader {
        id: islandLoader
        anchors.fill: parent
        sourceComponent: islandComponent
    }

    // ── Island: wallpaper, large clock, identity and a password capsule ──
    Component {
        id: islandComponent

        Item {
            id: stage
            property alias input: passwordInput

            Image {
                id: wallpaper
                anchors.fill: parent
                source: root.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: !root.blurEnabled
            }
            MultiEffect {
                anchors.fill: parent
                visible: root.blurEnabled && wallpaper.status === Image.Ready
                source: wallpaper
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 0.15
                // Blur pulls transparent edges inwards; a slight zoom hides them.
                transform: Scale { origin.x: stage.width / 2; origin.y: stage.height / 2; xScale: 1.06; yScale: 1.06 }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.28) }
                    GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.12) }
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.42) }
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: Math.round(parent.height * 0.09)
                spacing: 0

                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.locale().toString(DateTime.clock.date, "dddd, d MMMM")
                    color: ColorUtils.applyAlpha("#ffffff", 0.86)
                    font.pixelSize: Math.round(21 * IrisStyle.typeScale)
                    font.weight: Font.DemiBold
                }
                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -6 * root.d
                    text: DateTime.timeDisplay
                    color: "#ffffff"
                    font.family: IrisStyle.fontNumbers
                    font.features: ({ "tnum": 1 })
                    font.pixelSize: Math.round(112 * IrisStyle.typeScale)
                    font.weight: Font.Bold
                    font.letterSpacing: -2
                }

                // Now playing, only while something plays.
                Item {
                    readonly property bool active: MprisController.activePlayer !== null
                        && String(MprisController.activePlayer?.trackTitle ?? "").length > 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 18 * root.d
                    visible: active
                    implicitWidth: Math.round(380 * root.d)
                    implicitHeight: active ? mediaCard.implicitHeight : 0
                    Rectangle {
                        anchors.fill: parent
                        radius: Math.round(22 * root.d)
                        color: Qt.rgba(0, 0, 0, 0.34)
                    }
                    IrisMediaCard {
                        id: mediaCard
                        anchors.fill: parent
                        active: parent.active
                        showBackground: false
                    }
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Math.round(parent.height * 0.11)
                spacing: 0

                ClippingRectangle {
                    id: avatar
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Math.round(76 * root.d)
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.2)
                    property int sourceIndex: 0
                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: Directories.avatarSourceAt(avatar.sourceIndex)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: avatar.width * 2
                        sourceSize.height: avatar.height * 2
                        visible: status === Image.Ready
                        onStatusChanged: {
                            if (status === Image.Error && avatar.sourceIndex + 1 < Directories.userAvatarPaths.length)
                                Qt.callLater(() => avatar.sourceIndex++)
                        }
                    }
                    IrisText {
                        anchors.centerIn: parent
                        visible: avatarImage.status !== Image.Ready
                        text: (SystemInfo.displayName || SystemInfo.username || "?").charAt(0).toUpperCase()
                        color: "#ffffff"
                        font.pixelSize: Math.round(32 * IrisStyle.typeScale)
                        font.weight: Font.DemiBold
                    }
                }

                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12 * root.d
                    text: SystemInfo.displayName || SystemInfo.username
                    color: "#ffffff"
                    font.pixelSize: Math.round(16 * IrisStyle.typeScale)
                    font.weight: Font.DemiBold
                }

                // Password capsule; shakes on a rejected attempt.
                Rectangle {
                    id: capsule
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 14 * root.d
                    implicitWidth: Math.round(248 * root.d)
                    implicitHeight: Math.round(38 * root.d)
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, passwordInput.activeFocus ? 0.24 : 0.18)
                    border.width: root.context.showFailure ? 1 : 0
                    border.color: ColorUtils.applyAlpha(IrisStyle.danger, 0.8)
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }

                    transform: Translate { id: shakeOffset }
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shakeOffset; property: "x"; to: -12 * root.d; duration: 45; easing.type: Easing.OutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 10 * root.d; duration: 70; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: -6 * root.d; duration: 60; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 55; easing.type: Easing.OutQuad }
                    }
                    Connections {
                        target: root.context
                        function onFailed(): void { if (IrisStyle.motionEnabled) shake.restart() }
                    }

                    TextInput {
                        id: passwordInput
                        anchors.left: parent.left
                        anchors.right: submitButton.left
                        anchors.leftMargin: 16 * root.d
                        anchors.rightMargin: 6 * root.d
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        horizontalAlignment: TextInput.AlignHCenter
                        color: "#ffffff"
                        selectionColor: Qt.rgba(1, 1, 1, 0.3)
                        font.family: IrisStyle.fontMain
                        font.pixelSize: Math.round(14 * IrisStyle.typeScale)
                        font.letterSpacing: 1.5
                        clip: true
                        enabled: !root.context.unlockInProgress
                        text: root.context.currentText
                        onTextChanged: if (root.context.currentText !== text) root.context.currentText = text
                        onAccepted: root.submit()

                        IrisText {
                            anchors.centerIn: parent
                            visible: passwordInput.text.length === 0
                            text: root.context.fingerprintsConfigured ? Translation.tr("Password or fingerprint") : Translation.tr("Enter Password")
                            color: Qt.rgba(1, 1, 1, 0.62)
                            font.pixelSize: Math.round(13 * IrisStyle.typeScale)
                        }
                    }

                    // Submit arrow appears once there is something to submit.
                    Rectangle {
                        id: submitButton
                        anchors.right: parent.right
                        anchors.rightMargin: 5 * root.d
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(28 * root.d)
                        height: width
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, submitArea.containsMouse ? 0.4 : 0.28)
                        opacity: root.context.currentText.length > 0 || root.context.unlockInProgress ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.context.unlockInProgress ? "more_horiz" : "arrow_forward"
                            iconSize: Math.round(18 * root.d)
                            color: "#ffffff"
                        }
                        MouseArea {
                            id: submitArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr("Unlock")
                            onClicked: root.submit()
                        }
                    }
                }

                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10 * root.d
                    text: root.context.unlockInProgress ? Translation.tr("Unlocking…")
                        : root.context.showFailure ? Translation.tr("Incorrect password")
                        : root.context.fingerprintsConfigured ? Translation.tr("Touch the fingerprint reader or enter your password")
                        : " "
                    color: root.context.showFailure ? "#ffb4ab" : Qt.rgba(1, 1, 1, 0.7)
                    font.pixelSize: Math.round(12 * IrisStyle.typeScale)
                }
            }
        }
    }

}
