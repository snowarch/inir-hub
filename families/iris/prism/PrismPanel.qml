import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.parts

// Prism's body: sidebar, the page in the middle (heading, hero, sections) and the rail. Lays itself out from the room
// it is given; the window around it only places it.
Item {
    id: root
    property bool active: true
    property string flashPath: ""
    signal closeRequested()

    readonly property var page: PrismModel.page(PrismState.page)
    readonly property bool changesView: PrismState.page === "changes"
    readonly property real sideWidth: PrismTheme.dp(232)
    readonly property real railWidth: root.width >= PrismTheme.dp(1080) ? PrismTheme.dp(300) : 0

    function focusSearch(): void { sidebar.search.input.forceActiveFocus() }
    // Reach a row: its page, its section unfolded, the row scrolled into view and lit once.
    function reach(row: var): void {
        if (!row) return
        PrismState.go(row.page)
        root.flashPath = row.path
        Qt.callLater(() => {
            const item = root.findRow(content, row.path)
            if (item) {
                const y = item.mapToItem(content, 0, 0).y
                centre.contentY = Math.max(0, Math.min(centre.contentHeight - centre.height, y - centre.height * 0.35))
            }
            flashOff.restart()
        })
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
        function onPageChanged() { centre.contentY = 0 }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: PrismTheme.dp(28)
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
            onCloseRequested: root.closeRequested()
        }

        Flickable {
            id: centre
            anchors.left: sidebar.right
            anchors.right: rail.left
            height: parent.height
            contentHeight: content.implicitHeight + PrismTheme.dp(40)
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: content
                x: PrismTheme.dp(32)
                width: centre.width - PrismTheme.dp(64)
                spacing: 0

                Row {
                    topPadding: PrismTheme.dp(18)
                    spacing: PrismTheme.dp(8)
                    PrismRound { glyph: "chevron_left"; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
                    PrismRound { glyph: "chevron_right"; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
                }
                Item { width: 1; height: PrismTheme.dp(18) }

                PrismHeading {
                    width: content.width
                    eyebrow: PrismState.searching ? Translation.tr("Search")
                        : root.changesView ? Translation.tr("Yours") : Translation.tr(root.page.group)
                    title: PrismState.searching ? "“" + PrismState.query.trim() + "”"
                        : root.changesView ? Translation.tr("Changes") : Translation.tr(root.page.name)
                }
                Item { width: 1; height: PrismTheme.dp(18) }

                PrismHero {
                    visible: !PrismState.searching && !root.changesView
                    width: content.width
                    page: root.page
                    number: PrismModel.index(root.page.pageId) + 1
                    count: PrismModel.rowsOf(root.page.pageId).length
                    changed: PrismModel.changedOf(root.page.pageId)
                    lead: root.page.lead.map(path => PrismModel.find(path)).filter(row => row !== null)
                    onRestore: PrismModel.restore(root.page.pageId)
                }
                Item { visible: !PrismState.searching && !root.changesView; width: 1; height: PrismTheme.dp(34) }

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
                            fold: 100
                        }
                    }
                }

                Repeater {
                    model: PrismState.searching || root.changesView ? [] : root.page.sections
                    delegate: Column {
                        id: sectionBox
                        required property var modelData
                        required property int index
                        readonly property var rows: PrismModel.rowsOf(root.page.pageId).filter(row => row.section === sectionBox.modelData.title)
                        readonly property int before: {
                            let n = 0
                            for (let i = 0; i < sectionBox.index; i++)
                                n += PrismModel.rowsOf(root.page.pageId).filter(row => row.section === root.page.sections[i].title).length
                            return n
                        }
                        visible: rows.length > 0
                        width: content.width
                        PrismSection {
                            width: parent.width
                            eyebrow: Translation.tr(root.page.name)
                            title: Translation.tr(sectionBox.modelData.title)
                            rows: sectionBox.rows
                            heads: sectionBox.index === 0
                            firstNumber: sectionBox.before + 1
                            flashPath: root.flashPath
                            all: root.flashPath.length > 0 && sectionBox.rows.some(row => row.path === root.flashPath)
                        }
                        Item { width: 1; height: PrismTheme.dp(36) }
                    }
                }
            }
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

        PrismToast {
            anchors.horizontalCenter: centre.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: PrismTheme.dp(24)
        }
    }
    Rectangle { id: bodyShape; anchors.fill: parent; radius: body.radius; visible: false; layer.enabled: true }
}
