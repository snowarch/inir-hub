pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Waffle's power screen: the desktop sinks behind frosted glass, you sit on it, and one row of big tiles says what
// happens next. Arrows or Tab move, Enter chooses, Esc or a click on the glass goes back.
Scope {
    id: root

    property bool shown: false
    property bool closing: false
    property int currentIndex: 0

    readonly property var focusedScreen: {
        if (CompositorService.isNiri && typeof NiriService !== "undefined" && NiriService.currentOutput) {
            const matchNiri = Quickshell.screens.find(s => s && s.name === NiriService.currentOutput)
            if (matchNiri)
                return matchNiri
        }
        const hypr = Hyprland.focusedMonitor?.name ?? ""
        const matchHypr = hypr ? Quickshell.screens.find(s => s && s.name === hypr) : null
        return matchHypr ?? GlobalStates.primaryScreen
    }

    readonly property var mainActions: [
        { icon: "lock-closed", label: Translation.tr("Lock"), run: () => Session.lock() },
        { icon: "weather-moon", label: Translation.tr("Sleep"), run: () => Session.suspend() },
        { icon: "open", label: Translation.tr("Sign out"), run: () => Session.logout() },
        { icon: "arrow-clockwise", label: Translation.tr("Restart"), run: () => Session.reboot() },
        { icon: "power", label: Translation.tr("Shut down"), run: () => Session.poweroff() }
    ]
    readonly property var moreActions: (Session.showHibernateAction
            ? [{ icon: "leaf-two", label: Translation.tr("Hibernate"), run: () => Session.hibernate() }] : [])
        .concat([
            { icon: "pulse", label: Translation.tr("Task Manager"), run: () => Session.launchTaskManager() },
            { icon: "settings-cog-multiple", label: Translation.tr("Firmware settings"), run: () => Session.rebootToFirmware() }
        ])
    readonly property int count: mainActions.length + moreActions.length
    readonly property string warning: SessionWarnings.packageManagerRunning ? Translation.tr("Your package manager is running")
        : SessionWarnings.downloadRunning ? Translation.tr("There might be a download in progress") : ""

    function hide(): void {
        GlobalStates.sessionOpen = false
    }

    function choose(index: int): void {
        const action = root.mainActions.concat(root.moreActions)[index]
        if (!action)
            return
        action.run()
        root.hide()
    }

    function present(): void {
        closeTimer.stop()
        root.closing = false
        root.currentIndex = 0
        SessionWarnings.refresh()
        Qt.callLater(() => root.shown = GlobalStates.sessionOpen)
    }

    Component.onCompleted: if (GlobalStates.sessionOpen) root.present()

    Connections {
        target: GlobalStates
        function onSessionOpenChanged() {
            if (GlobalStates.sessionOpen) {
                root.present()
            } else {
                root.shown = false
                root.closing = true
                closeTimer.restart()
            }
        }
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked)
                GlobalStates.sessionOpen = false
        }
    }

    Timer {
        id: closeTimer
        interval: Looks.transition.duration.leave + 40
        onTriggered: root.closing = false
    }

    component Tile: Item {
        id: tile
        required property var modelData
        required property int index
        readonly property bool current: root.currentIndex === tile.index

        implicitWidth: Math.max(Looks.dp(116), tileLabel.implicitWidth + Looks.dp(28))
        implicitHeight: Looks.dp(116)
        scale: tileMouse.pressed ? 0.97 : tile.current ? 1.04 : 1
        Behavior on scale {
            NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
        }

        Rectangle {
            anchors.fill: parent
            radius: Looks.radius.xLarge
            color: tile.current ? Looks.colors.accent : Qt.alpha(Looks.colors.bg0Opaque, Looks.dark ? 0.5 : 0.62)
            border.width: 1
            border.color: tile.current ? Qt.alpha(Looks.colors.accentFg, 0.18) : Qt.alpha(Looks.colors.fg, 0.1)
            Behavior on color {
                ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0 }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Looks.dp(12)
            FluentIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: tile.modelData.icon
                filled: tile.current
                implicitSize: Looks.dp(30)
                color: tile.current ? Looks.colors.accentFg : Looks.colors.fg
            }
            WText {
                id: tileLabel
                Layout.alignment: Qt.AlignHCenter
                text: tile.modelData.label
                font.pixelSize: Looks.font.pixelSize.large
                font.weight: Looks.font.weight.strong
                color: tile.current ? Looks.colors.accentFg : Looks.colors.fg
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.currentIndex = tile.index
            onClicked: root.choose(tile.index)
        }
    }

    component Pill: Item {
        id: pill
        required property var modelData
        required property int index
        readonly property int slot: root.mainActions.length + pill.index
        readonly property bool current: root.currentIndex === pill.slot

        implicitWidth: pillRow.implicitWidth + Looks.dp(28)
        implicitHeight: Looks.dp(38)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: pill.current ? Looks.colors.accent : Qt.alpha(Looks.colors.bg0Opaque, Looks.dark ? 0.42 : 0.55)
            border.width: 1
            border.color: pill.current ? Qt.alpha(Looks.colors.accentFg, 0.18) : Qt.alpha(Looks.colors.fg, 0.08)
            Behavior on color {
                ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0 }
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Looks.dp(8)
            FluentIcon {
                icon: pill.modelData.icon
                implicitSize: Looks.dp(16)
                color: pill.current ? Looks.colors.accentFg : Looks.colors.fg
            }
            WText {
                text: pill.modelData.label
                color: pill.current ? Looks.colors.accentFg : Looks.colors.fg
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.currentIndex = pill.slot
            onClicked: root.choose(pill.slot)
        }
    }

    component Hint: RowLayout {
        id: hint
        property string keyLabel
        property string label
        spacing: Looks.dp(6)
        Rectangle {
            implicitWidth: hintKey.implicitWidth + Looks.dp(12)
            implicitHeight: Looks.dp(22)
            radius: Looks.radius.medium
            color: Qt.alpha(Looks.colors.fg, 0.08)
            WText {
                id: hintKey
                anchors.centerIn: parent
                text: hint.keyLabel
                font.weight: Looks.font.weight.strong
            }
        }
        WText {
            text: hint.label
            color: Looks.colors.subfg
        }
    }

    Loader {
        active: GlobalStates.sessionOpen || root.closing
        sourceComponent: PanelWindow {
            id: win
            screen: root.focusedScreen
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:session"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: PolkitService.active ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: backdrop
                anchors.fill: parent
                opacity: root.shown ? 1 : 0
                Behavior on opacity {
                    NumberAnimation { duration: !Looks.transition.enabled ? 0 : root.shown ? Looks.transition.duration.normal : Looks.transition.duration.leave; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
                }

                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: {
                        const wBg = Config.options?.waffles?.background ?? {}
                        const path = (wBg.useMainWallpaper ?? true)
                            ? Config.options?.background?.wallpaperPath ?? ""
                            : wBg.wallpaperPath ?? Config.options?.background?.wallpaperPath ?? ""
                        return Wallpapers.stillUrlFor(path)
                    }
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(
                        Math.ceil((win.screen?.width ?? 1920) * Math.max(1, win.devicePixelRatio ?? 1)),
                        Math.ceil((win.screen?.height ?? 1080) * Math.max(1, win.devicePixelRatio ?? 1)))
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: wallpaper
                    blurEnabled: Appearance.effectsEnabled
                    blur: 0.85
                    blurMax: 72
                    saturation: 0.4
                }

                // the scheme's own surface with a touch of accent, a little deeper than Task View: the session is ending
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(ColorUtils.mix(Looks.colors.bg0Opaque, Looks.colors.accent, 0.88), Looks.dark ? 0.7 : 0.58)
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.hide()
                }
            }

            Item {
                id: content
                anchors.fill: parent
                focus: true
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.96
                Behavior on opacity {
                    NumberAnimation { duration: !Looks.transition.enabled ? 0 : root.shown ? Looks.transition.duration.medium : Looks.transition.duration.leave; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate }
                }
                Behavior on scale {
                    NumberAnimation { duration: !Looks.transition.enabled ? 0 : root.shown ? Looks.transition.duration.panel : Looks.transition.duration.leave; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                }

                Keys.onPressed: event => {
                    const mainCount = root.mainActions.length
                    const moreCount = root.moreActions.length
                    const key = event.key
                    if (key === Qt.Key_Escape)
                        root.hide()
                    else if (key === Qt.Key_Right || key === Qt.Key_Tab)
                        root.currentIndex = (root.currentIndex + 1) % root.count
                    else if (key === Qt.Key_Left || key === Qt.Key_Backtab)
                        root.currentIndex = (root.currentIndex - 1 + root.count) % root.count
                    else if (key === Qt.Key_Down && root.currentIndex < mainCount)
                        root.currentIndex = mainCount + Math.min(moreCount - 1, Math.floor(root.currentIndex * moreCount / mainCount))
                    else if (key === Qt.Key_Up && root.currentIndex >= mainCount)
                        root.currentIndex = Math.min(mainCount - 1, Math.round((root.currentIndex - mainCount) * (mainCount - 1) / Math.max(1, moreCount - 1)))
                    else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
                        root.choose(root.currentIndex)
                    else
                        return
                    event.accepted = true
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Looks.dp(104)
                        implicitHeight: Looks.dp(104)
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: Looks.dp(2)
                            border.color: Qt.alpha(Looks.colors.accent, 0.75)
                        }
                        WUserAvatar {
                            anchors.centerIn: parent
                            sourceSize: Qt.size(Looks.dp(92), Looks.dp(92))
                        }
                    }

                    WText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Looks.dp(14)
                        text: SystemInfo.displayName || SystemInfo.username
                        font.pixelSize: Math.round(26 * Looks.fontScale)
                        font.weight: Looks.font.weight.strong
                    }

                    WText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Looks.dp(2)
                        // `hostname` is "" until /etc/hostname resolves
                        text: [SystemInfo.hostname, Translation.tr("Up for %1").arg(DateTime.uptime)].filter(part => part).join("  ·  ")
                        color: Looks.colors.subfg
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Looks.dp(36)
                        spacing: Looks.dp(12)
                        Repeater {
                            model: root.mainActions
                            delegate: Tile {}
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Looks.dp(18)
                        spacing: Looks.dp(8)
                        Repeater {
                            model: root.moreActions
                            delegate: Pill {}
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Looks.dp(24)
                        visible: root.warning.length > 0
                        implicitWidth: warningRow.implicitWidth + Looks.dp(28)
                        implicitHeight: Looks.dp(36)
                        radius: height / 2
                        color: Qt.alpha(Looks.colors.danger, 0.2)
                        border.width: 1
                        border.color: Qt.alpha(Looks.colors.danger, 0.45)
                        RowLayout {
                            id: warningRow
                            anchors.centerIn: parent
                            spacing: Looks.dp(8)
                            FluentIcon {
                                icon: "alert"
                                implicitSize: Looks.dp(16)
                                color: Looks.colors.danger
                            }
                            WText {
                                text: root.warning
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Looks.dp(40)
                    implicitWidth: hintsRow.implicitWidth + Looks.dp(20)
                    implicitHeight: Looks.dp(36)
                    radius: height / 2
                    color: Qt.alpha(Looks.colors.bg0Opaque, 0.55)
                    RowLayout {
                        id: hintsRow
                        anchors.centerIn: parent
                        spacing: Looks.dp(14)
                        Hint { keyLabel: "←  →"; label: Translation.tr("Move") }
                        Hint { keyLabel: "Enter"; label: Translation.tr("Choose") }
                        Hint { keyLabel: "Esc"; label: Translation.tr("Back") }
                    }
                }
            }
        }
    }
}
