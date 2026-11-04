pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.state

Item {
    id: root
    // The place a look is worn by (`iris.appearance.places.control`).
    readonly property string irisPlace: "control"

    property var screenData: null
    readonly property string screenName: root.screenData?.name ?? ""
    readonly property var options: Config.options?.iris?.controlCenter ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property string islandEdge: IrisFrame.islandEdge
    readonly property bool barBottom: root.islandEdge === "bottom"
    readonly property bool islandSide: root.islandEdge === "left" || root.islandEdge === "right"
    readonly property bool morphOpen: GlobalStates.controlPanelOpen
        && root.screenName === (GlobalStates.focusedScreen?.name ?? "")
        && (IrisDesign.has("controlCenter") || String(Config.options?.iris?.controlCenter?.opens ?? "island") !== "island" || IrisState.morphOwner === "stage")
    readonly property bool armed: root.morphOpen && panel.armed
    readonly property bool present: root.morphOpen || panel.progress > 0
    readonly property alias body: panel
    readonly property var fieldShapes: {
        void (panel.x + panel.y + panel.width + panel.height + panel.progress)
        if (!root.present || panel.width < 1) return []
        const rect = panel.bodyRect
        if (rect.width <= 1 || rect.height <= 1) return []
        const joinOrigin = IrisStyle.cardJoins
        const joinRise = root.fromPiece && joinOrigin && String(root.origin?.fieldId ?? "").length > 0
            ? IrisStyle.ramp(panel.progress, 0.08, 0.3) : 0
        const shapes = [{ x: rect.x, y: rect.y, width: rect.width, height: rect.height,
            radius: rect.radius, paints: true,
            fuse: root.fromPiece ? Math.round(IrisStyle.fuseDeep * joinRise) : IrisStyle.fuseDeep,
            id: "control-center", glass: IrisStyle.surfaceGlass("controlCenter"),
            joins: root.fromPiece ? (joinRise > 0 ? String(root.origin?.fieldId ?? "") : "")
                : root.islandBody && root.scene.length === 0 ? "island" : "" }]
        return shapes
    }
    readonly property var islandBody: IrisState.islandGeometry?.[root.screenName] ?? null

    visible: root.present
    readonly property real edgeGap: IrisFrame.islandVisualDepth + 8 * IrisStyle.density
    property var origin: IrisState.morphOrigin
    onMorphOpenChanged: if (root.morphOpen) root.origin = Qt.binding(() => IrisState.morphOrigin)
        else root.origin = root.origin
    readonly property bool fromPiece: root.origin?.owner === "stage" && String(root.origin?.fieldId ?? "").length > 0
    readonly property var besides: root.fromPiece ? IrisFrame.besides(root.screenName, root.origin, false) : []
    readonly property var rest: root.morphOpen ? ({ x: panel.x, y: panel.y, width: panel.width, height: panel.height }) : null
    onRestChanged: IrisFrame.publishOpen("control:" + root.screenName, root.screenName, root.rest)
    readonly property real baseRadius: IrisStyle.surfaceRadius("controlCenter", IrisStyle.radiusPanel)
    readonly property var placement: root.fromPiece
        ? IrisFrame.place(root.origin, panel.width, panel.height, root.width, root.height, root.baseRadius,
            root.besides, IrisStyle.cardJoins ? -IrisStyle.weld : Math.max(IrisFrame.bodyAir, IrisStyle.cardGap)) : null
    // The active Design may hold its own scene in this body (DESIGNS.md › Composiciones); the body stays this file's.
    readonly property string scene: IrisDesign.skin("controlCenter")
    readonly property real panelWidth: root.scene.length > 0 ? Math.min(root.width - 16, (360) * IrisStyle.density)
        : Math.min(root.width - 16, (Math.max(320, Number(root.options?.width ?? 360))
        + (IrisState.controlEdit ? IrisControlOptions.editorExtra : 0)) * IrisStyle.density)
    readonly property real contentPadding: root.scene.length > 0 ? (16) * IrisStyle.density : IrisStyle.concentricPad(IrisStyle.surfaceRadius("controlCenter", IrisStyle.radiusPanel), 16 * IrisStyle.density)
    // How far the body hangs from the Island: welded into it in iRiS, apart from it when a Design says so.
    readonly property real hang: root.scene.length > 0 ? (-IrisStyle.weld / IrisStyle.density) * IrisStyle.density : -IrisStyle.weld
    readonly property real edge: Math.round(8 * IrisStyle.density) + IrisFrame.band
    readonly property real edgeLeft: Math.round(8 * IrisStyle.density) + IrisFrame.safeInset("left")
    readonly property real edgeRight: Math.round(8 * IrisStyle.density) + IrisFrame.safeInset("right")

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.controlPanelOpen = false }
    Shortcut { sequence: "Escape"; onActivated: GlobalStates.controlPanelOpen = false }

    property bool engaged: false
    property real heldTop: 0
    readonly property bool holding: root.barBottom && root.engaged && panel.settled
    HoverHandler {
        property point last: Qt.point(-1, -1)
        onHoveredChanged: if (!hovered) root.engaged = false
        onPointChanged: {
            const p = point.position
            if (Math.abs(p.x - last.x) + Math.abs(p.y - last.y) > 2) {
                last = p
                root.engaged = panelHover.hovered
            }
        }
    }

    IrisMorphSurface {
        id: panel
        open: root.morphOpen
        motionSurface: "controlCenter"
        settles: true
        color: IrisStyle.bodySurface
        fieldBacked: true
        contentReady: contents.contentHeight > 0
        radius: root.baseRadius
        corners: root.placement && !IrisStyle.cardJoins
            ? IrisFrame.nestRadius({ x: root.placement.x, y: root.placement.y, width: panel.width, height: panel.height },
                root.baseRadius, root.origin?.obstacle ?? root.origin, Number(root.origin?.nestFuse ?? IrisStyle.fuse), root.width, root.height, root.besides)
            : null
        origin: root.fromPiece ? root.origin : null
        onClosed: if (IrisState.morphOwner === "stage" && !GlobalStates.settingsOverlayOpen) IrisState.morphOwner = ""
        light: IrisStyle.surfaceLight("controlCenter", IrisStyle.wallpaperLight)
        lightFrom: root.placement ? (root.placement.sideways ? (root.placement.towardsLeft ? "right" : "left") : (root.placement.towardsUp ? "bottom" : "top"))
            : root.islandSide ? root.islandEdge : root.barBottom ? "bottom" : "top"
        x: root.placement ? root.placement.x
            : root.islandSide && root.islandBody ? (root.islandEdge === "left"
                ? root.islandBody.x + root.islandBody.width - IrisStyle.weld
                : root.islandBody.x - width + IrisStyle.weld)
            : root.origin
            ? Math.max(root.edgeLeft, Math.min(root.width - width - root.edgeRight,
                root.origin.x + root.origin.width / 2 - width / 2))
            : (root.width - width) / 2
        y: root.placement ? root.placement.y
            : root.holding ? Math.max(12, Math.min(root.heldTop, root.height - height - root.edgeGap))
            : root.islandSide ? Math.round(Math.max(IrisFrame.safeInset("top") + root.edge, Math.min(root.height - height - IrisFrame.safeInset("bottom") - root.edge,
                (root.origin ? root.origin.y + root.origin.height / 2 : (root.islandBody ? root.islandBody.y + root.islandBody.height / 2 : root.height / 2)) - height / 2)))
            : root.barBottom ? (root.islandBody ? root.islandBody.y - height - root.hang
                : root.height - height - root.edgeGap - IrisFrame.band)
            : (root.islandBody ? root.islandBody.y + root.islandBody.height + root.hang
                : root.edgeGap + IrisFrame.band)
        onYChanged: if (!root.holding) root.heldTop = panel.y
        width: root.panelWidth
        readonly property real room: {
            const top = IrisFrame.safeInset("top") + Math.round(8 * IrisStyle.density)
            const bottom = IrisFrame.safeInset("bottom") + Math.round(8 * IrisStyle.density)
            const body = root.islandBody
            if (root.placement || root.islandSide || !body) return root.height - top - bottom
            return root.barBottom ? body.y - top : root.height - (body.y + body.height) - bottom
        }
        height: Math.min(panel.room, contents.contentHeight + root.contentPadding * 2)
        Behavior on y {
            enabled: panel.settled
            NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
        }
        Behavior on height {
            enabled: panel.settled
            NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
        }

        MouseArea { anchors.fill: parent }
        HoverHandler { id: panelHover; onHoveredChanged: if (hovered) root.engaged = true }

        Flickable {
            IrisScrollFeel {}
            id: contents
            anchors.fill: parent
            anchors.margins: root.contentPadding
            contentHeight: (root.scene.length > 0 ? designScene.item?.implicitHeight : quickPanel.item?.implicitHeight) ?? 0
            // Scroll only when capped, or a drag on a capsule becomes a flick.
            interactive: contents.contentHeight > contents.height + 1
            clip: true

            Loader {
                id: quickPanel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                active: root.scene.length === 0
                sourceComponent: IrisQuickPanel { targetScreen: root.screenData; bodyRadius: root.baseRadius; bodyInset: root.contentPadding }
            }
            Loader {
                id: designScene
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                active: root.scene.length > 0
                source: root.scene
                onLoaded: item.targetScreen = Qt.binding(() => root.screenData)
            }
        }
    }
}
