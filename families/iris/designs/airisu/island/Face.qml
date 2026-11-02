pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.bar.island
import qs.modules.iris.edit
import "../components"

// AIRISU's Island face. The engine (IrisIsland) decides the mode, the events, the levels, the clock style and the size;
// this lacquers the strip in the pigment of what it is showing and sets the one thing it says as type cut out of the
// lacquer. Only a notice and a recording lacquer the strip (the caution's yamabuki for a warning); at rest it is the body
// with the time cut in its ink, leaning like a livery number. Whatever runs (the hour, the song, the timer, a task, a
// level) is the second coat, its 45° edge travelling across the strip; a change of subject repaints the strip along the
// same cut instead of fading.
// At rest the day is a seal (印, his pick A "Hanko" of 11-02): the weekday's kanji over the date, stamped in the seal's
// pigment beside the leaning hour, the weather as ruby after it. The blade and the minute hairline left (his 11-02: "la
// diagonal y la línea de abajo no"). A notice, a level and a recording take the whole strip: those must be seen from
// across the room.
Item {
    id: root
    property var island: null
    readonly property real d: Airisu.d
    readonly property string mode: root.island?.compactMode ?? "idle"
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real pad: Math.round(14 * root.d)
    // What the engine sizes the strip from: the current mode's own content, without the strip's breathing.
    readonly property real contentWidth: (root.rows[root.mode]?.implicitWidth ?? 0) + 2 * root.pad - Math.round(29 * root.d)
    readonly property var rows: ({ idle: idle, clock: idle, media: media, record: record, timer: timer, task: task,
        event: event, feedback: level })
    readonly property real figure: Math.round(IrisStyle.typeHeadline * (root.island?.clockScale ?? 1))
    // A strip tall enough stacks a second line under the first; a slim one keeps everything on one line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)

    // ── What the strip is lacquered with, mode by mode.
    readonly property color eventTint: root.island?.event?.tint ?? IrisStyle.accentFill
    readonly property bool eventCaution: Qt.colorEqual(root.eventTint, IrisStyle.danger) || Qt.colorEqual(root.eventTint, IrisStyle.warning)
    readonly property string levelIcon: String(root.island?.feedbackIcon ?? "volume_up")
    readonly property color levelPigment: root.levelIcon.indexOf("bright") >= 0 || root.levelIcon.indexOf("light") >= 0
        ? Airisu.pigment("display") : root.levelIcon.indexOf("mic") >= 0 ? Airisu.pigment("time")
        : root.levelIcon.indexOf("volume") >= 0 || root.levelIcon.indexOf("speaker") >= 0 ? Airisu.pigment("music")
        : Airisu.pigment("system")
    readonly property color pigment: {
        switch (root.mode) {
        case "media": return Airisu.pigment("music")
        case "record": return Airisu.pigment("live")
        case "timer": return Airisu.pigment("time")
        case "task": return Airisu.pigment("rest")
        case "event": return Airisu.pigment("rest")
        case "feedback": return root.island?.feedbackMuted ? Airisu.pigment("system") : root.levelPigment
        default: return Airisu.pigment("time")
        }
    }
    // The strip is the body itself: only a notice and a recording lacquer it, the one thing that must be seen from across
    // the room. A warning or a danger is the same notice with a band of yamabuki along its foot.
    readonly property bool taped: root.mode === "event" && root.eventCaution
    readonly property color surface: root.mode === "event" || root.mode === "record" ? Airisu.coat(root.pigment) : "transparent"
    readonly property bool barLevel: root.mode === "feedback" && root.levelStyle === "bar"
    // A level fills the strip as a meter does; anything else that runs is a band of shu along its foot.
    readonly property bool fills: root.mode === "feedback" && !root.barLevel
    readonly property color coatColour: root.taped ? Airisu.tape : root.fills ? Airisu.levelCoat(root.pigment, root.seenLacquer) : Airisu.vivid(root.pigment)
    // The lacquer as the eye sees it under a level: on glass it is the body's tint over the wallpaper behind the strip
    // (the computed solid rung read 1.35:1 off a coat that showed 1.05:1 over a red wallpaper).
    readonly property color seenLacquer: {
        void Lume.revision
        if (!root.fills) return Airisu.solid(root.surface)
        if (root.surface.a > 0.99 || !IrisStyle.glassy) return Airisu.solid(root.surface)
        const p = root.mapToItem(null, 0, 0)
        const sample = Lume.read(String(root.island?.targetScreen?.name ?? ""), p.x, p.y, Math.max(1, root.width), Math.max(1, root.height))
        return sample ? Lume.stack(sample.color, IrisStyle.bodyTint) : Airisu.solid(root.surface)
    }
    // Type over a coat that runs the whole height takes the ink that reads on both coats.
    readonly property color ink: root.run > 0 && root.fills ? Airisu.inkOver(root.surface, root.coatColour) : Airisu.inkOn(root.surface)
    readonly property color inkSecond: ColorUtils.mix(root.ink, root.surface, 0.74) // iris-literal: second tone on lacquer
    readonly property color inkThird: ColorUtils.mix(root.ink, root.surface, 0.52)  // iris-literal: third tone on lacquer

    // What runs, as the second coat: how far, and whether it is moving now.
    readonly property string levelStyle: root.island?.levelStyle ?? "capsule"
    readonly property bool resting: root.mode === "idle" || root.mode === "clock"
    readonly property real run: root.resting ? 0
        : root.mode === "media" ? (root.island?.trackProgress ?? 0)
        : root.mode === "timer" ? (root.island?.timerProgress ?? 0)
        : root.mode === "task" ? Math.max(0, Number(root.island?.task?.progress ?? 0))
        : root.mode === "feedback" && root.levelStyle !== "minimal" ? (root.island?.feedbackValue ?? 0) : 0

    // Welded to the band (the notch) the body hangs square from it: the panel rounds only the far corners.
    readonly property bool welded: root.island?.notch ?? false
    readonly property bool atFoot: root.island?.bottomEdge ?? false
    readonly property int kiss: Math.max(2, Math.round(3 * root.d))
    ALacquer {
        id: panel
        anchors.fill: parent
        anchors.margins: root.kiss
        radius: IrisStyle.concentric(Math.min(root.width, root.height) / 2, root.kiss, IrisStyle.radiusChip)
        corners: root.welded ? (root.atFoot ? [1, 1, 0, 0] : [0, 0, 1, 1]) : null
        lacquer: root.surface
        coat: root.coatColour
        // At rest nothing runs along the foot: the seal says the day, the hour says itself.
        band: root.taped ? Math.max(3, Math.round(panel.height * 0.1)) : root.fills ? 0 : root.barLevel ? Math.max(3, Math.round(panel.height * 0.22))
            : root.resting ? 0 : Math.max(2, Math.round(panel.height * 0.09))
        share: root.taped ? 1 : root.run
        // A level follows the hand; a song and a timer step once a second (a pixel or two, no animation to pay for).
        travel: root.mode === "feedback" ? Airisu.detent : root.mode === "task" ? Airisu.snap : 0
    }

    // The time in the figures' face, its separator in the seal's ink.
    component Time: AText {
        property real figureSize: root.figure
        readonly property string said: String(DateTime.timeDisplay)
        readonly property int colon: said.indexOf(":")
        voice: "figure"
        lean: Airisu.lean
        size: figureSize
        color: root.ink
        textFormat: Text.StyledText
        text: colon < 0 ? said : said.slice(0, colon) + "<font color=\"" + Airisu.sealText + "\">:</font>" + said.slice(colon + 1)
    }

    // The day as a seal (印): the weekday's kanji over the date, in the seal's pigment, square as a hanko is.
    component Seal: Rectangle {
        id: seal
        readonly property date day: DateTime.clock.date
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Math.round(root.h * 0.7)
        implicitHeight: implicitWidth
        radius: IrisStyle.radiusMicro
        color: Airisu.seal
        Column {
            anchors.centerIn: parent
            spacing: Math.round(-2 * root.d)
            AText {
                anchors.horizontalCenter: parent.horizontalCenter
                voice: "kana"
                size: Math.round(seal.height * 0.4)
                color: Airisu.inkOnSeal
                text: "日月火水木金土"[seal.day.getDay()]
            }
            AText {
                anchors.horizontalCenter: parent.horizontalCenter
                size: Math.round(seal.height * 0.36)
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
                color: Airisu.inkOnSeal
                text: String(seal.day.getDate())
            }
        }
    }

    // What goes with the subject is ruby (ルビ), set small over it the way furigana sits over its word; a slim strip
    // keeps it on the line, before. The subject stays in the strip's ink; the ruby takes the second (SYSTEM.md §5).
    component Ruby: AText {
        voice: "ruby"
        font.weight: Font.Bold
        color: root.inkSecond
    }
    component Gloss: AText {
        Layout.alignment: Qt.AlignVCenter
        size: IrisStyle.typeMeta
        font.weight: Font.Bold
        color: root.inkSecond
    }

    // A small mark: AIRISU draws marks in the strip's ink, never on a plate of their own.
    component Mark: MaterialSymbol {
        iconSize: Math.round(17 * root.d)
        fill: 1
        color: root.ink
    }

    // A row of the strip, laid at the strip's width, shown only in its mode. Changing mode is a detent, not a fade.
    component Face: RowLayout {
        id: face
        property int enter: Airisu.detent
        property int leave: Airisu.detent
        readonly property bool current: root.rows[root.mode] === face
        anchors.fill: parent
        anchors.leftMargin: root.pad
        anchors.rightMargin: root.pad
        spacing: Airisu.u(2.5)
        opacity: face.current ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { enabled: Airisu.moving; NumberAnimation { duration: face.current ? face.enter : face.leave; easing.type: Easing.BezierSpline; easing.bezierCurve: Airisu.curve } }
    }

    // The clock, by the style Settings asks for: the time alone, with the day's seal, or after the weather.
    Face {
        id: idle
        readonly property string style: root.island?.clockStyle ?? "time"
        readonly property string temp: String(Weather.data?.temp ?? "")
        readonly property bool hasTemp: Weather.enabled && idle.temp.length > 0 && !idle.temp.startsWith("--")
        Item { Layout.fillWidth: true }
        Seal { visible: idle.style === "dateTime" }
        MaterialSymbol {
            visible: idle.style === "weather" && idle.hasTemp
            Layout.alignment: Qt.AlignVCenter
            text: Icons.getWeatherIcon(Weather.data?.wCode, Weather.isNightNow()) ?? "cloud"
            iconSize: Math.round(16 * root.d)
            fill: 1
            color: root.inkSecond
        }
        Ruby {
            visible: idle.style === "weather" && idle.hasTemp
            Layout.alignment: Qt.AlignVCenter
            text: idle.temp
        }
        Time { Layout.alignment: Qt.AlignVCenter }
        // After the hour, the weather as its ruby: the datum that goes with it, never louder.
        Ruby {
            visible: idle.style === "dateTime" && idle.hasTemp
            Layout.alignment: Qt.AlignVCenter
            text: idle.temp.replace(/[CF]$/, "")
        }
        PrivacyMarks { Layout.alignment: Qt.AlignVCenter; ink: root.ink }
        Item { Layout.fillWidth: true }
    }

    // Music: the cover as a print set into the lacquer, the title and under it the artist; playing is the coat moving,
    // so only a pause needs a mark.
    Face {
        id: media
        Item {
            Layout.preferredWidth: Math.round(root.h * 0.62)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            IrisArtwork {
                anchors.fill: parent
                source: MediaArtwork.displaySource
                radius: 0
                decodeSize: Math.ceil(parent.width * 2)
            }
        }
        Column {
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(artist.implicitWidth, track.implicitWidth)
            Layout.maximumWidth: Math.round(200 * root.d)
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(-1 * root.d)
            Ruby {
                id: artist
                visible: root.stacks && text.length > 0
                width: Math.min(implicitWidth, parent.width)
                text: String(MprisController.artistOf(root.island?.player) ?? "")
            }
            AText {
                id: track
                width: Math.min(implicitWidth, parent.width)
                text: StringUtils.cleanMusicTitle(root.island?.title ?? "")
                size: IrisStyle.typeLabel
                font.weight: Font.Bold
                color: root.ink
            }
        }
        Mark {
            visible: !(root.island?.playing ?? false)
            Layout.alignment: Qt.AlignVCenter
            text: "pause"
            color: root.inkSecond
        }
        PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false; ink: root.ink }
    }

    Face {
        id: record
        // The lamp: the one live mark, on and off at a slow beat.
        Rectangle {
            Layout.preferredWidth: Airisu.u(2)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            radius: width / 2
            color: root.ink
            SequentialAnimation on opacity {
                running: root.mode === "record" && Airisu.moving && root.visible
                loops: Animation.Infinite
                PropertyAction { value: 1 }
                PauseAnimation { duration: 700 }
                PropertyAction { value: 0.3 }
                PauseAnimation { duration: 500 }
            }
        }
        Gloss {
            visible: !root.stacks
            text: Translation.tr("Recording")
        }
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(-2 * root.d)
            Ruby {
                visible: root.stacks
                text: Translation.tr("Recording")
            }
            AText {
                voice: "figure"
                lean: Airisu.lean
                size: root.figure
                color: root.ink
                text: root.island?.clockText(RecorderStatus.elapsedSeconds) ?? ""
            }
        }
        PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false; ink: root.ink; alarm: root.ink }
    }

    Face {
        id: timer
        readonly property bool paused: root.island?.timerPaused ?? false
        Mark {
            text: timer.paused ? "pause" : (root.island?.timerGlyph ?? "timer")
            color: timer.paused ? root.inkSecond : root.ink
        }
        Gloss {
            visible: !root.stacks
            text: root.island?.timerLabel ?? ""
        }
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(-2 * root.d)
            Ruby {
                visible: root.stacks
                text: root.island?.timerLabel ?? ""
            }
            AText {
                voice: "figure"
                lean: Airisu.lean
                size: root.figure
                color: timer.paused ? root.inkSecond : Airisu.sealText
                text: root.island?.clockText(root.island?.timerSeconds ?? 0) ?? ""
            }
        }
        PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false; ink: root.ink }
    }

    Face {
        id: task
        Mark { text: String(root.island?.task?.glyph ?? "bolt") }
        Column {
            Layout.fillWidth: true
            Layout.preferredWidth: Math.max(taskDetail.implicitWidth, taskTitle.implicitWidth)
            Layout.maximumWidth: Math.round(200 * root.d)
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(-1 * root.d)
            Ruby {
                id: taskDetail
                visible: root.stacks && text.length > 0
                width: Math.min(implicitWidth, parent.width)
                text: String(root.island?.task?.detail ?? "")
            }
            AText {
                id: taskTitle
                width: Math.min(implicitWidth, parent.width)
                text: String(root.island?.task?.title ?? "")
                size: IrisStyle.typeLabel
                font.weight: Font.Bold
                color: root.ink
            }
        }
        // The percentage when the job knows it, how long it has run when it does not.
        AText {
            voice: "figure"
            lean: Airisu.lean
            size: root.figure
            color: root.ink
            text: Number(root.island?.task?.progress ?? -1) >= 0 ? (root.island?.percentOf(root.island?.task) ?? "") + "%"
                : (root.island?.elapsedOf(root.island?.task) ?? "")
        }
        PrivacyMarks { Layout.alignment: Qt.AlignVCenter; spelled: false; ink: root.ink }
    }

    // A notice: the strip is repainted in the notice's colour from its start, and what it says is set on it.
    Face {
        id: event
        enter: 0
        leave: Airisu.tear
        Mark {
            text: root.island?.eventGlyph ?? ""
        }
        AText {
            Layout.fillWidth: true
            Layout.maximumWidth: Math.round(180 * root.d)
            text: root.island?.event?.title ?? ""
            color: root.ink
            size: IrisStyle.typeLabel
            font.weight: Font.Bold
        }
        AText {
            visible: text.length > 0 && (root.island?.event?.value ?? -1) < 0
            Layout.maximumWidth: Math.round(130 * root.d)
            text: root.island?.event?.detail ?? ""
            color: root.inkSecond
            size: IrisStyle.typeMeta
            font.weight: Font.Medium
        }
        AText {
            visible: (root.island?.event?.value ?? -1) >= 0
            voice: "figure"
            lean: Airisu.lean
            size: root.figure
            color: root.ink
            text: Math.round((root.island?.event?.value ?? 0) * 100) + "%"
        }
    }

    // A level while it moves: the coat is the level, the mark and the figure are set on it. Bar keeps the coat to a band
    // along the foot; Minimal leaves the lacquer bare and says the level in the figure alone.
    Face {
        id: level
        readonly property bool muted: root.island?.feedbackMuted ?? false
        Mark {
            text: root.levelIcon
            color: level.muted ? root.inkSecond : root.ink
        }
        Item { Layout.fillWidth: true; Layout.preferredWidth: Math.round(120 * root.d) }
        AText {
            id: levelFigure
            visible: root.island?.levelFigure ?? true
            // Its box is the widest level it can say ("100") plus the lean of its top, so a figure is never elided
            // and the strip keeps its width while the level moves.
            Layout.preferredWidth: Math.ceil(levelWidest.advanceWidth + Airisu.lean * levelFigure.height)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideNone
            voice: "figure"
            lean: Airisu.lean
            size: root.figure
            color: level.muted ? root.inkSecond : root.ink
            text: Math.round((root.island?.feedbackValue ?? 0) * 100)
            TextMetrics { id: levelWidest; font: levelFigure.font; text: "100" }
        }
    }
}
