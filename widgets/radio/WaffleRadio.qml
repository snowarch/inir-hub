pragma ComponentBehavior: Bound

// The Waffle face: a card in Waffle's Widgets panel, drawn with Looks tokens and W* parts. The station with its logo
// and place, what it plays now, then play, next, its star, the tuner and the volume. It steers the same Radio as the
// other faces; closing the panel keeps the music playing.

import QtQuick
import QtQuick.Layouts
import Quickshell
import org.kde.kirigami as Kirigami
import qs.services
import qs.modules.common.functions
import qs.modules.waffle.looks

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    implicitHeight: content.implicitHeight + Looks.dp(32)

    // Fluent names for the Material ones the tuner asks for; the radio carries these few Fluent glyphs itself.
    readonly property var fluent: ({
        star: "star", search: "search", close: "dismiss", chevron_left: "chevron-left", chevron_right: "chevron-right",
        history: "history", public: "globe", sell: "tag", translate: "local-language", trending_up: "arrow-trending",
        trophy: "trophy", play_arrow: "play", stop: "stop", skip_next: "next", volume_up: "speaker-2",
        volume_off: "speaker-mute", content_copy: "copy", check: "checkmark", travel_explore: "globe-search",
        radio: "music-note-2", error: "warning", shuffle: "arrow-shuffle", explore: "globe-search"
    })
    function fluentSource(name: string, filled: bool): url {
        const file = root.fluent[name] ?? "music-note-2"
        return Qt.resolvedUrl(`fluent/${file}${filled ? "-filled" : ""}.svg`)
    }
    Component {
        id: fluentGlyph
        Kirigami.Icon {
            property string name: ""
            property real size: 20
            property bool filled: false
            implicitWidth: size
            implicitHeight: size
            source: root.fluentSource(name, filled)
            isMask: true
            roundToIconSize: false
        }
    }
    readonly property var tunerLook: ({
        d: Looks.dp(1),
        font: Looks.font.family.ui,
        small: Looks.font.pixelSize.normal,
        meta: Looks.font.pixelSize.large,
        body: Looks.font.pixelSize.larger,
        title: Looks.font.pixelSize.xlarger,
        bg: Looks.colors.bg0,
        raised: Looks.colors.bg2Base,
        track: Looks.colors.controlBg,
        hover: ColorUtils.applyAlpha(Looks.colors.fg, 0.06),
        press: ColorUtils.applyAlpha(Looks.colors.fg, 0.1),
        selected: ColorUtils.applyAlpha(Looks.colors.fg, 0.08),
        ink: Looks.colors.fg,
        muted: Looks.colors.subfg,
        faint: ColorUtils.applyAlpha(Looks.colors.fg, 0.46),
        line: Looks.colors.bg0Border,
        accent: Looks.colors.accent,
        onAccent: Looks.colors.accentFg,
        danger: Looks.colors.danger,
        scrim: ColorUtils.applyAlpha(Looks.colors.bg0, 0.4),
        radius: Looks.radius.large,
        radiusSmall: Looks.radius.medium,
        glyph: fluentGlyph
    })
    function openTuner(): void { Radio.openTuner(root.QsWindow.window?.screen ?? null, root.tunerLook) }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: Looks.dp(16)
        spacing: Looks.dp(12)

        RowLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(12)

            RadioLogo {
                Layout.alignment: Qt.AlignTop
                look: root.tunerLook
                station: Radio.current
                size: Looks.dp(48)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Looks.dp(2)
                WText {
                    Layout.fillWidth: true
                    text: Radio.current ? (Radio.tag.length > 0 ? `${Translation.tr("Radio")} · ${Radio.tag}` : `${Radio.flag} ${Radio.place}`.trim())
                        : Translation.tr("Radio")
                    elide: Text.ElideRight
                    font.pixelSize: Looks.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Looks.colors.subfg
                }
                WText {
                    Layout.fillWidth: true
                    text: Radio.current?.name ?? Translation.tr("Tune in somewhere")
                    elide: Text.ElideRight
                    font.pixelSize: Looks.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openTuner()
                    }
                }
                WText {
                    Layout.fillWidth: true
                    text: Radio.skipped.length > 0 && !Radio.playing ? Translation.tr("%1 didn't answer, moved on").arg(Radio.skipped) : Radio.line
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.pixelSize: Looks.font.pixelSize.normal
                    color: Radio.phase === "failed" ? Looks.colors.danger : Looks.colors.fg1
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Looks.dp(4)

            WBorderlessButton {
                implicitWidth: Looks.dp(40)
                implicitHeight: Looks.dp(40)
                contentItem: FluentIcon {
                    anchors.centerIn: parent
                    icon: Radio.playing || Radio.waiting ? "stop" : "play"
                    filled: true
                    implicitSize: Looks.dp(20)
                }
                onClicked: Radio.playPause()
                Accessible.name: Radio.playing ? Translation.tr("Stop") : Translation.tr("Play")
            }
            WBorderlessButton {
                implicitWidth: Looks.dp(36)
                implicitHeight: Looks.dp(36)
                enabled: !Radio.waiting
                contentItem: FluentIcon { anchors.centerIn: parent; icon: "next"; implicitSize: Looks.dp(18) }
                onClicked: Radio.next()
                Accessible.name: Translation.tr("Next station")
            }
            WBorderlessButton {
                implicitWidth: Looks.dp(36)
                implicitHeight: Looks.dp(36)
                enabled: Radio.current !== null
                contentItem: Kirigami.Icon {
                    anchors.centerIn: parent
                    implicitWidth: Looks.dp(18)
                    implicitHeight: Looks.dp(18)
                    source: root.fluentSource("star", Radio.kept)
                    isMask: true
                    color: Radio.kept ? Looks.colors.accent : Looks.colors.fg
                }
                onClicked: Radio.toggleFavourite(Radio.current)
                Accessible.name: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            }
            WBorderlessButton {
                implicitWidth: Looks.dp(36)
                implicitHeight: Looks.dp(36)
                contentItem: Kirigami.Icon {
                    anchors.centerIn: parent
                    implicitWidth: Looks.dp(18)
                    implicitHeight: Looks.dp(18)
                    source: root.fluentSource("explore", false)
                    isMask: true
                    color: Looks.colors.fg
                }
                onClicked: root.openTuner()
                Accessible.name: Translation.tr("Find a station")
            }
            Item { Layout.fillWidth: true }
            WBorderlessButton {
                implicitWidth: Looks.dp(32)
                implicitHeight: Looks.dp(32)
                contentItem: Kirigami.Icon {
                    anchors.centerIn: parent
                    implicitWidth: Looks.dp(16)
                    implicitHeight: Looks.dp(16)
                    source: root.fluentSource(Radio.muted || Radio.liveVolume === 0 ? "volume_off" : "volume_up", false)
                    isMask: true
                    color: Looks.colors.fg
                }
                onClicked: Radio.toggleMute()
                Accessible.name: Radio.muted ? Translation.tr("Unmute") : Translation.tr("Mute")
            }
            WSlider {
                id: volume
                Layout.preferredWidth: Looks.dp(110)
                from: 0
                to: 1
                scrollable: true
                onMoved: Radio.setVolume(volume.value * 100)
                // The wheel assigns value itself; a Binding outlives that, a plain binding would not.
                Binding { target: volume; property: "value"; value: Radio.muted ? 0 : Radio.liveVolume / 100 }
                Accessible.name: Translation.tr("Volume")
            }
        }
    }
}
