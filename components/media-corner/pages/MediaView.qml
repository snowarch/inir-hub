pragma ComponentBehavior: Bound
import QtQuick
import "../state"

// Only one presentation exists at a time; the state and catalogue code remain shared.
Item {
    id: root
    property bool windowed: false
    readonly property Item frame: view.item ? view.item.frame : null
    Loader {
        id: view
        anchors.fill: parent
        sourceComponent: CornerState.options.style === "prism" ? prismView : normalView
    }
    Component { id: normalView; MediaCorner { windowed: root.windowed; prism: false } }
    Component { id: prismView; MediaCorner { windowed: root.windowed; prism: true } }
}
