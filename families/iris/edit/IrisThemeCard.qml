pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.settings

// One theme as a Small widget of iRiS wears it (his 11-02: the widgets are the look): its own plate and corners, its
// name in its accent beside a glyph, a figure in its type, and its colours drawn as Screen Time's ribbon. Tapping it
// applies the theme; Undo takes it back.
MouseArea {
    id: card

    required property var theme
    // Glass themes show this screen's wallpaper through their plate.
    property var screen: GlobalStates.focusedScreen
    readonly property real d: IrisStyle.density
    readonly property var look: IrisThemes.swatch(card.theme)
    readonly property bool current: IrisThemes.activeId === card.theme.id
    readonly property bool mine: Boolean(card.theme.user)
    readonly property var tags: Array.from(card.theme.tags ?? [])
    readonly property real s: Math.max(0.35, Math.min(1.45, card.look.shape))
    // The plate's ink follows its own surface: a light theme's card reads dark on white.
    readonly property bool lightPlate: {
        const c = card.look.surface
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b > 0.55
    }
    readonly property color ink: card.lightPlate ? "#16161a" : "#f4f4f6"
    readonly property string glyph: card.tags.includes("glass") ? "water_drop"
        : card.tags.includes("mono") || card.tags.includes("brutalist") ? "terminal"
        : card.tags.includes("anime") ? "auto_awesome"
        : card.tags.includes("film") || card.tags.includes("analog") ? "camera_roll"
        : card.tags.includes("retro") ? "bolt"
        : card.tags.includes("wallpaper") ? "wallpaper"
        : card.tags.includes("organic") ? "eco"
        : card.tags.includes("sharp") || card.tags.includes("hard") ? "diamond" : "palette"
    readonly property real pad: Math.round(14 * card.d)

    signal shareRequested()

    implicitHeight: Math.round(Math.max(132 * card.d, width * 0.66))
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: card.theme.name
    onClicked: IrisEditHistory.applyTheme(card.theme)

    Rectangle {
        id: plate
        anchors.fill: parent
        radius: Math.round(18 * card.d * Math.min(1.25, card.s))
        color: card.look.surface
        scale: card.pressed ? IrisStyle.pressScale(0.97) : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }

        // Glass themes show the desktop through their plate, as their widgets do; only they pay for a clip.
        Loader {
            anchors.fill: parent
            active: card.look.glass
            sourceComponent: ClippingRectangle {
                radius: plate.radius
                color: "transparent"
                IrisImage {
                    anchors.fill: parent
                    source: WallpaperListener.wallpaperUrlForScreen(card.screen)
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(card.look.surface, Math.max(0.5, Math.min(0.86, card.look.tint + 0.22)))
                }
            }
        }
        // Lit from above as an iRiS body is (Ricelin): one lit top edge, brighter where the theme draws a rim; hover a quiet fill.
        Rectangle {
            x: Math.round(plate.radius * 0.7)
            width: parent.width - 2 * x
            height: 1
            color: Qt.alpha(card.ink, card.look.rim ? Math.min(0.34, 0.14 * card.look.lines + 0.08) : 0.1)
        }
        Rectangle {
            anchors.fill: parent
            radius: plate.radius
            color: Qt.alpha(card.ink, card.pressed ? 0.08 : 0.05)
            visible: card.containsMouse
        }

        Row {
            id: head
            x: card.pad
            y: Math.round(12 * card.d)
            width: parent.width - 2 * card.pad
            spacing: Math.round(5 * card.d)
            MaterialSymbol {
                id: headGlyph
                anchors.verticalCenter: parent.verticalCenter
                text: card.glyph
                fill: 1
                iconSize: Math.round(15 * card.d)
                color: card.look.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: head.width - headGlyph.width - head.spacing - (tools.visible ? tools.width : 0)
                text: card.theme.name
                color: card.look.accent
                font.family: IrisStyle.fontMain
                font.pixelSize: IrisStyle.typeMeta
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        Text {
            readonly property real size: Math.round(Math.min(40 * card.d, plate.height * 0.3))
            x: card.pad - Math.round(1 * card.d)
            anchors.top: head.bottom
            anchors.topMargin: Math.round(2 * card.d)
            text: "Aa"
            color: card.ink
            font.family: card.look.titleFont
            font.pixelSize: size
            font.weight: card.look.figureWeight
            font.letterSpacing: -size * 0.03
        }

        // Its colours as Screen Time's ribbon: a quiet track, rounded segments in the theme's own hues.
        Item {
            id: ribbon
            x: card.pad
            width: parent.width - 2 * card.pad
            height: Math.round(12 * card.d)
            anchors.bottom: words.top
            anchors.bottomMargin: Math.round(8 * card.d)
            readonly property var parts: [
                { share: 0.36, tone: card.look.accent },
                { share: 0.2, tone: card.look.highlight },
                { share: 0.14, tone: Qt.tint(card.look.accent, Qt.alpha(card.look.highlight, 0.5)) },
                { share: 0.1, tone: Qt.alpha(card.ink, 0.42) }
            ]
            Rectangle {
                anchors.fill: parent
                radius: Math.round(6 * card.d * Math.min(1.2, card.s))
                color: Qt.alpha(card.ink, 0.08)
            }
            Row {
                spacing: Math.round(2 * card.d)
                Repeater {
                    model: ribbon.parts
                    Rectangle {
                        required property var modelData
                        width: Math.round(ribbon.width * modelData.share)
                        height: ribbon.height
                        radius: Math.round(4 * card.d * Math.min(1.2, card.s))
                        color: modelData.tone
                    }
                }
            }
        }

        Text {
            id: words
            x: card.pad
            width: parent.width - 2 * card.pad
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(11 * card.d)
            // What it puts on, in words: the material, the corners, the type (his 11-02: say what changes).
            text: [card.look.glass ? Translation.tr("Glass") : Translation.tr("Solid"),
                card.s < 0.75 ? Translation.tr("Sharp") : card.s > 1.15 ? Translation.tr("Round") : Translation.tr("Soft"),
                String(card.look.titleFont).split(",")[0]].join(" · ")
                + (card.mine && card.theme.author ? " · " + Translation.tr("by %1").arg(card.theme.author) : "")
            color: Qt.alpha(card.ink, 0.5)
            font.family: IrisStyle.fontMain
            font.pixelSize: IrisStyle.typeFootnote
            elide: Text.ElideRight
        }

        Row {
            id: tools
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Math.round(6 * card.d)
            spacing: Math.round(2 * card.d)
            visible: card.containsMouse
            IrisIconButton { materialIcon: "ios_share"; Accessible.name: Translation.tr("Copy to share"); onClicked: card.shareRequested() }
            IrisIconButton { visible: card.mine; materialIcon: "delete"; Accessible.name: Translation.tr("Delete"); onClicked: IrisThemes.remove(card.theme.id) }
        }
    }

    // Chosen: a ring in its accent a step outside the plate (concentric, outward), as Screen Time marks the one you are on.
    Rectangle {
        readonly property real out: Math.round(3 * card.d)
        anchors.fill: plate
        anchors.margins: -out
        radius: plate.radius + out
        color: "transparent"
        scale: plate.scale
        visible: card.current
        border.width: Math.max(2, Math.round(2 * card.d))
        border.color: card.look.accent
    }
}
