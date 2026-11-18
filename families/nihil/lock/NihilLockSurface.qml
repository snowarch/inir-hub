pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// The lock: the wallpaper melted behind the time set as a poster's title, and one ticket of glass for the password,
// a bar of ink for each key typed. Power and restart wait in the corner, the charge in the other.
MouseArea {
    id: root

    required property LockContext context

    readonly property bool blur: Config.options?.nihil?.lock?.blur ?? true
    readonly property bool showBattery: Config.options?.nihil?.lock?.showBattery ?? true
    readonly property bool requirePasswordToPower: Config.options?.lock?.security?.requirePasswordToPower ?? true
    readonly property bool busy: root.context.unlockInProgress

    function focusField(): void {
        Qt.callLater(() => field.forceActiveFocus())
    }

    function submit(): void {
        if (root.context.currentText.length > 0 && !root.busy)
            root.context.tryUnlock()
    }

    function power(action: var): void {
        if (!root.requirePasswordToPower) {
            if (action === LockContext.ActionEnum.Poweroff) Session.poweroff()
            else Session.reboot()
            return
        }
        root.context.targetAction = action
        if (root.context.currentText.length > 0) root.submit()
        else root.focusField()
    }

    hoverEnabled: true
    onClicked: root.focusField()
    Component.onCompleted: root.focusField()

    Connections {
        target: root.context
        function onShouldReFocus(): void { root.focusField() }
        function onFailed(): void { shake.restart() }
    }

    Rectangle {
        anchors.fill: parent
        color: NihilStyle.scrim
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Config.options?.background?.wallpaperPath ?? ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        visible: !root.blur
    }
    MultiEffect {
        anchors.fill: wallpaper
        source: wallpaper
        visible: root.blur
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: NihilStyle.dark ? -0.22 : 0.06
    }

    // The time is the poster's title: set across the page in the condensed face with its bloom, the day on a rule
    // under it, sparks where the light lands.
    NDisplay {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.14)
        text: DateTime.time
        size: Math.min(parent.height * 0.42, parent.width * 0.5 / Math.max(2.5, text.length * 0.42))
        bloom: 1
    }
    NSpark { x: clock.x + clock.width - size * 0.3; y: clock.y + size * 0.2; size: NihilStyle.s(60) }
    NSpark { x: clock.x - size * 0.6; y: clock.y + clock.height - size; size: NihilStyle.s(34) }
    NRule {
        id: day
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clock.bottom
        anchors.topMargin: NihilStyle.s(10)
        width: Math.max(clock.width, NihilStyle.s(420))
        start: DateTime.date
        middle: "▶ ⋈ ◀"
        end: Translation.tr("Locked")
    }

    NGlass {
        id: capsule

        property real nudge: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.62)
        width: NihilStyle.s(380)
        height: NihilStyle.s(58)
        radius: NihilStyle.rCard
        ignite: field.activeFocus ? 1 : 0
        transform: Translate { x: capsule.nudge }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: capsule; property: "nudge"; to: NihilStyle.s(10); duration: 50 }
            NumberAnimation { target: capsule; property: "nudge"; to: -NihilStyle.s(10); duration: 80 }
            NumberAnimation { target: capsule; property: "nudge"; to: 0; duration: 60 }
        }

        TextInput {
            id: field
            anchors.fill: parent
            opacity: 0
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            text: root.context.currentText
            enabled: !root.busy
            onTextChanged: root.context.currentText = text
            Keys.onReturnPressed: root.submit()
            Keys.onEnterPressed: root.submit()
            Keys.onEscapePressed: root.context.clearText()
        }

        NLabel {
            anchors.centerIn: parent
            visible: root.context.currentText.length === 0
            text: root.context.showFailure ? Translation.tr("Try again") : Translation.tr("Password")
            strong: root.context.showFailure
            color: root.context.showFailure ? NihilStyle.live : NihilStyle.inkSoft
        }
        NSpectrum {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - NihilStyle.s(40)
            height: 1
            opacity: field.activeFocus ? 0.9 : 0
            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
        }

        Row {
            anchors.centerIn: parent
            spacing: NihilStyle.s(8)

            Repeater {
                model: Math.min(root.context.currentText.length, 18)
                delegate: Rectangle {
                    width: NihilStyle.s(3)
                    height: NihilStyle.s(16)
                    radius: 1
                    color: NihilStyle.ink
                }
            }
        }

        NButton {
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(8)
            anchors.verticalCenter: parent.verticalCenter
            lit: true
            icon: root.busy ? "more_horiz"
                : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart" : "arrow_forward"
            onClicked: root.submit()
        }
    }

    NLabel {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: NihilStyle.s(32)
        visible: root.showBattery && Battery.available
        text: (Battery.isCharging ? Translation.tr("Charging") + "   " : "") + Math.round(Battery.percentage * 100) + "%"
        strong: Battery.isLow && !Battery.isCharging
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: NihilStyle.s(24)
        spacing: NihilStyle.gap

        NButton {
            icon: "restart"
            onClicked: root.power(LockContext.ActionEnum.Reboot)
        }
        NButton {
            icon: "power_settings_new"
            onClicked: root.power(LockContext.ActionEnum.Poweroff)
        }
    }
}
