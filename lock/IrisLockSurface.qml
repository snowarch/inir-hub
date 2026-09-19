pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtMultimedia
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
    readonly property bool videoWallpaper: Wallpapers.isVideoFile(root.wallpaperLower)
    readonly property string wallpaperSource: Wallpapers.stillUrlFor(root.wallpaperPath)
    readonly property bool playsVideo: root.videoWallpaper && !root.blurEnabled
        && (Config.options?.lock?.enableAnimation ?? false)
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

    function clockText(total: real): string {
        const s = Math.max(0, Math.floor(total))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const sec = String(s % 60).padStart(2, "0")
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + sec : m + ":" + sec
    }

    component ActivityPlate: Item {
        id: plate
        property bool shown: false
        property string glyph: ""
        property color tint: IrisStyle.text
        property string label: ""
        property string figure: ""
        property bool countDown: false
        property real progress: -1
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: plate.shown ? 10 * root.d : 0
        visible: plate.shown
        implicitWidth: Math.round(380 * root.d)
        implicitHeight: plate.shown ? Math.round(64 * root.d) : 0

        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.radiusPlate
            color: IrisStyle.mediaScrim
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 * root.d
            anchors.rightMargin: 20 * root.d
            spacing: 12 * root.d
            Rectangle {
                Layout.preferredWidth: Math.round(40 * root.d)
                Layout.preferredHeight: Layout.preferredWidth
                radius: width / 2
                color: IrisStyle.tintFill(plate.tint)
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: plate.glyph
                    fill: 1
                    iconSize: 20 * root.d
                    color: plate.tint
                }
            }
            IrisText {
                Layout.fillWidth: true
                text: plate.label
                color: IrisStyle.onMedia
                font.pixelSize: Math.round(15 * IrisStyle.typeScale)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            IrisNumber {
                text: plate.figure
                countDown: plate.countDown
                color: plate.tint
                pixelSize: Math.round(26 * IrisStyle.typeScale)
                weight: Font.Bold
                letterSpacing: -0.5
            }
        }
        Rectangle {
            visible: plate.progress >= 0
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22 * root.d
            anchors.bottomMargin: 7 * root.d
            width: (parent.width - 44 * root.d) * Math.max(0, Math.min(1, plate.progress))
            height: Math.max(2, 2 * root.d)
            radius: height / 2
            color: plate.tint
        }
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
        color: IrisStyle.surfaceOpaque
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

    Component {
        id: islandComponent

        Item {
            id: stage
            property alias input: passwordInput

            Image {
                id: wallpaper
                anchors.fill: parent
                source: root.wallpaperSource
                sourceSize: Qt.size(stage.width, stage.height)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: !root.blurEnabled
            }
            Loader {
                anchors.fill: parent
                active: root.playsVideo
                sourceComponent: Video {
                    source: "file://" + root.wallpaperPath
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    muted: true
                    autoPlay: true
                }
            }
            MultiEffect {
                anchors.fill: parent
                visible: root.blurEnabled && wallpaper.status === Image.Ready
                source: wallpaper
                blurEnabled: true
                blur: 1
                blurMax: 48
                saturation: 0.15
                transform: Scale { origin.x: stage.width / 2; origin.y: stage.height / 2; xScale: 1.06; yScale: 1.06 }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.28) } // iris-literal: wallpaper legibility gradient
                    GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.12) } // iris-literal: wallpaper legibility gradient
                    GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.42) } // iris-literal: wallpaper legibility gradient
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
                    color: IrisStyle.onMedia
                    font.pixelSize: Math.round(21 * IrisStyle.typeScale)
                    font.weight: Font.DemiBold
                }
                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: -6 * root.d
                    text: DateTime.timeDisplay
                    color: IrisStyle.onMedia
                    font.family: IrisStyle.fontNumbers
                    font.features: ({ "tnum": 1 })
                    font.pixelSize: Math.round(112 * IrisStyle.typeScale)
                    font.weight: Font.Bold
                    font.letterSpacing: -2
                }

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
                        radius: IrisStyle.radiusPlate
                        color: IrisStyle.mediaScrim
                    }
                    IrisMediaCard {
                        id: mediaCard
                        anchors.fill: parent
                        active: parent.active
                        showBackground: false
                    }
                }

                ActivityPlate {
                    shown: RecorderStatus.isRecording
                    glyph: "radio_button_checked"
                    tint: IrisStyle.danger
                    label: Translation.tr("Recording")
                    figure: root.clockText(RecorderStatus.elapsedSeconds)
                }
                ActivityPlate {
                    readonly property string kind: TimerService.pomodoroRunning ? "pomodoro"
                        : TimerService.countdownRunning ? "countdown"
                        : TimerService.stopwatchRunning ? "stopwatch" : ""
                    readonly property bool paused: kind === "pomodoro" ? TimerService.pomodoroPaused
                        : kind === "countdown" ? TimerService.countdownPaused : TimerService.stopwatchPaused
                    shown: kind.length > 0
                    glyph: paused ? "pause" : kind === "stopwatch" ? "timer" : kind === "pomodoro" && TimerService.pomodoroBreak ? "coffee" : "hourglass_top"
                    tint: paused ? IrisStyle.onMediaSecondary : IrisStyle.secondaryAccent
                    label: kind === "pomodoro" ? (TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"))
                        : kind === "countdown" ? Translation.tr("Timer") : Translation.tr("Stopwatch")
                    countDown: kind !== "stopwatch"
                    figure: root.clockText(kind === "pomodoro" ? TimerService.pomodoroSecondsLeft
                        : kind === "countdown" ? TimerService.countdownSecondsLeft
                        : Math.floor(TimerService.stopwatchTime / 100))
                    progress: kind === "pomodoro" ? 1 - TimerService.pomodoroSecondsLeft / Math.max(1, TimerService.pomodoroLapDuration)
                        : kind === "countdown" ? 1 - TimerService.countdownSecondsLeft / Math.max(1, TimerService.countdownDuration) : -1
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
                    color: IrisStyle.onMediaFill
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
                        color: IrisStyle.onMedia
                        font.pixelSize: Math.round(32 * IrisStyle.typeScale)
                        font.weight: Font.DemiBold
                    }
                }

                IrisText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12 * root.d
                    text: SystemInfo.displayName || SystemInfo.username
                    color: IrisStyle.onMedia
                    font.pixelSize: Math.round(16 * IrisStyle.typeScale)
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: capsule
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 14 * root.d
                    implicitWidth: Math.round(248 * root.d)
                    implicitHeight: Math.round(38 * root.d)
                    radius: height / 2
                    color: (passwordInput.activeFocus ? IrisStyle.onMediaFillHover : IrisStyle.onMediaFill)
                    border.width: root.context.showFailure ? 1 : 0
                    border.color: IrisStyle.tintBorder(IrisStyle.danger)
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
                        color: IrisStyle.onMedia
                        selectionColor: IrisStyle.onMediaFillHover
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
                            color: IrisStyle.onMediaSecondary
                            font.pixelSize: Math.round(13 * IrisStyle.typeScale)
                        }
                    }

                    Rectangle {
                        id: submitButton
                        anchors.right: parent.right
                        anchors.rightMargin: 5 * root.d
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(28 * root.d)
                        height: width
                        radius: width / 2
                        color: (submitArea.containsMouse ? IrisStyle.onMediaFillHover : IrisStyle.onMediaFill)
                        opacity: root.context.currentText.length > 0 || root.context.unlockInProgress ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: root.context.unlockInProgress ? "more_horiz" : "arrow_forward"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.onMedia
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
                    color: root.context.showFailure ? IrisStyle.danger : IrisStyle.onMediaSecondary
                    font.pixelSize: Math.round(12 * IrisStyle.typeScale)
                }
            }
        }
    }

}
