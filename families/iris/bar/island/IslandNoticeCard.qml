pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.iris.style
import qs.modules.iris.components

// A notice the Island says by itself, drawn once for every place that shows one: the Island's own body, the body a
// bar hangs under its strip, and Settings' preview (the live Island sits under its window there).
// Large is Apple's expanded alert: what it is on the left (the thing itself when it can be drawn: the face, the
// headphones, the battery, the picture), what happened in the middle, its figure on the right. Compact is the line a
// bar hangs: a capsule, the words, the level. Laid once at the card's width and revealed on the body's own scalar,
// never relaid per frame.
Item {
    id: card

    // { icon, tint, title, detail, value (0..1 or -1), kind, failed, image }
    property var event: ({})
    // How far the body holding it has grown into the card (0..1).
    property real reveal: 0
    // The card is up: its ring closes and the face draws.
    property bool live: false
    property bool compact: false
    // The Island's resting thickness, its corner profile and the room it may take.
    property real band: 42
    property bool notch: false
    property real maxWidth: 460 * card.d
    property bool nothingLook: false
    property real dim: 1
    readonly property real d: IrisStyle.density

    readonly property string kind: String(card.event?.kind ?? "")
    readonly property real value: Number(card.event?.value ?? -1)
    readonly property bool battery: String(card.event?.icon ?? "").startsWith("battery") && card.value >= 0
    // Material's "lan" is a network diagram; a cable reads as the ethernet port, as the Network bubble shows it.
    readonly property string glyph: card.event?.icon === "lan" ? "settings_ethernet" : String(card.event?.icon ?? "")
    readonly property color tint: card.event?.tint ?? IrisStyle.text
    readonly property color ink: card.event?.failed || (card.nothingLook && Qt.colorEqual(card.tint, IrisStyle.danger))
        ? IrisStyle.signalInk : card.nothingLook ? IrisStyle.text : card.tint

    readonly property real cardHeight: card.compact ? card.band : Math.round(Math.max(72 * card.d, card.band * 2))
    readonly property real mark: Math.round(card.cardHeight * 0.62)
    readonly property real inset: Math.round((card.cardHeight - card.mark) / 2)
    readonly property real cardRadius: Math.min(Math.round(card.cardHeight * 0.44),
        IrisStyle.profileRadius(IrisStyle.bodyProfile(IrisStyle.barShape, card.notch), card.cardHeight))
    // Unlock is the face alone, in a square; every other card is laid from what it says.
    readonly property real cardWidth: card.compact ? Math.round(320 * card.d)
        : card.face ? card.cardHeight
        : Math.round(Math.max((card.trailWidth > 0 ? 300 : 240) * card.d, Math.min(card.maxWidth, 460 * card.d, card.wanted)))

    readonly property bool face: card.kind === "unlock" && !card.compact
    readonly property bool picture: card.kind === "shot" && String(card.event?.image ?? "").length > 0
    readonly property bool ringed: !card.battery && card.value >= 0
        && ["accessory", "kept", "soon", "done", ""].includes(card.kind)
    // A fraction that closes (an event coming, a job ending), never read as a percent.
    readonly property bool closes: card.kind === "soon" || card.kind === "kept" || card.kind === "done"
    // A headset's level reads as charge: green, red when low.
    readonly property color levelInk: card.kind === "accessory"
        ? (card.value <= 0.2 ? IrisStyle.danger : IrisStyle.success) : card.ink
    readonly property bool figured: card.battery && card.kind !== "unlock"
    readonly property bool worded: card.kind === "status" || card.kind === "quiet"
    readonly property real leadWidth: card.picture ? Math.round(card.mark * 1.42) : card.mark
    readonly property real trailWidth: card.ringed ? ring.width
        : card.figured ? figure.implicitWidth
        : card.worded ? word.implicitWidth : 0
    readonly property real gap: Math.round(14 * card.d)
    readonly property bool detailed: String(card.event?.detail ?? "").length > 0 && !card.worded
    readonly property real textWidth: Math.ceil(Math.max(title.implicitWidth, card.detailed ? detail.implicitWidth : 0))
    readonly property real wanted: 2 * card.inset + card.leadWidth + card.gap + card.textWidth
        + (card.trailWidth > 0 ? card.gap + card.trailWidth : 0) + Math.round(4 * card.d)
    // Concentric with the card's corner.
    readonly property real markRadius: Math.max(IrisStyle.radiusChip, card.cardRadius - card.inset)

    opacity: IrisStyle.contentAt(card.reveal) * card.dim * IrisStyle.recompose
    visible: opacity > 0.002

    FaceMark {
        visible: card.face
        anchors.centerIn: parent
        width: Math.round(card.cardHeight * 0.5)
        height: width
        tint: IrisStyle.identity.green
        live: card.live && card.face
    }

    // The line a bar hangs under its strip.
    RowLayout {
        visible: card.compact
        // The capsule sits concentric with the line's round end; the figure keeps a wider margin.
        x: Math.round((parent.width - card.cardWidth) / 2 + 6 * card.d)
        width: card.cardWidth - Math.round(20 * card.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(8 * card.d)
        Rectangle {
            // A screenshot is its own picture, a wider capsule.
            Layout.preferredHeight: card.band - Math.round(12 * card.d)
            Layout.preferredWidth: card.picture ? Math.round(Layout.preferredHeight * 1.42) : Layout.preferredHeight
            radius: IrisStyle.capsule(height)
            color: card.kind === "silent" ? IrisStyle.danger : card.nothingLook ? IrisStyle.fill : IrisStyle.tintFill(card.tint)
            Glyph {
                visible: !card.battery && !card.picture
                anchors.centerIn: parent
                text: card.glyph
                iconSize: Math.round(16 * card.d)
                color: card.kind === "silent" ? IrisStyle.onTintFor(IrisStyle.danger) : card.ink
            }
            ClippingRectangle {
                visible: card.picture
                anchors.fill: parent
                radius: parent.radius
                color: IrisStyle.fill
                IrisImage {
                    anchors.fill: parent
                    decodeWidth: Math.round(parent.width * 2)
                    decodeHeight: Math.round(parent.height * 2)
                    source: card.picture && card.compact ? String(card.event?.image ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                }
            }
            IrisBatteryMark {
                visible: card.battery
                anchors.centerIn: parent
                markHeight: Math.round(9 * card.d)
                level: Math.max(0, card.value)
                tint: card.ink
                frame: IrisStyle.trackOf(card.ink)
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: -1 * card.d
            IrisText {
                Layout.fillWidth: true
                text: String(card.event?.title ?? "")
                color: card.kind === "silent" ? IrisStyle.danger : IrisStyle.text
                font.pixelSize: IrisStyle.typeLabel
                font.weight: IrisStyle.weight(Font.DemiBold)
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: String(card.event?.detail ?? "")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                elide: Text.ElideRight
            }
        }
        // Its figure, small: a ring closing on an event or a job, the level in figures.
        Item {
            id: lineRing
            visible: card.ringed && card.closes
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: card.band - Math.round(18 * card.d)
            Layout.preferredHeight: Layout.preferredWidth
            ProgressRing {
                id: lineArc
                anchors.fill: parent
                stroke: Math.max(2, Math.round(3 * card.d))
                tint: card.levelInk
                progress: 0
                Binding on progress { when: card.compact && card.reveal > 0.5; value: Math.max(0, card.value) }
                Behavior on progress { NumberAnimation { duration: IrisStyle.duration(620); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve } }
            }
            Glyph {
                visible: card.kind !== "soon"
                anchors.centerIn: parent
                text: card.event?.failed ? "close" : "check"
                iconSize: Math.round(parent.height * 0.7)
                glyphWeight: Font.DemiBold
                color: card.levelInk
                opacity: lineArc.progress >= 0.98 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
            }
        }
        Metric {
            visible: card.value >= 0 && !card.closes
            Layout.alignment: Qt.AlignVCenter
            value: Math.round(card.value * 100)
            unit: "%"
            pixelSize: IrisStyle.typeBody
            weight: IrisStyle.figureWeight
            color: card.levelInk
        }
    }

    RowLayout {
        visible: !card.face && !card.compact
        x: Math.round((parent.width - width) / 2)
        width: card.cardWidth - 2 * card.inset
        anchors.verticalCenter: parent.verticalCenter
        spacing: card.gap

        // What it is.
        Item {
            Layout.preferredWidth: card.leadWidth
            Layout.preferredHeight: card.mark
            Layout.alignment: Qt.AlignVCenter
            // A tile in the notice's colour with its glyph, or the battery drawn to its level.
            Rectangle {
                visible: !["accessory", "charge", "kept"].includes(card.kind) && !card.picture
                anchors.fill: parent
                radius: card.markRadius
                color: card.kind === "silent" ? IrisStyle.danger
                    : card.nothingLook ? IrisStyle.fill : IrisStyle.tintFill(card.tint)
                Glyph {
                    visible: !card.battery
                    anchors.centerIn: parent
                    text: card.glyph
                    iconSize: Math.round(card.mark * 0.5)
                    color: card.kind === "silent" ? IrisStyle.onTintFor(IrisStyle.danger) : card.ink
                }
                IrisBatteryMark {
                    visible: card.battery
                    anchors.centerIn: parent
                    markHeight: Math.round(card.mark * 0.3)
                    level: Math.max(0, card.value)
                    tint: card.ink
                    frame: IrisStyle.trackOf(card.ink)
                }
            }
            // An accessory stands as itself, large and bare.
            Glyph {
                visible: card.kind === "accessory"
                anchors.centerIn: parent
                text: card.glyph
                iconSize: Math.round(card.mark * 0.86)
                color: IrisStyle.text
            }
            // Charging: the battery upright, filled to its level, the bolt inside.
            Rectangle {
                visible: card.kind === "charge"
                anchors.centerIn: parent
                width: Math.round(card.mark * 0.44)
                height: card.mark
                radius: Math.round(width * 0.3) // iris-literal: the battery drawn as the device, its own corners
                color: IrisStyle.trackOf(IrisStyle.identity.green)
                clip: true
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * Math.max(0.12, card.value)
                    radius: parent.radius
                    color: IrisStyle.identity.green
                }
                Glyph { anchors.centerIn: parent; text: "bolt"; iconSize: Math.round(parent.width * 0.8); color: IrisStyle.onTintFor(IrisStyle.identity.green) }
            }
            DropRadar {
                visible: card.kind === "kept"
                anchors.fill: parent
                tint: card.ink
                live: false
            }
            ClippingRectangle {
                visible: card.picture
                anchors.fill: parent
                radius: card.markRadius
                color: IrisStyle.fill
                IrisImage {
                    anchors.fill: parent
                    decodeWidth: Math.round(parent.width * 2)
                    decodeHeight: Math.round(parent.height * 2)
                    source: card.picture && !card.compact ? String(card.event?.image ?? "") : ""
                    fillMode: Image.PreserveAspectCrop
                }
            }
        }

        // What happened.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Math.round(2 * card.d)
            IrisText {
                id: title
                Layout.fillWidth: true
                text: String(card.event?.title ?? "")
                color: card.kind === "silent" ? IrisStyle.danger : IrisStyle.text
                font.pixelSize: IrisStyle.typeTitle
                font.weight: IrisStyle.weight(Font.DemiBold)
                elide: Text.ElideRight
            }
            IrisText {
                id: detail
                Layout.fillWidth: true
                visible: card.detailed
                text: String(card.event?.detail ?? "")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeLabel
                elide: Text.ElideRight
            }
        }

        // Its figure: a ring closing on it, the level, or the state in its colour.
        Item {
            id: ring
            visible: card.ringed
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.round(card.mark * 0.78)
            Layout.preferredHeight: Layout.preferredWidth
            width: Layout.preferredWidth
            readonly property color ink: card.levelInk
            ProgressRing {
                id: arc
                anchors.fill: parent
                stroke: Math.max(3, Math.round(4 * card.d))
                tint: ring.ink
                progress: 0
                Binding on progress { when: card.live && !card.compact; value: Math.max(0, card.value) }
                Behavior on progress { NumberAnimation { duration: IrisStyle.duration(620); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve } }
            }
            Tabular {
                visible: card.kind === "accessory" || card.kind === ""
                anchors.centerIn: parent
                text: Math.round(card.value * 100)
                color: IrisStyle.text
                font.pixelSize: Math.round(parent.height * 0.34)
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            Glyph {
                visible: card.kind === "kept" || card.kind === "done"
                anchors.centerIn: parent
                text: card.event?.failed ? "close" : "check"
                iconSize: Math.round(parent.height * 0.5)
                color: ring.ink
                opacity: arc.progress >= 0.98 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
            }
            Glyph {
                visible: card.kind === "soon"
                anchors.centerIn: parent
                text: "schedule"
                iconSize: Math.round(parent.height * 0.44)
                color: ring.ink
            }
        }
        Metric {
            id: figure
            visible: card.figured
            Layout.alignment: Qt.AlignVCenter
            value: Math.round(card.value * 100)
            unit: "%"
            pixelSize: IrisStyle.typeTitleL
            weight: IrisStyle.figureWeight
            color: card.ink
        }
        IrisText {
            id: word
            visible: card.worded
            Layout.alignment: Qt.AlignVCenter
            text: String(card.event?.detail ?? "")
            color: card.ink
            font.pixelSize: IrisStyle.typeTitle
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }
}
