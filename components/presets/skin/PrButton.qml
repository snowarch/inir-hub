import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets

// A rounded button with an optional icon and label. primary fills it with the accent; toggled marks the chosen one.
Rectangle {
    id: root
    property string label: ""
    property string symbol: ""
    property string hint: ""
    property bool primary: false
    property bool toggled: false
    property bool quiet: false
    property bool danger: false
    signal clicked()

    readonly property color ink: primary ? PrSkin.onAccent : danger ? PrSkin.danger : toggled ? PrSkin.rowOnInk : PrSkin.text
    readonly property color rest: primary ? PrSkin.accent : toggled ? PrSkin.rowOn : quiet ? "transparent" : PrSkin.plate

    implicitHeight: PrSkin.control
    implicitWidth: Math.max(implicitHeight, content.implicitWidth + PrSkin.gap * 2)
    radius: PrSkin.radius
    color: area.containsMouse && !primary && !toggled ? PrSkin.hover : rest
    opacity: enabled ? 1 : 0.4
    scale: area.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
    Accessible.role: Accessible.Button
    Accessible.name: label || hint

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: PrSkin.small
        PrGlyph { visible: root.symbol !== ""; name: root.symbol; color: root.ink }
        PrText { visible: root.label !== ""; text: root.label; color: root.ink; elide: Text.ElideNone }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
    StyledToolTip { text: root.hint; extraVisibleCondition: area.containsMouse && root.hint !== "" }
}
