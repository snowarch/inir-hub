pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.shared.mediaControls.components

// Apple's Island when several things live at once (his 11-04 reference 3): each its own tile. What is counted is a
// pill (a recording, a timer, a job, an accessory's charge) with its figure and its one control; the song runs the
// whole width under them with its cover, its time and its transport. One thing alone keeps the full page.
GridLayout {
    id: grid
    required property Item island
    readonly property real d: IrisStyle.density
    readonly property bool nothing: grid.island.nothingLook
    readonly property var jobs: LiveActivities.list.slice().sort((a, b) => b.started - a.started).slice(0, 4)
    readonly property var devices: (Bluetooth.devices?.values ?? []).filter(device => device && device.connected && device.batteryAvailable).slice(0, 2)
    readonly property bool timing: grid.island.timerKind.length > 0
    readonly property int pills: (grid.island.recording ? 1 : 0) + (grid.timing ? 1 : 0) + grid.jobs.length + grid.devices.length
    readonly property int count: grid.pills + (grid.island.hasMedia ? 1 : 0)
    // Worth a grid when two or more live and at least one is the system's own (the page is reached through those).
    readonly property bool useful: grid.count >= 2 && (grid.island.recording || grid.timing || grid.jobs.length > 0)
    readonly property real pillHeight: Math.round(54 * grid.d)

    columns: 2
    columnSpacing: Math.round(8 * grid.d)
    rowSpacing: Math.round(8 * grid.d)

    // A pill: what it is at the start, its words, its figure or control at the end, on one quiet plate.
    component Pill: Rectangle {
        id: pill
        property color tint: IrisStyle.accent
        property alias lead: leadSlot.data
        property alias trail: trailSlot.data
        property string title: ""
        property string meta: ""
        property string figure: ""
        signal tapped()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.columnSpan: 1
        implicitHeight: grid.pillHeight
        radius: IrisStyle.capsule(height)
        color: pillTap.hovered ? IrisStyle.fillHover : IrisStyle.fill
        Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        HoverHandler { id: pillTap; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: pill.tapped() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(8 * grid.d)
            anchors.rightMargin: Math.round(8 * grid.d)
            spacing: Math.round(10 * grid.d)
            Item {
                id: leadSlot
                Layout.preferredWidth: grid.pillHeight - Math.round(16 * grid.d)
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: -Math.round(1 * grid.d)
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: pill.meta
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: pill.title
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
            }
            IrisNumber {
                visible: pill.figure.length > 0
                Layout.alignment: Qt.AlignVCenter
                text: pill.figure
                color: grid.nothing ? IrisStyle.text : pill.tint
                pixelSize: Math.round(IrisStyle.typeHeadline * 1.05)
                weight: IrisStyle.figureWeight
            }
            Item {
                id: trailSlot
                visible: children.length > 0
                Layout.preferredWidth: grid.pillHeight - Math.round(16 * grid.d)
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
    // The round control of a pill: tinted in its activity's colour, as Apple's pause and stop.
    component Round: MouseArea {
        id: round
        property string glyph: ""
        property color tint: IrisStyle.text
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        scale: round.pressed ? IrisStyle.pressScale(0.88) : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(round.pressed ? 80 : 200); easing.type: IrisStyle.feedbackEasing } }
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: grid.nothing ? (round.containsMouse ? IrisStyle.fillActive : IrisStyle.fillHover)
                : round.containsMouse ? IrisStyle.trackOf(round.tint) : IrisStyle.tintFillHover(round.tint)
        }
        Glyph {
            anchors.centerIn: parent
            text: round.glyph
            iconSize: Math.round(parent.width * 0.52)
            color: grid.nothing ? IrisStyle.text : round.tint
        }
    }
    // A ring with its figure inside: a job's share, an accessory's charge.
    component Ring: Item {
        id: ringItem
        property real value: 0
        property color tint: IrisStyle.accent
        property string label: ""
        property bool spinning: false
        anchors.fill: parent
        ProgressRing {
            anchors.fill: parent
            stroke: Math.max(3, 3.5 * grid.d)
            tint: grid.nothing ? IrisStyle.text : ringItem.tint
            progress: ringItem.spinning ? 0.25 : Math.max(0, ringItem.value)
            Behavior on progress { NumberAnimation { duration: IrisStyle.duration(320); easing.type: Easing.OutCubic } }
            RotationAnimation on rotation {
                running: ringItem.spinning && ringItem.visible && IrisStyle.motionEnabled
                from: 0; to: 360; duration: 1200; loops: Animation.Infinite
            }
        }
        Tabular {
            anchors.centerIn: parent
            text: ringItem.label
            color: IrisStyle.text
            font.pixelSize: Math.round(ringItem.height * (ringItem.label.length > 3 ? 0.26 : 0.32))
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }

    Pill {
        visible: grid.island.recording
        tint: IrisStyle.danger
        meta: Translation.tr("Recording")
        figure: grid.island.clockText(RecorderStatus.elapsedSeconds)
        lead: RecordDot { anchors.centerIn: parent; width: Math.round(12 * grid.d); height: width; color: grid.nothing ? IrisStyle.signal : IrisStyle.danger }
        trail: Round {
            glyph: "stop"
            tint: IrisStyle.danger
            Accessible.name: Translation.tr("Stop")
            onClicked: {
                Quickshell.execDetached([Directories.recordScriptPath, "--stop"])
                RecorderStatus.scheduleQuickCheck()
            }
        }
        onTapped: grid.island.page = "activity"
    }
    Pill {
        visible: grid.timing
        tint: IrisStyle.identity.orange
        meta: grid.island.timerLabel
        figure: grid.island.clockText(grid.island.timerSeconds)
        lead: Item {
            anchors.fill: parent
            ProgressRing {
                anchors.fill: parent
                stroke: Math.max(3, 3.5 * grid.d)
                tint: grid.nothing ? IrisStyle.text : IrisStyle.identity.orange
                progress: grid.island.timerKind === "stopwatch" ? 1 : Math.max(0, grid.island.timerProgress)
            }
            Glyph { anchors.centerIn: parent; text: grid.island.timerGlyph; iconSize: Math.round(parent.width * 0.42); color: grid.nothing ? IrisStyle.text : IrisStyle.identity.orange }
        }
        trail: Round {
            glyph: grid.island.timerPaused ? "play_arrow" : "pause"
            tint: IrisStyle.identity.orange
            Accessible.name: grid.island.timerPaused ? Translation.tr("Resume") : Translation.tr("Pause")
            onClicked: {
                if (grid.island.timerKind === "pomodoro") TimerService.togglePomodoro()
                else if (grid.island.timerKind === "countdown") TimerService.toggleCountdown()
                else TimerService.toggleStopwatch()
            }
        }
    }
    Repeater {
        model: grid.jobs
        Pill {
            id: jobPill
            required property var modelData
            readonly property real value: Number(jobPill.modelData.progress ?? -1)
            readonly property bool ended: Boolean(jobPill.modelData.ended)
            tint: Boolean(jobPill.modelData.failed) ? IrisStyle.danger : IrisStyle.identityColor(String(jobPill.modelData.tint ?? "lavender"))
            meta: String(jobPill.modelData.app ?? "") !== String(jobPill.modelData.title ?? "") ? String(jobPill.modelData.app ?? "") : ""
            title: String(jobPill.modelData.title ?? "")
            lead: Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: grid.nothing ? IrisStyle.fill : IrisStyle.tintFill(jobPill.tint)
                Glyph { anchors.centerIn: parent; text: String(jobPill.modelData.glyph ?? "bolt"); iconSize: Math.round(parent.width * 0.5); color: grid.nothing ? IrisStyle.text : jobPill.tint }
            }
            trail: Ring {
                tint: jobPill.tint
                value: jobPill.ended ? 1 : jobPill.value
                spinning: !jobPill.ended && jobPill.value < 0
                label: jobPill.ended ? "" : jobPill.value >= 0 ? grid.island.percentOf(jobPill.modelData) : ""
            }
        }
    }
    Repeater {
        model: grid.devices
        Pill {
            id: devicePill
            required property var modelData
            readonly property real level: Number(devicePill.modelData.battery ?? 0)
            tint: devicePill.level <= 0.2 ? IrisStyle.danger : IrisStyle.success
            meta: Translation.tr("Connected")
            title: String(devicePill.modelData.name ?? "")
            lead: Glyph { anchors.centerIn: parent; text: BluetoothStatus.iconForDevice(devicePill.modelData); iconSize: Math.round(parent.width * 0.86); color: IrisStyle.text }
            trail: Ring { tint: devicePill.tint; value: devicePill.level; label: String(Math.round(devicePill.level * 100)) }
            onTapped: grid.island.openPage("controls", true)
        }
    }
    // An odd number of pills leaves the last one alone on its row: it takes the row, as a wide pill.
    Item {
        visible: grid.pills % 2 === 1
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 0
    }

    // The song: cover, title and artist, the bars in the cover's colour; its time either side of the line; the
    // transport under it. A tap on it opens the player page.
    Rectangle {
        id: song
        visible: grid.island.hasMedia
        Layout.columnSpan: 2
        Layout.fillWidth: true
        implicitHeight: songColumn.implicitHeight + Math.round(24 * grid.d)
        radius: Math.round(22 * grid.d)
        color: songHover.hovered ? IrisStyle.fillHover : IrisStyle.fill
        Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        HoverHandler { id: songHover }
        TapHandler { onTapped: grid.island.page = "media" }
        PlayerBase {
            id: media
            player: grid.island.player
            positionUpdatesActive: song.visible && grid.island.visualExpanded
        }
        readonly property real length: Math.max(0, grid.island.effectiveLength)
        readonly property real position: Math.max(0, Math.min(song.length, grid.island.effectivePosition))
        ColumnLayout {
            id: songColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(12 * grid.d)
            spacing: Math.round(8 * grid.d)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(12 * grid.d)
                IrisArtwork {
                    Layout.preferredWidth: Math.round(52 * grid.d)
                    Layout.preferredHeight: Layout.preferredWidth
                    source: MediaArtwork.displaySource
                    circular: Config.options?.iris?.player?.roundCover ?? false
                    radius: circular ? width / 2 : Math.round(11 * grid.d)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    IrisText {
                        Layout.fillWidth: true
                        text: StringUtils.cleanMusicTitle(grid.island.title)
                        font.pixelSize: IrisStyle.typeBody
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                    IrisText {
                        Layout.fillWidth: true
                        text: grid.island.ytMusic ? YtMusic.currentArtist : String(MprisController.artistOf(grid.island.player) ?? "")
                        color: IrisStyle.textSecondary
                        font.pixelSize: IrisStyle.typeLabel
                        elide: Text.ElideRight
                    }
                }
                IrisVisualizer {
                    Layout.alignment: Qt.AlignVCenter
                    running: song.visible && grid.island.playing && grid.island.visualExpanded
                    tint: grid.nothing ? IrisStyle.text : grid.island.artTint
                    barHeight: Math.round(18 * grid.d)
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: song.length > 0
                spacing: Math.round(8 * grid.d)
                Tabular { text: grid.island.durationText(song.position); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeFootnote }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(5 * grid.d)
                    radius: height / 2
                    color: IrisStyle.trackOf(IrisStyle.text)
                    Rectangle {
                        width: parent.width * (song.length > 0 ? song.position / song.length : 0)
                        height: parent.height
                        radius: parent.radius
                        color: IrisStyle.text
                    }
                }
                Tabular { text: "-" + grid.island.durationText(song.length - song.position); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeFootnote }
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.round(28 * grid.d)
                GlyphButton {
                    glyph: "fast_rewind"
                    glyphSize: 26 * grid.d
                    implicitWidth: 40 * grid.d
                    buttonRadius: height / 2
                    buttonRadiusPressed: buttonRadius
                    enabled: media.effectiveCanGoPrevious
                    Accessible.name: Translation.tr("Previous track")
                    onClicked: media.previous()
                }
                GlyphButton {
                    glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"
                    glyphSize: 32 * grid.d
                    implicitWidth: 44 * grid.d
                    buttonRadius: height / 2
                    buttonRadiusPressed: buttonRadius
                    Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play")
                    onClicked: media.togglePlaying()
                }
                GlyphButton {
                    glyph: "fast_forward"
                    glyphSize: 26 * grid.d
                    implicitWidth: 40 * grid.d
                    buttonRadius: height / 2
                    buttonRadiusPressed: buttonRadius
                    enabled: media.effectiveCanGoNext
                    Accessible.name: Translation.tr("Next track")
                    onClicked: media.next()
                }
            }
        }
    }
}
