import QtQuick

// A button that shows the chosen option and lists the others in a menu. options: [{ value, label }].
PrButton {
    id: root
    property var options: []
    property var current
    property string fallback: ""
    signal picked(var value)

    readonly property var chosen: options.find(o => o.value === current) ?? null
    label: chosen ? chosen.label : fallback
    onClicked: {
        list.model = root.options.map(o => ({
            text: o.label,
            iconName: o.value === root.current ? "check" : "",
            action: () => root.picked(o.value)
        }));
        list.open(root, Qt.point(width / 2, height));
    }
    PrMenu { id: list }
}
