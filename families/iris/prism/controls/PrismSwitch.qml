import QtQuick
import qs.services
import qs.modules.iris.prism.core

// The reference's OFF/ON pill: a dark track that names the other state faintly, and a knob that carries the word of
// the state it is in. Off is a white knob, on the person's accent.
Item {
    id: root
    property bool checked: false
    signal toggled(bool value)

    readonly property real pad: PrismTheme.dp(3)
    readonly property real knobWidth: Math.max(PrismTheme.dp(44), Math.max(onMetrics.advanceWidth, offMetrics.advanceWidth) + PrismTheme.dp(20))
    implicitWidth: root.knobWidth * 2 + root.pad * 2
    implicitHeight: PrismTheme.dp(32)

    TextMetrics { id: onMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.caption; font.weight: Font.Bold; text: Translation.tr("On").toUpperCase() }
    TextMetrics { id: offMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.caption; font.weight: Font.Bold; text: Translation.tr("Off").toUpperCase() }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse ? Qt.darker(PrismTheme.sunk, PrismTheme.light ? 1.04 : 0.8) : PrismTheme.sunk
    }
    // The word the knob is not on.
    PrismText {
        x: root.checked ? root.pad : root.width - root.pad - root.knobWidth
        width: root.knobWidth
        height: root.height
        horizontalAlignment: Text.AlignHCenter
        text: (root.checked ? offMetrics.text : onMetrics.text)
        color: PrismTheme.ink3
        font.pixelSize: PrismTheme.caption
        font.weight: Font.Bold
    }
    Rectangle {
        id: knob
        x: root.checked ? root.width - root.pad - width : root.pad
        y: root.pad
        width: root.knobWidth
        height: root.height - root.pad * 2
        radius: height / 2
        color: root.checked ? PrismTheme.accent : PrismTheme.paper
        Behavior on x { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(180) } }
        PrismText {
            anchors.centerIn: parent
            text: root.checked ? onMetrics.text : offMetrics.text
            color: root.checked ? PrismTheme.inkAccent : "#000000" // iris-literal: black on the white knob in every scheme
            font.pixelSize: PrismTheme.caption
            font.weight: Font.Bold
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
