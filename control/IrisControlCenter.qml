pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

PanelWindow {
    id: root

    readonly property var options: Config.options?.iris?.controlCenter ?? ({})
    readonly property var barOptions: Config.options?.iris?.bar ?? ({})
    readonly property bool barBottom: String(root.barOptions?.position ?? "top") === "bottom"
    readonly property bool morphOpen: GlobalStates.controlPanelOpen

    visible: root.morphOpen || panel.progress > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:iris-controls"
    anchors { left: true; right: true; top: true; bottom: true }
    WlrLayershell.keyboardFocus: GlobalStates.controlPanelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // The full-screen canvas only catches outside clicks while the panel is
    // really presented. Loading, arming and collapsing yield everything but the
    // panel, so an invisible surface can never swallow the desktop's input.
    mask: root.morphOpen && panel.armed ? null : panelRegion
    Region { id: panelRegion; item: panel }
    readonly property real edgeGap: (Number(root.barOptions?.height ?? 42)
        + ((root.barOptions?.notch ?? false) ? 0 : Number(root.barOptions?.margin ?? 8) * 2)) * IrisStyle.density + 8 * IrisStyle.density
    // Hangs under the Island part that opened it.
    readonly property var origin: GlobalStates.irisMorphOrigin
    readonly property real panelWidth: Math.min(root.width - 16, Math.max(360, Number(root.options?.width ?? 380)) * IrisStyle.density)
    readonly property real contentPadding: 16 * IrisStyle.density

    MouseArea { anchors.fill: parent; onClicked: GlobalStates.controlPanelOpen = false }
    Shortcut { sequence: "Escape"; onActivated: GlobalStates.controlPanelOpen = false }

    // A panel hanging from a bottom bar grows upward, which would slide its
    // header (and the control just pressed) away. While the pointer is on it the
    // top edge holds and the bottom moves; it rests on the edge again once the
    // pointer really leaves. A shrink under a still pointer is not leaving.
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
        contentReady: contents.contentHeight > 0
        radius: Math.round(30 * IrisStyle.density)
        x: root.origin
            ? Math.max(8, Math.min(root.width - width - 8, root.origin.x + root.origin.width / 2 - width / 2))
            : (root.width - width) / 2
        y: root.holding ? Math.max(12, Math.min(root.heldTop, root.height - height - root.edgeGap))
            : root.barBottom ? root.height - height - root.edgeGap : root.edgeGap
        onYChanged: if (!root.holding) root.heldTop = panel.y
        width: root.panelWidth
        height: Math.min(root.height - root.edgeGap - 12, contents.contentHeight + root.contentPadding * 2)
        // Once presented, sections opening and closing glide on the morph curve.
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
            // Only scrolls when the panel is capped: otherwise a vertical drag on
            // a level capsule is taken as a flick and the level stops following.
            interactive: contents.contentHeight > contents.height + 1
            clip: true

            Loader {
                id: quickPanel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                sourceComponent: IrisQuickPanel { targetScreen: root.screen }
            }
        }
    }
}
