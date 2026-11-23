pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

// A one-line text field in the family's own field.
Loader {
    id: root
    property string text: ""
    property string placeholder: ""
    signal accepted()
    readonly property bool focused: root.item ? root.item.activeFocus : false
    function focusField(): void { if (root.item) root.item.forceActiveFocus() }
    function selectAll(): void { if (root.item) root.item.selectAll() }
    active: visible
    sourceComponent: InkSkin.iris ? irisField : InkSkin.waffle ? waffleField : materialField

    Binding { target: root.item; property: "text"; value: root.text; when: root.item !== null }
    Binding { target: root.item; property: "placeholderText"; value: root.placeholder; when: root.item !== null }
    Connections {
        target: root.item
        function onTextChanged(): void { root.text = root.item.text }
        function onAccepted(): void { root.accepted() }
    }
    Component { id: irisField; IrisField {} }
    Component { id: waffleField; WTextField {} }
    Component { id: materialField; MaterialTextField {} }
}
