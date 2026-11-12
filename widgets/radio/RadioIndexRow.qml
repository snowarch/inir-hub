pragma ComponentBehavior: Bound

import QtQuick
import "radio.js" as R

// One way in: a country with its flag, a genre or a language, how many stations it has, and a chevron.
Item {
    id: root

    required property var modelData
    property var look
    property string kind: ""           // countries, tags, languages
    readonly property real d: root.look?.d ?? 1
    readonly property bool prism: root.look?.grammar === "prism"
    signal picked(var entry)

    width: ListView.view?.width ?? 0
    height: Math.round(44 * root.d)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Math.round(4 * root.d)
        anchors.rightMargin: Math.round(4 * root.d)
        anchors.topMargin: root.prism ? Math.round(2 * root.d) : 0
        anchors.bottomMargin: root.prism ? Math.round(2 * root.d) : 0
        radius: root.prism ? Math.round(14 * root.d) : root.look.radiusSmall
        color: mouse.pressed ? root.look.press : mouse.containsMouse ? root.look.hover : "transparent"
    }
    Rectangle {
        visible: root.prism && !mouse.containsMouse
        anchors { bottom: parent.bottom; left: lead.right; leftMargin: Math.round(12 * root.d); right: parent.right; rightMargin: Math.round(12 * root.d) }
        height: 1
        color: root.look.line
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.picked(root.modelData)
    }
    Item {
        id: lead
        x: Math.round(14 * root.d)
        width: Math.round(26 * root.d)
        height: parent.height
        Text {
            anchors.centerIn: parent
            visible: root.kind === "countries"
            text: R.flag(root.modelData.key)
            font.pixelSize: root.look.title
        }
        RadioGlyph {
            anchors.centerIn: parent
            visible: root.kind !== "countries"
            look: root.look
            name: root.kind === "tags" ? "sell" : "translate"
            size: Math.round(18 * root.d)
            color: root.look.muted
        }
    }
    Text {
        anchors.left: lead.right
        anchors.leftMargin: Math.round(12 * root.d)
        anchors.right: count.left
        anchors.rightMargin: Math.round(12 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        text: root.modelData.name
        elide: Text.ElideRight
        font.family: root.look.font
        font.pixelSize: root.look.body
        color: root.look.ink
    }
    Text {
        id: count
        anchors.right: chevron.left
        anchors.rightMargin: Math.round(6 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        text: root.modelData.count.toLocaleString(Qt.locale(), "f", 0)
        font.family: root.look.font
        font.pixelSize: root.look.small
        color: root.look.faint
    }
    RadioGlyph {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: Math.round(14 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        name: "chevron_right"
        size: Math.round(18 * root.d)
        color: root.look.faint
    }
}
