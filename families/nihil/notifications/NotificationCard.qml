pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One notification on its plate: the app's mark, the summary, the body, a picture if it brought one, then its actions.
// A click opens it, resting on it keeps it, the round key lets it go.
MouseArea {
    id: root

    required property var notice

    readonly property bool pictured: String(root.notice.image ?? "").length > 0
    readonly property bool hot: root.containsMouse || drop.containsMouse

    implicitHeight: Math.max(NihilStyle.s(84), words.implicitHeight + NihilStyle.s(32))
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: root.notice.summary
    onEntered: Notifications.cancelTimeout(root.notice.id)
    onClicked: Notifications.attemptInvokeAction(root.notice.id, "default")

    Rectangle {
        anchors.fill: parent
        radius: NihilStyle.r(24)
        color: root.hot ? NihilStyle.pieceRaised : NihilStyle.piece
        border.width: root.notice.critical ? NihilStyle.s(2) : 0
        border.color: NihilStyle.danger
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
    }
    NAppIcon {
        id: mark
        x: NihilStyle.s(16)
        y: NihilStyle.s(16)
        appId: root.notice.icon
        size: NihilStyle.s(48)
    }
    Column {
        id: words
        x: mark.x + mark.width + NihilStyle.s(14)
        y: NihilStyle.s(16)
        width: parent.width - x - NihilStyle.s(16) - (root.pictured ? picture.width + NihilStyle.s(12) : 0)
        spacing: NihilStyle.s(3)

        NText {
            width: parent.width - NihilStyle.s(30)
            text: root.notice.summary || root.notice.app
            font.pixelSize: NihilStyle.s(15)
            font.weight: Font.Medium
            color: root.notice.critical ? NihilStyle.danger : NihilStyle.ink
        }
        NText {
            width: parent.width
            visible: text.length > 0
            text: root.notice.body
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: 3
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
        Row {
            visible: root.notice.actions.length > 0
            topPadding: NihilStyle.s(8)
            spacing: NihilStyle.s(6)
            Repeater {
                model: root.notice.actions
                NButton {
                    required property var modelData
                    required property int index
                    height: NihilStyle.s(34)
                    label: modelData.text
                    lit: index === 0
                    tone: NihilStyle.pieceRaised
                    onClicked: Notifications.attemptInvokeAction(root.notice.id, modelData.id)
                }
            }
        }
    }
    ClippingRectangle {
        id: picture
        visible: root.pictured
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(16)
        y: NihilStyle.s(16)
        width: NihilStyle.s(64)
        height: width
        radius: NihilStyle.r(14)
        color: NihilStyle.piece
        Image {
            anchors.fill: parent
            source: root.pictured ? root.notice.image : ""
            sourceSize: Qt.size(parent.width * 2, parent.height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }
    NButton {
        id: drop
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: NihilStyle.s(8)
        width: NihilStyle.s(30)
        height: width
        tone: NihilStyle.pieceRaised
        opacity: root.hot ? 1 : 0
        icon: "close"
        iconSize: NihilStyle.s(14)
        Accessible.name: Translation.tr("Dismiss")
        onClicked: Notifications.discardNotification(root.notice.id)
    }
}
