pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// The lock: the wallpaper melted behind the day and the time, and one pill of glass for the password, a dot for each
// key typed. Power and restart wait in one corner, the charge in the other.
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

    // The day over the time, both centred high on the page; the time in Geist's medium weight, tight and large.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.12)
        spacing: NihilStyle.s(4)
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.locale.toString(DateTime.clock.date, "dddd, d MMMM")
            font.pixelSize: NihilStyle.s(20)
            font.weight: Font.Medium
            color: Qt.alpha(NihilStyle.ink, 0.82)
        }
        NDisplay {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DateTime.time
            size: Math.round(Math.min(root.height * 0.17, root.width * 0.11))
        }
    }

    NGlass {
        id: capsule

        property real nudge: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.7)
        width: NihilStyle.s(320)
        height: NihilStyle.s(50)
        radius: height / 2
        ignite: field.activeFocus ? 0.6 : 0.2
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

        NText {
            x: NihilStyle.s(22)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.context.currentText.length === 0
            text: root.context.showFailure ? Translation.tr("Try again") : Translation.tr("Password")
            color: root.context.showFailure ? NihilStyle.danger : NihilStyle.inkSoft
        }

        Row {
            x: NihilStyle.s(22)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(6)

            Repeater {
                model: Math.min(root.context.currentText.length, 22)
                delegate: Rectangle {
                    width: NihilStyle.s(7)
                    height: width
                    radius: width / 2
                    color: NihilStyle.ink
                }
            }
        }

        NButton {
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(7)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(36)
            height: NihilStyle.s(36)
            lit: true
            icon: root.busy ? "more_horiz"
                : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart" : "arrow_forward"
            onClicked: root.submit()
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: NihilStyle.s(30)
        visible: root.showBattery && Battery.available
        spacing: NihilStyle.s(6)
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: Battery.isCharging ? "battery_charging_full" : "battery_full"
            size: NihilStyle.s(16)
            color: Battery.isLow && !Battery.isCharging ? NihilStyle.danger : NihilStyle.inkSoft
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Battery.percentage * 100) + "%"
            figures: true
            color: NihilStyle.inkSoft
        }
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
