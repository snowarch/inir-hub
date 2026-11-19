pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// NiHiL's parts over the compositor's own overview, on one screen. The compositor draws the workspaces and the live
// windows (their motion, drags between workspaces, a window opening or closing), so nothing here can lag behind them.
// This surface holds the search line, the dash and the workspace index; its input mask is only those pieces, so a
// window can be dragged anywhere around them.
PanelWindow {
    id: root

    required property var modelData
    readonly property string output: root.modelData.name
    readonly property bool focusedHere: (GlobalStates.focusedScreen?.name ?? root.output) === root.output
    readonly property bool open: NihilState.overviewOpen && NihilState.nativeStage && NiriService.inOverview
        && NihilState.view === "windows"
    property real shown: root.open ? 1 : 0
    Behavior on shown { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }

    readonly property var nihil: Config.options?.nihil
    readonly property var modules: root.nihil?.modules
    readonly property bool panelShown: (root.modules?.panel ?? true) && (root.nihil?.panel?.visibility ?? "always") !== "hidden"
    // The rail stays beside the overview, which keeps clear of its edge.
    readonly property real rail: root.panelShown ? NihilStyle.railRoom : 0
    readonly property real top: NihilStyle.railEdge === "top" ? root.rail : 0
    readonly property real bottom: NihilStyle.railEdge === "bottom" ? root.rail : 0
    readonly property real lead: NihilStyle.railEdge === "left" ? root.rail : 0
    readonly property real trail: NihilStyle.railEdge === "right" ? root.rail : 0
    readonly property real roomHeight: root.height - root.top - root.bottom
    readonly property real margin: NihilStyle.s(18)
    readonly property string dashAt: (root.modules?.dash ?? true) ? (root.nihil?.dash?.position ?? "left") : "hidden"
    readonly property bool indexShown: (root.modules?.thumbnails ?? true)
    readonly property string indexAt: root.dashAt === "right" ? "left" : "right"
    readonly property bool entryShown: (root.modules?.search ?? true) && (root.nihil?.search?.showEntry ?? true)

    readonly property var workspaces: NihilState.workspacesOn(root.output)
    readonly property int activeIndex: NihilState.activeIndexOn(root.output)
    readonly property var activeWindows: NihilState.windowsOn(root.workspaces[root.activeIndex]?.id)

    screen: root.modelData
    visible: root.open || root.shown > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:nihil-stage"
    WlrLayershell.keyboardFocus: root.open && root.focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {
        Region { item: entryGlass }
        Region { item: dash }
        Region { item: index }
    }
    BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && root.open ? glassZone : null
    Region {
        id: glassZone
        Region { item: entryGlass; radius: entryGlass.radius }
        Region { item: dash; radius: dash.radius }
    }

    onOpenChanged: if (root.open) keys.forceActiveFocus()

    function stepWindow(by: int): void {
        const list = root.activeWindows
        if (list.length === 0) return
        const at = list.findIndex(win => win.is_focused)
        NiriService.focusWindow(list[(at + by + list.length) % list.length].id)
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: root.shown

        Keys.onPressed: event => {
            const pages = root.nihil?.overview?.pageShortcuts ?? true
            switch (event.key) {
            case Qt.Key_Escape:
            case Qt.Key_Return:
            case Qt.Key_Enter: NihilState.closeOverview(); break
            case Qt.Key_Left: NiriService.focusColumnLeft(); break
            case Qt.Key_Right: NiriService.focusColumnRight(); break
            case Qt.Key_Tab: root.stepWindow(1); break
            case Qt.Key_Backtab: root.stepWindow(-1); break
            case Qt.Key_Up: NiriService.focusWorkspaceUp(); break
            case Qt.Key_Down: NiriService.focusWorkspaceDown(); break
            case Qt.Key_PageUp: if (pages) NihilState.stepWorkspace(root.output, -1); break
            case Qt.Key_PageDown: if (pages) NihilState.stepWorkspace(root.output, 1); break
            case Qt.Key_Delete: {
                const win = root.activeWindows.find(item => item.is_focused)
                if (win) NiriService.closeWindow(win.id)
                break
            }
            default:
                if ((root.modules?.search ?? true) && event.text.length === 1 && event.text.trim().length === 1
                        && !(event.modifiers & Qt.ControlModifier)) {
                    NihilState.setQuery(NihilState.query + event.text)
                    break
                }
                return
            }
            event.accepted = true
        }

        // The search line, at the head of the page.
        NGlass {
            id: entryGlass
            visible: root.entryShown
            x: root.lead + (root.width - root.lead - root.trail - width) / 2
            y: root.top + root.margin + (1 - root.shown) * -NihilStyle.s(16)
            width: NihilStyle.s(440) * (root.nihil?.search?.width ?? 1)
            height: NihilStyle.s(42)
            radius: height / 2
            tracks: true
            NField {
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                glyph: "search"
                placeholder: Translation.tr("Search apps, windows, files")
                value: NihilState.query
                onEdited: text => NihilState.setQuery(text)
            }
        }
        Dash {
            id: dash
            output: root.output
            visible: root.dashAt !== "hidden"
            room: dash.vertical ? root.roomHeight - root.margin * 2 : root.width - root.lead - root.trail - root.margin * 2
            readonly property real slide: (1 - root.shown) * NihilStyle.s(28)
            x: dash.vertical ? (root.dashAt === "left" ? root.lead + root.margin - dash.slide : root.width - root.trail - width - root.margin + dash.slide)
                : root.lead + (root.width - root.lead - root.trail - width) / 2
            y: dash.vertical ? root.top + (root.roomHeight - height) / 2
                : root.dashAt === "top" ? root.top + root.margin : root.height - root.bottom - height - root.margin + dash.slide
            onMenuAsked: (app, at) => { menu.at = at; menu.app = app }
        }

        WorkspaceIndex {
            id: index
            visible: root.indexShown
            output: root.output
            readonly property real slide: (1 - root.shown) * NihilStyle.s(28)
            x: root.indexAt === "right" ? root.width - root.trail - width - root.margin + index.slide : root.lead + root.margin - index.slide
            y: root.top + (root.roomHeight - height) / 2
        }

        DashMenu {
            id: menu
            output: root.output
        }
    }
}
