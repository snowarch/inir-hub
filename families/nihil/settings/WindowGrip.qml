import QtQuick

// Empty surface that moves Settings' window when dragged; a double click asks for the whole screen.
Item {
    id: root

    signal maximize()

    DragHandler {
        target: null
        onActiveChanged: if (active) root.Window.window?.startSystemMove()
    }
    TapHandler {
        onDoubleTapped: root.maximize()
    }
}
