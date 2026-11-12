pragma ComponentBehavior: Bound

// The iRiS face, on the Island's Desktop page, drawn in the grammar of the Island's player page: the station's logo
// as the cover, its name large over where it is and what it plays, the live bars; the volume where the player has
// its timeline; then the controls on soft discs, play the largest, the star and the tuner bare at the ends. It
// steers the same Radio as the desktop card; closing the Island keeps the music playing.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    // Given by the Island: where the module sits, which screen it is on and the width of its row.
    property string irisSlot: ""
    property var targetScreen
    property real availableWidth: 0

    readonly property real d: IrisStyle.density
    readonly property real coverSide: Math.round(Math.min(root.width * 0.23, 92 * root.d))

    implicitWidth: root.availableWidth > 0 ? root.availableWidth : Math.round(400 * root.d)
    implicitHeight: content.implicitHeight + 2 * Math.round(10 * root.d)

    // The tuner in Prism's grammar, the look of iRiS Settings (IrisLook.qml).
    IrisLook { id: irisLook }
    readonly property var tunerLook: irisLook.look
    onTunerLookChanged: Radio.offerLook("iris", root.tunerLook)
    Component.onCompleted: Radio.offerLook("iris", root.tunerLook)
    function openTuner(): void { Radio.openTuner(root.targetScreen, root.tunerLook) }

    // A control on a soft disc, as the player page's: the lead the largest and most lit, the ends bare until hovered.
    component Disc: IrisButton {
        id: disc
        property string glyph: ""
        property bool lead: false
        property bool side: false
        property bool on: false
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Math.round((disc.lead ? 54 : disc.side ? 38 : 44) * root.d)
        implicitHeight: implicitWidth
        colBackground: disc.side ? "transparent" : disc.lead ? IrisStyle.fillHover : IrisStyle.fillQuiet
        colBackgroundHover: IrisStyle.fillActive
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        opacity: disc.enabled ? 1 : 0.4
        MaterialSymbol {
            anchors.centerIn: parent
            text: disc.glyph
            iconSize: (disc.lead ? 30 : disc.side ? 21 : 25) * root.d
            fill: disc.on || disc.lead ? 1 : 0
            color: disc.on ? IrisStyle.accent : disc.side ? IrisStyle.textSecondary : IrisStyle.text
        }
    }

    ColumnLayout {
        id: content
        x: Math.round(10 * root.d)
        y: Math.round(10 * root.d)
        width: root.width - 2 * x
        spacing: Math.round(10 * root.d)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(14 * root.d)

            // The station's logo is the cover; a tap opens the tuner.
            RadioLogo {
                Layout.alignment: Qt.AlignVCenter
                look: root.tunerLook
                station: Radio.current
                size: root.coverSide
                radius: Math.round(root.coverSide * 0.17)
                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: root.openTuner()
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Math.round(3 * root.d) // iris-literal: title and lines sit tight, as the player page
                IrisText {
                    Layout.fillWidth: true
                    role: IrisText.Meta
                    color: IrisStyle.textTertiary
                    elide: Text.ElideRight
                    text: !Radio.current ? Translation.tr("Radio")
                        : Radio.tag.length > 0 ? `${Translation.tr("Radio")} · ${Radio.tag}`
                        : `${Radio.flag} ${Radio.place}`.trim()
                }
                IrisMarquee {
                    Layout.fillWidth: true
                    text: Radio.current?.name ?? Translation.tr("Tune in somewhere")
                    pixelSize: IrisStyle.typeTitle
                    weight: Font.Bold
                    running: root.visible && Radio.playing
                }
                IrisMarquee {
                    Layout.fillWidth: true
                    text: Radio.skipped.length > 0 && !Radio.playing ? Translation.tr("%1 didn't answer, moved on").arg(Radio.skipped)
                        : Radio.line
                    color: Radio.phase === "failed" ? IrisStyle.danger : IrisStyle.textSecondary
                    pixelSize: IrisStyle.typeHeadline
                    running: root.visible && Radio.playing
                }
                IrisVisualizer {
                    Layout.topMargin: Math.round(4 * root.d)
                    visible: Radio.current !== null
                    running: root.visible && Radio.playing
                    tint: IrisStyle.visualizerTint(IrisStyle.accent)
                    barHeight: 11 * root.d
                }
            }
        }

        // The volume sits where the player page has its timeline: a live stream has no time to scrub.
        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(12 * root.d)
            IrisButton {
                quiet: true
                implicitWidth: Math.round(30 * root.d)
                implicitHeight: implicitWidth
                buttonRadius: height / 2
                buttonRadiusPressed: height / 2
                onClicked: Radio.toggleMute()
                Accessible.name: Radio.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Radio.muted || Radio.liveVolume === 0 ? "volume_off" : Radio.liveVolume < 50 ? "volume_down" : "volume_up"
                    iconSize: 18 * root.d
                    color: IrisStyle.textSecondary
                }
            }
            IrisScrubber {
                id: volume
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                thickness: 6
                engagedThickness: 10
                knob: true
                value: Radio.muted ? 0 : Radio.liveVolume / 100
                fillColor: IrisStyle.text
                trackColor: IrisStyle.fillHover
                onMoved: next => Radio.setVolume(next * 100)
                Accessible.name: Translation.tr("Volume")
            }
            IrisText {
                Layout.minimumWidth: Math.round(30 * root.d)
                horizontalAlignment: Text.AlignRight
                role: IrisText.Meta
                color: IrisStyle.textSecondary
                font.features: { "tnum": 1 }
                text: Radio.muted ? "0" : String(Math.round(Radio.liveVolume))
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(12 * root.d)
            Disc {
                side: true
                glyph: "star"
                on: Radio.kept
                enabled: Radio.current !== null
                onClicked: Radio.toggleFavourite(Radio.current)
                Accessible.name: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            }
            Disc {
                glyph: "skip_previous"
                enabled: !Radio.waiting && Radio.index > 0
                onClicked: Radio.playAt(Radio.index - 1)
                Accessible.name: Translation.tr("Previous station")
            }
            Disc {
                lead: true
                glyph: Radio.playing || Radio.waiting ? "stop" : "play_arrow"
                onClicked: Radio.playPause()
                Accessible.name: Radio.playing ? Translation.tr("Stop") : Translation.tr("Play")
            }
            Disc {
                glyph: "skip_next"
                enabled: !Radio.waiting
                onClicked: Radio.next()
                Accessible.name: Translation.tr("Next station")
            }
            Disc {
                side: true
                glyph: "explore"
                on: Radio.tunerOpen
                onClicked: root.openTuner()
                Accessible.name: Translation.tr("Find a station")
            }
        }
    }
}
