pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.lock
import qs.modules.nihil.style

// The lock: the time at the heart of a ring of sixty ticks. At rest the ring tells the minute; each key typed lights more
// of it, and a wrong password turns it red. What the computer is doing and the ways out wait in the corners.
MouseArea {
    id: root

    required property LockContext context

    readonly property bool blur: Config.options?.nihil?.lock?.blur ?? true
    readonly property bool showBattery: Config.options?.nihil?.lock?.showBattery ?? true
    readonly property bool requirePasswordToPower: Config.options?.lock?.security?.requirePasswordToPower ?? true
    readonly property bool busy: root.context.unlockInProgress
    readonly property bool failed: root.context.showFailure && root.context.currentText.length === 0

    readonly property int typed: root.context.currentText.length
    readonly property real ringRadius: Math.round(Math.min(root.height * 0.3, root.width * 0.22))
    readonly property real ringCentre: Math.round(root.height * 0.42)
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
        property color tone: NihilStyle.textSecondary
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
        color: NihilStyle.background
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
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 1
        blurMax: 64
        saturation: -0.1
        brightness: NihilStyle.dark ? -0.2 : 0.08
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(NihilStyle.background, NihilStyle.dark ? 0.26 : 0.24)
    }

    // The ring tells the minute at rest and counts the password while it is typed.
    NRing {
        id: ring
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.ringCentre - root.ringRadius
        width: root.ringRadius * 2
        height: width
        ticks: 60
        level: root.typed > 0 ? Math.min(root.typed * 4, 60) / 60 : DateTime.clock.date.getMinutes() / 60
        fillColor: root.failed ? NihilStyle.danger : root.typed > 0 ? NihilStyle.accent : NihilStyle.text
        Behavior on level { NumberAnimation { duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }
        Behavior on fillColor { ColorAnimation { duration: NihilStyle.durationShort } }
    }

    Column {
        anchors.centerIn: ring
        width: root.ringRadius * 1.46
        spacing: NihilStyle.s(4)
        NDisplay {
            width: parent.width
            height: root.ringRadius * 0.5
            horizontalAlignment: Text.AlignHCenter
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: NihilStyle.s(40)
            size: root.ringRadius * 0.46
            text: DateTime.time
        }
        NText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Translation.locale.toString(DateTime.clock.date, "dddd d MMMM")
            font.pixelSize: NihilStyle.s(18)
            font.weight: Font.Light
            color: NihilStyle.textSecondary
        }
    }

    // The password, under the ring.
    Rectangle {
        id: capsule

        property real nudge: 0

        anchors.horizontalCenter: parent.horizontalCenter
        y: ring.y + ring.height + NihilStyle.s(30)
        width: NihilStyle.s(360)
        height: NihilStyle.s(60)
        radius: height / 2
        color: Qt.alpha(NihilStyle.background, 0.72)
        border.width: field.activeFocus || root.failed ? 2 : 1
        border.color: root.failed ? NihilStyle.danger : field.activeFocus ? NihilStyle.accent : NihilStyle.border
        transform: Translate { x: capsule.nudge }
        Behavior on border.color { ColorAnimation { duration: NihilStyle.durationShort } }

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
            visible: root.typed === 0
            text: Translation.tr("Password")
            color: NihilStyle.textSecondary
        }

        Row {
            x: NihilStyle.s(26)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(11)

            Repeater {
                model: Math.min(root.typed, 16)
                delegate: Rectangle {
                    width: NihilStyle.s(7)
                    height: width
                    radius: width / 2
                    color: NihilStyle.text
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
            highlighted: true
            icon: root.busy ? "more_horiz"
                : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart" : "arrow_forward"
            Accessible.name: Translation.tr("Unlock")
            onClicked: root.submit()
        }
    }

    NText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: capsule.y + capsule.height + NihilStyle.s(14)
        text: root.failed ? Translation.tr("Try again") : SystemInfo.username
        font.pixelSize: NihilStyle.s(15)
        font.weight: Font.Medium
        color: root.failed ? NihilStyle.danger : NihilStyle.text
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
            tone: Battery.isLow && !Battery.isCharging ? NihilStyle.danger : NihilStyle.textSecondary
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
