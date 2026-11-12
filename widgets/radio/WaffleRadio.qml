pragma ComponentBehavior: Bound

// The Waffle face: a card in Waffle's Widgets panel, drawn with Looks tokens and W* parts. It steers the same Radio
// as the other faces; closing the panel keeps the music playing.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.waffle.looks

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    readonly property bool playing: Radio.phase === "playing"
    readonly property bool waiting: Radio.phase === "searching" || Radio.phase === "tuning"

    implicitHeight: content.implicitHeight + Looks.dp(32)

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Looks.dp(16)
        spacing: Looks.dp(12)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(2)

            WText {
                Layout.fillWidth: true
                text: Radio.current ? `Radio · ${Radio.tag}` : "Radio"
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.normal
                font.weight: Font.Medium
                color: Looks.colors.subfg
            }
            WText {
                Layout.fillWidth: true
                text: Radio.current?.name ?? "Tune in somewhere"
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.larger
                font.weight: Font.DemiBold
            }
            WText {
                Layout.fillWidth: true
                visible: Radio.current !== null
                text: `${Radio.flag} ${Radio.place}`.trim()
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.fg1
            }
            WText {
                Layout.fillWidth: true
                text: Radio.line
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.small
                color: Radio.phase === "failed" ? Looks.colors.danger : Looks.colors.fg1
            }
        }

        WBorderlessButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Looks.dp(48)
            implicitHeight: Looks.dp(48)
            contentItem: FluentIcon {
                anchors.centerIn: parent
                icon: root.playing ? "stop" : "play"
                implicitSize: Looks.dp(24)
            }
            onClicked: Radio.playPause()
            Accessible.name: root.playing ? "Stop" : "Play"
        }
        WBorderlessButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Looks.dp(40)
            implicitHeight: Looks.dp(40)
            enabled: !root.waiting
            contentItem: FluentIcon { anchors.centerIn: parent; icon: "next"; implicitSize: Looks.dp(18) }
            onClicked: Radio.next()
            Accessible.name: "Next station"
        }
    }
}
