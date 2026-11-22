pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.bar.tasks
import qs.modules.waffle.bar.tray

Rectangle {
    id: root

    property bool nativeBlurAllowed: true
    readonly property var panelScreen: root.QsWindow?.window?.screen ?? null
    readonly property real panelScale: Looks.barScale(panelScreen)
    readonly property bool glassActive: Looks.glassActive
    readonly property string nativeBlurTopology: Appearance.blurTopology.rectangle
    readonly property bool nativeBlurActive: nativeBlurAllowed && glassActive
        && Appearance.useCompositorBlur("waffle", root.nativeBlurTopology)
    readonly property bool barAtBottom: Config.options?.waffles?.bar?.bottom ?? false
    readonly property bool floating: Looks.barFloating
    // floating, the end groups keep off the rounded corners
    readonly property real endPad: root.floating ? Looks.dp(6) : 0
    readonly property real _screenW: panelScreen?.width ?? Quickshell.screens[0]?.width ?? 1920
    readonly property real _screenH: panelScreen?.height ?? Quickshell.screens[0]?.height ?? 1080
    color: root.glassActive ? "transparent" : Looks.colors.bg0
    clip: true
    radius: root.floating ? Looks.radius.large : 0
    implicitHeight: Looks.scaledBar(48, panelScreen)

    PaletteFade {
        anchors.fill: parent
        target: root
        active: root.visible && Looks.transition.enabled
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }

    // Right-click context menu anchor (invisible, positioned at click)
    Item {
        id: contextMenuAnchor
        width: 1
        height: 1
    }

    // Right-click context menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: -1  // Below other elements so they can handle their own right-clicks
        onClicked: (mouse) => {
            contextMenuAnchor.x = mouse.x
            contextMenuAnchor.y = 0
            taskbarContextMenu.active = true
        }
    }
    // The pointer still on the bar keeps its menu open (it closed 500 ms after the right click).
    HoverHandler {
        id: barHover
    }

    BarMenu {
        id: taskbarContextMenu
        anchorItem: contextMenuAnchor
        anchorHovered: barHover.hovered
        closeOnHoverLostDelay: 500  // Slower close to give time to click

        model: [
            {
                iconName: "pulse",
                text: Translation.tr("Task Manager"),
                action: () => {
                    Session.launchTaskManager()
                }
            },
            { type: "separator" },
            {
                iconName: "settings",
                text: Translation.tr("Taskbar settings"),
                action: () => {
                    Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                }
            }
        ]
    }

    // Glass background for aurora/angel styles
    GlassBackground {
        anchors.fill: parent
        visible: root.glassActive && !root.nativeBlurActive && !Looks.gameModeMinimal
        radius: root.radius
        screenX: Looks.barGap
        screenY: root.barAtBottom ? (root._screenH - root.height - Looks.barGap) : Looks.barGap
        screenWidth: root._screenW
        screenHeight: root._screenH
        auroraTransparency: Appearance.aurora.overlayTransparentize
    }

    Rectangle {
        id: border
        visible: !root.floating
        anchors {
            left: parent.left
            right: parent.right
            top: root.barAtBottom ? parent.top : undefined
            bottom: root.barAtBottom ? undefined : parent.bottom
        }
        color: root.glassActive
            ? (Looks.angelEverywhere ? Appearance.angel.colPanelBorder : Appearance.aurora.colTooltipBorder)
            : Looks.colors.bg0Border
        implicitHeight: 1
    }

    BarGroupRow {
        id: bloatRow
        anchors.left: parent.left
        anchors.leftMargin: root.endPad
        opacity: (Config.options?.waffles?.bar?.leftAlignApps ?? false) ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
        }

        WeatherButton {}
    }

    BarGroupRow {
        id: appsRow
        anchors.left: undefined
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.leftMargin: root.endPad

        states: State {
            name: "left"
            when: Config.options?.waffles?.bar?.leftAlignApps ?? false
            AnchorChanges {
                target: appsRow
                anchors.left: parent.left
                anchors.horizontalCenter: undefined
            }
        }

        transitions: Transition {
            AnchorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
        }

        StartButton {}
        SearchButton {}
        TaskViewButton {}
        WTaskbarSeparator { }
        Tasks {}
    }

    BarGroupRow {
        id: systemRow
        anchors.right: parent.right
        anchors.rightMargin: root.endPad
        FadeLoader {
            Layout.fillHeight: true
            shown: Config.options?.waffles?.bar?.leftAlignApps ?? false
            sourceComponent: WeatherButton {}
        }
        Tray {}
        TimerButton {}
        UpdatesButton {}
        SystemButton {}
        TimeButton {}
        DesktopPeekButton {}
    }

    // Floating, the bar is a pane of its own: the dark ring parts it from the wallpaper, the lit rim inside catches
    // the light from above, as every Waffle Next surface does
    Rectangle {
        visible: root.floating
        z: 10
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.glassActive ? Looks.colors.tooltipBorder : Looks.colors.ring
    }
    Rectangle {
        visible: root.floating
        z: 10
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: Looks.colors.rim
        opacity: root.glassActive ? 0.6 : 1
    }

    component BarGroupRow: RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
    }
}
