import QtQuick

// A button that opens a menu of choices. options: [{ value, label }]; picked(value) when one is chosen.
Item {
    id: root
    property var options: []
    property var current
    property string symbol: ""
    property string hint: ""
    property string fallback: ""
    signal picked(var value)
    readonly property var chosen: root.options.find(o => o.value === root.current) ?? null
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    InkButton {
        id: button
        label: root.chosen ? root.chosen.label : root.fallback
        symbol: root.symbol
        hint: root.hint
        onClicked: menu.open(button, Qt.point(button.width / 2, button.height))
    }
    InkMenu {
        id: menu
        model: root.options.map(o => ({
            text: o.label,
            iconName: o.value === root.current ? "check" : "",
            monochromeIcon: true,
            action: () => root.picked(o.value)
        }))
    }
}
