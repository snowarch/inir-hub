pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// What the launcher's search finds. As a list: launchers and open windows on the page itself, or only the windows, or
// only the recent files, when that is what was asked for. As a filter: the app grid itself, narrowed in place. The search
// field keeps the keys and sends its arrows and Enter here.
Item {
    id: root

    readonly property var options: Config.options?.nihil?.results ?? ({})
    readonly property string scope: NihilState.searchScope
    readonly property bool asGrid: root.scope === "all" && (root.options.appsMode ?? "view") === "filter"
    readonly property real rowHeight: NihilStyle.s(60) + (root.options.iconSize ?? 0)
    readonly property int most: Config.options?.nihil?.search?.maxRows ?? 5
    readonly property string words: NihilState.query.trim().toLowerCase()
    readonly property bool dotted: root.words.startsWith("..")
    readonly property string sought: root.dotted ? root.words.slice(2).trim() : root.words
    readonly property string highlight: Config.options?.nihil?.overview?.highlight ?? "bold"

    readonly property var windows: {
        const only = root.scope === "windows"
        if (root.scope === "recent")
            return []
        if (!only && (!(root.options.includeWindows ?? true) || root.dotted || root.words.length === 0))
            return []
        const found = (NiriService.windows ?? [])
            .filter(win => `${win.title ?? ""} ${win.app_id ?? ""}`.toLowerCase().includes(root.words))
        return (only ? found : found.slice(0, root.most))
            .map(win => ({ kind: "window", id: win.id, name: win.title ?? "", icon: win.app_id ?? "", workspace: win.workspace_id }))
    }

    // The files the desktop remembers opening, newest first. The list is read only while this scope is open.
    property string recentXml: ""
    readonly property var recents: {
        if (root.scope !== "recent")
            return []
        const found = []
        const bookmark = /<bookmark\b([^>]*)>/g
        let match
        while ((match = bookmark.exec(root.recentXml)) !== null) {
            const href = (/href="([^"]*)"/.exec(match[1])?.[1] ?? "").replace(/&amp;/g, "&")
            if (!href.startsWith("file://"))
                continue
            const name = root.fileName(href)
            if (root.words.length > 0 && !name.toLowerCase().includes(root.words))
                continue
            found.push({ kind: "file", id: href, name: name, url: href, when: /modified="([^"]*)"/.exec(match[1])?.[1] ?? "" })
        }
        return found.sort((a, b) => b.when.localeCompare(a.when)).slice(0, 40)
    }

    readonly property var rows: {
        if (root.scope === "windows")
            return root.windows
        if (root.scope === "recent")
            return root.recents
        const apps = catalog.items.slice(0, root.most)
        return (root.options.windowsOrder ?? "last") === "first" ? [...root.windows, ...apps] : [...apps, ...root.windows]
    }
    property int current: 0

    onRowsChanged: root.current = 0

    function fileName(href: string): string {
        const last = href.split("/").pop()
        try {
            return decodeURIComponent(last)
        } catch (error) {
            return last
        }
    }

    function escaped(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    // The name with what was typed marked in it, the way the person chose to see matches.
    function marked(name: string): string {
        const at = root.sought.length > 0 && root.highlight !== "none" ? name.toLowerCase().indexOf(root.sought) : -1
        if (at < 0)
            return root.escaped(name)
        const tag = root.highlight === "underline" ? "u" : "b"
        const end = at + root.sought.length
        return `${root.escaped(name.slice(0, at))}<${tag}>${root.escaped(name.slice(at, end))}</${tag}>${root.escaped(name.slice(end))}`
    }

    function step(by: int): void {
        if (root.asGrid) {
            grid.item?.step(by)
            return
        }
        root.current = NihilStyle.clamp(root.current + by, 0, Math.max(0, root.rows.length - 1))
        list.positionViewAtIndex(root.current, ListView.Contain)
    }

    function activateFirst(): void {
        if (root.asGrid)
            grid.item?.activateFirst()
        else
            root.take(root.rows[root.current])
    }

    function take(row: var): void {
        if (!row)
            return
        const reach = root.options.activateSettings ?? "default"
        if (row.kind === "file")
            Qt.openUrlExternally(row.url)
        else if (row.kind !== "window")
            catalog.launch(row)
        else if (reach === "bring")
            NiriService.moveWindowToWorkspaceById(row.id, Number(NiriService.focusedWorkspaceId), true)
        else if (reach === "switch")
            NiriService.switchToWorkspaceById(row.workspace)
        else
            NiriService.focusWindow(row.id)
        NihilState.closeOverview()
    }

    NihilAppModel {
        id: catalog
        query: NihilState.query
    }

    FileView {
        id: recentFile
        path: root.scope === "recent"
            ? `${Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`}/recently-used.xbel` : ""
        printErrors: false
        onLoaded: root.recentXml = recentFile.text()
    }

    Loader {
        id: grid
        anchors.fill: parent
        active: root.asGrid
        sourceComponent: NihilApps { takesKeys: false }
    }

    NEmpty {
        anchors.centerIn: parent
        visible: !root.asGrid && root.rows.length === 0
        icon: root.words.length > 0 ? "search_off" : root.scope === "windows" ? "windows" : "schedule"
        title: root.words.length > 0 ? Translation.tr("Nothing found")
            : root.scope === "recent" ? Translation.tr("No recent files")
            : root.scope === "windows" ? Translation.tr("No open windows") : Translation.tr("Nothing found")
        note: root.words.length > 0 ? Translation.tr("Try another word") : ""
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows

        delegate: MouseArea {
            id: row
            required property var modelData
            required property int index
            readonly property bool marked: root.current === row.index
            readonly property bool isFile: row.modelData.kind === "file"

            width: ListView.view.width
            height: root.rowHeight
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.current = row.index
            onClicked: root.take(row.modelData)

            NInset {
                anchors.fill: parent
                radius: NihilStyle.radiusCard
                highlighted: row.marked ? 0.8 : 0
                visible: row.marked
            }
            NAppIcon {
                id: mark
                x: NihilStyle.s(14)
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.isFile
                appId: row.isFile ? "" : (row.modelData.icon || row.modelData.id)
                size: root.rowHeight - NihilStyle.s(24)
            }
            NIcon {
                anchors.centerIn: mark
                visible: row.isFile
                text: "page"
                size: NihilStyle.s(22)
                color: NihilStyle.textSecondary
            }
            NText {
                anchors.left: mark.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.right: kind.left
                anchors.rightMargin: NihilStyle.s(12)
                anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.StyledText
                text: root.marked(row.modelData.name)
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.s(16)
            }
            NText {
                id: kind
                anchors.right: parent.right
                anchors.rightMargin: NihilStyle.s(16)
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.kind === "window" || row.isFile
                text: row.isFile ? Translation.tr("Recent file") : Translation.tr("Open window")
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.textSecondary
            }
        }
    }
}
