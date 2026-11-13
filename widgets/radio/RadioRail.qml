pragma ComponentBehavior: Bound

import QtQuick
import qs.services

// The tuner's ways in: its name, the places to go and "Surprise me". In the family's own plates, or in Prism's
// grammar the Settings sidebar: a glyph and a bold name, the search pill, places in captioned groups, the open one
// on its accent plate with a mark at the edge, and the main action a solid pill at the foot.
Item {
    id: root

    property var look
    property var sections: []
    property string section: ""
    property bool searching: false
    readonly property real d: root.look?.d ?? 1
    readonly property bool prism: root.look?.grammar === "prism"
    readonly property real inset: Math.round((root.prism ? 20 : 18) * root.d)
    // Where the search field sits when the grammar keeps it in the sidebar.
    readonly property Item searchSlot: slot
    signal went(string id)

    Rectangle {
        anchors.fill: parent
        visible: root.prism
        color: root.look.rail ?? "transparent"
        topLeftRadius: root.look.radius
    }
    Rectangle {
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 1
        color: root.look.line
    }

    Row {
        id: brand
        x: root.inset
        y: Math.round((root.prism ? 22 : 20) * root.d)
        spacing: Math.round((root.prism ? 10 : 8) * root.d)
        RadioGlyph {
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            name: "radio"
            filled: true
            size: Math.round((root.prism ? 22 : 20) * root.d)
            color: root.prism ? root.look.ink : root.look.accent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Radio")
            font.family: root.look.font
            font.pixelSize: root.look.title
            font.weight: Font.Bold
            font.letterSpacing: root.prism ? -0.3 : 0
            color: root.look.ink
        }
    }
    Item {
        id: slot
        anchors { top: brand.bottom; topMargin: root.prism ? Math.round(16 * root.d) : 0; left: parent.left; right: parent.right }
        anchors.leftMargin: Math.round(16 * root.d)
        anchors.rightMargin: Math.round(16 * root.d)
        height: root.prism ? Math.round(34 * root.d) : 0
    }

    Column {
        anchors { top: slot.bottom; topMargin: Math.round((root.prism ? 10 : 16) * root.d); left: parent.left; right: parent.right }
        anchors.leftMargin: root.prism ? root.inset : Math.round(8 * root.d)
        anchors.rightMargin: Math.round((root.prism ? 12 : 8) * root.d)
        spacing: Math.round(2 * root.d)
        Repeater {
            model: root.sections
            delegate: Column {
                id: way
                required property var modelData
                required property int index
                readonly property bool here: root.section === way.modelData.id && !root.searching
                readonly property bool opensGroup: root.prism && (way.index === 0 || root.sections[way.index - 1].group !== way.modelData.group)
                width: parent.width

                Text {
                    visible: way.opensGroup
                    height: Math.round((way.index === 0 ? 24 : 34) * root.d)
                    verticalAlignment: Text.AlignBottom
                    bottomPadding: Math.round(6 * root.d)
                    text: way.modelData.group.toUpperCase()
                    font.family: root.look.font
                    font.pixelSize: root.look.caption ?? root.look.small
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                    color: root.look.faint
                }
                Item {
                    width: parent.width
                    height: Math.round((root.prism ? 30 : 38) * root.d)
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: root.prism ? -Math.round(8 * root.d) : 0
                        radius: root.prism ? Math.round(9 * root.d) : root.look.radiusSmall
                        color: way.here ? (root.prism ? root.look.accentPlate : root.look.selected)
                            : wayMouse.containsMouse ? root.look.hover : "transparent"
                    }
                    // Prism's mark of the open place: a short bar flush with the sidebar's edge.
                    Rectangle {
                        visible: root.prism && way.here
                        x: -root.inset
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(3 * root.d)
                        height: Math.round(18 * root.d)
                        radius: width / 2
                        color: root.look.accent
                    }
                    RadioGlyph {
                        id: wayGlyph
                        x: Math.round((root.prism ? 4 : 12) * root.d)
                        anchors.verticalCenter: parent.verticalCenter
                        look: root.look
                        name: way.modelData.glyph
                        filled: way.here
                        size: Math.round((root.prism ? 16 : 18) * root.d)
                        color: root.prism ? (way.here ? root.look.accentInk : root.look.muted)
                            : way.here ? root.look.accent : root.look.muted
                    }
                    Text {
                        anchors.left: wayGlyph.right
                        anchors.leftMargin: Math.round(12 * root.d)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: way.modelData.label
                        elide: Text.ElideRight
                        font.family: root.look.font
                        font.pixelSize: root.prism ? root.look.meta + 1 : root.look.body
                        font.weight: way.here ? Font.DemiBold : Font.Normal
                        color: root.prism ? (way.here ? root.look.accentInk : root.look.inkNav ?? root.look.ink) : root.look.ink
                    }
                    MouseArea {
                        id: wayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.went(way.modelData.id)
                    }
                }
            }
        }
    }

    // The old radio's gift, kept: a station somewhere playing what the person likes, picked for them.
    readonly property string likes: Radio.genres.length > 0 ? Radio.genres.join(", ") : Translation.tr("Anywhere, any genre")
    Item {
        visible: !root.prism
        anchors { bottom: parent.bottom; bottomMargin: Math.round(14 * root.d); left: parent.left; right: parent.right }
        anchors.leftMargin: Math.round(8 * root.d)
        anchors.rightMargin: Math.round(8 * root.d)
        height: Math.round(52 * root.d)
        Rectangle {
            anchors.fill: parent
            radius: root.look.radiusSmall
            color: luckMouse.pressed ? root.look.press : luckMouse.containsMouse ? root.look.hover : "transparent"
            border.width: 1
            border.color: root.look.line
        }
        RadioGlyph {
            id: luckGlyph
            x: Math.round(12 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            look: root.look
            name: "shuffle"
            size: Math.round(18 * root.d)
            color: root.look.accent
        }
        Column {
            anchors.left: luckGlyph.right
            anchors.leftMargin: Math.round(12 * root.d)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(8 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width
                text: Translation.tr("Surprise me")
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.body
                font.weight: Font.DemiBold
                color: root.look.ink
            }
            Text {
                width: parent.width
                text: root.likes
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.small
                color: root.look.muted
            }
        }
        MouseArea {
            id: luckMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Radio.tune()
        }
    }
    // Prism: what it picks from in a quiet line, then the solid pill.
    Column {
        visible: root.prism
        anchors { bottom: parent.bottom; bottomMargin: Math.round(18 * root.d); left: parent.left; right: parent.right }
        anchors.leftMargin: Math.round(16 * root.d)
        anchors.rightMargin: Math.round(16 * root.d)
        spacing: Math.round(8 * root.d)
        Text {
            width: parent.width
            leftPadding: Math.round(4 * root.d)
            text: root.likes
            elide: Text.ElideRight
            font.family: root.look.font
            font.pixelSize: root.look.small
            color: root.look.faint
        }
        Rectangle {
            width: parent.width
            height: Math.round(34 * root.d)
            radius: height / 2
            color: root.look.solid ?? root.look.accent
            scale: pillMouse.pressed ? 0.97 : 1
            opacity: pillMouse.containsMouse && !pillMouse.pressed ? 0.9 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Row {
                anchors.centerIn: parent
                spacing: Math.round(8 * root.d)
                RadioGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    look: root.look
                    name: "shuffle"
                    size: Math.round(16 * root.d)
                    color: root.look.onSolid ?? root.look.onAccent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Surprise me")
                    font.family: root.look.font
                    font.pixelSize: root.look.meta
                    font.weight: Font.DemiBold
                    color: root.look.onSolid ?? root.look.onAccent
                }
            }
            MouseArea {
                id: pillMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Radio.tune()
            }
        }
    }
}
