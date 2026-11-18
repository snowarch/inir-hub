import QtQuick
import qs.services
import qs.modules.iris.prism.core

// One of a few (B · Carpeta): the names on a dark track, the chosen one on a white thumb that glides there. Past four
// choices or past its room it folds to a value pill, the chosen name and the up and down marks; `open` then asks the
// row to lay the choices out under it, in place.
Item {
    id: root
    property var choices: []
    property var current
    property real room: PrismTheme.dp(360)
    property bool open: false
    // How many choices stand side by side before they fold to a pill.
    property int most: 4
    signal picked(var value)
    signal toggleOpen()

    readonly property var names: root.choices.map(choice => Translation.tr(choice.label))
    readonly property real slotPad: PrismTheme.dp(13)
    readonly property real wanted: {
        let sum = 0
        const _ = metrics.font
        for (const name of root.names) sum += metrics.advanceWidth(name) + root.slotPad * 2
        return sum + PrismTheme.dp(6)
    }
    readonly property bool folded: root.choices.length > root.most || root.wanted > root.room
    readonly property int chosen: root.choices.findIndex(choice => JSON.stringify(choice.value) === JSON.stringify(root.current))

    implicitHeight: PrismTheme.dp(30)
    implicitWidth: root.folded ? foldRow.implicitWidth + PrismTheme.dp(24) : root.wanted

    FontMetrics { id: metrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.small; font.weight: Font.DemiBold }

    Rectangle {
        visible: !root.folded
        anchors.fill: parent
        radius: height / 2
        color: PrismTheme.track
    }
    Rectangle {
        visible: root.folded
        anchors.fill: parent
        radius: height / 2
        color: foldArea.containsMouse || root.open ? PrismTheme.keyHover(PrismTheme.keyQuiet) : PrismTheme.keyQuiet
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
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
            id: thumb
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

    // Folded: the chosen name and the up and down marks.
    Row {
        id: foldRow
        visible: root.folded
        anchors.centerIn: parent
        spacing: PrismTheme.dp(6)
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.chosen >= 0 ? root.names[root.chosen] : String(root.current ?? "")
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
        }
        PrismGlyph {
            anchors.verticalCenter: parent.verticalCenter
            text: root.open ? "unfold_less" : "unfold_more"
            iconSize: PrismTheme.dp(16)
            color: PrismTheme.ink2
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
