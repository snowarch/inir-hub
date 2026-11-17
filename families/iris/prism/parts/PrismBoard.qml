import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The Board's frame (his 11-17, design D3): the way back and forward, where the page stands and the search on one line,
// then the category's pages as tabs, the open one rising out of the one sheet the page is read on. The page's art lies
// across the sheet's top and fades before the modules; the page scrolls over it.
Item {
    id: root
    property alias search: searchField
    signal searchEntered()
    property var page: null
    readonly property real radius: PrismTheme.dp(26)
    readonly property real tabHeight: PrismTheme.dp(40)
    readonly property real slope: PrismTheme.dp(22)
    // Where the sheet's body starts, under the tabs, in this item's frame: the page is laid from here.
    readonly property real sheetTop: sheet.y + root.tabHeight

    readonly property bool changes: PrismState.page === "changes"
    // Changes is Home's second tab: what the person changed, beside the shell they shape (the Folders' side column
    // holds it there; the Board has no column).
    readonly property bool home: root.changes || String(root.page?.group ?? "").length === 0
    readonly property var tabs: PrismState.searching ? [{ pageId: "", name: "Search", glyph: "search" }]
        : root.home ? PrismModel.inGroup("").concat([{ pageId: "changes", name: "Changes", glyph: "history" }])
        : PrismModel.inGroup(String(root.page?.group ?? ""))
    readonly property string credit: PrismState.searching ? Translation.tr("Search")
        : root.home ? Translation.tr("Home") : Translation.tr(String(root.page.group))

    // ── The line over the sheet.
    Item {
        id: bar
        y: PrismTheme.dp(16)
        width: root.width
        height: PrismTheme.dp(36)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismRound {
                glyph: "arrow_back"
                enabled_: PrismState.canBack
                Accessible.name: Translation.tr("Back")
                onClicked: PrismState.goBack()
            }
            PrismRound {
                glyph: "arrow_forward"
                enabled_: PrismState.canForward
                Accessible.name: Translation.tr("Forward")
                onClicked: PrismState.goForward()
            }
            Item { width: PrismTheme.dp(6); height: 1 }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.credit.toUpperCase()
                mono: true
                font.pixelSize: PrismTheme.caption
                font.weight: Font.DemiBold
                font.letterSpacing: 0.9
            }
        }
        PrismField {
            id: searchField
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(PrismTheme.dp(260), root.width * 0.34)
            height: PrismTheme.dp(34)
            glyph: "search"
            placeholder: Translation.tr("Search settings")
            text: PrismState.query
            onEdited: text => PrismState.query = text
            onCommitted: text => PrismState.query = text
            onEntered: text => { PrismState.query = text; root.searchEntered() }
            Connections {
                target: searchField.input
                function onActiveFocusChanged() { if (searchField.input.activeFocus) PrismModel.searchIndex() }
            }
        }
    }

    // ── The sheet, its open tab rising out of it.
    Item {
        id: sheet
        y: bar.y + bar.height + PrismTheme.dp(10)
        width: root.width
        height: root.height - y

        readonly property Item open: {
            const _ = tabRow.children.length
            for (let i = 0; i < tabRepeater.count; ++i) {
                const tab = tabRepeater.itemAt(i)
                if (tab?.on) return tab
            }
            return tabRepeater.itemAt(0)
        }
        readonly property real openX: sheet.open ? sheet.open.x - tabFlick.contentX : 0
        readonly property real openW: sheet.open ? sheet.open.width : 0

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: PrismTheme.sunk
                strokeColor: "transparent"
                strokeWidth: -1
                PathSvg {
                    readonly property real w: sheet.width
                    readonly property real h: sheet.height
                    readonly property real a: Math.max(0, Math.min(sheet.openX, w - sheet.openW - root.slope - root.radius))
                    readonly property real t: sheet.openW
                    readonly property real k: root.tabHeight
                    readonly property real r: root.radius
                    readonly property real s: root.slope
                    readonly property string side: `L ${a + t - s * 0.15} 0 C ${a + t + s * 0.35} 0 ${a + t + s * 0.45} ${k} ${a + t + s} ${k} `
                        + `L ${w - r} ${k} Q ${w} ${k} ${w} ${k + r} L ${w} ${h - r} Q ${w} ${h} ${w - r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h - r} Z`
                    path: a < 1 ? `M 0 ${r} Q 0 0 ${r} 0 ` + side
                        : `M 0 ${k + r} Q 0 ${k} ${r} ${k} L ${a - s} ${k} C ${a - s * 0.45} ${k} ${a - s * 0.35} 0 ${a + s * 0.15} 0 ` + side
                }
            }
        }

        // The page's art across the sheet's top, fading before the modules; its corners are the sheet's.
        PrismFlow {
            y: root.tabHeight
            width: sheet.width
            height: Math.min(PrismTheme.dp(270), sheet.height - y)
            tint: String(root.page?.tint ?? "grey")
            seed: PrismModel.index(String(root.page?.pageId ?? "")) * 1.7 + 0.4
            centre: Qt.point(0.74, 0.32)
            thickness: 0.5
            fade: 0.2
            bare: true
            mute: 0.08
            strength: PrismTheme.light ? 0.55 : 0.85
            topLeftRadius: sheet.openX < 1 ? 0 : root.radius
            topRightRadius: root.radius
            visible: !PrismState.searching && !root.changes
            opacity: PrismTheme.light ? 0.6 : 0.95
        }

        Flickable {
            id: tabFlick
            width: sheet.width - root.radius
            height: root.tabHeight
            contentWidth: tabRow.width
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            interactive: contentWidth > width
            Row {
                id: tabRow
                height: root.tabHeight
                Repeater {
                    id: tabRepeater
                    model: root.tabs
                    delegate: Item {
                        id: tab
                        required property var modelData
                        readonly property bool on: root.tabs.length === 1 || tab.modelData.pageId === PrismState.page
                        width: tabLine.width + PrismTheme.dp(40)
                        height: root.tabHeight
                        onOnChanged: if (tab.on) tabFlick.contentX = Math.max(0, Math.min(tabFlick.contentWidth - tabFlick.width, tab.x - PrismTheme.dp(40)))
                        Row {
                            id: tabLine
                            anchors.centerIn: parent
                            spacing: PrismTheme.dp(8)
                            PrismGlyph {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(tab.modelData.glyph ?? "")
                                filled: tab.on
                                iconSize: PrismTheme.dp(16)
                                color: tab.on ? PrismTheme.accentInk : PrismTheme.inkNav
                            }
                            PrismText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Translation.tr(String(tab.modelData.name))
                                color: tab.on ? PrismTheme.ink : PrismTheme.inkNav
                                font.pixelSize: PrismTheme.body
                                font.weight: tab.on ? Font.Bold : Font.Medium
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: !tab.on && String(tab.modelData.pageId).length > 0
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PrismState.go(tab.modelData.pageId)
                        }
                    }
                }
            }
        }
    }
}
