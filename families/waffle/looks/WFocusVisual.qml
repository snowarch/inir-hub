import QtQuick
import qs.modules.waffle.looks

// Windows 11's keyboard focus visual (WinUI's system focus, read from microsoft-ui-xaml): a 2 px outer stroke over a
// 1 px inner one, FocusVisualMargin -3 outside the control; white over black in dark, black over white in light. It
// shows only for focus that came from the keyboard (a control's visualFocus): a click never leaves one.
Item {
    id: root
    property bool shown: false
    // The control's own corner radius; the strokes stay concentric with it.
    property real radius: Looks.radius.medium
    // Negative of WinUI's FocusVisualMargin: 3 outside; 0 for items packed edge to edge (navigation, lists).
    property real margin: 3

    visible: root.shown
    z: 10
    x: -root.margin
    y: -root.margin
    width: (parent?.width ?? 0) + 2 * root.margin
    height: (parent?.height ?? 0) + 2 * root.margin

    Rectangle {
        anchors.fill: parent
        radius: root.radius + root.margin
        color: "transparent"
        border.width: 2
        border.color: Looks.dark ? "#ffffff" : Qt.rgba(0, 0, 0, 0.894)
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Math.max(0, root.radius + root.margin - 2)
        color: "transparent"
        border.width: 1
        border.color: Looks.dark ? Qt.rgba(0, 0, 0, 0.702) : Qt.rgba(1, 1, 1, 0.702)
    }
}
