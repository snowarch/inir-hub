import QtQuick

// A level the hand sets: a raised pill filled from its start (bottom when `vertical`) to `value`, its figure printed
// on it. Brightness fills in ink, volume in the signal, as the reference's two columns do.
Rectangle {
    id: root

    property real value: 0
    property bool vertical: true
    property color fill: NihilStyle.litLevel
    property color fillInk: NihilStyle.onLitLevel
    property string label: Math.round(root.value * 100) + "%"
    property string icon: ""
    // A chevron at the far end that leads to the level's list (the sound devices); a tap there opens it.
    property bool opens: false
    signal moved(real value)
    signal opened()

    radius: NihilStyle.rowRadius
    color: NihilStyle.pieceRaised
    clip: true

    readonly property real _v: Math.max(0, Math.min(1, root.value))
    Rectangle {
        id: bar
        color: root.fill
        radius: root.radius
        width: root.vertical ? root.width : Math.max(root.radius * 2 * (root._v > 0 ? 1 : 0), root.width * root._v)
        height: root.vertical ? Math.max(root.radius * 2 * (root._v > 0 ? 1 : 0), root.height * root._v) : root.height
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        Behavior on height { enabled: !drag.pressed; NumberAnimation { duration: NihilStyle.quick } }
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: NihilStyle.quick } }
    }

    // Figure (and glyph) at the start end: on the fill once the fill reaches it.
    readonly property bool _onFill: root.vertical ? bar.height > root.height * 0.24 : bar.width > figure.x + figure.width
    Column {
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        anchors.bottom: root.vertical ? parent.bottom : undefined
        anchors.bottomMargin: NihilStyle.s(10)
        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
        x: root.vertical ? 0 : NihilStyle.s(16)
        spacing: NihilStyle.s(4)
        NIcon {
            visible: root.icon.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            size: NihilStyle.s(18)
            color: root._onFill ? root.fillInk : NihilStyle.ink
        }
        NText {
            id: figure
            figures: true
            text: root.label
            font.pixelSize: NihilStyle.textSmall
            color: root._onFill ? root.fillInk : NihilStyle.ink
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(mx: real, my: real): void {
            const v = root.vertical ? 1 - my / root.height : mx / root.width
            root.moved(Math.max(0, Math.min(1, v)))
        }
        onPressed: event => drag.set(event.x, event.y)
        onPositionChanged: event => { if (drag.pressed) drag.set(event.x, event.y) }
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }

    Item {
        visible: root.opens
        width: root.vertical ? root.width : NihilStyle.s(34)
        height: root.vertical ? NihilStyle.s(34) : root.height
        anchors.top: parent.top
        anchors.right: parent.right
        NIcon {
            anchors.centerIn: parent
            text: root.vertical ? "expand_less" : "chevron_right"
            size: NihilStyle.s(18)
            color: root._v > 0.9 ? root.fillInk : NihilStyle.inkSoft
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened()
        }
    }
}
