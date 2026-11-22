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
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

// Waffle Next quick setting: a wide pill that holds its name and its state, as the Windows 12 concepts draw them.
// The body switches it, the chevron opens its page when it has one, and a right-click runs its other action.
Item {
    id: root

    required property QuickToggleModel toggleModel
    property string name: toggleModel?.name ?? ""
    property string statusText: (toggleModel?.hasStatusText) ? (toggleModel?.statusText || (toggled ? Translation.tr("Active") : Translation.tr("Inactive"))) : ""
    property string tooltipText: toggleModel?.tooltipText ?? ""
    required property string icon
    property bool available: toggleModel?.available ?? true
    property bool toggled: toggleModel?.toggled ?? false
    property var mainAction: toggleModel?.mainAction ?? null
    property var altAction: toggleModel?.hasMenu ? (() => root.openMenu()) : (toggleModel?.altAction ?? null)
    property bool hasMenu: toggleModel?.hasMenu ?? false
    property Component menu

    readonly property color colForeground: toggled ? Looks.colors.accentFg : Looks.colors.fg
    readonly property real radius: Looks.radius.large

    function openMenu(): void {
        if (root.menu)
            ActionCenterContext.push(root.menu)
    }

    Layout.fillWidth: true
    implicitWidth: Looks.dp(160)
    implicitHeight: Looks.dp(56)
    opacity: root.available ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.toggled ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.07 : 0.05)
        border.width: 1
        border.color: root.toggled ? Qt.alpha(Looks.colors.accentFg, 0.14) : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.06 : 0.08)
        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.OutQuad }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Fragment {
            id: mainPart
            Layout.fillWidth: true
            Layout.fillHeight: true
            topLeftRadius: root.radius
            bottomLeftRadius: root.radius
            topRightRadius: root.hasMenu ? 0 : root.radius
            bottomRightRadius: root.hasMenu ? 0 : root.radius
            enabled: root.available
            onClicked: {
                Audio.playEvent(root.toggled ? "toggleOff" : "toggleOn")
                if (root.mainAction) root.mainAction()
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: !!root.altAction
                onTapped: root.altAction()
            }

            contentItem: RowLayout {
                spacing: Looks.dp(10)

                Rectangle {
                    Layout.leftMargin: Looks.dp(10)
                    Layout.preferredWidth: Looks.dp(32)
                    Layout.preferredHeight: Looks.dp(32)
                    radius: width / 2
                    color: Qt.alpha(root.colForeground, root.toggled ? 0.16 : 0.08)
                    scale: mainPart.down ? 0.88 : 1
                    Behavior on scale {
                        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive }
                    }

                    FluentIcon {
                        anchors.centerIn: parent
                        icon: root.icon
                        implicitSize: Looks.dp(17)
                        monochrome: true
                        filled: root.toggled
                        color: root.colForeground
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.rightMargin: root.hasMenu ? Looks.dp(2) : Looks.dp(10)
                    spacing: 0

                    WText {
                        Layout.fillWidth: true
                        text: root.name
                        color: root.colForeground
                        font.weight: Looks.font.weight.strong
                        // with no state line a long name takes two lines, not an ellipsis
                        wrapMode: Text.Wrap
                        maximumLineCount: statusLine.visible ? 1 : 2
                        elide: Text.ElideRight
                    }
                    WText {
                        id: statusLine
                        Layout.fillWidth: true
                        // Bluetooth names itself by its state: the line would say it twice
                        visible: text.length > 0 && text !== root.name
                        text: root.statusText
                        color: Qt.alpha(root.colForeground, 0.72)
                        font.pixelSize: Looks.font.pixelSize.small
                        elide: Text.ElideRight
                    }
                }
            }

            WToolTip {
                text: root.tooltipText || root.name
            }
        }

        Fragment {
            visible: root.hasMenu
            Layout.preferredWidth: Looks.dp(30)
            Layout.fillHeight: true
            topRightRadius: root.radius
            bottomRightRadius: root.radius
            onClicked: root.openMenu()

            contentItem: Item {
                FluentIcon {
                    anchors.centerIn: parent
                    icon: "chevron-right"
                    implicitSize: Looks.dp(12)
                    color: root.colForeground
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.46
                color: Qt.alpha(root.colForeground, 0.16)
            }
        }
    }

    component Fragment: WButton {
        inset: 0
        padding: 0
        topLeftRadius: 0
        bottomLeftRadius: 0
        topRightRadius: 0
        bottomRightRadius: 0
        border.width: 0
        colBackground: "transparent"
        colBackgroundHover: Qt.alpha(root.colForeground, 0.07)
        colBackgroundActive: Qt.alpha(root.colForeground, 0.13)
    }
}
