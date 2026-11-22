import QtQuick
import QtQuick.Effects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The left column, nothing in it but the way to a place: the search, the person (Home is theirs), every page under its
// category, then the rows they pinned. The open page alone wears the accent.
Item {
    id: root
    // A pinned row opens its page with the row lit.
    signal reach(var row)
    // Enter in the search: the page takes its first hit.
    signal searchEntered()
    property alias search: searchField
    // The body's corner radius: the list's fade meets the body's lower left corner.
    property real corner: 0
    // The open page's parts (its groups' names) under its line, and those the page shows now; a press goes to one.
    property var subsections: []
    property var reading: []
    // A page of a chapter is open: the other chapters step back. Home or a search: every line in full ink.
    readonly property bool located: !PrismState.searching && PrismModel.groups.some(name => name.length > 0
        && PrismModel.inGroup(name).some(page => page.pageId === PrismState.page))
    signal pickGroup(string title)
    // Where something differs from iNiR's: every page holding a change, and under the open page each group holding one.
    // Read from PrismModel.changes, which settles once a burst of writes ends; a row this machine hides is no place to go.
    readonly property var changedAt: {
        const out = ({})
        for (const row of PrismModel.changes) {
            if (!PrismModel.shown(row)) continue
            out[row.page] = true
            out[row.page + "|" + row.section] = true
        }
        return out
    }
    // The open page's line comes into sight once its parts have opened under it.
    property Item opened: null
    function reveal(): void {
        if (!root.opened) return
        const top = root.opened.mapToItem(column, 0, 0).y
        const end = top + root.opened.height
        const room = flick.height - PrismTheme.dp(28)
        let to = flick.contentY
        if (top < flick.contentY + PrismTheme.dp(12)) to = top - PrismTheme.dp(12)
        else if (end > flick.contentY + room) to = Math.min(top - PrismTheme.dp(12), end - room)
        to = Math.max(0, Math.min(flick.contentHeight - flick.height, to))
        if (Math.abs(to - flick.contentY) < 1) return
        slide.to = to
        slide.restart()
    }
    NumberAnimation { id: slide; target: flick; property: "contentY"; duration: PrismTheme.ms(300); easing.type: Easing.OutCubic }
    Timer { id: revealLater; interval: 240; onTriggered: root.reveal() }
    // Home has no line in the list: the list goes back to its top.
    Connections {
        target: PrismState
        function onPageChanged() {
            if (PrismState.page !== "general") return
            root.opened = null
            slide.to = 0
            slide.restart()
        }
    }
    readonly property real side: PrismTheme.dp(14)

    // The search and the person stay put; only the pages scroll under them.
    Column {
        id: head
        z: 1
        x: root.side
        width: root.width - 2 * root.side
        spacing: 0
        Item { width: 1; height: PrismTheme.dp(20) }
        PrismField {
            id: searchField
            width: head.width
            height: PrismTheme.dp(36)
            glyph: "search"
            placeholder: Translation.tr("Search settings")
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
        Item { width: 1; height: PrismTheme.dp(12) }
        // Home is the person's: their picture and name open it.
        Item {
            id: you
            readonly property bool current: !PrismState.searching && PrismState.page === "general"
            width: head.width
            height: PrismTheme.dp(52)
            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(12)
                color: you.current ? PrismTheme.accentPlate : youArea.pressed ? PrismTheme.fillPress : youArea.containsMouse ? PrismTheme.fill : "transparent"
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
            }
            PrismAvatar {
                id: face
                x: PrismTheme.dp(8)
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(34)
            }
            Column {
                anchors.left: face.right
                anchors.leftMargin: PrismTheme.dp(10)
                anchors.right: parent.right
                anchors.rightMargin: PrismTheme.dp(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                PrismText {
                    width: parent.width
                    text: face.name.length > 0 ? face.name : Translation.tr("Home")
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.DemiBold
                }
                PrismText {
                    width: parent.width
                    visible: face.name.length > 0
                    text: Translation.tr("Home")
                    color: you.current ? PrismTheme.accentInk : PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                }
            }
            MouseArea {
                id: youArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.PageTab
                Accessible.name: Translation.tr("Home")
                onClicked: PrismState.go("general")
            }
        }
        Item { width: 1; height: PrismTheme.dp(4) }
    }

    Flickable {
        id: flick
        // On a whole pixel: over glass the list is drawn through a layer, and a layer at a half pixel blurs its text.
        y: Math.ceil(head.height)
        height: parent.height - y
        width: parent.width
        contentHeight: column.implicitHeight + PrismTheme.dp(28)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        // Over glass the rows fade out through a mask: a band of the fill would stand darker than the glass.
        layer.enabled: listEdge.active
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: listEdge.mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        // The open page's plate, one for the list: it slides from the page left to the page opened and follows its line
        // while the parts above it fold, instead of one plate fading out as another fades in.
        Rectangle {
            id: selection
            readonly property Item at: root.opened && root.opened.current ? root.opened : null
            property Item held: null
            property bool shown: false
            onAtChanged: {
                if (!selection.at) { selection.shown = false; return }
                selection.held = selection.at
                selection.shown = true
            }
            x: column.x
            y: column.y + (selection.held ? selection.held.y + selection.held.parent.y : 0)
            width: column.width
            height: selection.held?.line?.height ?? 0
            radius: PrismTheme.dp(10)
            color: PrismTheme.accentPlate
            opacity: selection.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
            Behavior on y {
                enabled: selection.shown && PrismTheme.motion
                SmoothedAnimation { duration: PrismTheme.ms(260); velocity: -1 }
            }
        }

        Column {
            id: column
            x: root.side
            width: root.width - 2 * root.side
            spacing: 0

            Repeater {
                // Home has its own place above; every other caption with its pages.
                model: PrismModel.groups.filter(group => group.length > 0)
                delegate: Column {
                    id: group
                    required property string modelData
                    readonly property var pages: PrismModel.inGroup(group.modelData)
                    // The caption over the open page wears the accent's ink: where you stand, at two levels.
                    readonly property bool here: !PrismState.searching && group.pages.some(page => page.pageId === PrismState.page)
                    width: column.width
                    // The chapter's name, in the ink and bold, with room above it: a chapter reads as a block by its space, with
                    // no grey and no rule (his 11-21).
                    Item {
                        width: group.width
                        height: caption.implicitHeight + PrismTheme.dp(26)
                        PrismText {
                            id: caption
                            x: PrismTheme.dp(10)
                            y: PrismTheme.dp(18)
                            width: parent.width - x - PrismTheme.dp(8)
                            text: Translation.tr(group.modelData)
                            color: group.here ? PrismTheme.accentInk : PrismTheme.ink
                            font.pixelSize: PrismTheme.small
                            font.weight: Font.Bold
                            font.letterSpacing: PrismTheme.small * 0.02
                            elide: Text.ElideRight
                            Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                        }
                    }
                    Repeater {
                        model: group.pages
                        delegate: Column {
                            id: place
                            required property var modelData
                            readonly property bool current: !PrismState.searching && PrismState.page === place.modelData.pageId
                            onCurrentChanged: if (place.current) { root.opened = place; revealLater.restart() }
                            Component.onCompleted: if (place.current) { root.opened = place; revealLater.restart() }
                            width: group.width
                            readonly property Item line: navLine
                            PrismNavItem {
                                id: navLine
                                width: place.width
                                glyph: place.modelData.glyph
                                text: Translation.tr(place.modelData.name)
                                current: place.current
                                plate: false
                                changed: root.changedAt[place.modelData.pageId] === true
                                inGroup: group.here || !root.located
                                onClicked: PrismState.go(place.modelData.pageId)
                            }
                            // The page's parts, threaded under its glyph: the ones on screen wear the accent's tick.
                            Item {
                                id: parts
                                readonly property bool open: place.current && root.subsections.length > 1
                                width: place.width
                                height: parts.open ? partList.implicitHeight : 0
                                clip: true
                                Behavior on height { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
                                Rectangle {
                                    x: PrismTheme.dp(19)
                                    y: PrismTheme.dp(4)
                                    width: 1
                                    height: Math.max(0, partList.implicitHeight - PrismTheme.dp(12))
                                    color: PrismTheme.line
                                }
                                Column {
                                    id: partList
                                    width: parts.width
                                    topPadding: PrismTheme.dp(2)
                                    bottomPadding: PrismTheme.dp(6)
                                    Repeater {
                                        model: parts.open ? root.subsections : []
                                        delegate: Item {
                                            id: part
                                            required property string modelData
                                            readonly property bool here: root.reading.includes(part.modelData)
                                            readonly property bool changed: root.changedAt[PrismState.page + "|" + part.modelData] === true
                                            width: partList.width
                                            height: Math.max(PrismTheme.dp(28), partName.implicitHeight + PrismTheme.dp(10))
                                            Rectangle {
                                                x: PrismTheme.dp(32)
                                                width: parent.width - x
                                                height: parent.height
                                                radius: PrismTheme.dp(8)
                                                color: partArea.pressed ? PrismTheme.fillPress : partArea.containsMouse ? PrismTheme.fill : "transparent"
                                                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                                            }
                                            Rectangle {
                                                x: PrismTheme.dp(18)
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: PrismTheme.dp(3)
                                                height: PrismTheme.dp(14)
                                                radius: width / 2
                                                color: PrismTheme.accent
                                                opacity: part.here ? 1 : 0
                                                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                                            }
                                            PrismText {
                                                id: partName
                                                x: PrismTheme.dp(42)
                                                width: parent.width - x - (part.changed ? PrismTheme.dp(24) : PrismTheme.dp(8))
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: Translation.tr(part.modelData)
                                                color: part.here ? PrismTheme.accentInk : partArea.containsMouse ? PrismTheme.ink : PrismTheme.inkNav
                                                font.pixelSize: PrismTheme.body
                                                font.weight: part.here ? Font.DemiBold : Font.Normal
                                                Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                            }
                                            Rectangle {
                                                anchors.right: parent.right
                                                anchors.rightMargin: PrismTheme.dp(12)
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: PrismTheme.dp(5)
                                                height: width
                                                radius: width / 2
                                                visible: part.changed
                                                color: part.here || partArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                                            }
                                            MouseArea {
                                                id: partArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                Accessible.role: Accessible.Link
                                                Accessible.name: Translation.tr(part.modelData)
                                                onClicked: root.pickGroup(part.modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Rows the person keeps at hand, while there are any.
            Column {
                id: pinned
                width: column.width
                readonly property var rows: PrismModel.pinnedRows()
                visible: pinned.rows.length > 0
                PrismText {
                    topPadding: PrismTheme.dp(16)
                    bottomPadding: PrismTheme.dp(4)
                    leftPadding: PrismTheme.dp(10)
                    text: Translation.tr("Pinned")
                    color: PrismTheme.ink
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.Bold
                }
                Repeater {
                    model: ScriptModel { objectProp: "key"; values: pinned.rows }
                    delegate: PrismNavItem {
                        required property var modelData
                        width: pinned.width
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

    // The list fades where it meets the column's ends: into the fill over a solid body, through the mask over glass.
    IrisScrollEdge {
        id: listEdge
        flick: flick
        anchors.fill: flick
        blurs: false
        reach: PrismTheme.dp(24)
        veil: PrismTheme.glass ? "transparent" : PrismTheme.canvas
        bottomLeftRadius: root.corner
    }
}
