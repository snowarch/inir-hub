import QtQuick
import qs.services
import qs.modules.iris.prism.core

// A colour pick in the grammar of Prism's segmented pill: one smoked track, the chosen colour a solid part that says
// its own name, the others discs beside it. A disc under the pointer names itself over the track, inside the row, so
// nothing hangs into the next line and no disc moves (his 11-07 "no dice que carajo es cada chip", 11-11 "rediseño").
// `chart` lays every colour out with its name, wrapped to the width: what a long list (themes) needs to be read.
Item {
    id: root
    property var choices: []      // { label, value, colour }
    property var current
    property real room: PrismTheme.dp(300)
    property bool chart: false
    signal picked(var value)
    property int aimed: -1

    readonly property int chosenIndex: root.choices.findIndex(choice => choice.value === root.current)
    readonly property real pad: PrismTheme.dp(3)
    readonly property real slot: PrismTheme.dp(26)
    readonly property real part: PrismTheme.dp(26)
    // The chosen part takes what the discs leave, so a long name in any language never pushes the track past its room.
    readonly property real nameRoom: Math.max(PrismTheme.dp(40), root.room - root.pad * 2 - Math.max(0, root.choices.length - 1) * root.slot - PrismTheme.dp(24))

    function ink(colour: color): color {
        return (0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b) > 0.6 ? "#000000" : "#ffffff" // iris-literal: a name that reads on any swatch
    }
    // A colour as dark (or as light) as the track it lies on gets a hairline, or it is a hole.
    function faint(colour: color): bool {
        return Math.abs((0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b)
            - (0.299 * PrismTheme.canvas.r + 0.587 * PrismTheme.canvas.g + 0.114 * PrismTheme.canvas.b)) < 0.16
    }

    implicitWidth: root.chart ? root.width : track.width
    implicitHeight: root.chart ? flow.implicitHeight : PrismTheme.dp(32)

    // ── The track.
    Rectangle {
        id: track
        visible: !root.chart
        width: strip.implicitWidth + root.pad * 2
        height: PrismTheme.dp(32)
        radius: height / 2
        color: PrismTheme.fill

        PrismText {
            visible: root.aimed >= 0 && root.aimed !== root.chosenIndex
            y: -height - PrismTheme.dp(1)
            x: {
                const item = root.aimed >= 0 ? strip.children[root.aimed] : null
                return item ? Math.max(0, Math.min(track.width - width, strip.x + item.x + item.width / 2 - width / 2)) : 0
            }
            text: Translation.tr(String(root.choices[root.aimed]?.label ?? ""))
            font.pixelSize: PrismTheme.caption
            font.weight: Font.DemiBold
        }

        Row {
            id: strip
            x: root.pad
            y: root.pad
            Repeater {
                model: root.chart ? [] : root.choices
                delegate: Item {
                    id: swatch
                    required property var modelData
                    required property int index
                    readonly property bool chosen: index === root.chosenIndex
                    readonly property color colour: modelData.colour
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: Translation.tr(String(modelData.label ?? ""))
                    Accessible.checked: swatch.chosen
                    width: swatch.chosen ? Math.min(root.nameRoom, word.implicitWidth) + PrismTheme.dp(24) : root.slot
                    height: root.part
                    Behavior on width { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.centerIn: parent
                        width: swatch.chosen ? parent.width : area.containsMouse ? PrismTheme.dp(22) : PrismTheme.dp(18)
                        height: swatch.chosen ? parent.height : width
                        radius: height / 2
                        color: swatch.colour
                        border.width: root.faint(swatch.colour) ? 1 : 0
                        border.color: Qt.alpha(PrismTheme.ink, 0.2)
                        Behavior on width { enabled: !swatch.chosen; NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                    }
                    PrismText {
                        id: word
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, root.nameRoom)
                        opacity: swatch.chosen ? 1 : 0
                        visible: opacity > 0
                        text: Translation.tr(String(swatch.modelData.label ?? ""))
                        color: root.ink(swatch.colour)
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: if (containsMouse) root.aimed = swatch.index; else if (root.aimed === swatch.index) root.aimed = -1
                        onClicked: root.picked(swatch.modelData.value)
                    }
                }
            }
        }
    }

    // ── The chart: every colour with its name.
    Flow {
        id: flow
        visible: root.chart
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.chart ? root.choices : []
            delegate: Rectangle {
                id: chip
                required property var modelData
                required property int index
                readonly property bool chosen: index === root.chosenIndex
                readonly property color colour: modelData.colour
                Accessible.role: Accessible.RadioButton
                Accessible.name: name.text
                Accessible.checked: chip.chosen
                width: dot.width + name.implicitWidth + PrismTheme.dp(30)
                height: PrismTheme.dp(32)
                radius: height / 2
                color: chip.chosen ? chip.colour : chipArea.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                border.width: chip.chosen && root.faint(chip.colour) ? 1 : 0
                border.color: Qt.alpha(PrismTheme.ink, 0.2)
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                Rectangle {
                    id: dot
                    x: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(16)
                    height: width
                    radius: width / 2
                    color: chip.chosen ? root.ink(chip.colour) : chip.colour
                    border.width: !chip.chosen && root.faint(chip.colour) ? 1 : 0
                    border.color: Qt.alpha(PrismTheme.ink, 0.2)
                    PrismGlyph {
                        anchors.centerIn: parent
                        visible: chip.chosen
                        text: "check"
                        iconSize: PrismTheme.dp(12)
                        color: chip.colour
                    }
                }
                PrismText {
                    id: name
                    anchors.left: dot.right
                    anchors.leftMargin: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr(String(chip.modelData.label ?? ""))
                    color: chip.chosen ? root.ink(chip.colour) : chipArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(chip.modelData.value)
                }
            }
        }
    }
}
