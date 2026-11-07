import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: sidebar, the page in the middle (heading, hero, sections) and the rail. Lays itself out from the room
// it is given; the window around it only places it.
Item {
    id: root
    property bool active: true
    property string flashPath: ""
    // Hosted as a window: square corners (the compositor rounds a window), the lights act on the window, the switch
    // between hosts reads "Over the desktop".
    property bool windowed: false
    signal closeRequested()
    // The green light in a window: its column takes the screen.
    signal growRequested()

    // The other host opens on the page this one stands on.
    function switchHost(): void {
        GlobalStates.settingsOverlayRequestedKey = PrismState.page
        Config.setNestedValue("iris.appearance.settingsHost", root.windowed ? "overlay" : "window")
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (PrismState.searching) PrismState.query = ""
            else root.closeRequested()
            event.accepted = true
        } else if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            root.focusSearch()
            event.accepted = true
        } else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
            PrismState.goBack()
            event.accepted = true
        } else if (event.key === Qt.Key_Right && (event.modifiers & Qt.AltModifier)) {
            PrismState.goForward()
            event.accepted = true
        }
    }
    // Every change made here is iRiS Settings' own: the same history, the island under the page tells it and takes it back.
    Shortcut { sequences: ["Ctrl+Z"]; enabled: root.active && IrisOptions.canUndo; onActivated: IrisOptions.undo() }
    Shortcut { sequences: ["Ctrl+Shift+Z", "Ctrl+Y"]; enabled: root.active && IrisOptions.canRedo; onActivated: IrisOptions.redo() }

    readonly property var page: PrismModel.page(PrismState.page)
    readonly property bool changesView: PrismState.page === "changes"
    // A page iRiS draws as a view of its own (Community Hub, Keyboard shortcuts, About) fills the middle below its title.
    readonly property bool hosted: !PrismState.searching && !root.changesView && String(root.page.view ?? "").length > 0
    readonly property var sections: PrismState.searching || root.changesView || root.hosted ? [] : PrismModel.sectionsOf(root.page.pageId)
    // A long page is read one group at a time, picked from the strip under the hero.
    readonly property bool paged: PrismModel.paged(root.sections)
    readonly property string group: {
        const chosen = String(PrismState.groupOf[root.page.pageId] ?? "")
        return root.sections.some(section => section.title === chosen) ? chosen : String(root.sections[0]?.title ?? "")
    }
    readonly property var shownSections: root.paged ? root.sections.filter(section => section.title === root.group) : root.sections
    readonly property real sideWidth: PrismTheme.dp(232)
    readonly property real railWidth: root.width >= PrismTheme.dp(1080) ? PrismTheme.dp(300) : 0

    function focusSearch(): void { sidebar.search.input.forceActiveFocus() }
    // Reach a row: its page and group, its section unfolded, the row scrolled into view and lit once.
    function reach(row: var): void {
        if (!row) return
        PrismState.query = ""
        PrismState.go(row.page)
        PrismState.pickGroup(row.page, row.section)
        root.flashPath = row.path
        reachLater.restart()
    }
    // The page lays out first; then the row is found where it landed.
    Timer {
        id: reachLater
        interval: 60
        onTriggered: {
            const item = root.findRow(content, root.flashPath)
            if (item) {
                const y = item.mapToItem(content, 0, 0).y
                centre.contentY = Math.max(0, Math.min(centre.contentHeight - centre.height, y - centre.height * 0.35))
            }
            flashOff.restart()
        }
    }
    function findRow(item: Item, path: string): var {
        for (const child of item.children) {
            if (child.row !== undefined && child.row?.path === path && child.number !== undefined) return child
            const found = root.findRow(child, path)
            if (found) return found
        }
        return null
    }
    Timer { id: flashOff; interval: 1400; onTriggered: root.flashPath = "" }

    Connections {
        target: PrismState
        // A new area folds its fine-tune rows again; one changed while it was up stays open under the pointer.
        function onPageChanged() { centre.contentY = 0; IrisOptions.settle() }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.windowed ? 0 : PrismTheme.dp(28)
        color: PrismTheme.canvas
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: bodyShape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        PrismSidebar {
            id: sidebar
            width: root.sideWidth
            height: parent.height
            windowed: root.windowed
            onCloseRequested: root.closeRequested()
            onGrowRequested: root.growRequested()
            onSwitchHost: root.switchHost()
            onReach: row => root.reach(row)
        }

        Flickable {
            id: centre
            visible: !root.hosted
            anchors.left: sidebar.right
            anchors.right: rail.left
            height: parent.height
            contentHeight: content.implicitHeight + PrismTheme.dp(40)
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            onContentYChanged: PrismState.scrolledAt = Date.now()
            // Rows leaving the top soften into a blur and fade, and so does the foot while rows wait past it.
            layer.enabled: centreEdge.active
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: centreEdge.mask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Column {
                id: content
                x: PrismTheme.dp(32)
                width: centre.width - PrismTheme.dp(64)
                spacing: 0

                PageTop { width: content.width }

                PrismHero {
                    visible: !PrismState.searching && !root.changesView
                    width: content.width
                    page: root.page
                    number: PrismModel.index(root.page.pageId) + 1
                    count: root.sections.reduce((n, section) => n + section.rows.length, 0)
                    changed: PrismModel.changedOf(root.page.pageId)
                    restorable: PrismModel.restorableOf(root.page.pageId)
                    lead: root.page.lead.map(path => PrismModel.find(path)).filter(row => row !== null)
                    onRestore: PrismModel.restore(root.page.pageId)
                }
                Item { visible: !PrismState.searching && !root.changesView; width: 1; height: PrismTheme.dp(34) }

                // Home: the settings touched every day, as tiles that act.
                Loader {
                    active: !PrismState.searching && !root.changesView && root.page.pageId === "general"
                    visible: active
                    width: content.width
                    sourceComponent: Column {
                        width: content.width
                        PrismHome { width: parent.width; onReach: row => root.reach(row) }
                        Item { width: 1; height: PrismTheme.dp(40) }
                    }
                }

                // A search, or every change: one chart whose rows say where they live.
                Loader {
                    active: PrismState.searching || root.changesView
                    visible: active
                    width: content.width
                    sourceComponent: Column {
                        width: content.width
                        readonly property var hits: PrismState.searching ? PrismModel.search(PrismState.query) : PrismModel.changes
                        PrismText {
                            visible: parent.hits.length === 0
                            topPadding: PrismTheme.dp(12)
                            text: PrismState.searching ? Translation.tr("No setting matches that.") : Translation.tr("Everything is as it came.")
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.row
                        }
                        PrismSection {
                            visible: parent.hits.length > 0
                            width: parent.width
                            eyebrow: PrismState.searching ? Translation.tr("Settings") : Translation.tr("From the factory profile")
                            title: Translation.tr("%1 found").arg(parent.hits.length)
                            rows: parent.hits
                            showPage: true
                            tunes: false
                            fold: 100
                        }
                    }
                }

                // A long page's groups, one at a time: the strip names them all.
                Column {
                    visible: root.paged
                    width: content.width
                    PrismTabs {
                        width: parent.width
                        choices: root.sections.map(section => ({ label: section.title, value: section.title }))
                        current: root.group
                        onPicked: value => { PrismState.pickGroup(root.page.pageId, String(value)); centre.contentY = Math.min(centre.contentY, groupsAt.y) }
                    }
                    Item { id: groupsAt; width: 1; height: PrismTheme.dp(30) }
                }

                // Groups keyed by title: a write rebuilds the list, never the groups on screen.
                Repeater {
                    model: ScriptModel { objectProp: "title"; values: root.shownSections }
                    delegate: Column {
                        id: sectionBox
                        required property var modelData
                        required property int index
                        visible: sectionBox.modelData.rows.length > 0
                        width: content.width
                        PrismSection {
                            width: parent.width
                            eyebrow: Translation.tr(root.page.name)
                            title: Translation.tr(sectionBox.modelData.title)
                            rows: sectionBox.modelData.rows
                            heads: sectionBox.index === 0
                            firstNumber: 1
                            flashPath: root.flashPath
                            all: root.flashPath.length > 0 && sectionBox.modelData.rows.some(row => row.path === root.flashPath)
                        }
                        Item { width: 1; height: PrismTheme.dp(36) }
                    }
                }
            }
        }

        // A page iRiS draws itself: Prism gives it the title and the room; the view scrolls on its own.
        Item {
            id: hostedBox
            visible: root.hosted
            anchors.left: sidebar.right
            anchors.right: rail.left
            height: parent.height
            PageTop {
                id: hostedTop
                x: PrismTheme.dp(32)
                width: parent.width - PrismTheme.dp(64)
            }
            Loader {
                anchors.top: hostedTop.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                active: root.hosted
                source: root.hosted ? root.page.view : ""
            }
        }

        IrisScrollEdge {
            id: centreEdge
            flick: centre
            anchors.fill: centre
            reach: PrismTheme.dp(36)
        }

        PrismRail {
            id: rail
            anchors.right: parent.right
            width: root.railWidth
            visible: width > 0
            height: parent.height
            active: root.active
            onSeeAllChanges: PrismState.go("changes")
            onReach: row => root.reach(row)
        }

        IrisSettingsIsland {
            d: IrisStyle.settingsDensity
            room: centre.width
            allowed: root.active && !IrisOptions.homeEditing
            x: Math.round(centre.x + (centre.width - width) / 2)
            y: Math.round(body.height - height - PrismTheme.dp(22))
            z: 20
        }
    }
    // The page's top: back and forward, then where it stands and its name.
    component PageTop: Column {
        spacing: 0
        Row {
            topPadding: PrismTheme.dp(18)
            spacing: PrismTheme.dp(8)
            PrismRound { glyph: "chevron_left"; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
            PrismRound { glyph: "chevron_right"; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        }
        Item { width: 1; height: PrismTheme.dp(18) }
        PrismHeading {
            width: parent.width
            eyebrow: PrismState.searching ? Translation.tr("Search")
                : root.changesView ? Translation.tr("Yours") : Translation.tr(root.page.group)
            title: PrismState.searching ? "“" + PrismState.query.trim() + "”"
                : root.changesView ? Translation.tr("Changes") : Translation.tr(root.page.name)
        }
        Item { width: 1; height: PrismTheme.dp(18) }
    }
    Rectangle { id: bodyShape; anchors.fill: parent; radius: body.radius; visible: false; layer.enabled: true }
}
