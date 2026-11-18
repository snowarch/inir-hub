import QtQuick

// A tile of a block that carries a reading: its small line at the top, the rest its own. It answers the hand only when
// `interactive`.
NButton {
    id: root

    property string caption: ""
    readonly property color inkSoft: Qt.alpha(root.ink, 0.62)
    readonly property real pad: NihilStyle.s(14)

    interactive: false
    square: true

    NCaps {
        x: root.pad
        y: root.pad - NihilStyle.s(2)
        width: root.width - root.pad * 2
        visible: root.caption.length > 0
        text: root.caption
        color: root.inkSoft
    }
}
