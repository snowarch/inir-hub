pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components

// The media bubble become a card: it floats out of the bubble beside the
// Island (growing away from it, top edge level with the bubble) and collapses
// back into it. Opened from the bubble it is transient (outside click, Escape);
// pinned it stays while a player is active and yields all input but its own.
PanelWindow {
    id: root

    readonly property var bubble: GlobalStates.irisMediaBubble
    readonly property bool pinned: Config.options?.iris?.player?.cardPinned ?? false
    readonly property bool hasPlayer: MprisController.activePlayer !== null
        && String(MprisController.activePlayer?.trackTitle ?? "").length > 0
    // Only one shape at a time: an expanding Island takes the stage, and a
    // pinned card tucks into its bubble until the Island rests again.
    readonly property bool morphOpen: root.hasPlayer && root.bubble !== null
        && (GlobalStates.irisMediaCardOpen || (root.pinned && !GlobalStates.irisIslandExpanded))
    readonly property bool dismissible: GlobalStates.irisMediaCardOpen && !root.pinned
    readonly property bool barBottom: String(Config.options?.iris?.bar?.position ?? "top") === "bottom"
    readonly property real d: IrisStyle.density

    visible: root.morphOpen || card.progress > 0
    screen: Quickshell.screens.find(s => s.name === root.bubble?.screen) ?? GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:iris-media-card"
    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.keyboardFocus: root.dismissible && root.morphOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Outside clicks count only while a transient card is really presented.
    mask: root.dismissible && root.morphOpen && card.armed ? null : cardRegion
    Region { id: cardRegion; item: card }

    Binding {
        target: GlobalStates
        property: "irisMediaCardShown"
        value: root.visible
        restoreMode: Binding.RestoreValue
    }
    // A card with nothing to play has nothing to show.
    onHasPlayerChanged: if (!root.hasPlayer) GlobalStates.irisMediaCardOpen = false

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.irisMediaCardOpen = false }
    Shortcut { sequence: "Escape"; enabled: root.dismissible; onActivated: GlobalStates.irisMediaCardOpen = false }

    // The last bubble rect seen, so a card keeps its place while the Island
    // expands and the bubble tucks behind the chassis.
    property var anchorRect: null
    onBubbleChanged: if (root.bubble) root.anchorRect = root.bubble
    // Beside the Island the card grows away from it; a floating bubble grows it
    // away from the nearest screen edge instead, so it stays on screen.
    readonly property bool floatingAnchor: root.anchorRect?.floating ?? false
    readonly property real anchorCentreX: (root.anchorRect?.x ?? 0) + (root.anchorRect?.width ?? 0) / 2
    readonly property real anchorCentreY: (root.anchorRect?.y ?? 0) + (root.anchorRect?.height ?? 0) / 2
    readonly property bool growsLeft: root.floatingAnchor ? root.anchorCentreX > root.width / 2 : root.anchorCentreX < root.width / 2
    readonly property bool growsUp: root.floatingAnchor ? root.anchorCentreY > root.height / 2 : root.barBottom

    // Colour carries identity: progress wears the artwork's own hue (plain text
    // for greyscale covers), like the Island's player.
    ColorQuantizer {
        id: tintQuantizer
        source: root.hasPlayer ? MediaArtwork.displaySource : ""
        depth: 2
        rescaleSize: 48
    }
    readonly property color artTint: {
        const colors = tintQuantizer.colors ?? []
        let best = null
        let bestScore = -1
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i]
            const score = Math.max(0, c.hslSaturation) * (1 - Math.abs(c.hslLightness - 0.5))
            if (score > bestScore) { bestScore = score; best = c }
        }
        if (!best || best.hslSaturation < 0.14 || best.hslHue < 0) return IrisStyle.text
        return Qt.hsla(best.hslHue, Math.max(0.5, best.hslSaturation), Math.max(0.64, Math.min(0.76, best.hslLightness + 0.22)), 1)
    }

    // It floats over windows: a soft shadow under the resting shape, arriving
    // as the card settles so the morph itself stays one clean silhouette.
    RectangularShadow {
        x: card.x
        y: card.y + 6 * root.d
        width: card.width
        height: card.height
        radius: card.radius
        blur: 28 * root.d
        spread: -4 * root.d
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: Math.pow(Math.max(0, card.progress), 3)
    }

    IrisMorphSurface {
        id: card
        open: root.morphOpen
        contentReady: mediaCard.implicitHeight > 0
        radius: Math.round(26 * root.d)
        // Grows out of the bubble itself; the Island hides it while the card shows.
        origin: root.anchorRect
        width: Math.round(Math.min(root.width - 16, 380 * root.d))
        height: Math.round(mediaCard.implicitHeight)
        x: !root.anchorRect ? (root.width - width) / 2
            : root.growsLeft ? Math.max(8, root.anchorRect.x + root.anchorRect.width - width)
            : Math.min(root.width - width - 8, root.anchorRect.x)
        y: !root.anchorRect ? 8
            : root.growsUp ? Math.max(8, root.anchorRect.y + root.anchorRect.height - height)
            : Math.min(root.height - height - 8, root.anchorRect.y)

        MouseArea { anchors.fill: parent }

        // Vibrancy: the blurred cover fills the card, a wash of its hue glows
        // from the cover's side, and the rest melts into the black surface.
        Loader {
            anchors.fill: parent
            active: (Config.options?.iris?.player?.artworkBackground ?? true) && MediaArtwork.displaySource.length > 0
            sourceComponent: Item {
                IrisMediaBackdrop { anchors.fill: parent; source: MediaArtwork.displaySource; strength: 0.9 }
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: ColorUtils.applyAlpha(root.artTint, 0.16) }
                        GradientStop { position: 0.55; color: ColorUtils.applyAlpha(root.artTint, 0.04) }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }
            }
        }

        IrisMediaCard {
            id: mediaCard
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 4 * root.d
            anchors.rightMargin: 4 * root.d
            anchors.topMargin: 2 * root.d
            showBackground: false
            active: root.visible
            headerReserve: actions.width + 6 * root.d
            tint: root.artTint
        }

        // The frame: a hairline just inside the edge so the silhouette holds over
        // dark windows, catching a little more light along the top.
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: 1
            border.color: ColorUtils.applyAlpha(IrisStyle.text, 0.1)
        }
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - card.radius * 2
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: ColorUtils.applyAlpha(IrisStyle.text, 0.16) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        Row {
            id: actions
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 12 * root.d
            anchors.rightMargin: 12 * root.d
            spacing: 2 * root.d

            IrisIconButton {
                materialIcon: "keep"
                selected: root.pinned
                Accessible.name: root.pinned ? Translation.tr("Let the card close") : Translation.tr("Keep the card open")
                onClicked: {
                    const wasPinned = root.pinned
                    // Unpinning leaves it open until the next outside click.
                    if (wasPinned) GlobalStates.irisMediaCardOpen = true
                    Config.setNestedValue("iris.player.cardPinned", !wasPinned)
                }
            }
            IrisIconButton {
                materialIcon: "open_in_full"
                Accessible.name: Translation.tr("Open in the Island")
                onClicked: {
                    GlobalStates.irisMediaCardOpen = false
                    GlobalStates.irisIslandPageRequest = "media"
                }
            }
        }
    }
}
