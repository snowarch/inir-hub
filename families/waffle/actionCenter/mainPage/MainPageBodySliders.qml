pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.models.quickToggles
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter
import qs.modules.waffle.actionCenter.volumeControl

// Waffle Next sliders: thick rounded bars that fill with the accent, the icon riding inside and the value at the end.
ColumnLayout {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    onVisibleChanged: if (visible) root.brightnessMonitor?.refresh()
    spacing: Looks.dp(10)

    RowLayout {
        // a screen with no brightness control gets no bar that moves nothing
        visible: root.brightnessMonitor !== null
        spacing: Looks.dp(8)

        FillSlider {
            id: brightnessSlider
            iconName: "weather-sunny"
            iconRotation: brightnessSlider.value * 90
            label: Translation.tr("Brightness")
            property real modelValue: root.brightnessMonitor?.brightness ?? 0

            Binding {
                target: brightnessSlider
                property: "value"
                value: brightnessSlider.modelValue
                when: !brightnessSlider.pressed && !brightnessSlider._userInteracting
            }
            onMoved: root.brightnessMonitor?.setBrightness(value)
        }

        NightLightToggle { id: nightLight }
        RoundButton {
            iconName: "weather-moon"
            checked: nightLight.toggled
            tip: Translation.tr("Night Light")
            onClicked: nightLight.mainAction()
        }
    }

    RowLayout {
        spacing: Looks.dp(8)

        FillSlider {
            id: volumeSlider
            iconName: WIcons.volumeIcon ?? "speaker"
            iconTip: volumeSlider.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
            label: Translation.tr("Volume")
            muted: Audio.sink?.audio?.muted ?? false
            onIconClicked: Audio.toggleMute()
            to: 1.5
            property real modelValue: Audio.sink?.audio?.volume ?? 0

            Binding {
                target: volumeSlider
                property: "value"
                value: volumeSlider.modelValue
                when: !volumeSlider.pressed && !volumeSlider._userInteracting
            }
            onMoved: Audio.setSinkVolume(value)
        }

        RoundButton {
            Component {
                id: volumeControlComp
                VolumeControl {}
            }
            iconName: "options"
            tip: Translation.tr("Volume mixer")
            onClicked: if (ActionCenterContext.stackView) ActionCenterContext.stackView.push(volumeControlComp)
        }
    }

    component FillSlider: Slider {
        id: fill
        property string iconName
        property real iconRotation: 0
        // set: the icon is a button (mute) with this tooltip
        property string iconTip
        property string label
        property bool muted: false
        property bool _userInteracting: false
        signal iconClicked()

        Layout.fillWidth: true
        implicitHeight: Looks.dp(40)
        padding: 0
        stepSize: 0.01
        Accessible.name: fill.label

        WFocusVisual { shown: fill.visualFocus; radius: height / 2 }

        Timer {
            id: interactingReset
            interval: 180
            onTriggered: fill._userInteracting = false
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                fill._userInteracting = true
                interactingReset.restart()
                const step = event.angleDelta.y > 0 ? 0.02 : -0.02
                fill.value = Math.max(fill.from, Math.min(fill.to, fill.value + step))
                fill.moved()
            }
        }

        background: Rectangle {
            radius: height / 2
            color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.08 : 0.06)
            border.width: 1
            border.color: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.05 : 0.07)

            Rectangle {
                id: fillBar
                height: parent.height
                // never narrower than round: the icon always sits on the fill
                width: Math.max(height, fill.visualPosition * parent.width)
                radius: height / 2
                color: fill.muted ? Qt.alpha(Looks.colors.fg, 0.26) : Looks.colors.accent
                Behavior on width {
                    enabled: !fill.pressed && !fill._userInteracting
                    animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    animation: ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.OutQuad }
                }
            }

            // past this mark the sound is boosted
            Rectangle {
                visible: fill.to > 1
                x: parent.width * (1 - fill.from) / (fill.to - fill.from) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: Looks.dp(4)
                height: width
                radius: width / 2
                color: Qt.alpha(fillBar.width > x ? Looks.colors.accentFg : Looks.colors.fg, 0.3)
            }
        }

        handle: Rectangle {
            x: fillBar.width - width - Looks.dp(10)
            y: (fill.height - height) / 2
            width: Looks.dp(4)
            height: fill.height * (fill.pressed ? 0.5 : 0.4)
            radius: width / 2
            color: fill.muted ? Looks.colors.fg : Looks.colors.accentFg
            // near the start the grip would sit on the icon: the round end of the fill is the grip then
            visible: fillBar.width > Looks.dp(58)
            opacity: fill.pressed ? 0.95 : fill.hovered ? 0.75 : 0.5
            Behavior on height {
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.OutQuad }
            }
        }

        FluentIcon {
            z: 2
            x: (Looks.dp(40) - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            icon: fill.iconName
            implicitSize: Looks.dp(18)
            rotation: fill.iconRotation
            color: fill.muted ? Looks.colors.fg : Looks.colors.accentFg
        }

        MouseArea {
            z: 3
            visible: fill.iconTip.length > 0
            width: Looks.dp(40)
            height: parent.height
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fill.iconClicked()
            WToolTip {
                text: fill.iconTip
                extraVisibleCondition: parent.containsMouse
            }
        }

        WText {
            z: 2
            anchors.right: parent.right
            anchors.rightMargin: Looks.dp(14)
            anchors.verticalCenter: parent.verticalCenter
            text: `${Math.round(fill.value * 100)}%`
            font.pixelSize: Looks.font.pixelSize.small
            color: fillBar.width > fill.width - Looks.dp(46) ? Looks.colors.accentFg : Looks.colors.subfg
        }
    }

    component RoundButton: WButton {
        id: round
        property string iconName
        property string tip
        implicitWidth: Looks.dp(40)
        implicitHeight: Looks.dp(40)
        padding: 0
        radius: height / 2
        colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.08 : 0.06)
        colBackgroundHover: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.12 : 0.1)
        colBackgroundActive: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.16 : 0.14)
        contentItem: Item {
            FluentIcon {
                anchors.centerIn: parent
                icon: round.iconName
                implicitSize: Looks.dp(18)
                filled: round.checked
                color: round.checked ? Looks.colors.accentFg : Looks.colors.fg
            }
        }
        WToolTip { text: round.tip }
    }
}
