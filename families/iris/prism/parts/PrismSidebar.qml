import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The left column: the window's lights, the name, the search and the pages by group, then what the person changed and
// pinned (B · Carpeta, his 11-18 "tal cual"): one line per page, no index under it; the page's groups are its folders.
Item {
    id: root
    signal closeRequested()
    signal minimizeRequested()
    signal growRequested()
    signal switchHost()
    // A pinned row opens its page with the row lit.
    signal reach(var row)
    // Enter in the search: the page takes its first hit.
    signal searchEntered()
    property alias search: searchField
    // In a window the green light grows the window's column instead of the panel, and the host key reads "over the desktop".
    property bool windowed: false
    // The body's corner radius: the column draws the body's left corners itself.
    property real corner: 0

    // No column of its own: the pages sit on the window's own ground, beside the cards (B · Carpeta).

    // Over the desktop or as a window: one key on the lights' line, the glyph says where it goes.
    PrismRound {
        id: hostKey
        z: 2
        x: root.width - width - PrismTheme.dp(14)
        y: PrismTheme.dp(18) + PrismTheme.dp(6) - height / 2
        implicitWidth: PrismTheme.dp(26)
        glyphSize: PrismTheme.dp(15)
        glyph: root.windowed ? "picture_in_picture_center" : "open_in_new"
        onClicked: root.switchHost()
        Accessible.name: root.windowed ? Translation.tr("Over the desktop") : Translation.tr("As a window")
        PrismText {
            visible: hostKey.hovered
            anchors.right: parent.left
            anchors.rightMargin: PrismTheme.dp(6)
            anchors.verticalCenter: parent.verticalCenter
            text: root.windowed ? Translation.tr("Over the desktop") : Translation.tr("As a window")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.caption
        }
    }

    // The lights, the name and the search stay put; only the pages scroll under them.
    Column {
        id: head
        z: 1
        x: PrismTheme.dp(20)
        width: root.width - x
        spacing: 0
        // The lights: red and yellow put Settings away, green gives it the whole room (a window: its column the screen).
        Row {
            topPadding: PrismTheme.dp(18)
            spacing: PrismTheme.dp(8)
            Repeater {
                model: [{ c: "#ff5f57", g: "close" }, { c: "#febc2e", g: "remove" }, { c: "#28c840", g: root.windowed || !PrismState.wide ? "open_in_full" : "close_fullscreen" }] // iris-literal: macOS window lights
                delegate: Rectangle {
                    id: light
                    required property var modelData
                    required property int index
                    width: PrismTheme.dp(11)
                    height: width
                    radius: width / 2
                    // Grey at rest, their colours under the pointer (B · Carpeta: no colour that says nothing).
                    color: lightsHover.hovered ? light.modelData.c : PrismTheme.light ? "#c9c9ce" : "#3a3a3e" // iris-literal: the lights at rest, Prism's own grey
                    PrismGlyph {
                        anchors.centerIn: parent
                        visible: lightsHover.hovered
                        text: light.modelData.g
                        iconSize: PrismTheme.dp(9)
                        color: Qt.rgba(0, 0, 0, 0.6) // iris-literal: Prism's own fills and scrims, scheme-aware above
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -PrismTheme.dp(3)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: light.index === 0 ? root.closeRequested()
                            : light.index === 1 ? (root.windowed ? root.minimizeRequested() : root.closeRequested())
                            : root.windowed ? root.growRequested() : (PrismState.wide = !PrismState.wide)
                    }
                }
            }
            HoverHandler { id: lightsHover }
        }

        PrismText {
            topPadding: PrismTheme.dp(20)
            leftPadding: PrismTheme.dp(2)
            text: Translation.tr("Settings")
            font.pixelSize: PrismTheme.dp(21)
            font.weight: Font.Bold
            font.letterSpacing: -PrismTheme.dp(21) * 0.035
        }

        Item { width: 1; height: PrismTheme.dp(14) }
        PrismField {
            id: searchField
            width: head.width - PrismTheme.dp(12)
            height: PrismTheme.dp(32)
            glyph: "search"
            placeholder: Translation.tr("Search")
            text: PrismState.query
            onEdited: text => PrismState.query = text
            onCommitted: text => PrismState.query = text
            onEntered: text => { PrismState.query = text; root.searchEntered() }
            // The search's index is made as the field takes focus, so the first key finds it ready.
            Connections {
                target: searchField.input
                function onActiveFocusChanged() { if (searchField.input.activeFocus) PrismModel.searchIndex() }
            }
        }
        Item { width: 1; height: PrismTheme.dp(4) }
    }

    Flickable {
        id: flick
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: column.implicitHeight + PrismTheme.dp(24)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: column
            x: PrismTheme.dp(20)
            width: root.width - x
            spacing: 0

            Repeater {
                model: PrismModel.groups
                delegate: Column {
                    id: group
                    required property string modelData
                    readonly property var pages: PrismModel.inGroup(group.modelData)
                    // The caption over the open page warms with it: where you are reads at the group's level too.
                    readonly property bool here: !PrismState.searching && group.pages.some(page => page.pageId === PrismState.page)
                    width: column.width
                    PrismText {
                        visible: group.modelData.length > 0
                        topPadding: PrismTheme.dp(14)
                        bottomPadding: PrismTheme.dp(4)
                        leftPadding: PrismTheme.dp(4)
                        text: Translation.tr(group.modelData)
                        color: PrismTheme.ink
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                    Repeater {
                        model: group.pages
                        delegate: PrismNavItem {
                            id: entry
                            required property var modelData
                            width: group.width
                            edge: group.width
                            glyph: entry.modelData.glyph
                            text: Translation.tr(entry.modelData.name)
                            current: !PrismState.searching && PrismState.page === entry.modelData.pageId
                            onClicked: PrismState.go(entry.modelData.pageId)
                        }
                    }
                }
            }

            // What the person changed from the factory, a page of its own, while there is something to show.
            Column {
                id: yours
                width: column.width
                readonly property int count: PrismModel.changes.length
                visible: yours.count > 0
                PrismText {
                    topPadding: PrismTheme.dp(14)
                    bottomPadding: PrismTheme.dp(4)
                    leftPadding: PrismTheme.dp(4)
                    text: Translation.tr("Yours")
                    color: PrismTheme.ink
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                PrismNavItem {
                    width: yours.width
                    edge: yours.width
                    glyph: "history"
                    text: Translation.tr("Changes")
                    current: !PrismState.searching && PrismState.page === "changes"
                    onClicked: PrismState.go("changes")
                }
            }

            // Pinned rows: the reference's playlists, each one a row the person keeps at hand.
            Column {
                id: pinned
                width: column.width
                readonly property var rows: PrismModel.pinnedRows()
                visible: pinned.rows.length > 0
                PrismText {
                    topPadding: PrismTheme.dp(18)
                    bottomPadding: PrismTheme.dp(6)
                    text: Translation.tr("Pinned")
                    color: PrismTheme.ink
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: ScriptModel { objectProp: "key"; values: pinned.rows }
                    delegate: PrismNavItem {
                        required property var modelData
                        width: pinned.width
                        edge: pinned.width
                        glyph: modelData.glyph
                        text: Translation.tr(modelData.label)
                        trailing: "close"
                        onClicked: root.reach(modelData)
                        onTrailingClicked: PrismModel.togglePin(modelData)
                    }
                }
            }

        }
    }

    // The page list fades into the column where it meets the panel's edge.
    IrisScrollEdge {
        id: sideEdge
        flick: flick
        anchors.fill: flick
        blurs: false
        reach: PrismTheme.dp(28)
        veil: PrismTheme.canvas
        bottomLeftRadius: root.corner
    }
}
