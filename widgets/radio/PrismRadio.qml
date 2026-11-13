pragma ComponentBehavior: Bound

// The desktop card in Prism (the widget design "Prism" of iRiS): the genre on the head with the place as its one fact,
// the station in the pane beside its play key, the keys and the volume on the foot; large keeps your stations there too.
// The light passes whole only while a station plays.
import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets
import qs.modules.iris.widgets.prism

PrismFolder {
    id: root

    readonly property var card: root.widget
    readonly property bool steerable: root.card.steerable

    tabGlyph: "radio"
    tabText: root.card.eyebrow
    flapText: root.card.station ? Radio.place : ""
    lightPass: root.card.playing ? 1 : 0.55

    readonly property var partLook: ({
        grammar: "prism",
        d: root.k * root.type(0.82, 0.82, 0.94),
        font: root.fontMain,
        small: root.px(11),
        meta: root.px(11.5),
        body: root.px(13),
        raised: root.fill,
        hover: root.fillHover,
        press: root.fillActive,
        ink: root.ink,
        muted: root.inkSecondary,
        faint: root.inkTertiary,
        line: root.hairline,
        track: root.fill,
        accent: root.shelf,
        onAccent: root.inkOnShelf,
        solid: root.ink,
        onSolid: root.onFill(root.ink),
        spectrum: IrisStyle.prismStops,
        radiusSmall: root.dp(8),
        glyph: faceGlyph
    })
    readonly property var partCard: ({
        cardLook: root.partLook,
        px: value => root.dp(value),
        widgetCapitalization: root.label ? Font.AllUppercase : Font.MixedCase,
        steerable: root.steerable
    })
    Component {
        id: faceGlyph
        MaterialSymbol {
            property string name: ""
            property real size: 20
            property bool filled: false
            text: name
            iconSize: size
            fill: filled ? 1 : 0
        }
    }

    // ── the pane: the station, and its key ──
    Rectangle {
        id: playKey
        width: root.pick(40, 52, 64)
        height: width
        x: root.width - root.inset - width
        y: Math.round(root.paneMiddle - height / 2)
        radius: width / 2
        enabled: root.steerable
        color: root.card.playing ? root.shelf : keyHover.hovered ? root.fillHover : root.fill
        scale: keyTap.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.card.playIcon
            fill: 1
            iconSize: Math.round(playKey.width * 0.5)
            color: root.card.playing ? root.onFill(playKey.color) : root.ink
        }
        HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: keyTap; gesturePolicy: TapHandler.WithinBounds; onTapped: Radio.playPause() }
        Accessible.role: Accessible.Button
        Accessible.name: root.card.playing ? Translation.tr("Stop") : Translation.tr("Play")
    }
    Column {
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: playKey.x - root.inset - root.dp(12)
        spacing: root.dp(1)
        FaceText {
            face: root
            width: parent.width
            text: root.card.title
            size: root.type(15, 22, 28)
            weight: Font.Bold
            wrapMode: Text.WordWrap
            maximumLineCount: root.medium ? 1 : 2
            lineHeight: 0.96
            TapHandler { enabled: root.steerable; onTapped: root.card.openTuner() }
            HoverHandler { enabled: root.steerable; cursorShape: Qt.PointingHandCursor }
        }
        FaceText {
            face: root
            visible: !root.small
            width: parent.width
            text: root.card.statusLine
            color: root.card.failed ? root.danger : root.inkSecondary
            size: root.type(12, 13, 14)
            wrapMode: root.large ? Text.WordWrap : Text.NoWrap
            maximumLineCount: root.large ? 2 : 1
        }
    }

    // ── the foot: the keys and the volume; large keeps your stations under them ──
    readonly property real footRow: root.large ? root.footTop + root.dp(14)
        : Math.round(root.footTop + (root.footHeight - root.dp(32)) / 2 - root.dp(2))
    Row {
        x: root.inset
        y: root.footRow
        spacing: root.dp(6)
        enabled: root.steerable
        FaceAction {
            face: root
            visible: root.card.station !== null
            glyph: "star"
            name: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            tint: Radio.kept ? root.shelf : root.inkSecondary
            onActivated: Radio.toggleFavourite(root.card.station)
        }
        FaceAction {
            face: root
            glyph: "explore"
            name: Translation.tr("Find a station")
            onActivated: root.card.openTuner()
        }
        FaceAction {
            face: root
            glyph: "skip_next"
            name: Translation.tr("Next station")
            enabled: !root.card.waiting
            opacity: enabled ? 1 : 0.4
            onActivated: Radio.next()
        }
    }
    RadioVolume {
        id: volume
        visible: !root.small
        x: root.width - root.inset - width
        y: Math.round(root.footRow + (root.dp(32) - height) / 2)
        look: root.partLook
    }
    Loader {
        x: root.inset
        y: root.footRow + root.dp(32) + root.dp(12)
        width: root.innerWidth
        active: root.large
        sourceComponent: RadioCardStations {
            card: root.partCard
            rows: 2
        }
    }
}
