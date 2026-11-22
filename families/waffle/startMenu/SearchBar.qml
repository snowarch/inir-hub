pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

FooterRectangle {
    id: root

    property real horizontalPadding: Looks.dp(24)
    property real verticalPadding: Looks.dp(18)
    property bool searching: text.length > 0
    property alias searchInput: searchInput
    property alias text: searchInput.text
    implicitHeight: outline.implicitHeight + verticalPadding * 2

    signal accepted()

    Component.onCompleted: forceFocus()
    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    focus: true
    // one sheet with the page under it: the search sits on Start, not on a band of its own
    color: Looks.colors.bgPanelBody

    Behavior on horizontalPadding {
        enabled: Config.options.waffles?.tweaks?.smootherSearchBar ?? false
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    Behavior on verticalPadding {
        enabled: Config.options.waffles?.tweaks?.smootherSearchBar ?? false
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }

    Rectangle {
        id: outline
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            verticalCenter: parent.verticalCenter
        }
        implicitHeight: Looks.dp(40)
        color: "transparent"
        radius: height / 2
        border.width: 1
        // the field lights in the accent while it has the keyboard, as WinUI's does
        border.color: searchInput.activeFocus ? Looks.colors.accent : Looks.colors.bg2Border
        Behavior on border.color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.OutQuad }
        }
    }

    Rectangle {
        id: searchInputBg
        anchors.fill: outline
        anchors.margins: 1
        radius: height / 2
        color: Looks.colors.inputBg

        RowLayout {
            anchors.fill: parent
            spacing: Looks.dp(12)

            WAppIcon {
                Layout.leftMargin: Looks.dp(16)
                iconName: "system-search-checked"
                separateLightDark: true
                implicitSize: 18
            }

            WTextInput {
                id: searchInput
                focus: true
                Layout.fillWidth: true
                Layout.rightMargin: Looks.dp(16)

                WText {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                    }
                    color: Looks.colors.accentUnfocused
                    text: Translation.tr("Search for apps")
                    visible: searchInput.text.length === 0
                    font.pixelSize: Looks.font.pixelSize.large
                }

                onAccepted: {
                    root.accepted();
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
        acceptedButtons: Qt.NoButton
    }
}
