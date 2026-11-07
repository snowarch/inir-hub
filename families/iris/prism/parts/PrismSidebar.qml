import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The left column: the window's lights, iRiS's mark, the search and the pages by group, then what the person pinned.
// The open page unfolds its groups under it, the sidebar's own table of contents: a long page is read a group at a
// time and a short one scrolls to the group, so nothing is ever looked for sideways (his 11-07).
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
    // The open page's groups ({ title, changed }) and the one on screen; a press asks the page for one.
    property var groups: []
    property string currentGroup: ""
    signal pickGroup(string title)
    property alias search: searchField
    // In a window the green light grows the window's column instead of the panel, and the host key reads "over the desktop".
    property bool windowed: false
    // The body's corner radius: the column draws the body's left corners itself.
    property real corner: 0

    Rectangle {
        anchors.fill: parent
        color: PrismTheme.rail
        topLeftRadius: root.corner
        bottomLeftRadius: root.corner
    }
    // The haze the reference spills from its corner, in the person's accent, filling only the column's own shape.
    PrismGlow {
        id: glow
        x: -width * 0.45
        y: -height * 0.42
        width: root.width * 2.2
        height: root.width * 2.2
        colour: PrismTheme.accent
        strength: PrismTheme.light ? 0.22 : 0.36
        area: Qt.rect(-glow.x, -glow.y, glow.width + glow.x, Math.min(root.height, glow.height + glow.y))
        corner: root.corner
    }
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: PrismTheme.line
    }

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

    property Item pending: null
    NumberAnimation { id: sideGlide; target: flick; property: "contentY"; duration: PrismTheme.ms(320); easing.type: Easing.OutCubic }
    function keepInSight(item: Item): void {
        const top = item.mapToItem(column, 0, 0).y
        const bottom = top + item.height
        const margin = PrismTheme.dp(40)
        const to = bottom + margin > flick.contentY + flick.height ? Math.min(flick.contentHeight - flick.height, bottom + margin - flick.height)
            : top - margin < flick.contentY ? Math.max(0, top - margin) : flick.contentY
        if (to === flick.contentY) return
        sideGlide.to = to
        sideGlide.restart()
    }
    Timer {
        id: revealLater
        interval: PrismTheme.ms(260) + 20
        onTriggered: {
            if (!root.pending) return
            const top = root.pending.mapToItem(column, 0, 0).y
            const bottom = top + root.pending.height + PrismTheme.dp(16)
            const to = bottom > flick.contentY + flick.height ? Math.min(flick.contentHeight - flick.height, Math.min(top - PrismTheme.dp(12), bottom - flick.height))
                : top < flick.contentY ? Math.max(0, top - PrismTheme.dp(12)) : flick.contentY
            if (to === flick.contentY) return
            sideGlide.to = to
            sideGlide.restart()
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
                    width: PrismTheme.dp(12)
                    height: width
                    radius: width / 2
                    color: light.modelData.c
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

        Row {
            topPadding: PrismTheme.dp(26)
            spacing: PrismTheme.dp(8)
            PrismGlyph {
                anchors.verticalCenter: parent.verticalCenter
                text: "tune"
                filled: true
                iconSize: PrismTheme.dp(22)
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Settings")
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -0.3
            }
        }

        Item { width: 1; height: PrismTheme.dp(22) }
        PrismField {
            id: searchField
            width: head.width - PrismTheme.dp(20)
            height: PrismTheme.dp(34)
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
                    width: column.width
                    PrismText {
                        topPadding: PrismTheme.dp(18)
                        bottomPadding: PrismTheme.dp(6)
                        text: Translation.tr(group.modelData).toUpperCase()
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }
                    Repeater {
                        model: PrismModel.inGroup(group.modelData)
                        delegate: Column {
                            id: entry
                            required property var modelData
                            readonly property bool open: !PrismState.searching && PrismState.page === entry.modelData.pageId
                            readonly property bool lists: entry.open && root.groups.length > 1
                            width: group.width
                            // A page opened from far down the list brings its groups into sight once they unfold.
                            onListsChanged: if (entry.lists) { root.pending = entry; revealLater.restart() }
                            PrismNavItem {
                                width: group.width
                                edge: group.width
                                glyph: entry.modelData.glyph
                                text: Translation.tr(entry.modelData.name)
                                current: entry.open
                                marked: entry.open && !entry.lists
                                onClicked: PrismState.go(entry.modelData.pageId)
                            }
                            // The open page's groups, unfolding under it on a hairline that hangs from its glyph.
                            Item {
                                id: toc
                                width: group.width
                                height: entry.lists ? tocColumn.implicitHeight + PrismTheme.dp(4) : 0
                                clip: true
                                Behavior on height { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
                                Rectangle {
                                    x: PrismTheme.dp(12)
                                    y: PrismTheme.dp(2)
                                    width: 1
                                    height: tocColumn.implicitHeight - PrismTheme.dp(4)
                                    color: PrismTheme.fillPress
                                }
                                Column {
                                    id: tocColumn
                                    width: parent.width
                                    Repeater {
                                        // Keyed by title: a write refreshes the dots, never the entries.
                                        model: ScriptModel { objectProp: "title"; values: entry.lists ? root.groups : [] }
                                        delegate: Item {
                                            id: chapter
                                            required property var modelData
                                            readonly property bool here: chapter.modelData.title === root.currentGroup
                                            // Reading past the index's edge brings the group being read into sight.
                                            onHereChanged: if (chapter.here && !revealLater.running) root.keepInSight(chapter)
                                            width: tocColumn.width
                                            height: PrismTheme.dp(26)
                                            PrismText {
                                                x: PrismTheme.dp(32)
                                                width: parent.width - x - PrismTheme.dp(30)
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: Translation.tr(chapter.modelData.title)
                                                elide: Text.ElideRight
                                                font.pixelSize: PrismTheme.small
                                                font.weight: chapter.here ? Font.DemiBold : Font.Normal
                                                color: chapter.here || chapterArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                                            }
                                            // A group holding something changed from the factory says so with a dot.
                                            Rectangle {
                                                visible: chapter.modelData.changed
                                                anchors.right: parent.right
                                                anchors.rightMargin: PrismTheme.dp(18)
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: PrismTheme.dp(5)
                                                height: width
                                                radius: width / 2
                                                color: PrismTheme.accent
                                            }
                                            Rectangle {
                                                x: parent.width - width
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: PrismTheme.dp(3)
                                                height: chapter.here ? PrismTheme.dp(16) : 0
                                                radius: width / 2
                                                color: PrismTheme.accent
                                                Behavior on height { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
                                            }
                                            MouseArea {
                                                id: chapterArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                Accessible.role: Accessible.Link
                                                Accessible.name: Translation.tr(chapter.modelData.title)
                                                onClicked: root.pickGroup(chapter.modelData.title)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
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
                    text: Translation.tr("Pinned").toUpperCase()
                    color: PrismTheme.ink3
                    font.pixelSize: PrismTheme.caption
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
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
        veil: PrismTheme.rail
    }
}
