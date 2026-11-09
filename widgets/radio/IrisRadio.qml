pragma ComponentBehavior: Bound

// The iRiS face: one line on the Island's Desktop page. Play, the station and where it is, what it plays now, next.
// It steers the same Radio as the desktop card; closing the Island keeps the music playing.

import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    // Given by the Island: where the module sits and which screen it is on.
    property string irisSlot: ""
    property var targetScreen

    readonly property real d: IrisStyle.density
    readonly property bool playing: Radio.phase === "playing"
    readonly property bool waiting: Radio.phase === "searching" || Radio.phase === "tuning"

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * root.d)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * root.d)

        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.round(28 * root.d)
            materialIcon: root.playing ? "pause" : root.waiting ? "more_horiz" : "play_arrow"
            selected: root.playing
            onClicked: Radio.playPause()
            Accessible.name: root.playing ? "Stop" : "Play"
        }
        IrisText {
            id: name
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.round(180 * root.d))
            role: IrisText.Label
            elide: Text.ElideRight
            text: Radio.current ? `${Radio.flag} ${Radio.current.name}`.trim() : "Radio"
        }
        IrisText {
            anchors.baseline: name.baseline
            width: Math.min(implicitWidth, Math.round(220 * root.d))
            role: IrisText.Meta
            elide: Text.ElideRight
            color: Radio.phase === "failed" ? IrisStyle.danger : IrisStyle.textSecondary
            text: Radio.current && root.playing && Radio.onAir.length === 0 ? Radio.place : Radio.line
        }
        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.round(28 * root.d)
            materialIcon: "skip_next"
            enabled: !root.waiting
            opacity: enabled ? 1 : 0.4
            onClicked: Radio.next()
            Accessible.name: "Next station"
        }
    }
}
