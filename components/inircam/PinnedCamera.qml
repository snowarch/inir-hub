import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// One pinned camera: a small floating card on the desktop, draggable and
// resizable. It stays up while the panel is closed.
Item {
    id: root

    required property var pin
    required property var camera
    property size bounds: Qt.size(1920, 1080)
    property bool showChrome: false

    signal moved(string id, real x, real y)
    signal resized(string id, real width)
    signal closed(string id)
    signal opened(string cameraId)
    signal topToggled(string id, bool onTop)

    readonly property bool live: camera !== null
    readonly property real aspect: 9 / 16

    property bool dragging: false
    property bool sizing: false
    property real liveX: Number(pin.x) || 0
    property real liveY: Number(pin.y) || 0
    property real liveWidth: Number(pin.width) || 360

    width: Math.round(liveWidth)
    height: Math.round(liveWidth * aspect)

    onPinChanged: {
        if (!pin || root.dragging || root.sizing) return
        root.liveX = Number(pin.x) || 0
        root.liveY = Number(pin.y) || 0
        root.liveWidth = Number(pin.width) || 360
    }

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: Appearance.colors.colSurfaceContainerHighest
        border.color: root.showChrome
            ? Appearance.colors.colPrimary
            : Appearance.colors.colOutlineVariant
        border.width: 1
        clip: true

        CameraFeed {
            id: feed
            anchors.fill: parent
            camera: root.camera
            quality: "sub"
            muted: true
            active: root.visible
            lowLatency: true
        }

        // The name, over the picture.
        Rectangle {
            anchors { left: parent.left; bottom: parent.bottom; right: parent.right }
            height: 26
            color: Appearance.colors.colLayer0
            opacity: 0.7
            visible: root.showChrome

            StyledText {
                anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                text: root.camera ? (root.camera.name || Translation.tr("Camera")) : ""
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
            }
        }

        // Move the card.
        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.bottomMargin: 22
            anchors.rightMargin: 22
            z: 2
            acceptedButtons: Qt.LeftButton
            cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.ArrowCursor
            property point press: Qt.point(0, 0)
            property point start: Qt.point(0, 0)

            onPressed: mouse => {
                drag.press = drag.mapToItem(null, mouse.x, mouse.y)
                drag.start = Qt.point(root.liveX, root.liveY)
            }
            onPositionChanged: mouse => {
                if (!drag.pressed) return
                const at = drag.mapToItem(null, mouse.x, mouse.y)
                const dx = at.x - drag.press.x
                const dy = at.y - drag.press.y
                if (!root.dragging && Math.abs(dx) + Math.abs(dy) < 5) return
                root.dragging = true
                root.liveX = Math.max(-root.width + 48, Math.min(root.bounds.width - 48, drag.start.x + dx))
                root.liveY = Math.max(0, Math.min(root.bounds.height - 48, drag.start.y + dy))
            }
            onReleased: {
                if (!root.dragging) return
                root.dragging = false
                root.moved(root.pin.id, Math.round(root.liveX), Math.round(root.liveY))
            }
            onDoubleClicked: if (root.camera) root.opened(root.camera.id)
        }

        // Resize from the corner.
        MouseArea {
            id: grip
            width: 22
            height: 22
            anchors { right: parent.right; bottom: parent.bottom }
            z: 3
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            property real pressX: 0
            property real startWidth: 0

            onPressed: mouse => {
                grip.pressX = grip.mapToItem(null, mouse.x, mouse.y).x
                grip.startWidth = root.liveWidth
                root.sizing = true
            }
            onPositionChanged: mouse => {
                if (!grip.pressed) return
                const dx = grip.mapToItem(null, mouse.x, mouse.y).x - grip.pressX
                root.liveWidth = Math.max(220, Math.min(960, grip.startWidth + dx))
            }
            onReleased: {
                root.sizing = false
                root.resized(root.pin.id, Math.round(root.liveWidth))
            }

            Rectangle {
                anchors { right: parent.right; bottom: parent.bottom; margins: 5 }
                width: 10
                height: 10
                radius: Appearance.rounding.verysmall
                color: Appearance.colors.colOnSurfaceVariant
                opacity: root.showChrome ? 0.8 : 0.3
            }
        }

        // The controls, over the picture while the pointer is on the card.
        Row {
            id: actions
            anchors { right: parent.right; top: parent.top; margins: 6 }
            spacing: 4
            visible: root.showChrome

            PinAction {
                icon: "volume_off"
                tip: Translation.tr("Mute")
                onTriggered: feed.muted = !feed.muted
            }
            PinAction {
                icon: root.pin.onTop ? "vertical_align_top" : "vertical_align_bottom"
                tip: root.pin.onTop ? Translation.tr("Keep above the windows") : Translation.tr("Keep on the desktop")
                onTriggered: root.topToggled(root.pin.id, !root.pin.onTop)
            }
            PinAction {
                icon: "open_in_full"
                tip: Translation.tr("Open in the panel")
                onTriggered: if (root.camera) root.opened(root.camera.id)
            }
            PinAction {
                icon: "close"
                tip: Translation.tr("Unpin")
                danger: true
                onTriggered: root.closed(root.pin.id)
            }
        }
    }

    HoverHandler {
        id: hover
        onHoveredChanged: root.showChrome = hover.hovered
    }

    component PinAction: Rectangle {
        id: act
        property string icon: ""
        property string tip: ""
        property bool danger: false
        signal triggered()

        width: 28
        height: 28
        radius: Appearance.rounding.verysmall
        color: actMouse.containsMouse
            ? (act.danger ? Appearance.colors.colError : Appearance.colors.colLayer2Hover)
            : "transparent"

        MaterialSymbol {
            anchors.centerIn: parent
            text: act.icon
            iconSize: Appearance.font.pixelSize.small
            color: act.danger ? Appearance.colors.colError : Appearance.colors.colOnSurface
        }

        MouseArea {
            id: actMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: act.triggered()
        }

        StyledToolTip {
            visible: actMouse.containsMouse && act.tip !== ""
            text: act.tip
        }
    }
}