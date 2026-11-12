pragma ComponentBehavior: Bound

// The desktop card in iRiS (the widget design "iRiS"): the family's own plate, glass and ink, as every iRiS widget.
// The station leads; its genre heads the face and where it is ends the head; the play key is the one accent.
// Small: the station, play, find, next. Medium: the song, the star and the volume too. Large: your stations under them.
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

IrisWidgetFace {
    id: root

    readonly property var card: root.widget
    readonly property bool steerable: root.card.steerable
    readonly property color live: root.nothing ? root.signal : root.accent

    // The radio's own parts (volume, station rows) in this face's ink.
    readonly property var partLook: ({
        d: root.k,
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
        accent: root.live,
        onAccent: root.onFill(root.live),
        radiusSmall: root.dp(8),
        glyph: faceGlyph
    })
    readonly property var partCard: ({
        cardLook: root.partLook,
        px: value => root.dp(value),
        widgetCapitalization: Font.MixedCase,
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

    component PlayKey: Rectangle {
        id: key
        implicitWidth: root.dp(44)
        implicitHeight: implicitWidth
        radius: width / 2
        enabled: root.steerable
        color: root.card.playing ? root.live : keyHover.hovered ? root.fillHover : root.fill
        scale: keyTap.pressed ? IrisStyle.pressScale(0.94) : 1
        Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.card.playIcon
            fill: 1
            iconSize: Math.round(key.width * 0.5)
            color: root.card.playing ? root.onFill(key.color) : root.ink
        }
        HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: keyTap; gesturePolicy: TapHandler.WithinBounds; onTapped: Radio.playPause() }
        Accessible.role: Accessible.Button
        Accessible.name: root.card.playing ? Translation.tr("Stop") : Translation.tr("Play")
    }
    component Station: FaceText {
        face: root
        text: root.card.title
        weight: Font.Bold
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        lineHeight: 0.96
        TapHandler { enabled: root.steerable; onTapped: root.card.openTuner() }
        HoverHandler { enabled: root.steerable; cursorShape: Qt.PointingHandCursor }
    }
    component Keys: Row {
        property bool star: true
        spacing: root.dp(6)
        enabled: root.steerable
        FaceAction {
            face: root
            visible: parent.star && root.card.station !== null
            glyph: "star"
            name: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            tint: Radio.kept ? root.live : root.inkSecondary
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

    // Small
    ColumnLayout {
        visible: root.small
        anchors.fill: parent
        spacing: root.dp(2)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "radio"
            text: root.card.eyebrow
            tint: root.heading
        }
        Station {
            Layout.fillWidth: true
            Layout.topMargin: root.dp(2)
            size: 16
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            text: root.card.turning || root.card.failed || root.card.waiting || root.card.where.length === 0 ? root.card.statusLine : root.card.where
            color: root.card.failed ? root.danger : root.inkSecondary
            size: 12
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: 0
            PlayKey { implicitWidth: root.dp(40) }
            Item { Layout.fillWidth: true }
            Keys { star: false }
        }
    }

    // Medium
    ColumnLayout {
        visible: root.medium
        anchors.fill: parent
        spacing: root.dp(2)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "radio"
            text: root.card.eyebrow
            trailing: root.card.where
            trailingMax: root.contentWidth * 0.55
            tint: root.heading
        }
        Station {
            Layout.fillWidth: true
            Layout.topMargin: root.dp(2)
            maximumLineCount: 1
            size: 22
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            text: root.card.statusLine
            color: root.card.failed ? root.danger : root.inkSecondary
            size: 13
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: root.dp(10)
            PlayKey {}
            Keys {}
            Item { Layout.fillWidth: true }
            RadioVolume {
                look: root.partLook
                barWidth: root.dp(64)
            }
        }
    }

    // Large
    ColumnLayout {
        visible: root.large
        anchors.fill: parent
        spacing: root.dp(4)
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "radio"
            text: root.card.eyebrow
            trailing: root.card.where
            trailingMax: root.contentWidth * 0.55
            tint: root.heading
        }
        Station {
            Layout.fillWidth: true
            Layout.topMargin: root.dp(4)
            size: 26
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            text: root.card.statusLine
            color: root.card.failed ? root.danger : root.inkSecondary
            size: 14
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.topMargin: root.dp(8)
            spacing: root.dp(10)
            PlayKey {}
            Keys {}
            Item { Layout.fillWidth: true }
            RadioVolume {
                look: root.partLook
                barWidth: root.dp(72)
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: root.dp(8)
            Layout.bottomMargin: root.dp(4)
            implicitHeight: 1
            color: root.hairline
        }
        // As many of your stations as the face has room left for.
        Item {
            id: shelf
            Layout.fillWidth: true
            Layout.fillHeight: true
            Loader {
                width: shelf.width
                active: root.large
                sourceComponent: RadioCardStations {
                    card: root.partCard
                    rows: Math.max(1, Math.floor((shelf.height - root.dp(22)) / root.dp(38)))
                }
            }
        }
    }
}
