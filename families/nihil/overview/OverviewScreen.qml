pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// NiHiL's own overview on one screen, where the compositor's is not used: dash, workspace strip, the workspaces in the
// centre and the search above them. What is typed opens the launcher, a page of the sheet.
PanelWindow {
    id: root

    required property var modelData
    readonly property string output: root.modelData.name
    readonly property bool primary: Quickshell.screens[0]?.name === root.output
    readonly property bool focusedHere: (GlobalStates.focusedScreen?.name ?? root.output) === root.output
    readonly property bool open: NihilState.overviewOpen && !NihilState.nativeStage && NihilState.view === "windows"
    property real shown: root.open ? 1 : 0
    Behavior on shown { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }

    readonly property var nihil: Config.options?.nihil
    readonly property var modules: root.nihil?.modules
    readonly property var thumbs: root.nihil?.thumbnails

    readonly property string dashAt: (root.modules?.dash ?? true) ? (root.nihil?.dash?.position ?? "left") : "hidden"
    readonly property string thumbsAt: {
        if (!(root.modules?.thumbnails ?? true)) return "hidden"
        const main = root.thumbs?.position ?? "right"
        const other = root.thumbs?.secondaryPosition ?? "same"
        if (root.primary || other === "same") return main
        if (other === "hidden") return "hidden"
        const sideways = main === "left" || main === "right"
        return other === "start" ? (sideways ? "left" : "top") : (sideways ? "right" : "bottom")
    }
    readonly property bool thumbsVertical: root.thumbsAt === "left" || root.thumbsAt === "right"
    readonly property real thumbScale: root.primary ? (root.thumbs?.scale ?? 0.13) : (root.thumbs?.secondaryScale ?? 0.1)
    readonly property bool stripShown: root.thumbsAt !== "hidden" && root.thumbScale > 0
    readonly property real stripAdjust: root.primary ? (root.thumbs?.adjust ?? 0) : (root.thumbs?.secondaryAdjust ?? 0)
    readonly property real screenW: root.modelData.width
    readonly property real screenH: root.modelData.height
    readonly property real screenAspect: root.screenW / Math.max(1, root.screenH)
    readonly property real thumbW: Math.round(root.width * root.thumbScale)
    readonly property real thumbH: Math.round(root.thumbW / root.screenAspect)
    readonly property real margin: NihilStyle.s(14)
    readonly property bool panelShown: (root.modules?.panel ?? true) && (root.nihil?.panel?.visibility ?? "always") !== "hidden"
    readonly property bool panelBottom: (root.nihil?.panel?.position ?? "top") === "bottom"
    // The panel stays above the overview, which starts where it ends.
    readonly property real barTop: root.panelShown && !root.panelBottom ? NihilStyle.barHeight : 0
    readonly property real barEnd: root.panelShown && root.panelBottom ? NihilStyle.barHeight : 0
    readonly property bool entryShown: (root.modules?.search ?? true) && (root.nihil?.search?.showEntry ?? true)

    readonly property var workspaces: NihilState.workspacesOn(root.output)
    readonly property int activeIndex: NihilState.activeIndexOn(root.output)
    readonly property var activeWindows: NihilState.windowsOn(root.workspaces[root.activeIndex]?.id)
    property int selected: -1
    readonly property string selectedKey: root.selected >= 0 ? String(root.activeWindows[root.selected]?.id ?? "") : ""

    screen: root.modelData
    visible: root.open || root.shown > 0.001
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:nihil-overview"
    WlrLayershell.keyboardFocus: root.open && root.focusedHere ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    margins { top: root.barTop; bottom: root.barEnd }

    onOpenChanged: {
        if (!root.open) return
        root.selected = root.firstSelection()
        keys.forceActiveFocus()
    }
    function firstSelection(): int {
        const list = root.activeWindows
        switch (root.nihil?.overview?.selectWindow ?? "pointer") {
        case "first": return list.length > 0 ? 0 : -1
        case "focused": return list.findIndex(win => win.is_focused)
        case "previous": {
            const recent = NiriService.mruWindowIds ?? []
            return list.findIndex(win => win.id === recent[1])
        }
        }
        return -1
    }

    function focusWindow(win: var): void {
        NiriService.focusWindow(win.id)
        NihilState.closeOverview()
    }
    function moveSelection(by: int): void {
        const count = root.activeWindows.length
        if (count > 0) root.selected = (root.selected + by + count) % count
    }
    // Leaving the overview, with the selected window taken along if the person asked for that.
    function leave(): void {
        const win = root.activeWindows[root.selected]
        if ((root.nihil?.overview?.alwaysActivateSelected ?? false) && win) root.focusWindow(win)
        else NihilState.closeOverview()
    }
    function stepBack(): void {
        root.leave()
    }

    // The room the side strips leave for the centre.
    readonly property real stripRoomW: root.stripShown && root.thumbsVertical ? root.thumbW + root.margin : 0
    readonly property real stripRoomH: root.stripShown && !root.thumbsVertical ? root.thumbH + root.margin : 0
    readonly property real topRoom: root.margin + (root.dashAt === "top" ? dash.height + root.margin : 0)
        + (root.thumbsAt === "top" ? root.stripRoomH : 0) + (root.entryShown ? entryGlass.height + root.margin : 0)
    readonly property real bottomRoom: root.margin + (root.dashAt === "bottom" ? dash.height + root.margin : 0)
        + (root.thumbsAt === "bottom" ? root.stripRoomH : 0)
    readonly property real leftRoom: root.margin + (root.dashAt === "left" ? dash.width + root.margin : 0)
        + (root.thumbsAt === "left" ? root.stripRoomW : 0)
    readonly property real rightRoom: root.margin + (root.dashAt === "right" ? dash.width + root.margin : 0)
        + (root.thumbsAt === "right" ? root.stripRoomW : 0)

    // The desktop behind everything: the wallpaper, as blurred and dimmed as the view asks.
    readonly property string backdropMode: root.nihil?.overview?.background ?? "blurSmooth"
    readonly property bool backdropBlurred: root.backdropMode === "blurFast" || root.backdropMode === "blurSmooth"
    readonly property real brightness: root.nihil?.overview?.backgroundBrightness ?? 0.5
    Image {
        id: backdrop
        anchors.fill: parent
        visible: root.backdropMode === "desktop"
        opacity: root.shown
        source: root.backdropMode === "transparent" ? "" : Wallpapers.effectiveWallpaperUrl
        sourceSize.width: root.backdropMode === "blurFast" ? 960 : 1920
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: root.backdropBlurred
        source: backdrop
        opacity: root.shown
        blurEnabled: true
        blurMax: root.backdropMode === "blurFast" ? 32 : 64
        blur: (root.nihil?.overview?.backgroundBlur ?? 1) * ((root.nihil?.overview?.smoothAnimation ?? true) ? root.shown : 1)
    }
    Rectangle {
        anchors.fill: parent
        visible: root.backdropMode !== "transparent"
        color: "#000000"
        opacity: root.shown * (1 - root.brightness)
        Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: root.shown

        MouseArea {
            anchors.fill: parent
            onClicked: if (root.nihil?.overview?.closeOnEmptyClick ?? true) root.leave()
            onWheel: wheel => NihilState.stepWorkspace(root.output, wheel.angleDelta.y > 0 ? -1 : 1)
        }

        Keys.onPressed: event => {
            const pages = root.nihil?.overview?.pageShortcuts ?? true
            switch (event.key) {
            case Qt.Key_Escape: root.stepBack(); break
            case Qt.Key_Tab:
            case Qt.Key_Right:
            case Qt.Key_Down: root.moveSelection(1); break
            case Qt.Key_Backtab:
            case Qt.Key_Left:
            case Qt.Key_Up: root.moveSelection(-1); break
            case Qt.Key_PageUp: if (pages) NihilState.stepWorkspace(root.output, -1); break
            case Qt.Key_PageDown: if (pages) NihilState.stepWorkspace(root.output, 1); break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (root.activeWindows[root.selected]) root.focusWindow(root.activeWindows[root.selected])
                break
            case Qt.Key_Delete:
                if (root.activeWindows[root.selected]) NiriService.closeWindow(root.activeWindows[root.selected].id)
                break
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

        // The workspaces, stacked along the strip's axis, the active one in the centre.
        Item {
            id: stage
            readonly property real fit: root.primary ? (root.nihil?.stage?.scale ?? 0.95) : (root.nihil?.stage?.secondaryScale ?? 0.95)
            // Other screens may centre on the screen instead of on what the strip leaves.
            readonly property bool shifted: root.primary || (root.nihil?.stage?.secondaryShift ?? true)
            readonly property real roomLeft: shifted ? root.leftRoom : Math.max(root.leftRoom, root.rightRoom)
            readonly property real roomRight: shifted ? root.rightRoom : Math.max(root.leftRoom, root.rightRoom)
            readonly property real boxW: root.width - roomLeft - roomRight
            readonly property real boxH: root.height - root.topRoom - root.bottomRoom
            readonly property real pageScale: Math.min(boxW / root.screenW, boxH / root.screenH) * fit
            readonly property real spacing: root.nihil?.stage?.spacing ?? 30
            x: roomLeft + (boxW - width) / 2
            y: root.topRoom + (boxH - height) / 2
            width: root.screenW * pageScale
            height: root.screenH * pageScale

            Repeater {
                model: root.workspaces
                WorkspacePage {
                    id: page
                    required property var modelData
                    required property int index
                    readonly property int away: page.index - root.activeIndex
                    readonly property real step: (root.thumbsVertical ? stage.height : stage.width) + stage.spacing
                    workspace: page.modelData
                    screenWidth: root.screenW
                    width: stage.width
                    height: stage.height
                    x: root.thumbsVertical ? 0 : page.away * page.step
                    y: root.thumbsVertical ? page.away * page.step : 0
                    current: page.away === 0
                    built: Math.abs(page.away) <= 1
                    open: root.open
                    visible: page.away === 0 || (Math.abs(page.away) === 1 && (root.nihil?.stage?.adjacent ?? true))
                    selectedKey: page.away === 0 ? root.selectedKey : ""
                    onWindowActivated: win => root.focusWindow(win)
                    onEmptyClicked: {
                        if (page.away !== 0) NiriService.switchToWorkspaceById(page.modelData.id)
                        else if (root.nihil?.overview?.closeOnEmptyClick ?? true) root.leave()
                    }
                    Behavior on x { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }
                    Behavior on y { NumberAnimation { duration: NihilStyle.slow; easing.type: Easing.OutQuint } }
                }
            }
        }

        // The strip's glass, along its edge or just behind it.
        NGlass {
            visible: root.stripShown && (root.thumbs?.background ?? false)
            readonly property bool full: root.thumbs?.fullLength ?? false
            readonly property real pad: NihilStyle.s(8)
            x: root.thumbsVertical ? strip.x - pad : full ? root.margin : strip.x - pad
            y: root.thumbsVertical ? (full ? root.margin : strip.y - pad) : strip.y - pad
            width: root.thumbsVertical ? strip.width + pad * 2 : full ? root.width - root.margin * 2 : strip.width + pad * 2
            height: root.thumbsVertical ? (full ? root.height - root.margin * 2 : strip.height + pad * 2)
                : strip.height + pad * 2
            radius: NihilStyle.rPanel
        }

        // The workspace strip.
        Grid {
            id: strip
            visible: root.stripShown
            rows: root.thumbsVertical ? -1 : 1
            columns: root.thumbsVertical ? 1 : -1
            spacing: NihilStyle.s(10)
            readonly property real dashLeft: root.dashAt === "left" ? dash.width + root.margin : 0
            readonly property real dashRight: root.dashAt === "right" ? dash.width + root.margin : 0
            readonly property real dashTop: root.dashAt === "top" ? dash.height + root.margin : 0
            readonly property real dashBottom: root.dashAt === "bottom" ? dash.height + root.margin : 0
            x: root.thumbsVertical
                ? (root.thumbsAt === "left" ? root.margin + dashLeft : root.width - width - root.margin - dashRight)
                : (root.width - width) / 2 * (1 + root.stripAdjust)
            y: root.thumbsVertical
                ? root.topRoom + (root.height - root.topRoom - root.bottomRoom - height) / 2 * (1 + root.stripAdjust)
                : root.thumbsAt === "top" ? root.margin + dashTop
                : root.height - height - root.margin - dashBottom
            Repeater {
                model: root.stripShown ? root.workspaces : []
                WorkspaceThumb {
                    required property var modelData
                    required property int index
                    workspace: modelData
                    number: index + 1
                    width: root.thumbW
                    height: root.thumbH
                    open: root.open
                }
            }
        }

        Dash {
            id: dash
            output: root.output
            visible: root.dashAt !== "hidden"
            room: dash.vertical ? root.height - root.margin * 2 : root.width - root.margin * 2
            readonly property real adjust: root.nihil?.dash?.adjust ?? 0
            readonly property bool followStage: root.nihil?.dash?.centerToWorkspaces ?? false
            readonly property real centreX: dash.followStage ? stage.x + stage.width / 2 : root.width / 2
            readonly property real centreY: dash.followStage ? stage.y + stage.height / 2
                : root.height / 2
            x: dash.vertical ? (root.dashAt === "left" ? root.margin : root.width - width - root.margin)
                : NihilStyle.clamp(centreX - width / 2 + (root.width - width) / 2 * dash.adjust, root.margin, root.width - width - root.margin)
            y: dash.vertical ? NihilStyle.clamp(centreY - height / 2 + (root.height - height) / 2 * dash.adjust, root.margin,
                    root.height - height - root.margin)
                : root.dashAt === "top" ? root.margin : root.height - height - root.margin
            onMenuAsked: (app, at) => { menu.at = at; menu.app = app }
        }

        NGlass {
            id: entryGlass
            visible: root.entryShown
            readonly property bool centred: root.nihil?.search?.center ?? true
            x: centred ? (root.width - width) / 2 : stage.x + (stage.width - width) / 2
            y: root.margin + (root.dashAt === "top" ? dash.height + root.margin : 0)
                + (root.thumbsAt === "top" ? root.stripRoomH : 0)
            width: NihilStyle.s(420) * (root.nihil?.search?.width ?? 1)
            height: NihilStyle.s(42)
            radius: height / 2
            tracks: true
            ignite: entry.typing ? 0.6 : 0

            NField {
                id: entry
                anchors.fill: parent
                color: "transparent"
                radius: parent.radius
                glyph: "search"
                placeholder: Translation.tr("Type to search")
                value: NihilState.query
                onEdited: text => NihilState.setQuery(text)
            }
        }

        DashMenu {
            id: menu
            output: root.output
        }
    }
}
