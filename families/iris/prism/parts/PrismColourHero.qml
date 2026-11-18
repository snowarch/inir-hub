pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Colour's head (his 11-18): the colours iRiS wears as paint chips, the accent leading, each with its role and what it
// is now; a press goes to its group. Beside them the same colours at work: the hour's colon in the highlight, a switch
// and a level in the accent, a live mark in the signal.
Item {
    id: root
    signal pickGroup(string title)

    readonly property real gap: PrismTheme.dp(10)
    readonly property bool narrow: root.width < PrismTheme.dp(640)
    readonly property real chipHeight: PrismTheme.dp(196)
    readonly property real chipsWidth: root.narrow ? root.width : Math.round((root.width - root.gap) * 0.62)
    implicitHeight: root.narrow ? root.chipHeight + root.gap + work.height : root.chipHeight

    readonly property var roles: [
        { group: "Accent", name: "Accent", use: "Switches, levels, the chosen", path: "iris.appearance.accent", share: 1.6, get colour() { return IrisStyle.accent } },
        { group: "Highlight", name: "Highlight", use: "The glanced detail", path: "iris.appearance.highlight", share: 1, get colour() { return IrisStyle.secondaryAccent } },
        { group: "Signal", name: "Signal", use: "Live, urgent, final", path: "iris.appearance.signal", share: 1, get colour() { return IrisStyle.signal } }
    ].filter(role => role.group !== "Highlight" || !IrisStyle.mono)
    readonly property real shares: root.roles.reduce((sum, role) => sum + role.share, 0)

    Row {
        id: chips
        width: root.chipsWidth
        height: root.chipHeight
        spacing: root.gap
        Repeater {
            model: root.roles
            delegate: Rectangle {
                id: chip
                required property var modelData
                readonly property var row: PrismModel.find(chip.modelData.path)
                readonly property string said: { const _ = PrismModel.revision; return chip.row ? PrismModel.sayNow(chip.row) : "" }
                // Ink on the chip from its own lightness: dark on a light colour, white on a deep one.
                readonly property color ink: (0.2126 * chip.color.r + 0.7152 * chip.color.g + 0.0722 * chip.color.b) > 0.56 ? PrismTheme.night : PrismTheme.paper
                width: Math.floor((chips.width - root.gap * (root.roles.length - 1)) * chip.modelData.share / root.shares)
                height: chips.height
                radius: PrismTheme.dp(22)
                color: chip.modelData.colour
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(280); easing.type: Easing.OutCubic } }
                // The pointer shades the chip in its own ink; nothing grows.
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: chip.ink
                    opacity: hit.pressed ? 0.14 : hit.containsMouse ? 0.07 : 0
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                }
                Column {
                    x: PrismTheme.dp(18)
                    y: PrismTheme.dp(16)
                    width: parent.width - PrismTheme.dp(36)
                    spacing: PrismTheme.dp(1)
                    PrismText {
                        width: parent.width
                        text: Translation.tr(chip.modelData.use)
                        color: chip.ink
                        opacity: 0.72
                        font.pixelSize: PrismTheme.small
                        elide: Text.ElideRight
                    }
                }
                Column {
                    x: PrismTheme.dp(18)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: PrismTheme.dp(16)
                    width: parent.width - PrismTheme.dp(36)
                    spacing: PrismTheme.dp(2)
                    PrismText {
                        width: parent.width
                        text: Translation.tr(chip.modelData.name)
                        color: chip.ink
                        font.pixelSize: PrismTheme.head
                        font.weight: Font.Bold
                        font.letterSpacing: -0.2
                        elide: Text.ElideRight
                    }
                    PrismText {
                        width: parent.width
                        visible: chip.said.length > 0
                        text: chip.said
                        color: chip.ink
                        opacity: 0.8
                        font.pixelSize: PrismTheme.body
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: hit
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickGroup(chip.modelData.group)
                }
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr(chip.modelData.name) + ", " + chip.said
            }
        }
    }

    // The colours at work, drawn from the same roles the shell wears.
    Rectangle {
        id: work
        x: root.narrow ? 0 : chips.width + root.gap
        y: root.narrow ? chips.height + root.gap : 0
        width: root.narrow ? root.width : root.width - x
        height: root.narrow ? PrismTheme.dp(168) : root.chipHeight
        radius: PrismTheme.dp(22)
        color: PrismTheme.sunk

        readonly property real padX: PrismTheme.dp(20)
        readonly property var now: DateTime.clock.date

        Row {
            id: hour
            x: work.padX
            y: PrismTheme.dp(14)
            PrismText {
                text: Qt.formatTime(work.now, "hh")
                font.family: IrisStyle.faceFigures
                font.pixelSize: PrismTheme.dp(46)
                font.weight: IrisStyle.figureWeight
                font.letterSpacing: -1
            }
            PrismText {
                text: ":"
                color: IrisStyle.mono ? PrismTheme.ink : IrisStyle.secondaryAccent
                font.family: IrisStyle.faceFigures
                font.pixelSize: PrismTheme.dp(46)
                font.weight: IrisStyle.figureWeight
            }
            PrismText {
                text: Qt.formatTime(work.now, "mm")
                font.family: IrisStyle.faceFigures
                font.pixelSize: PrismTheme.dp(46)
                font.weight: IrisStyle.figureWeight
                font.letterSpacing: -1
            }
        }
        // A live mark in the signal, at the hour's right.
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: work.padX
            anchors.verticalCenter: hour.verticalCenter
            width: liveRow.implicitWidth + PrismTheme.dp(20)
            height: PrismTheme.dp(26)
            radius: height / 2
            color: PrismTheme.fill
            Row {
                id: liveRow
                anchors.centerIn: parent
                spacing: PrismTheme.dp(6)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(8)
                    height: width
                    radius: width / 2
                    color: IrisStyle.signal
                }
                PrismText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Live")
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
            }
        }
        Column {
            x: work.padX
            width: work.width - 2 * work.padX
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(18)
            spacing: PrismTheme.dp(14)
            Item {
                width: parent.width
                height: PrismTheme.dp(24)
                PrismText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Wi-Fi")
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.Medium
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(40)
                    height: PrismTheme.dp(24)
                    radius: height / 2
                    color: IrisStyle.accent
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(3)
                        anchors.verticalCenter: parent.verticalCenter
                        width: PrismTheme.dp(18)
                        height: width
                        radius: width / 2
                        color: PrismTheme.inkAccent
                    }
                }
            }
            Item {
                width: parent.width
                height: PrismTheme.dp(20)
                PrismGlyph {
                    id: speaker
                    anchors.verticalCenter: parent.verticalCenter
                    text: "volume_up"
                    iconSize: PrismTheme.dp(18)
                    color: PrismTheme.ink2
                }
                Rectangle {
                    anchors.left: speaker.right
                    anchors.leftMargin: PrismTheme.dp(10)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: PrismTheme.dp(8)
                    radius: height / 2
                    color: PrismTheme.fill
                    Rectangle {
                        width: parent.width * 0.64
                        height: parent.height
                        radius: parent.radius
                        color: IrisStyle.accent
                    }
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pickGroup("Scheme")
        }
    }
}
