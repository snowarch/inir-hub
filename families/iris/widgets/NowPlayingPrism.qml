pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Prism (his 11-06 references: a player widget concept, dressed in Figma's refraction card): a folder of frosted glass.
// Its dark tab carries the player; a flap lit in the song's colour beside it holds the hour; a pane laid across the
// folder holds the cover, what is happening and the lines being sung (the song's bars without them); under it the
// title, the artist, the timeline and the keys, play on the song's colour. A beam of white light crosses the glass and
// breaks into its colours on the pane while the song plays. Medium keeps the folder and the pane and sets the song in
// the pane, the timeline and the keys under it; small sets the title and artist in the pane and the keys under it, the
// hour alone on the flap. The body is PrismBody, the folder every Prism face stands on (`widgets/prism/`): no plate.
Item {
    id: view
    required property var face
    required property var media

    readonly property bool wide: view.face.medium
    readonly property bool compact: view.face.small
    readonly property bool label: view.face.nothing ?? false
    readonly property color songLight: view.label ? view.face.signal : view.face.accent
    function dp(value: real): real { return view.face.dp(value) }

    // What it shows: the song, the paused one, the one that played last, or nothing yet.
    readonly property var rest: view.face.restState
    readonly property bool resting: view.face.resting
    readonly property bool known: !view.resting || view.rest.known
    readonly property bool remembered: view.resting && view.rest.remembered
    readonly property bool controllable: !view.resting || view.rest.paused
    readonly property string title: !view.resting ? (view.media.effectiveTitle || view.face.source)
        : view.known ? view.rest.title : Translation.tr("Not playing")
    readonly property string artist: !view.resting ? view.media.effectiveArtist
        : view.known ? view.rest.detail : Translation.tr("Play something and it shows here")
    readonly property string cover: view.resting ? view.rest.coverArt : view.face.art
    readonly property string head: view.remembered ? String(view.rest.last.source || Translation.tr("Music"))
        : view.face.hasPlayer ? view.face.source : Translation.tr("Music")
    readonly property string stateWord: view.face.playing ? Translation.tr("Now playing")
        : view.remembered ? Translation.tr("Last played") : view.known ? Translation.tr("Paused") : ""
    readonly property bool timed: view.controllable && view.media.effectiveLength > 0

    // The player's own mark, as the reference wears the app's logo; none found, the song's colour holds a note.
    readonly property string entryId: view.remembered ? String(view.rest.last.entry ?? "") : String(view.face.player?.desktopEntry ?? "")
    readonly property string appIcon: {
        const entry = view.entryId.length > 0 ? AppSearch.lookupDesktopEntry(view.entryId) : null
        const own = String(entry?.icon ?? "")
        if (own.startsWith("/"))
            return own
        // The head names the player only when there is one; with none it is the word "Music", and a theme's icon of
        // that name (a folder, a file type) stood in for a player's logo.
        const source = view.face.hasPlayer || view.remembered ? view.head.toLowerCase() : ""
        const name = [own, view.entryId, source].find(icon => icon.length > 0 && AppSearch.iconExists(icon))
        return name ? Quickshell.iconPath(name) : ""
    }
    // The hour as the reference sets it: the figures, and a 12-hour clock's AM/PM raised small beside them.
    readonly property var hour: {
        const text = String(DateTime.time ?? "")
        const split = text.match(/^(.*?)\s*([AaPp]\.?\s?[Mm]\.?)$/)
        return split ? [split[1], split[2].replace(/[.\s]/g, "").toUpperCase()] : [text, ""]
    }

    // The folder, in dp of the grid's box (368 x 368 large, 368 x 176 medium, 176 x 176 small); the reference's
    // proportions, small keeping medium's rhythm.
    function pick(small: real, medium: real, large: real): real { return view.dp(view.compact ? small : view.wide ? medium : large) }
    readonly property real tabRight: view.pick(98, 196, 214)
    readonly property real lean: view.pick(22, 22, 40)
    readonly property real flapTop: view.pick(12, 14, 29)
    readonly property real flapRight: view.width - view.pick(14, 30, 26)
    readonly property real paneTop: view.pick(44, 42, 79)
    readonly property real paneBottom: view.pick(112, 120, 200)
    readonly property real paneRadius: view.pick(13, 14, 16)
    readonly property real headY: Math.round(view.paneTop * 0.52)
    readonly property real coverSide: view.paneBottom - view.paneTop - 2 * view.pick(8, 8, 11)
    readonly property real coverX: view.pick(10, 18, 42)
    readonly property real textX: view.coverX + view.coverSide + view.pick(10, 14, 18)
    readonly property real textRight: view.width - view.pick(12, 18, 24)
    readonly property real sideInset: view.pick(16, 22, 40)

    // Light passes while the song plays; paused, the glass keeps a little of it.
    property real lightPass: view.face.playing ? 1 : 0.3
    Behavior on lightPass { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    PrismBody {
        id: glass
        anchors.fill: parent
        face: view.face
        tabRight: view.tabRight
        lean: view.lean
        tabRadius: view.pick(16, 20, 26)
        flapTop: view.flapTop
        flapRight: view.flapRight
        flapRadius: view.pick(18, 22, 30)
        paneTop: view.paneTop
        paneBottom: view.paneBottom
        paneRadius: view.paneRadius
        // The cover is the prism: the white beam climbs from the folder's left edge to it, past every line of text,
        // and its spectrum leaves the cover's right side toward the upper right.
        prism: Qt.point(art.x + art.width / 2, art.y + art.height / 2)
        entry: view.compact ? Qt.point(-view.width * 0.3, view.height * 1.05)
            : view.wide ? Qt.point(-view.width * 0.2, view.height * 1.15) : Qt.point(-view.width * 0.16, view.height * 0.9)
        fanAngle: view.compact ? -0.55 : view.wide ? -0.4 : -0.46
        fanSpread: view.compact ? 0.34 : view.wide ? 0.28 : 0.3
        lightPass: view.lightPass
        shelf: view.songLight
        white: view.label
    }

    // ── the tab: the player's mark and name ──
    Item {
        id: mark
        readonly property real side: view.pick(20, 24, 34)
        x: view.pick(14, 22, 54)
        y: Math.round(view.headY - mark.side / 2)
        width: mark.side
        height: mark.side
        Image {
            anchors.fill: parent
            visible: view.appIcon.length > 0
            source: view.appIcon
            sourceSize.width: Math.round(mark.side * 2)
            sourceSize.height: Math.round(mark.side * 2)
            smooth: true
            mipmap: true
            asynchronous: true
        }
        Rectangle {
            anchors.fill: parent
            visible: view.appIcon.length === 0
            radius: width / 2
            color: view.songLight
            MaterialSymbol {
                anchors.centerIn: parent
                text: "graphic_eq"
                fill: 1
                iconSize: Math.round(mark.side * 0.6)
                color: view.face.onFill(view.songLight)
            }
        }
    }
    FaceText {
        face: view.face
        x: mark.x + mark.width + view.pick(6, 8, 9)
        y: Math.round(view.headY - height / 2)
        width: glass.edgeAt(y) - x - view.dp(10)
        text: view.label ? view.head.toUpperCase() : view.head
        color: view.label ? view.face.ink : view.songLight
        size: view.label ? (view.compact ? 10.5 : view.wide ? 12 : 14) : (view.compact ? 13 : view.wide ? 16 : 21)
        weight: Font.Bold
        font.family: view.label ? view.face.fontLabel : view.face.fontMain
        font.letterSpacing: view.label ? view.face.px(12) * 0.08 : -view.face.px(view.compact ? 13 : view.wide ? 16 : 21) * 0.02
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: view.face.px(view.compact ? 10 : 12)
    }

    // ── the flap: the hour ──
    Row {
        id: hourRow
        readonly property real centerY: (view.flapTop + view.paneTop) / 2
        x: Math.round((glass.edgeAt(hourRow.centerY) + view.flapRight) / 2 + view.dp(4) - width / 2)
        y: Math.round(hourRow.centerY - hourFigure.height / 2)
        spacing: view.dp(1)
        FaceText {
            id: hourFigure
            face: view.face
            text: view.hour[0]
            color: view.face.onFill(view.songLight)
            size: view.compact ? 12 : view.wide ? 13 : 17
            weight: Font.Bold
            font.family: view.face.fontNumbers
            font.features: ({ "tnum": 1 })
        }
        FaceText {
            visible: text.length > 0
            face: view.face
            y: Math.round(hourFigure.height * 0.06)
            text: view.hour[1]
            color: view.face.onFill(view.songLight)
            size: view.compact ? 7 : view.wide ? 7.5 : 9
            weight: Font.Bold
        }
    }

    // ── the pane: the cover, what is happening, the lines ──
    Item {
        id: art
        x: view.coverX
        y: Math.round((view.paneTop + view.paneBottom - view.coverSide) / 2)
        width: view.coverSide
        height: view.coverSide
        IrisArtwork {
            anchors.fill: parent
            visible: view.cover.length > 0
            source: view.cover
            circular: false
            radius: view.pick(7, 7, 8)
        }
        Rectangle {
            anchors.fill: parent
            visible: view.cover.length === 0
            radius: view.pick(7, 7, 8)
            color: IrisStyle.tintFill(view.face.accent)
            MaterialSymbol {
                anchors.centerIn: parent
                text: "music_note"
                fill: 1
                iconSize: Math.round(parent.width * 0.42)
                color: view.face.accent
            }
        }
        // The cover plays and pauses, as Apple's does; it settles back a little while paused.
        scale: coverTap.pressed ? IrisStyle.pressScale(0.94) : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        HoverHandler { enabled: view.controllable || view.remembered; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            id: coverTap
            enabled: view.controllable || view.remembered
            gesturePolicy: TapHandler.WithinBounds
            onTapped: view.remembered ? MprisController.resumeLast() : view.media.togglePlaying()
        }
    }

    readonly property real stateY: view.paneTop + view.dp(view.wide ? 15 : 22)
    FaceText {
        id: stateLine
        face: view.face
        visible: view.stateWord.length > 0 && !view.compact
        x: view.textX
        y: Math.round(view.stateY - height / 2)
        width: (output.visible ? output.x - view.dp(8) : view.textRight) - x
        text: "• " + view.stateWord.toUpperCase()
        color: view.face.ink
        size: view.wide ? 10.5 : 12
        weight: Font.Bold
        font.family: view.label ? view.face.fontLabel : view.face.fontMain
        font.letterSpacing: view.face.px(view.wide ? 10.5 : 12) * (view.label ? 0.08 : 0.02)
    }
    // Where the sound goes, read from the real output, in the reference's badge; nothing without an output.
    Rectangle {
        id: output
        readonly property string device: IrisStyle.soundDeviceGlyph(Audio.defaultSink, false)
        visible: !view.resting && !view.compact && Audio.defaultSink !== null && Audio.defaultSink !== undefined
        width: view.dp(view.wide ? 18 : 20)
        height: width
        x: view.textRight - width
        y: Math.round(view.stateY - height / 2)
        radius: width / 2
        color: view.songLight
        MaterialSymbol {
            anchors.centerIn: parent
            text: output.device === "speaker" ? "volume_up" : output.device
            fill: 1
            iconSize: Math.round(output.width * 0.66)
            color: view.face.onFill(view.songLight)
        }
        Accessible.role: Accessible.StaticText
        Accessible.name: Translation.tr("Sound output")
    }

    // Large: the lines around the one being sung, gliding up a line as it changes; the song's bars without them.
    readonly property int sung: LyricsService.activeIndex
    property int lastSung: -1
    property real shift: 0
    onSungChanged: {
        const step = view.sung - view.lastSung
        view.lastSung = view.sung
        if (Math.abs(step) === 1 && view.face.moving && IrisStyle.motionEnabled) {
            glide.stop()
            view.shift = step * lines.pitch
            glide.start()
        }
    }
    NumberAnimation { id: glide; target: view; property: "shift"; to: 0; duration: 460; easing.type: Easing.OutCubic }
    Item {
        id: lines
        readonly property real pitch: view.face.px(21)
        visible: view.face.large && !view.resting && view.face.lyricsReady
        x: view.textX
        y: view.paneTop + view.dp(36)
        width: view.textRight - view.textX
        height: view.paneBottom - view.dp(6) - lines.y
        clip: true
        Repeater {
            model: lines.visible ? 5 : 0
            FaceText {
                required property int index
                readonly property real offset: (index - 2) * lines.pitch + view.shift
                readonly property real away: Math.abs(offset) / lines.pitch
                face: view.face
                width: lines.width
                y: Math.round(lines.height / 2 + offset - height / 2)
                text: LyricsService.slots[index + 1] ?? ""
                color: view.songLight
                opacity: away < 1 ? 1 - 0.64 * away : Math.max(0, 0.36 - 0.3 * (away - 1))
                size: 15
                weight: Font.DemiBold
            }
        }
    }
    // Without lines: the song's bars and its album, where the sung line would be.
    readonly property real linesCenter: Math.round((view.paneTop + view.dp(36) + view.paneBottom - view.dp(6)) / 2)
    readonly property string album: String(view.face.player?.trackAlbum ?? "")
    IrisVisualizer {
        id: bars
        visible: view.face.large && !lines.visible && view.known && !view.remembered
        x: view.textX
        y: Math.round(view.linesCenter - height / 2)
        running: visible && view.face.playing && view.face.moving
        tint: view.songLight
        barHeight: view.dp(22)
    }
    FaceText {
        face: view.face
        visible: bars.visible && text.length > 0
        x: bars.x + bars.width + view.dp(10)
        y: Math.round(view.linesCenter - height / 2)
        width: view.textRight - x
        text: view.resting ? "" : view.album
        color: view.songLight
        size: 15
        weight: Font.DemiBold
    }
    FaceText {
        face: view.face
        visible: view.remembered && text.length > 0 && !view.compact
        // where the lines are on large, the timeline's place on medium
        x: view.wide ? view.sideInset : view.textX
        y: Math.round((view.wide ? view.paneBottom + view.dp(28) : view.linesCenter) - height / 2)
        width: view.wide ? view.keysX - view.keyGap - view.dp(28) - x : view.textRight - view.textX
        text: view.rest.when
        color: view.face.inkTertiary
        size: view.wide ? 12 : 13
    }

    // ── the song: under the pane on large, in it on medium ──
    // A long title or artist never loses its words: faded at the edge it runs past, it slides through once when the
    // song changes and again while the pointer is on it, then rests (a marquee looping on the desktop repaints it for
    // nobody).
    HoverHandler { id: songHover }
    Timer {
        id: songPass
        interval: Math.max(titleLine.passDuration, artistLine.passDuration)
    }
    onTitleChanged: if (view.face.moving) songPass.restart()
    readonly property bool songMoving: view.face.moving && (songHover.hovered || songPass.running)
    IrisMarquee {
        id: titleLine
        readonly property bool inPane: view.wide || view.compact
        x: titleLine.inPane ? view.textX : view.sideInset
        y: Math.round((view.compact ? view.paneTop + view.dp(25) : view.wide ? view.paneTop + view.dp(39) : view.paneBottom + view.dp(23)) - height / 2)
        width: titleLine.inPane ? view.textRight - view.textX : view.width - 2 * view.sideInset
        horizontalAlignment: titleLine.inPane ? Text.AlignLeft : Text.AlignHCenter
        text: view.title
        color: view.known ? view.face.ink : view.face.inkSecondary
        pixelSize: view.face.px(view.compact ? 13 : view.wide ? 15 : 18)
        weight: Font.Bold
        running: view.songMoving
    }
    IrisMarquee {
        id: artistLine
        visible: view.artist.length > 0
        x: titleLine.x
        y: Math.round((view.compact ? view.paneTop + view.dp(43) : view.wide ? view.paneTop + view.dp(58) : view.paneBottom + view.dp(45)) - height / 2)
        width: titleLine.width
        horizontalAlignment: titleLine.horizontalAlignment
        text: view.artist
        color: view.known ? view.face.inkSecondary : view.face.inkTertiary
        pixelSize: view.face.px(view.compact ? 11.5 : view.wide ? 12.5 : 15.5)
        running: view.songMoving
    }

    // ── the timeline: elapsed and length under a line of the song's colour with its knob ──
    readonly property real keysCenter: view.paneBottom + view.pick(38, 28, 116)
    readonly property real playSide: view.pick(34, 36, 44)
    readonly property real keyGap: view.pick(44, 40, 77)
    readonly property real keysX: view.wide ? view.width - view.dp(26) - view.dp(14) - view.keyGap : Math.round(view.width / 2)
    Item {
        id: timeline
        visible: view.timed
        x: view.sideInset
        y: Math.round(view.paneBottom + view.pick(12, 19, 66) - height / 2)
        width: (view.wide ? view.keysX - view.keyGap - view.dp(28) : view.width - view.sideInset) - x
        height: view.dp(10)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: view.dp(3)
            radius: height / 2
            color: view.face.fill
            Rectangle {
                width: parent.width * view.face.progress
                height: parent.height
                radius: parent.radius
                color: view.songLight
            }
        }
        Rectangle {
            x: Math.round(parent.width * view.face.progress - width / 2)
            anchors.verticalCenter: parent.verticalCenter
            width: view.pick(8, 9, 10)
            height: width
            radius: width / 2
            color: view.songLight
        }
    }
    FaceText {
        face: view.face
        visible: view.timed && !view.compact
        x: timeline.x
        y: Math.round(timeline.y + timeline.height / 2 + view.dp(view.wide ? 13 : 17) - height / 2)
        text: StringUtils.friendlyTimeForSeconds(view.media.effectivePosition)
        color: view.face.inkTertiary
        size: view.wide ? 10.5 : 12.5
        font.family: view.face.fontNumbers
        font.features: ({ "tnum": 1 })
    }
    FaceText {
        face: view.face
        visible: view.timed && !view.compact
        x: timeline.x + timeline.width - width
        y: Math.round(timeline.y + timeline.height / 2 + view.dp(view.wide ? 13 : 17) - height / 2)
        text: StringUtils.friendlyTimeForSeconds(view.media.effectiveLength)
        color: view.face.inkTertiary
        size: view.wide ? 10.5 : 12.5
        font.family: view.face.fontNumbers
        font.features: ({ "tnum": 1 })
    }

    // ── the keys: previous and next in grey, play on the song's colour ──
    component Key: Item {
        id: key
        property string glyph: ""
        property string name: ""
        property bool lead: false
        property real side: view.playSide
        signal activated()
        width: key.side
        height: key.side
        opacity: key.enabled ? 1 : 0.35
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: key.lead ? view.songLight : keyHover.hovered ? view.face.fillHover : ColorUtils.applyAlpha(view.face.fillHover, 0)
            scale: keyTap.pressed ? IrisStyle.pressScale(0.9) : keyHover.hovered && key.lead ? 1.05 : 1
            Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
            Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: key.glyph
            fill: 1
            iconSize: Math.round(key.side * (key.lead ? 0.66 : 0.95))
            color: key.lead ? view.face.onFill(view.songLight) : view.face.inkSecondary
            scale: keyTap.pressed ? IrisStyle.pressScale(0.9) : 1
            Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        }
        HoverHandler { id: keyHover; enabled: key.enabled; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: keyTap; enabled: key.enabled; gesturePolicy: TapHandler.WithinBounds; onTapped: key.activated() }
        Accessible.role: Accessible.Button
        Accessible.name: key.name
    }
    Key {
        visible: view.known
        x: Math.round(view.keysX - view.keyGap - width / 2)
        y: Math.round(view.keysCenter - height / 2)
        side: Math.round(view.playSide * 0.9)
        glyph: "skip_previous"
        name: Translation.tr("Previous")
        enabled: view.controllable && view.media.effectiveCanGoPrevious
        onActivated: view.media.previous()
    }
    Key {
        visible: view.known
        x: Math.round(view.keysX - width / 2)
        y: Math.round(view.keysCenter - height / 2)
        lead: true
        glyph: view.face.playing ? "pause" : "play_arrow"
        name: view.face.playing ? Translation.tr("Pause") : Translation.tr("Play")
        onActivated: view.remembered ? MprisController.resumeLast() : view.media.togglePlaying()
    }
    Key {
        visible: view.known
        x: Math.round(view.keysX + view.keyGap - width / 2)
        y: Math.round(view.keysCenter - height / 2)
        side: Math.round(view.playSide * 0.9)
        glyph: "skip_next"
        name: Translation.tr("Next")
        enabled: view.controllable && view.media.effectiveCanGoNext
        onActivated: view.media.next()
    }
}
