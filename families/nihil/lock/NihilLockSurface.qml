pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// The lock: the wallpaper melted behind a large thin clock, and one capsule of glass for the password, its dots lit as
// they are typed. Power and restart wait in the corner, the charge in the other.
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

    Column {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.24)
        spacing: NihilStyle.s(6)

        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DateTime.time
            font.pixelSize: NihilStyle.s(132)
            font.weight: Font.Light
            color: NihilStyle.ink
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: DateTime.date
            font.pixelSize: NihilStyle.textLarge
            color: NihilStyle.inkSoft
        }
    }

    NGlass {
        id: capsule

        property real nudge: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.62)
        width: NihilStyle.s(360)
        height: NihilStyle.s(60)
        radius: height / 2
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

        NText {
            anchors.centerIn: parent
            visible: root.context.currentText.length === 0
            text: root.context.showFailure ? Translation.tr("Try again") : Translation.tr("Password")
            font.pixelSize: NihilStyle.textBody
            color: root.context.showFailure ? NihilStyle.m3.m3error : NihilStyle.inkSoft
        }

        Row {
            anchors.centerIn: parent
            spacing: NihilStyle.s(8)

            Repeater {
                model: Math.min(root.context.currentText.length, 18)
                delegate: Rectangle {
                    width: NihilStyle.s(8)
                    height: width
                    radius: width / 2
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

    NText {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: NihilStyle.s(32)
        visible: root.showBattery && Battery.available
        text: (Battery.isCharging ? Translation.tr("Charging") + "  " : "") + Math.round(Battery.percentage * 100) + "%"
        font.pixelSize: NihilStyle.textBody
        color: Battery.isLow && !Battery.isCharging ? NihilStyle.m3.m3error : NihilStyle.inkSoft
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
