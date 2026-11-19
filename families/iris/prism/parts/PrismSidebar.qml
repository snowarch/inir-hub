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
                        delegate: PrismNavItem {
                            id: entry
                            required property var modelData
                            width: group.width
                            glyph: entry.modelData.glyph
                            text: Translation.tr(entry.modelData.name)
                            current: !PrismState.searching && PrismState.page === entry.modelData.pageId
                            onClicked: PrismState.go(entry.modelData.pageId)
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
