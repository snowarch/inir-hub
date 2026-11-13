pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Vinyl (his 11-06 references): the cover is the sleeve and the record rides behind it. Playing, the record slides
// half out and turns, its label the cover; paused it slips back in, only its edge showing. The reflection on the
// record stays still as the label turns, as on a real one. Beside it (medium) or under it (large) the title, the
// artist, the timeline and the keys, play on the song's colour (the signal under Nothing).
Item {
    id: view
    required property var face
    required property var media

    readonly property bool wide: view.face.medium
    readonly property bool label: view.face.nothing ?? false
    readonly property color songLight: view.label ? view.face.signal : view.face.accent
    // A record is black vinyl in every theme and scheme, and what it catches is white light.
    readonly property color vinyl: "#0d0d0f" // iris-literal: a record is black in every theme
    readonly property color shine: "#ffffff" // iris-literal: light on black vinyl, the same in every theme
    readonly property bool spinning: view.face.playing && view.face.moving && IrisStyle.motionEnabled

    // The sleeve's side: as tall as the face allows on medium, a little over half the face on large.
    readonly property real sleeve: view.wide ? Math.min(view.height, Math.round(view.width * 0.4))
        : Math.min(Math.round(view.height * 0.5), Math.round(view.width * 0.56))
    // How far the record stands out of the sleeve, as a share of the sleeve: half out playing, its edge paused.
    readonly property real outPlaying: view.wide ? 0.32 : 0.42
    IrisSpring {
        id: outSpring
        intent: "move"
        to: view.face.playing ? view.outPlaying : 0.1
        minimum: 0
    }

    // The sleeve with the record behind it; the block keeps the width the record takes playing, so nothing beside it
    // moves when the song stops.
    component Deck: Item {
        id: deck
        implicitWidth: view.sleeve * (1 + view.outPlaying)
        implicitHeight: view.sleeve

        Item {
            id: record
            readonly property real side: Math.round(view.sleeve * 0.94)
            width: side
            height: side
            x: view.sleeve * outSpring.value + (view.sleeve - side) / 2
            y: (view.sleeve - side) / 2

            // The record itself is black in every theme; a hair of light marks its edge on a dark plate.
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: view.vinyl
                border.width: Math.max(1, view.face.dp(0.75))
                border.color: Qt.alpha(view.shine, 0.09)
            }
            // The grooves: rings that catch a little light, closer together towards the label.
            Repeater {
                model: [0.9, 0.8, 0.71, 0.63, 0.56]
                Rectangle {
                    required property real modelData
                    required property int index
                    anchors.centerIn: parent
                    width: record.side * modelData
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: Math.max(1, view.face.dp(0.6))
                    border.color: Qt.alpha(view.shine, 0.045 + 0.012 * index)
                }
            }
            // Where the needle is: one groove lit in the song's colour, walking in from the edge to the label as the
            // song plays. It is the timeline; the figures beside it say the same in minutes.
            Rectangle {
                anchors.centerIn: parent
                visible: view.media.effectiveLength > 0
                width: Math.round(record.side * (0.9 - 0.44 * view.face.progress))
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1.5, view.face.dp(1.5))
                border.color: Qt.alpha(view.songLight, 0.9)
            }
            // The label turns with the record: the cover, a disc of the song's colour when there is none.
            Item {
                id: spinner
                anchors.centerIn: parent
                width: Math.round(record.side * 0.4)
                height: width
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: view.songLight
                    visible: view.face.art.length === 0
                }
                IrisArtwork {
                    anchors.fill: parent
                    visible: view.face.art.length > 0
                    source: view.face.art
                    circular: true
                    decodeSize: width * 2
                }
                // The spindle hole, and a notch off-centre so a turning label reads as turning on a plain cover.
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(4, Math.round(record.side * 0.035))
                    height: width
                    radius: width / 2
                    color: view.vinyl
                }
                Rectangle {
                    x: parent.width * 0.68
                    y: parent.height * 0.24
                    width: Math.max(3, Math.round(record.side * 0.022))
                    height: width
                    radius: width / 2
                    color: Qt.alpha(view.shine, 0.5)
                    visible: view.face.art.length === 0
                }
                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1800
                    loops: Animation.Infinite
                    running: view.face.moving
                    // Paused only once it runs: Qt refuses a pause before the start (it warns).
                    paused: running && !view.spinning
                }
            }
            // The reflection: two soft wedges of light across the grooves, fixed while the record turns.
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillRule: ShapePath.OddEvenFill
                    fillGradient: ConicalGradient {
                        centerX: record.side / 2
                        centerY: record.side / 2
                        angle: 135
                        GradientStop { position: 0; color: Qt.alpha(view.shine, 0) }
                        GradientStop { position: 0.06; color: Qt.alpha(view.shine, 0.11) }
                        GradientStop { position: 0.13; color: Qt.alpha(view.shine, 0) }
                        GradientStop { position: 0.5; color: Qt.alpha(view.shine, 0) }
                        GradientStop { position: 0.56; color: Qt.alpha(view.shine, 0.07) }
                        GradientStop { position: 0.63; color: Qt.alpha(view.shine, 0) }
                    }
                    PathAngleArc { centerX: record.side / 2; centerY: record.side / 2; radiusX: record.side * 0.47; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                    PathAngleArc { centerX: record.side / 2; centerY: record.side / 2; radiusX: record.side * 0.21; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                }
            }
            // The sleeve's shadow on the record, right where it comes out.
            Shape {
                id: sleeveShadow
                readonly property real edge: view.sleeve - record.x
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: sleeveShadow.edge
                        y1: 0
                        x2: sleeveShadow.edge + view.face.dp(16)
                        y2: 0
                        GradientStop { position: 0; color: Qt.alpha(view.vinyl, 0.85) }
                        GradientStop { position: 1; color: Qt.alpha(view.vinyl, 0) }
                    }
                    PathAngleArc { centerX: record.side / 2; centerY: record.side / 2; radiusX: record.side / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                }
            }
        }

        // The sleeve over the record's left half: the cover, square.
        IrisArtwork {
            id: cover
            width: view.sleeve
            height: view.sleeve
            source: view.face.art
            circular: false
            radius: Math.max(view.face.dp(6), Math.round(width * 0.06))
        }
    }

    // The minutes gone and the minutes left: the record's lit groove draws the same as a place.
    component Timeline: ColumnLayout {
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            FaceText {
                face: view.face
                text: StringUtils.friendlyTimeForSeconds(view.media.effectivePosition)
                color: view.face.inkTertiary
                size: 11
                font.family: view.face.fontNumbers
                font.features: ({ "tnum": 1 })
            }
            Item { Layout.fillWidth: true }
            FaceText {
                face: view.face
                text: "-" + StringUtils.friendlyTimeForSeconds(Math.max(0, view.media.effectiveLength - view.media.effectivePosition))
                color: view.face.inkTertiary
                size: 11
                font.family: view.face.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
    }

    component Keys: RowLayout {
        spacing: view.face.dp(view.wide ? 8 : 18)
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(34)
            color: "transparent"
            glyph: "skip_previous"
            name: Translation.tr("Previous")
            enabled: view.media.effectiveCanGoPrevious
            opacity: enabled ? 1 : 0.4
            onActivated: view.media.previous()
        }
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(42)
            glyph: view.face.playing ? "pause" : "play_arrow"
            name: view.face.playing ? Translation.tr("Pause") : Translation.tr("Play")
            tint: view.face.onFill(view.songLight)
            color: view.songLight
            onActivated: view.media.togglePlaying()
        }
        FaceAction {
            face: view.face
            implicitWidth: view.face.dp(34)
            color: "transparent"
            glyph: "skip_next"
            name: Translation.tr("Next")
            enabled: view.media.effectiveCanGoNext
            opacity: enabled ? 1 : 0.4
            onActivated: view.media.next()
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: view.wide ? 2 : 1
        columnSpacing: view.face.dp(14)
        rowSpacing: view.face.dp(12)
        Deck {
            Layout.alignment: view.wide ? Qt.AlignVCenter | Qt.AlignLeft : Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredWidth: implicitWidth
            Layout.preferredHeight: implicitHeight
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: view.face.dp(2)
            FaceText {
                face: view.face
                Layout.fillWidth: true
                horizontalAlignment: view.wide ? Text.AlignLeft : Text.AlignHCenter
                text: view.label ? view.face.source.toUpperCase() : view.face.source
                color: view.label ? view.face.inkSecondary : view.songLight
                size: view.label ? 10.5 : 12
                weight: Font.DemiBold
                font.family: view.label ? view.face.fontLabel : view.face.fontMain
                font.letterSpacing: view.label ? view.face.px(10.5) * 0.1 : 0
            }
            Item { Layout.fillHeight: true; visible: view.wide }
            FaceText {
                face: view.face
                Layout.fillWidth: true
                horizontalAlignment: view.wide ? Text.AlignLeft : Text.AlignHCenter
                text: view.media.effectiveTitle || view.face.source
                size: view.wide ? 14.5 : 17
                weight: Font.DemiBold
            }
            FaceText {
                face: view.face
                Layout.fillWidth: true
                horizontalAlignment: view.wide ? Text.AlignLeft : Text.AlignHCenter
                visible: text.length > 0
                text: view.media.effectiveArtist
                color: view.face.inkSecondary
                size: view.wide ? 12.5 : 13.5
            }
            Timeline {
                Layout.fillWidth: true
                Layout.topMargin: view.face.dp(view.wide ? 8 : 12)
                visible: view.media.effectiveLength > 0
            }
            Keys {
                Layout.alignment: view.wide ? Qt.AlignLeft : Qt.AlignHCenter
                Layout.leftMargin: view.wide ? -view.face.dp(6) : 0
                Layout.topMargin: view.face.dp(view.wide ? 4 : 6)
            }
            Item { Layout.fillHeight: true }
        }
    }
}
