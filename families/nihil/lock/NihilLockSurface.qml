pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// The lock: the sheet has bent into the horizon of a dark planet and the password sits on it, where the light gathers.
// Each key typed feeds that light. The day and the time stand above; what the computer is doing and the ways out wait
// in the corners below the horizon.
MouseArea {
    id: root

    required property LockContext context

    readonly property bool blur: Config.options?.nihil?.lock?.blur ?? true
    readonly property bool showBattery: Config.options?.nihil?.lock?.showBattery ?? true
    readonly property bool requirePasswordToPower: Config.options?.lock?.security?.requirePasswordToPower ?? true
    readonly property bool busy: root.context.unlockInProgress
    readonly property bool failed: root.context.showFailure && root.context.currentText.length === 0

    readonly property real unit: root.height / 1080
    readonly property real limbAt: Math.round(root.height * 0.7685)
    readonly property string layoutCode: NiriService.hasMultipleKeyboardLayouts
        ? String(NiriService.keyboardLayoutNames[NiriService.currentKeyboardLayoutIndex] ?? "").slice(0, 2).toUpperCase() : ""

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

    component Fact: Row {
        id: fact
        property string glyph: ""
        property string word: ""
        property color tone: NihilStyle.inkSoft
        spacing: NihilStyle.s(8)
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            text: fact.glyph
            size: NihilStyle.s(18)
            color: fact.tone
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            text: fact.word
            font.pixelSize: NihilStyle.textSmall
            color: fact.tone
        }
    }

    component Way: NButton {
        width: NihilStyle.s(40)
        height: NihilStyle.s(40)
        radius: height / 2
        tone: "transparent"
        iconSize: NihilStyle.s(20)
    }

    Rectangle {
        anchors.fill: parent
        color: NihilStyle.void_
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Wallpapers.effectiveWallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
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
        saturation: -0.1
        brightness: NihilStyle.dark ? -0.42 : 0.08
    }

    NSheet {
        anchors.fill: parent
        band: 0
        limb: 1
        limbAt: root.limbAt
        limbRadius: root.width * 1.354
        limbGlass: 0.42
        light: Qt.point(root.width / 2, root.limbAt)
        lightReach: NihilStyle.s(380)
        lightPower: 1.05 + Math.min(root.context.currentText.length, 8) * 0.05
        Behavior on lightPower { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    }

    NText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(170 * root.unit)
        text: Translation.locale.toString(DateTime.clock.date, "dddd d MMMM")
        font.pixelSize: NihilStyle.s(20)
        font.weight: Font.Light
        color: NihilStyle.inkSoft
    }
    NDisplay {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(166 * root.unit)
        text: DateTime.time
        size: Math.round(Math.min(184 * root.unit, root.width * 0.096))
        font.weight: Font.ExtraLight
        font.letterSpacing: -size * 0.043
    }

    NBloom {
        anchors.centerIn: capsule
        width: capsule.width * 1.7
        height: capsule.height * 3.4
        tone: NihilStyle.specA
        strength: 0.3 + Math.min(root.context.currentText.length, 8) * 0.04
        Behavior on strength { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
    }

    // The password, on the horizon.
    Rectangle {
        id: capsule

        property real nudge: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: root.limbAt - height / 2
        width: NihilStyle.s(360)
        height: NihilStyle.s(60)
        radius: height / 2
        color: NihilStyle.void_
        border.width: 1
        border.color: root.failed ? NihilStyle.danger : NihilStyle.hair
        transform: Translate { x: capsule.nudge }
        Behavior on border.color { ColorAnimation { duration: NihilStyle.quick } }

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
            x: NihilStyle.s(26)
            anchors.verticalCenter: parent.verticalCenter
            visible: root.context.currentText.length === 0
            text: Translation.tr("Password")
            color: NihilStyle.inkFaint
        }

        Row {
            x: NihilStyle.s(26)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(11)

            Repeater {
                model: Math.min(root.context.currentText.length, 16)
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
            anchors.rightMargin: NihilStyle.s(9)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(42)
            height: NihilStyle.s(42)
            radius: height / 2
            lit: true
            icon: root.busy ? "more_horiz"
                : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart" : "arrow_forward"
            Accessible.name: Translation.tr("Unlock")
            onClicked: root.submit()
        }
    }

    NText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.limbAt + NihilStyle.s(48)
        text: root.failed ? Translation.tr("Try again") : SystemInfo.username
        font.pixelSize: NihilStyle.s(16)
        font.weight: Font.Medium
        color: root.failed ? NihilStyle.danger : NihilStyle.ink
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: NihilStyle.s(44)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(32)
        height: NihilStyle.s(20)
        spacing: NihilStyle.s(20)

        Fact {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showBattery && Battery.available
            glyph: Battery.isCharging ? "battery_charging_full" : "battery_full"
            word: Math.round(Battery.percentage * 100) + " %"
            tone: Battery.isLow && !Battery.isCharging ? NihilStyle.danger : NihilStyle.inkSoft
        }
        Fact {
            anchors.verticalCenter: parent.verticalCenter
            visible: Network.ethernet || Network.networkName.length > 0
            glyph: Network.ethernet ? "lan" : "wifi"
            word: Network.ethernet ? Translation.tr("Wired") : Network.networkName
        }
        Fact {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layoutCode.length > 0
            glyph: "keyboard"
            word: root.layoutCode
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(34)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(22)
        spacing: NihilStyle.s(2)

        Way {
            icon: "bedtime"
            Accessible.name: Translation.tr("Sleep")
            onClicked: Session.suspend()
        }
        Way {
            icon: "restart"
            Accessible.name: Translation.tr("Restart")
            onClicked: root.power(LockContext.ActionEnum.Reboot)
        }
        Way {
            icon: "power_settings_new"
            Accessible.name: Translation.tr("Shut down")
            onClicked: root.power(LockContext.ActionEnum.Poweroff)
        }
    }
}
