pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One area's options on the shelf, whole, as the lines of Prism's chart the widget's quick controls draw (his 11-07: the
// Look page showed three tiles and a "More"): columns of numbered lines that scroll sideways, every row the area has in
// Settings, refinements too. A group opens a column of its own and names itself under its first line. A folded choice
// lays its chips across the page, with the way back, since there is no room under a line here. The card above shows
// each change as it lands.
Item {
    id: root

    required property string section
    // One group of the area when the shelf wants only it (Look = Desktop › Widgets).
    property string group: ""

    readonly property real lineHeight: PrismTheme.dp(46)
    readonly property int perColumn: Math.max(1, Math.floor(root.height / root.lineHeight))
    readonly property real columnWidth: PrismTheme.dp(330)
    readonly property real columnGap: PrismTheme.dp(36)
    readonly property var drawn: ["switch", "choice", "range", "text", "action"]
    readonly property var specs: {
        Config.revision
        return IrisOptions.settings.filter(spec => spec.section === root.section && (root.group.length === 0 || spec.group === root.group)
            && !spec.mirror && spec.shelf !== false && root.drawn.includes(spec.kind) && IrisOptions.shown(spec))
    }
    readonly property bool grouped: new Set(root.specs.map(spec => spec.group)).size > 1
    // Numbered in reading order, laid down in columns of as many lines as the page holds.
    readonly property var columns: {
        const out = []
        let number = 1
        let column = null
        for (const spec of root.specs) {
            const opens = root.grouped && (column === null || column.group !== spec.group)
            if (column === null || opens || column.specs.length >= root.perColumn) {
                column = { key: String(spec.path ?? spec.label), group: spec.group, first: number, opens: opens, specs: [] }
                out.push(column)
            }
            column.specs.push(opens && spec.group !== spec.label ? Object.assign({}, spec, { caption: spec.group }) : spec)
            number++
        }
        return out
    }

    // The folded choice laid open across the page, or none.
    property var unfolded: null
    readonly property var unfoldedNow: { Config.revision; return root.unfolded ? IrisOptions.currentValue(root.unfolded) : undefined }
    onSectionChanged: root.unfolded = null
    onGroupChanged: root.unfolded = null

    Flickable {
        IrisScrollFeel {}
        id: board
        anchors.fill: parent
        contentWidth: lanes.width
        contentHeight: height
        Behavior on contentX { enabled: !board.moving; NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        flickableDirection: Flickable.HorizontalFlick
        clip: true
        opacity: root.unfolded ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y
                board.contentX = Math.max(0, Math.min(board.contentWidth - board.width, board.contentX - delta / 120 * PrismTheme.dp(200)))
            }
        }

        Row {
            id: lanes
            height: board.height
            spacing: root.columnGap
            Repeater {
                model: ScriptModel { values: root.columns; objectProp: "key" }
                delegate: Item {
                    id: lane
                    required property var modelData
                    required property int index
                    width: root.columnWidth
                    height: lanes.height
                    // A group's first column: a hairline sets it off from the one before.
                    Rectangle {
                        visible: lane.modelData.opens && lane.index > 0
                        x: -Math.round(root.columnGap / 2)
                        y: PrismTheme.dp(8)
                        width: 1
                        height: lane.height - PrismTheme.dp(16)
                        color: PrismTheme.line
                    }
                    IrisSheetRows {
                        x: PrismTheme.dp(8)
                        width: lane.width - PrismTheme.dp(16)
                        specs: lane.modelData.specs
                        firstNumber: lane.modelData.first
                        fold: spec => root.unfolded = spec
                    }
                }
            }
        }
    }

    // More lines past the edge: a round arrow there turns the page.
    PrismRound {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        glyph: "chevron_right"
        smoked: true
        readonly property bool more: board.contentX < board.contentWidth - board.width - 1
        opacity: !root.unfolded && more ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        Accessible.name: Translation.tr("More")
        onClicked: board.contentX = Math.min(board.contentWidth - board.width, board.contentX + root.columnWidth + root.columnGap)
    }

    // A folded choice, open: its name and the way back, every option a chip under it.
    Item {
        anchors.fill: parent
        opacity: root.unfolded ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
        Row {
            id: unfoldedHead
            x: PrismTheme.dp(8)
            y: PrismTheme.dp(6)
            spacing: PrismTheme.dp(8)
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "arrow_back"
                Accessible.name: Translation.tr("Back")
                onClicked: root.unfolded = null
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.unfolded ? Translation.tr(String(root.unfolded.label ?? "")) : ""
                color: PrismTheme.ink
                font.pixelSize: PrismTheme.body
                font.weight: Font.DemiBold
            }
        }
        PrismChips {
            x: PrismTheme.dp(8)
            anchors.top: unfoldedHead.bottom
            anchors.topMargin: PrismTheme.dp(10)
            width: parent.width - PrismTheme.dp(16)
            choices: root.unfolded ? IrisOptions.choicesOf(root.unfolded) : []
            current: root.unfoldedNow
            onPicked: value => {
                IrisOptions.commit(root.unfolded, value)
                root.unfolded = null
            }
        }
    }
}
