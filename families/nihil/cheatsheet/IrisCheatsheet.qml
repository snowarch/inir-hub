pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.components
import "../../shared/cheatsheet/periodic_table.js" as PTable

// The keybinds and the elements on one printed sheet: three lanes of ruled groups, the keys boxed, and the table of
// elements as a grid of cells that invert under the pointer.
Scope {
    id: root

    readonly property real d: IrisStyle.density
    property int page: 0
    property string query: ""
    property var element: null

    readonly property var keybinds: CompositorService.isNiri ? NiriKeybinds.keybinds : HyprlandKeybinds.keybinds
    readonly property var shown: {
        const q = root.query.trim().toLowerCase()
        const out = []
        for (const cat of (root.keybinds?.children ?? [])) {
            const name = String(cat.name ?? "")
            const rows = (cat.children?.[0]?.keybinds ?? []).filter(kb => q.length === 0
                || String(kb.key ?? "").toLowerCase().includes(q)
                || (kb.mods ?? []).some(m => String(m).toLowerCase().includes(q))
                || String(kb.comment ?? "").toLowerCase().includes(q)
                || name.toLowerCase().includes(q))
            if (rows.length > 0) out.push({ name: name, rows: rows })
        }
        return out
    }
    // Each group goes to the shortest lane.
    readonly property var lanes: {
        const lanes = [[], [], []], loads = [0, 0, 0]
        for (const group of root.shown) {
            const at = loads.indexOf(Math.min(...loads))
            lanes[at].push(group)
            loads[at] += group.rows.length + 2
        }
        return lanes
    }

    readonly property var names: ({ "mouse_up": "Scroll ↓", "mouse_down": "Scroll ↑", "mouse:272": "LMB", "mouse:273": "RMB",
        "mouse:275": "Back", "Slash": "/", "Hash": "#", "Return": "Enter" })
    function keysOf(kb: var): var {
        return [...(kb.mods ?? []), kb.key].filter(k => k && k !== "Super_L").map(k => root.names[k] ?? String(k))
    }
    function close(): void { GlobalStates.cheatsheetOpen = false }

    component Tab: Rectangle {
        id: tab
        required property string label
        required property int index
        readonly property bool here: root.page === tab.index
        implicitWidth: tabLabel.implicitWidth + Math.round(24 * root.d)
        implicitHeight: Math.round(30 * root.d)
        color: tab.here ? IrisStyle.text : tabArea.containsMouse ? IrisStyle.fillHover : IrisStyle.surfaceOpaque
        border.width: IrisStyle.edgeWidth
        border.color: IrisStyle.text
        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: tab.label
            color: tab.here ? IrisStyle.surfaceOpaque : IrisStyle.text
            font.family: IrisStyle.fontMono
            font.pixelSize: Math.round(20 * root.d)
        }
        MouseArea {
            id: tabArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: tab.label
            onClicked: root.page = tab.index
        }
    }

    PanelWindow {
        id: window
        visible: GlobalStates.cheatsheetOpen
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "quickshell:cheatsheet"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }
        onVisibleChanged: if (visible) search.forceActiveFocus()

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            x: sheet.x + IrisStyle.shadowThrow
            y: sheet.y + IrisStyle.shadowThrow
            width: sheet.width
            height: sheet.height
            color: IrisStyle.text
        }
        Rectangle {
            id: sheet
            anchors.centerIn: parent
            width: Math.min(parent.width - Math.round(64 * root.d), Math.round(1280 * root.d))
            height: Math.min(parent.height - Math.round(64 * root.d), Math.round(820 * root.d))
            color: IrisStyle.surfaceOpaque
            border.width: IrisStyle.edgeWidth
            border.color: IrisStyle.text
            readonly property real pad: Math.round(18 * root.d)

            MouseArea { anchors.fill: parent }
            Keys.forwardTo: [search]

            IrisWindowBar {
                id: bar
                width: parent.width
                title: root.page === 0 ? Translation.tr("Keybinds") : Translation.tr("Elements")
            }

            Row {
                id: tabs
                x: sheet.pad
                y: bar.height + sheet.pad
                spacing: Math.round(6 * root.d)
                Tab { index: 0; label: Translation.tr("Keybinds") }
                Tab { index: 1; label: Translation.tr("Elements") }
            }

            Rectangle {
                visible: root.page === 0
                anchors.right: closeKey.left
                anchors.rightMargin: Math.round(6 * root.d)
                y: tabs.y
                width: Math.round(280 * root.d)
                height: closeKey.height
                color: IrisStyle.surfaceOpaque
                border.width: IrisStyle.edgeWidth
                border.color: IrisStyle.text
                TextInput {
                    id: search
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(10 * root.d)
                    anchors.rightMargin: Math.round(10 * root.d)
                    verticalAlignment: TextInput.AlignVCenter
                    color: IrisStyle.text
                    selectionColor: IrisStyle.text
                    selectedTextColor: IrisStyle.surfaceOpaque
                    font.family: IrisStyle.fontMono
                    font.pixelSize: Math.round(20 * root.d)
                    clip: true
                    text: root.query
                    onTextChanged: root.query = text
                    Keys.onEscapePressed: event => {
                        if (search.text.length > 0) search.text = ""
                        else root.close()
                        event.accepted = true
                    }
                    Accessible.name: Translation.tr("Search")
                }
                Text {
                    visible: search.text.length === 0
                    anchors.fill: search
                    verticalAlignment: Text.AlignVCenter
                    text: Translation.tr("Search")
                    color: IrisStyle.textTertiary
                    font: search.font
                }
            }

            Rectangle {
                id: closeKey
                anchors.right: parent.right
                anchors.rightMargin: sheet.pad
                y: tabs.y
                width: Math.round(30 * root.d)
                height: width
                color: closeArea.containsMouse ? IrisStyle.text : IrisStyle.surfaceOpaque
                border.width: IrisStyle.edgeWidth
                border.color: IrisStyle.text
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: Math.round(18 * root.d)
                    color: closeArea.containsMouse ? IrisStyle.surfaceOpaque : IrisStyle.text
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Close")
                    onClicked: root.close()
                }
            }

            Item {
                id: body
                x: sheet.pad
                y: tabs.y + tabs.height + sheet.pad
                width: sheet.width - sheet.pad * 2
                height: sheet.height - y - sheet.pad

                Flickable {
                    id: binds
                    visible: root.page === 0
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: laneRow.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: laneRow
                        spacing: sheet.pad
                        Repeater {
                            model: root.lanes
                            Column {
                                id: lane
                                required property var modelData
                                width: Math.floor((binds.width - sheet.pad * 2) / 3)
                                spacing: Math.round(14 * root.d)
                                Repeater {
                                    model: lane.modelData
                                    Column {
                                        id: group
                                        required property var modelData
                                        width: lane.width
                                        Rectangle {
                                            width: parent.width
                                            height: Math.round(24 * root.d)
                                            color: IrisStyle.text
                                            Text {
                                                x: Math.round(8 * root.d)
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: group.modelData.name
                                                color: IrisStyle.surfaceOpaque
                                                font.family: IrisStyle.fontMono
                                                font.pixelSize: Math.round(20 * root.d)
                                            }
                                        }
                                        Repeater {
                                            model: group.modelData.rows
                                            Item {
                                                id: bind
                                                required property var modelData
                                                width: group.width
                                                height: Math.round(30 * root.d)
                                                IrisText {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: Math.round(8 * root.d)
                                                    width: parent.width - x - chips.width - Math.round(10 * root.d)
                                                    text: String(bind.modelData.comment ?? "")
                                                    font.pixelSize: IrisStyle.typeLabel
                                                    elide: Text.ElideRight
                                                }
                                                Row {
                                                    id: chips
                                                    anchors.right: parent.right
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    spacing: Math.round(3 * root.d)
                                                    Repeater {
                                                        model: root.keysOf(bind.modelData)
                                                        Rectangle {
                                                            id: chip
                                                            required property string modelData
                                                            width: Math.max(height, chipText.implicitWidth + Math.round(10 * root.d))
                                                            height: Math.round(22 * root.d)
                                                            color: IrisStyle.surfaceOpaque
                                                            border.width: 1
                                                            border.color: IrisStyle.text
                                                            Text {
                                                                id: chipText
                                                                anchors.centerIn: parent
                                                                text: chip.modelData
                                                                color: IrisStyle.text
                                                                font.family: IrisStyle.fontMono
                                                                font.pixelSize: Math.round(18 * root.d)
                                                            }
                                                        }
                                                    }
                                                }
                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    height: 1
                                                    color: IrisStyle.text
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                IrisText {
                    visible: root.page === 0 && root.shown.length === 0
                    anchors.centerIn: parent
                    text: Translation.tr("No results")
                    color: IrisStyle.textSecondary
                }

                Item {
                    id: table
                    visible: root.page === 1
                    anchors.fill: parent
                    readonly property real cell: Math.floor(Math.min(table.width / 18, (table.height - Math.round(40 * root.d)) / 10.4))

                    Column {
                        id: tableRows
                        anchors.horizontalCenter: parent.horizontalCenter
                        Repeater {
                            model: table.visible ? [...PTable.elements, [], ...PTable.series] : []
                            Row {
                                id: period
                                required property var modelData
                                height: period.modelData.length > 0 ? table.cell : Math.round(table.cell * 0.4)
                                Repeater {
                                    model: period.modelData
                                    Rectangle {
                                        id: atom
                                        required property var modelData
                                        readonly property bool real: atom.modelData.type !== "empty"
                                        width: table.cell
                                        height: table.cell
                                        color: !atom.real ? "transparent" : atomArea.containsMouse ? IrisStyle.text : IrisStyle.surfaceOpaque
                                        border.width: atom.real ? 1 : 0
                                        border.color: IrisStyle.text
                                        Text {
                                            visible: atom.real
                                            x: Math.round(3 * root.d)
                                            y: Math.round(1 * root.d)
                                            text: atom.modelData.number
                                            color: atomArea.containsMouse ? IrisStyle.surfaceOpaque : IrisStyle.text
                                            font.family: IrisStyle.fontMono
                                            font.pixelSize: Math.round(table.cell * 0.26)
                                        }
                                        Text {
                                            visible: atom.real
                                            anchors.centerIn: parent
                                            anchors.verticalCenterOffset: Math.round(table.cell * 0.1)
                                            text: atom.modelData.symbol
                                            color: atomArea.containsMouse ? IrisStyle.surfaceOpaque : IrisStyle.text
                                            font.family: IrisStyle.fontMono
                                            font.pixelSize: Math.round(table.cell * 0.5)
                                        }
                                        MouseArea {
                                            id: atomArea
                                            anchors.fill: parent
                                            enabled: atom.real
                                            hoverEnabled: true
                                            onContainsMouseChanged: if (containsMouse) root.element = atom.modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.element ? root.element.name + "  ·  " + root.element.weight : ""
                        color: IrisStyle.text
                        font.family: IrisStyle.fontMono
                        font.pixelSize: Math.round(24 * root.d)
                    }
                }
            }
        }
    }
}
