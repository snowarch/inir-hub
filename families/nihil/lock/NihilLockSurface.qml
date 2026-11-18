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

// NiHiL's lock: the wallpaper softened and one block in its middle. The hours in heavy dots on paper, the minutes beside
// them on the signal's tile, the day and the charge, then power, restart, the password and the key that unlocks.
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

    // One block in the middle: the hours on paper, the minutes beside them, the day, the way in.
    Column {
        id: block
        readonly property real wide: NihilStyle.s(556)
        readonly property real half: (block.wide - NihilStyle.seam) / 2
        anchors.centerIn: parent
        spacing: NihilStyle.seam

        property real shake: 0
        transform: Translate { x: block.shake }
        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: block; property: "shake"; to: NihilStyle.s(10); duration: 50 }
            NumberAnimation { target: block; property: "shake"; to: -NihilStyle.s(10); duration: 80 }
            NumberAnimation { target: block; property: "shake"; to: 0; duration: 60 }
        }
        Connections {
            target: root.context
            function onFailed(): void { shakeAnim.restart() }
        }

        Row {
            spacing: NihilStyle.seam
            NTile {
                id: hoursTile
                width: block.half
                height: NihilStyle.s(232)
                paper: true
                DotText {
                    anchors.centerIn: parent
                    text: root.hours
                    fuse: root.fused
                    color: hoursTile.ink
                    dot: NihilStyle.s(23)
                    spacing: root.fused ? NihilStyle.s(1) : NihilStyle.s(3)
                }
            }
            NTile {
                id: minutesTile
                width: block.half
                height: NihilStyle.s(232)
                lit: root.twoTone
                DotText {
                    anchors.centerIn: parent
                    text: root.minutes
                    fuse: root.fused
                    color: minutesTile.ink
                    dot: NihilStyle.s(23)
                    spacing: root.fused ? NihilStyle.s(1) : NihilStyle.s(3)
                }
            }
        }

        Row {
            spacing: NihilStyle.seam
            NTile {
                id: dayTile
                width: block.wide - (charge.visible ? charge.width + NihilStyle.seam : 0)
                height: NihilStyle.s(72)
                NText {
                    x: dayTile.pad
                    width: dayTile.width - dayTile.pad * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.date
                    font.pixelSize: NihilStyle.textTitle
                    font.weight: Font.Black
                    color: dayTile.ink
                }
            }
            NStat {
                id: charge
                visible: Battery.available
                width: NihilStyle.s(132)
                height: NihilStyle.s(72)
                figure: String(Math.round(Battery.percentage * 100))
                figureSize: NihilStyle.s(30)
                unit: Battery.isCharging ? Translation.tr("Charging") : "%"
                strokeColor: Battery.isLow && !Battery.isCharging ? NihilStyle.accent : ink
            }
        }

        Row {
            spacing: NihilStyle.seam
            NButton {
                id: offKey
                width: NihilStyle.s(64); height: width
                square: true
                icon: "power_settings_new"
                iconSize: NihilStyle.s(26)
                onClicked: root.power(LockContext.ActionEnum.Poweroff)
            }
            NButton {
                id: againKey
                width: NihilStyle.s(64); height: width
                square: true
                icon: "restart_alt"
                iconSize: NihilStyle.s(26)
                onClicked: root.power(LockContext.ActionEnum.Reboot)
            }
            NButton {
                width: block.wide - offKey.width - againKey.width - goKey.width - NihilStyle.seam * 3
                height: NihilStyle.s(64)
                square: true
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
                    x: NihilStyle.s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.context.currentText.length === 0
                    text: root.context.showFailure ? Translation.tr("Try again") : Translation.tr("Password")
                    font.pixelSize: NihilStyle.s(18)
                    font.weight: Font.Black
                    color: root.context.showFailure ? NihilStyle.accent : NihilStyle.inkSoft
                }
                Row {
                    x: NihilStyle.s(16)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(5)
                    Repeater {
                        model: Math.min(root.context.currentText.length, 16)
                        delegate: Rectangle {
                            width: NihilStyle.s(12); height: width
                            radius: NihilStyle.squareDots ? NihilStyle.s(2) : width / 2
                            color: NihilStyle.ink
                        }
                    }
                }
            }
            NButton {
                id: goKey
                width: NihilStyle.s(84); height: NihilStyle.s(64)
                square: true
                lit: true
                icon: root.context.unlockInProgress ? "more_horiz"
                    : root.context.targetAction === LockContext.ActionEnum.Poweroff ? "power_settings_new"
                    : root.context.targetAction === LockContext.ActionEnum.Reboot ? "restart_alt" : "arrow_forward"
                iconSize: NihilStyle.s(28)
                onClicked: root.submit()
            }
        }
    }
}
