import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
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
    signal pickGroup(string title)
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
        anchors.top: head.bottom
        anchors.bottom: parent.bottom
        width: parent.width
        contentHeight: column.implicitHeight + PrismTheme.dp(28)
        boundsBehavior: Flickable.StopAtBounds
        clip: true

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
                    width: column.width
                    PrismText {
                        topPadding: PrismTheme.dp(18)
                        bottomPadding: PrismTheme.dp(6)
                        leftPadding: PrismTheme.dp(10)
                        text: Translation.tr(group.modelData)
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption
                        font.weight: Font.DemiBold
                        font.letterSpacing: PrismTheme.caption * 0.05
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
                            PrismNavItem {
                                width: place.width
                                glyph: place.modelData.glyph
                                text: Translation.tr(place.modelData.name)
                                current: place.current
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
                                            width: partList.width
                                            height: Math.max(PrismTheme.dp(28), partName.implicitHeight + PrismTheme.dp(10))
                                            Rectangle {
                                                x: PrismTheme.dp(30)
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
                                                x: PrismTheme.dp(40)
                                                width: parent.width - x - PrismTheme.dp(8)
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: Translation.tr(part.modelData)
                                                color: part.here || partArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                                                font.pixelSize: PrismTheme.small
                                                font.weight: part.here ? Font.Medium : Font.Normal
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
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
                    font.weight: Font.DemiBold
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

    // The list fades where it meets the column's ends.
    IrisScrollEdge {
        flick: flick
        anchors.fill: flick
        blurs: false
        reach: PrismTheme.dp(24)
        veil: PrismTheme.canvas
        bottomLeftRadius: root.corner
    }
}
