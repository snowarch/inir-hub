pragma ComponentBehavior: Bound

// The lanes every face draws, in that face's ink: one lane per workspace, top to bottom as Niri stacks them, its number
// before it; the columns as wide as they are on the screen, stacked windows splitting the column, floating ones a
// small column at the end. The window a workspace comes back to is lit in the one in use, a step brighter in the
// others. Press a window to go to it, a lane to go to that workspace.
import QtQuick
import qs.services
import qs.modules.common.widgets
import "workspaces.js" as Logic

Item {
    id: root

    property var lanes: []
    property bool steerable: true
    property bool icons: true
    property bool names: true
    // The face's own measure: every size here is `unit * d`, rounded.
    property real d: 1
    // Its type's measure (iRiS scales type apart from space); text sizes are `size * t`.
    property real t: root.d
    property real laneGap: 6
    property real tileGap: 3
    property real radius: 10
    property real maxLane: 40
    property real numberWidth: 22
    property real numberSize: 13
    property real wordSize: 11
    property string fontNumbers: ""
    property string fontMain: ""
    property int feedback: 140 // literal: a face passes its family's feedback duration
    property color ink: "transparent"
    property color inkMuted: "transparent"
    property color number: root.inkMuted
    property color numberActive: root.ink
    property color well: "transparent"
    property color wellActive: "transparent"
    property color wellHover: "transparent"
    property color tile: "transparent"
    property color tileHover: "transparent"
    property color tileHere: "transparent"
    property color lit: "transparent"
    property color onLit: root.ink
    // Laid over the lit window's fill (Prism breaks the light there); null wears `lit` as it is.


    function dp(v: real): real { return Math.round(v * root.d) }
    readonly property real span: Logic.span(root.lanes)
    // An empty workspace is a thin slot; the ones with windows share the rest, so a card on an empty workspace (where
    // the desktop shows) spends its room on the windows elsewhere. The one in use leads: it stands taller, so its
    // stacked windows keep their icons where the others would shrink them.
    readonly property real thin: root.dp(18)
    readonly property real lead: 1.4
    readonly property var heights: {
        const count = root.lanes.length
        if (count === 0) return []
        const room = root.height - root.dp(root.laneGap) * (count - 1)
        const empty = root.lanes.filter(lane => lane.count === 0).length
        const most = root.dp(root.maxLane)
        if (empty === count) return root.lanes.map(() => Math.min(most, room / count))
        const weight = lane => lane.active ? root.lead : 1
        const shares = root.lanes.reduce((sum, lane) => sum + (lane.count === 0 ? 0 : weight(lane)), 0)
        const each = Math.min(most, (room - empty * root.thin) / shares)
        return root.lanes.map(lane => lane.count === 0 ? root.thin : Math.round(each * weight(lane)))
    }
    function laneTop(at: int): real {
        let y = (root.height - root.blockHeight) / 2
        for (let i = 0; i < at; ++i) y += root.heights[i] + root.dp(root.laneGap)
        return y
    }
    readonly property real blockHeight: root.heights.reduce((sum, h) => sum + h, 0) + Math.max(0, root.lanes.length - 1) * root.dp(root.laneGap)
    readonly property real wellX: root.numberWidth > 0 ? root.dp(root.numberWidth) : 0

    // Where the lit window's middle sits in this item, for a face that aims its light there (none: the middle).
    readonly property point litAt: {
        const at = root.lanes.findIndex(lane => lane.active)
        const lane = root.lanes[at]
        const gap = root.dp(root.tileGap)
        const unit = (root.width - root.wellX - 2 * gap) / root.span
        let from = 0
        for (const column of lane?.columns ?? []) {
            const row = column.windows.findIndex(w => w.here)
            if (row >= 0) {
                const inner = root.heights[at] - 2 * gap
                return Qt.point(root.wellX + gap + (from + column.share / 2) * unit,
                    root.laneTop(at) + gap + inner * (row + 0.5) / column.windows.length)
            }
            from += column.share
        }
        return Qt.point(root.width / 2, root.height / 2)
    }

    function iconOf(app: string): string {
        const entry = AppSearch.lookupDesktopEntry(app)
        return IconThemeService.smartIconName(entry?.icon || AppSearch.guessIcon(app), app)
    }

    Column {
        id: block
        width: root.width
        y: Math.round((root.height - root.blockHeight) / 2)
        spacing: root.dp(root.laneGap)

        Repeater {
            model: root.lanes
            Item {
                id: lane
                required property var modelData
                required property int index
                width: block.width
                height: root.heights[lane.index] ?? 0
                readonly property real inner: well.height - 2 * root.dp(root.tileGap)
                readonly property real unit: (well.width - 2 * root.dp(root.tileGap)) / root.span

                Text {
                    width: root.dp(root.numberWidth)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.numberWidth > 0
                    text: lane.modelData.idx
                    color: lane.modelData.active ? root.numberActive : root.number
                    font.family: root.fontNumbers
                    font.pixelSize: Math.round(root.numberSize * root.t)
                    font.weight: lane.modelData.active ? Font.Black : Font.DemiBold
                    font.features: ({ "tnum": 1 })
                }

                Rectangle {
                    id: well
                    x: root.numberWidth > 0 ? root.dp(root.numberWidth) : 0
                    width: parent.width - x
                    height: parent.height
                    radius: Math.min(root.dp(root.radius), height / 2)
                    color: lane.modelData.active ? root.wellActive : laneArea.containsMouse ? root.wellHover : root.well
                    Behavior on color { ColorAnimation { duration: root.feedback; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: laneArea
                        anchors.fill: parent
                        enabled: root.steerable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: Translation.tr("Workspace %1").arg(lane.modelData.idx)
                        onClicked: NiriService.switchToWorkspaceById(lane.modelData.id)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: lane.modelData.count === 0 && well.height >= root.dp(16)
                        text: Translation.tr("Empty")
                        color: root.inkMuted
                        font.family: root.fontMain
                        font.pixelSize: Math.round(root.wordSize * root.t)
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: lane.modelData.columns
                        Item {
                            id: column
                            required property var modelData
                            required property int index
                            readonly property real from: lane.modelData.columns.slice(0, column.index).reduce((sum, c) => sum + c.share, 0)
                            readonly property real rise: column.modelData.floating ? Math.round(lane.inner * 0.16) : 0
                            x: root.dp(root.tileGap) + Math.round(column.from * lane.unit)
                            y: root.dp(root.tileGap) + column.rise
                            width: Math.max(root.dp(4), Math.round(column.modelData.share * lane.unit) - root.dp(root.tileGap))
                            height: lane.inner - 2 * column.rise

                            Repeater {
                                model: column.modelData.windows
                                Item {
                                    id: tile
                                    required property var modelData
                                    required property int index
                                    readonly property int count: column.modelData.windows.length
                                    readonly property bool lit: tile.modelData.here && lane.modelData.active
                                    readonly property real side: Math.min(tile.width, tile.height)
                                    y: Math.round(tile.index * (column.height + root.dp(root.tileGap)) / tile.count)
                                    width: column.width
                                    height: Math.round((column.height + root.dp(root.tileGap)) / tile.count) - root.dp(root.tileGap)
                                    scale: tileArea.pressed ? 0.94 : 1
                                    Behavior on scale { NumberAnimation { duration: root.feedback; easing.type: Easing.OutCubic } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.min(Math.max(root.dp(3), well.radius - root.dp(root.tileGap)), tile.side / 2)
                                        color: tile.lit ? root.lit : tileArea.containsMouse ? root.tileHover
                                            : tile.modelData.here ? root.tileHere : root.tile
                                        Behavior on color { ColorAnimation { duration: root.feedback; easing.type: Easing.OutCubic } }
                                    }
                                    // The app's icon where it fits, its name beside it only where it fits whole.
                                    Row {
                                        id: mark
                                        readonly property bool named: root.names && tile.height >= root.dp(16)
                                            && word.implicitWidth <= tile.width - root.dp(16) - (appIcon.visible ? appIcon.width + mark.spacing : 0)
                                        anchors.centerIn: parent
                                        spacing: root.dp(6)
                                        SmartAppIcon {
                                            id: appIcon
                                            anchors.verticalCenter: parent.verticalCenter
                                            // Stacked windows in a short lane keep their icons, drawn closer to the edge.
                                            visible: root.icons && tile.side >= root.dp(12)
                                            icon: root.iconOf(tile.modelData.app)
                                            iconSize: Math.round(Math.min(root.dp(26), tile.side - (tile.side < root.dp(20) ? root.dp(2) : root.dp(8))))
                                        }
                                        Text {
                                            id: word
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: mark.named
                                            text: AppSearch.appName(tile.modelData.app)
                                            color: tile.lit ? root.onLit : root.ink
                                            font.family: root.fontMain
                                            font.pixelSize: Math.round(root.wordSize * root.t)
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                    MouseArea {
                                        id: tileArea
                                        anchors.fill: parent
                                        enabled: root.steerable
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        Accessible.role: Accessible.Button
                                        Accessible.name: AppSearch.appName(tile.modelData.app)
                                        onClicked: NiriService.focusWindow(tile.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
