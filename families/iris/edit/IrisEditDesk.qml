pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.field as Field
import qs.modules.iris.state

// Arranging the desktop on one output (1:1 with rin-shell's desk editor):
// left stage carries the top wallpaper strip above the shrunk live desktop card;
// right glass panel hosts the Widget Gallery / Inspector / Look / Presets in place.
PanelWindow {
    id: root

    signal gone()

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-edit"
    WlrLayershell.keyboardFocus: PolkitService.active || IrisState.menusUp > 0 ? WlrKeyboardFocus.None : bar.holdsKeyboard ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { left: true; right: true; top: true; bottom: true }

    readonly property string outputName: root.screen?.name ?? ""
    readonly property var card: DesktopEditStage.cardFor(root.outputName, root.width, root.height)
    readonly property bool leaving: !GlobalStates.widgetEditMode && !bar.shown
    onLeavingChanged: if (root.leaving) Qt.callLater(root.gone)

    mask: Region {
        item: panelHit
        Region { item: keysHit }
        Region { item: wallHit }
    }
    Item {
        id: wallHit
        x: wallStrip.hitRect.x
        y: wallStrip.hitRect.y
        width: wallStrip.hitRect.width
        height: wallStrip.hitRect.height
    }
    Item {
        id: keysHit
        readonly property rect at: chosen.item?.keysRect ?? Qt.rect(0, 0, 0, 0)
        x: keysHit.at.x
        y: keysHit.at.y
        width: keysHit.at.width
        height: keysHit.at.height
    }
    Item {
        id: panelHit
        x: bar.hitRect.x
        y: bar.hitRect.y
        width: bar.hitRect.width
        height: bar.hitRect.height
    }

    readonly property var fieldShapes: bar.fieldShapes
    Field.IrisField {
        id: field
        anchors.fill: parent
        framed: false
        compositorAllowed: true
        providesBackdrop: true
        shapes: root.fieldShapes
    }
    Field.IrisBlurRegion {
        window: root
        shapes: root.fieldShapes.filter(shape => field.glassOf(shape) === 2 && !(shape.frost < 0.5))
        windowWidth: root.width
        windowHeight: root.height
    }

    IrisEditStage {
        anchors.fill: parent
        side: "lit"
        output: root.outputName
        card: root.card
    }

    // The chosen widget's ring, name and keys, and the name of the one under the pointer, over the card at true size.
    component Outfit: Loader {
        id: outfit
        property var entry: null
        readonly property Item widget: outfit.entry?.output === root.outputName ? outfit.entry.widget : null
        active: outfit.widget !== null && GlobalStates.widgetEditMode
        x: root.card.x + (outfit.widget?.x ?? 0) * root.card.s
        y: root.card.y + (outfit.widget?.y ?? 0) * root.card.s
        width: (outfit.widget?.width ?? 0) * root.card.s
        height: (outfit.widget?.height ?? 0) * root.card.s
        sourceComponent: IrisWidgetOutfit {
            overlay: true
            widget: outfit.widget
            width: outfit.width
            height: outfit.height
            x: 0
            y: 0
            room: Qt.rect(0, wallStrip.reserveTop, Math.max(200, root.width - bar.panelReserve), Math.max(200, root.height - wallStrip.reserveTop))
        }
    }
    Outfit {
        entry: DesktopEditStage.pointed?.widget !== DesktopEditStage.chosen?.widget ? DesktopEditStage.pointed : null
    }
    Outfit {
        id: chosen
        entry: DesktopEditStage.chosen
    }

    IrisEditWallpaperStrip {
        id: wallStrip
        anchors.fill: parent
        screenData: root.screen
        panelReserve: bar.panelReserve
        presentation: bar.presentation
    }

    IrisWidgetBar {
        id: bar
        anchors.fill: parent
        screenData: root.screen
        topReserve: wallStrip.reserveTop
    }
}
