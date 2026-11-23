pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.waffle.looks

// An icon by its Material Symbols name; Waffle draws the Fluent one when its set has it.
Item {
    id: root
    property string name: ""
    property color color: InkSkin.text
    property real size: InkSkin.iconSize
    readonly property string fluent: InkSkin.waffle ? InkSkin.fluentName(root.name) : ""
    implicitWidth: root.size
    implicitHeight: root.size

    Loader { anchors.centerIn: parent; active: root.name !== ""; sourceComponent: root.fluent !== "" ? fluentIcon : symbol }
    Component {
        id: fluentIcon
        FluentIcon { icon: root.fluent; implicitSize: root.size; color: root.color }
    }
    Component {
        id: symbol
        MaterialSymbol { text: root.name; iconSize: root.size; color: root.color; fill: 0 }
    }
}
