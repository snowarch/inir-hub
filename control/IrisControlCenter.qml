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

Item {
    id: root

    property var screenData: null
    readonly property string screenName: root.screenData?.name ?? ""
    readonly property var options: Config.options?.iris?.controlCenter ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barBottom: String(root.barOptions?.position ?? "top") === "bottom"
    readonly property bool morphOpen: GlobalStates.controlPanelOpen
        && root.screenName === (GlobalStates.focusedScreen?.name ?? "")
    readonly property bool armed: root.morphOpen && panel.armed
    readonly property bool present: root.morphOpen || panel.progress > 0
    readonly property alias body: panel
    readonly property var fieldShapes: {
        void (panel.x + panel.y + panel.width + panel.height + panel.progress)
        if (!root.present || panel.width < 1) return []
        const rect = panel.bodyRect
        if (rect.width <= 1 || rect.height <= 1) return []
        const shapes = [{ x: rect.x, y: rect.y, width: rect.width, height: rect.height,
            radius: rect.radius, paints: true, fuse: IrisStyle.fuseDeep, id: "control-center",
            joins: root.fromPiece ? "" : root.islandBody ? "island" : "" }]
        const neck = root.fromPiece ? IrisFrame.neck(root.origin, root.placement, rect, panel.progress) : null
        if (neck) shapes.push({ x: neck.x, y: neck.y, width: neck.width, height: neck.height, radius: 0,
            fuse: IrisFrame.neckFuse, id: "control-center-neck", joins: [root.origin.fieldId, "control-center"] })
        return shapes
    }
    readonly property var islandBody: GlobalStates.irisIslandGeometry?.[root.screenName] ?? null

    visible: root.present
    readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
        + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2)) * IrisStyle.density + 8 * IrisStyle.density
    readonly property var origin: GlobalStates.irisMorphOrigin
    readonly property bool fromPiece: root.origin?.owner === "stage" && String(root.origin?.fieldId ?? "").length > 0
    readonly property var placement: root.fromPiece
        ? IrisFrame.place(root.origin, panel.width, panel.height, root.width, root.height, panel.radius) : null
    readonly property real panelWidth: Math.min(root.width - 16, Math.max(320, Number(root.options?.width ?? 360)) * IrisStyle.density)
    readonly property real contentPadding: 16 * IrisStyle.density
    readonly property real edge: Math.round(8 * IrisStyle.density) + IrisFrame.band
    readonly property real edgeLeft: Math.round(8 * IrisStyle.density) + IrisFrame.clear("left")
    readonly property real edgeRight: Math.round(8 * IrisStyle.density) + IrisFrame.clear("right")

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
        color: IrisStyle.bodySurface
        contentReady: contents.contentHeight > 0
        radius: IrisStyle.surfaceRadius("controlCenter", IrisStyle.radiusPanel)
        onClosed: if (GlobalStates.irisMorphOwner === "stage" && !GlobalStates.settingsOverlayOpen) GlobalStates.irisMorphOwner = ""
        light: IrisStyle.surfaceLight("controlCenter", IrisStyle.wallpaperLight)
        lightFrom: root.fromPiece ? (root.placement.sideways ? (root.placement.towardsLeft ? "right" : "left") : (root.placement.towardsUp ? "bottom" : "top"))
            : root.barBottom ? "bottom" : "top"
        x: root.fromPiece ? root.placement.x
            : root.origin
            ? Math.max(root.edgeLeft, Math.min(root.width - width - root.edgeRight,
                root.origin.x + root.origin.width / 2 - width / 2))
            : (root.width - width) / 2
        y: root.fromPiece ? root.placement.y
            : root.holding ? Math.max(12, Math.min(root.heldTop, root.height - height - root.edgeGap))
            : root.barBottom ? (root.islandBody ? root.islandBody.y - height + IrisStyle.weld
                : root.height - height - root.edgeGap - IrisFrame.band)
            : (root.islandBody ? root.islandBody.y + root.islandBody.height - IrisStyle.weld
                : root.edgeGap + IrisFrame.band)
        onYChanged: if (!root.holding) root.heldTop = panel.y
        width: root.panelWidth
        height: Math.min(root.height - root.edgeGap - 12, contents.contentHeight + root.contentPadding * 2)
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
            id: contents
            anchors.fill: parent
            anchors.margins: root.contentPadding
            contentHeight: quickPanel.item?.implicitHeight ?? 0
            boundsBehavior: Flickable.StopAtBounds
            // Scroll only when capped, or a drag on a capsule becomes a flick.
            interactive: contents.contentHeight > contents.height + 1
            clip: true

            Loader {
                id: quickPanel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                sourceComponent: IrisQuickPanel { targetScreen: root.screenData }
            }
        }
    }
}
