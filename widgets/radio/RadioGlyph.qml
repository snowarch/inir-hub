pragma ComponentBehavior: Bound

import QtQuick

// A glyph in the family of the face that opened the tuner: `look.glyph` is that family's icon, named with Material
// Symbols' names (Waffle maps them to Fluent ones).
Item {
    id: root

    property var look
    property string name: ""
    property real size: 20
    property color color: root.look?.ink ?? "white" // literal: only while the look is still arriving
    property bool filled: false

    implicitWidth: root.size
    implicitHeight: root.size

    Loader {
        id: face
        anchors.centerIn: parent
        sourceComponent: root.look?.glyph ?? null
    }
    Binding { target: face.item; property: "name"; value: root.name; when: face.item !== null }
    Binding { target: face.item; property: "size"; value: root.size; when: face.item !== null }
    Binding { target: face.item; property: "color"; value: root.color; when: face.item !== null }
    Binding { target: face.item; property: "filled"; value: root.filled; when: face.item !== null }
}
