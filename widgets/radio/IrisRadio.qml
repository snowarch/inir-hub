pragma ComponentBehavior: Bound

// The iRiS face: one line on the Island's Desktop page. Play, the station with its logo and where it is, what it
// plays now, its star, the tuner and next; the wheel over the line sets the volume. It steers the same Radio as the
// desktop card; closing the Island keeps the music playing.

import QtQuick
import Quickshell
import qs.services
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    // Given by the Island: where the module sits and which screen it is on.
    property string irisSlot: ""
    property var targetScreen

    readonly property real d: IrisStyle.density
    property bool turning: false
    Timer { id: turned; interval: 1400; onTriggered: root.turning = false }

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(32 * root.d)

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            Radio.nudgeVolume(event.angleDelta.y > 0 ? 1 : event.angleDelta.y < 0 ? -1 : 0)
            root.turning = true
            turned.restart()
        }
    }

    // The tuner in iRiS's own colours, type and corners.
    readonly property var tunerLook: ({
        d: root.d,
        font: IrisStyle.fontMain,
        small: IrisStyle.typeFootnote,
        meta: IrisStyle.typeMeta,
        body: IrisStyle.typeBody,
        title: IrisStyle.typeTitle,
        bg: IrisStyle.surfaceHighOpaque,
        raised: IrisStyle.fill,
        hover: IrisStyle.fillHover,
        press: IrisStyle.fillActive,
        selected: IrisStyle.fill,
        ink: IrisStyle.text,
        muted: IrisStyle.textSecondary,
        faint: IrisStyle.textTertiary,
        line: IrisStyle.hairline,
        accent: IrisStyle.accent,
        onAccent: IrisStyle.inkOnAccent,
        danger: IrisStyle.danger,
        scrim: ColorUtils.applyAlpha(IrisStyle.scrim, 0.32),
        radius: IrisStyle.radiusSheet,
        radiusSmall: IrisStyle.radiusRow,
        glyph: irisGlyph
    })
    Component {
        id: irisGlyph
        MaterialSymbol {
            property string name: ""
            property real size: 20
            property bool filled: false
            text: name
            iconSize: size
            fill: filled ? 1 : 0
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * root.d)

        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.round(28 * root.d)
            materialIcon: Radio.playing ? "stop" : Radio.waiting ? "more_horiz" : "play_arrow"
            selected: Radio.playing
            onClicked: Radio.playPause()
            Accessible.name: Radio.playing ? Translation.tr("Stop") : Translation.tr("Play")
        }
        RadioLogo {
            anchors.verticalCenter: parent.verticalCenter
            visible: Radio.current !== null
            look: root.tunerLook
            station: Radio.current
            size: Math.round(24 * root.d)
        }
        IrisText {
            id: stationName
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.round(170 * root.d))
            role: IrisText.Label
            elide: Text.ElideRight
            text: Radio.current ? Radio.current.name : Translation.tr("Radio")
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Radio.openTuner(root.targetScreen, root.tunerLook)
            }
        }
        IrisText {
            anchors.baseline: stationName.baseline
            width: Math.min(implicitWidth, Math.round(210 * root.d))
            role: IrisText.Meta
            elide: Text.ElideRight
            color: Radio.phase === "failed" ? IrisStyle.danger : IrisStyle.textSecondary
            text: root.turning ? (Radio.muted ? Translation.tr("Muted") : Translation.tr("Volume %1 %").arg(Math.round(Radio.liveVolume)))
                : Radio.current && Radio.playing && Radio.onAir.length === 0 ? `${Radio.flag} ${Radio.place}`.trim()
                : Radio.line
        }
        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            visible: Radio.current !== null
            implicitWidth: Math.round(28 * root.d)
            materialIcon: "star"
            selected: Radio.kept
            onClicked: Radio.toggleFavourite(Radio.current)
            Accessible.name: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
        }
        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.round(28 * root.d)
            materialIcon: "explore"
            selected: Radio.tunerOpen
            onClicked: Radio.openTuner(root.targetScreen, root.tunerLook)
            Accessible.name: Translation.tr("Find a station")
        }
        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.round(28 * root.d)
            materialIcon: "skip_next"
            enabled: !Radio.waiting
            opacity: enabled ? 1 : 0.4
            onClicked: Radio.next()
            Accessible.name: Translation.tr("Next station")
        }
    }
}
