pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// One window in the overview: its live picture, its icon, its title and a close key, each placed as the person set.
Item {
    id: root

    required property var win
    property var slot: ({ x: 0, y: 0, w: 0, h: 0 })
    property bool selected: false
    property bool live: true
    signal activated()

    readonly property var options: Config.options?.nihil?.windows
    readonly property bool hot: hand.containsMouse || iconHand.containsMouse || closeKey.containsMouse || root.selected
    readonly property string titleAt: root.options?.titlePosition ?? "below"
    readonly property bool titleShown: root.titleAt.endsWith("Always") || root.hot
    readonly property bool titleOnTop: root.titleAt.startsWith("top")
    readonly property bool titleInside: root.titleAt.startsWith("inside")
    readonly property string closeShown: root.options?.closeButton ?? "selected"
    readonly property real iconSize: NihilStyle.s(root.options?.iconSize ?? 48)
    readonly property var windowId: root.win.id

    x: root.slot.x
    y: root.slot.y
    width: root.slot.w
    height: root.slot.h
    z: hand.drag.active ? 100 : root.hot ? 2 : 1

    Behavior on x { enabled: !hand.drag.active; NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }
    Behavior on y { enabled: !hand.drag.active; NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }
    Behavior on width { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }

    Drag.active: hand.drag.active
    Drag.keys: ["nihil-window"]
    Drag.hotSpot: Qt.point(root.width / 2, root.height / 2)

    NGlass {
        anchors.fill: parent
        radius: NihilStyle.rCard
        flare: root.hot ? NihilStyle.glassFlare : 0
        ignite: root.hot ? 0.8 : 0
        tracks: true
    }

    WindowShot {
        anchors.fill: parent
        anchors.margins: NihilStyle.s(2)
        radius: NihilStyle.rCard - NihilStyle.s(2)
        windowId: root.win.id
        appId: root.win.app_id ?? ""
        live: root.live
        iconWhileEmpty: false
    }

    MouseArea {
        id: hand
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        drag.target: root
        drag.threshold: NihilStyle.s(12)
        onReleased: {
            if (root.Drag.active) root.Drag.drop()
            root.x = Qt.binding(() => root.slot.x)
            root.y = Qt.binding(() => root.slot.y)
        }
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) root.activated()
            else if (mouse.button === Qt.MiddleButton) NihilState.windowAction(root.options?.middleClick ?? "close", root.win)
            else NihilState.windowAction(root.options?.rightClick ?? "next", root.win)
        }
    }

    NAppIcon {
        id: appIcon
        visible: root.iconSize > 0
        appId: root.win.app_id ?? ""
        size: root.iconSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.bottom
        scale: root.hot ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutBack } }
        MouseArea {
            id: iconHand
            anchors.fill: parent
            hoverEnabled: true
            enabled: (root.options?.iconClick ?? "activate") !== "none"
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const action = root.options?.iconClick ?? "activate"
                if (action === "activate") root.activated()
                else NihilState.windowAction(action, root.win)
            }
        }
    }

    NGlass {
        visible: root.titleShown && (root.win.title ?? "").length > 0
        x: (root.width - width) / 2
        y: root.titleOnTop ? NihilStyle.s(8)
            : root.titleInside ? root.height - height - root.iconSize / 2 - NihilStyle.s(8)
            : root.height + root.iconSize / 2 + NihilStyle.s(4)
        width: Math.min(title.implicitWidth + NihilStyle.s(22), root.width - NihilStyle.s(12))
        height: NihilStyle.s(28)
        radius: height / 2
        shadow: 0.5
        NText {
            id: title
            anchors.fill: parent
            anchors.leftMargin: NihilStyle.s(11)
            anchors.rightMargin: NihilStyle.s(11)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            text: root.win.title ?? ""
            font.pixelSize: NihilStyle.textSmall
        }
    }

    NButton {
        id: closeKey
        visible: root.closeShown === "all" || (root.closeShown === "selected" && root.hot)
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: NihilStyle.s(7)
        width: NihilStyle.s(28)
        height: NihilStyle.s(28)
        radius: height / 2
        tone: NihilStyle.scrim
        icon: "close"
        iconSize: NihilStyle.s(14)
        Accessible.name: Translation.tr("Close window")
        onClicked: NiriService.closeWindow(root.win.id)
    }
}
