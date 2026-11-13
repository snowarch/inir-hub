import QtQuick
import qs.services
import qs.modules.iris.prism.core

// One of a few: a segmented pill whose chosen part is the solid white of the reference. Past four choices or past its
// room it folds to the chosen name and a chevron; `open` then asks the row to lay the chips out under it, in place.
Item {
    id: root
    property var choices: []
    property var current
    property real room: PrismTheme.dp(360)
    property bool open: false
    signal picked(var value)
    signal toggleOpen()

    readonly property var names: root.choices.map(choice => Translation.tr(choice.label))
    readonly property real slotPad: PrismTheme.dp(14)
    readonly property real wanted: {
        let sum = 0
        const _ = metrics.font
        for (const name of root.names) sum += metrics.advanceWidth(name) + root.slotPad * 2
        return sum + PrismTheme.dp(6)
    }
    readonly property bool folded: root.choices.length > 4 || root.wanted > root.room
    readonly property int chosen: root.choices.findIndex(choice => JSON.stringify(choice.value) === JSON.stringify(root.current))

    implicitHeight: PrismTheme.dp(32)
    implicitWidth: root.folded ? foldRow.implicitWidth + PrismTheme.dp(26) : root.wanted

    FontMetrics { id: metrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.small; font.weight: Font.DemiBold }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.folded && foldArea.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
    }

    // Unfolded: the segments, a white thumb sliding under the chosen one.
    Item {
        id: segments
        visible: !root.folded
        anchors.fill: parent
        anchors.margins: PrismTheme.dp(3)
        readonly property var widths: root.names.map(name => metrics.font && metrics.advanceWidth(name) + root.slotPad * 2)
        readonly property var starts: { let at = 0; return widths.map(w => { const s = at; at += w; return s }) }
        readonly property real scaleX: widths.length > 0 ? width / widths.reduce((a, b) => a + b, 0) : 1
        Rectangle {
            visible: root.chosen >= 0
            x: (segments.starts[root.chosen] ?? 0) * segments.scaleX
            width: (segments.widths[root.chosen] ?? 0) * segments.scaleX
            height: parent.height
            radius: height / 2
            color: PrismTheme.solid
            Behavior on x { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
        }
        Repeater {
            model: root.names
            delegate: Item {
                required property int index
                required property string modelData
                x: segments.starts[index] * segments.scaleX
                width: segments.widths[index] * segments.scaleX
                height: segments.height
                PrismText {
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                    color: parent.index === root.chosen ? PrismTheme.inkSolid : segArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                }
                MouseArea {
                    id: segArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(root.choices[parent.index].value)
                }
            }
        }
    }

    // Folded: the chosen name and a chevron that turns when the chips are out.
    Row {
        id: foldRow
        visible: root.folded
        anchors.centerIn: parent
        spacing: PrismTheme.dp(4)
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.chosen >= 0 ? root.names[root.chosen] : String(root.current ?? "")
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
        }
        PrismGlyph {
            anchors.verticalCenter: parent.verticalCenter
            text: "expand_more"
            iconSize: PrismTheme.dp(18)
            color: PrismTheme.ink2
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        }
    }
    MouseArea {
        id: foldArea
        visible: root.folded
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleOpen()
    }
}
