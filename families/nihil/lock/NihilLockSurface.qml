pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// NiHiL's lock: the wallpaper softened, the time in large dots (hours lit, minutes in ink), the day in the serif
// under it, and at the foot one pill for the password, each typed letter a dot, beside a lit key that unlocks.
// Power and restart wait at the left; the battery at the right.
MouseArea {
    id: root

    required property LockContext context
    readonly property bool blur: Config.options?.nihil?.lock?.blur ?? true
    readonly property bool fused: (Config.options?.nihil?.clock?.style ?? "dots") === "fused"
    readonly property bool twoTone: Config.options?.nihil?.clock?.twoTone ?? true
    readonly property bool requirePasswordToPower: Config.options?.lock?.security?.requirePasswordToPower ?? true
    readonly property string time: DateTime.time
    readonly property string hours: root.time.split(":")[0] ?? ""
    readonly property string minutes: (root.time.split(":")[1] ?? "").slice(0, 2)

    function focusField(): void { Qt.callLater(() => field.forceActiveFocus()) }
    function submit(): void {
        if (root.context.currentText.length > 0 && !root.context.unlockInProgress) root.context.tryUnlock()
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
    }

    Rectangle { anchors.fill: parent; color: NihilStyle.well }

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
        brightness: NihilStyle.dark ? -0.18 : 0.08
    }

    // The time and the day.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.28)
        spacing: NihilStyle.s(28)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: NihilStyle.s(40)
            DotText {
                text: root.hours
                fuse: root.fused
                color: root.twoTone ? NihilStyle.accent : NihilStyle.ink
                dot: NihilStyle.s(22)
                spacing: root.fused ? NihilStyle.s(2) : NihilStyle.s(7)
            }
            DotText {
                text: root.minutes
                fuse: root.fused
                color: NihilStyle.ink
                dot: NihilStyle.s(22)
                spacing: root.fused ? NihilStyle.s(2) : NihilStyle.s(7)
            }
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            dots: true
            text: DateTime.date
            font.pixelSize: NihilStyle.s(28)
            color: NihilStyle.ink
        }
    }

    // The password.
    Row {
        id: entry
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(64)
        spacing: NihilStyle.cellGap
        property real shake: 0
        transform: Translate { x: entry.shake }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: entry; property: "shake"; to: NihilStyle.s(10); duration: 50 }
            NumberAnimation { target: entry; property: "shake"; to: -NihilStyle.s(10); duration: 80 }
            NumberAnimation { target: entry; property: "shake"; to: 0; duration: 60 }
        }
        Connections {
            target: root.context
            function onFailed(): void { shakeAnim.restart() }
        }

        NButton {
            width: NihilStyle.s(320)
            height: NihilStyle.button
            onClicked: root.focusField()
            TextInput {
                id: field
                anchors.fill: parent
                opacity: 0
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData
                text: root.context.currentText
                enabled: !root.context.unlockInProgress
                onTextChanged: root.context.currentText = text
                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: root.context.clearText()
            }
            NText {
                anchors.centerIn: parent
                visible: root.context.currentText.length === 0
                figures: true
                text: (root.context.showFailure ? Translation.tr("Try again") : Translation.tr("Password")).toUpperCase()
                color: root.context.showFailure ? NihilStyle.accent : NihilStyle.inkSoft
            }
            Row {
                anchors.centerIn: parent
                spacing: NihilStyle.s(7)
                Repeater {
                    model: Math.min(root.context.currentText.length, 22)
                    delegate: Rectangle {
                        width: NihilStyle.s(8); height: width
                        radius: width / 2
                        color: NihilStyle.ink
                    }
                }
            }
        }
        NButton {
            lit: true
            icon: root.context.unlockInProgress ? "more_horiz"
                : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart_alt" : "arrow_forward"
            iconSize: NihilStyle.s(24)
            onClicked: root.submit()
        }
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: NihilStyle.edge
        anchors.verticalCenter: entry.verticalCenter
        spacing: NihilStyle.gap
        NButton { icon: "power_settings_new"; onClicked: root.power(LockContext.ActionEnum.Poweroff) }
        NButton { icon: "restart_alt"; onClicked: root.power(LockContext.ActionEnum.Reboot) }
    }

    NButton {
        visible: Battery.available
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.edge
        anchors.verticalCenter: entry.verticalCenter
        width: NihilStyle.s(120)
        Row {
            anchors.centerIn: parent
            spacing: NihilStyle.s(8)
            NIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.isCharging ? "bolt" : "battery_full"
                color: Battery.isLow && !Battery.isCharging ? NihilStyle.accent : NihilStyle.ink
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: Math.round(Battery.percentage * 100) + "%"
            }
        }
    }
}
