pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.frame
import qs.modules.nihil.components
import qs.modules.nihil.control
import qs.modules.nihil.preview.parts

PreviewScene {
    id: ccRoot
    subject: Qt.rect(ccPlate.x, ccPlate.y, ccPlate.width, ccPlate.height)
    readonly property bool on: ccRoot.opt("nihil.modules.controlCenter", true)
    readonly property bool fromIsland: String(ccRoot.opt("nihil.controlCenter.opens", "island")) === "island"
    readonly property bool round: String(ccRoot.opt("nihil.controlCenter.controls", "tiles")) === "round"
    readonly property real plateWidth: Math.max(320, Math.min(540, Number(ccRoot.opt("nihil.controlCenter.width", 360)))) * ccRoot.d
    readonly property int columns: { ccRoot.rev; return IrisControlOptions.columns }
    readonly property var ids: { ccRoot.rev; return IrisControlOptions.gridModules }
    readonly property bool listed: { ccRoot.rev; return IrisControlOptions.modules.includes("notifications") }
    readonly property var packed: {
        ccRoot.rev
        const shapes = ({})
        for (const id of ccRoot.ids) shapes[id] = IrisControlOptions.shapeOf(id)
        return IrisControlOptions.pack(ccRoot.ids, shapes, ccRoot.columns)
    }
    readonly property real naturalWidth: ccRoot.plateWidth + Math.round(120 * ccRoot.d)
    // The whole panel, every row: what the scene asks for, whatever part of it the frame shows.
    readonly property real naturalHeight: ccPlate.y + ccTitle.height + ccGrid.fullHeight
        + (ccRoot.listed ? Math.round(62 * ccRoot.d) : 0) + Math.round(62 * ccRoot.d)
    readonly property bool cropBottom: true
    // A frame lower than the panel shows the rows that fit whole and closes the plate under them: cut across, its last
    // tiles read as broken. The notifications row comes back only with every row shown.
    readonly property int shownRows: {
        const free = ccRoot.height - ccPlate.y - ccTitle.height - Math.round(48 * ccRoot.d) + ccGrid.gap
        return Math.max(ccRoot.leastRows, Math.min(ccRoot.packed.rows, Math.floor(free / (ccGrid.unit + ccGrid.gap))))
    }
    // Pieces span rows: a frame cut to whole rows may hold no whole piece, and the plate stood empty. The first piece
    // that ends decides the least it shows, and the frame scales to hold that.
    readonly property int leastRows: Math.max(1, Math.min(ccRoot.packed.rows, ...ccRoot.ids.map(id => {
        const spot = ccRoot.packed.placed[id]
        return spot ? spot.row + spot.h : ccRoot.packed.rows
    })))
    lowest: ccPlate.y + ccTitle.height + Math.round(48 * ccRoot.d) + ccRoot.leastRows * ccGrid.unit + (ccRoot.leastRows - 1) * ccGrid.gap
    readonly property bool trimmed: ccRoot.shownRows < ccRoot.packed.rows
    IslandPill {
        id: ccIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: IrisFrame.band
        opacity: ccRoot.fromIsland ? 0 : 1
    }
    // A Design that draws the Control Center's keys and levels shows its own here, on stand-in hosts.
    readonly property bool skinned: IrisDesign.has("controlTile")
    component StandIn: Item {
        id: standIn
        property string part: ""
        property var skinData: null
        property bool hovered: false
        property bool down: false
        property bool visualFocus: false
        property real shownValue: 0.6
        property bool vertical: true
        property bool muted: false
        property bool held: false
        property string icon: ""
        property string label: ""
        Loader {
            anchors.fill: parent
            active: standIn.visible && standIn.part.length > 0
            source: IrisDesign.skin(standIn.part)
            onLoaded: item.host = standIn
        }
    }
    Plate {
        id: ccPlate
        surface: "controlCenter"
        fallbackRadius: IrisStyle.radiusPanel
        opacity: ccRoot.on ? 1 : 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        y: ccRoot.fromIsland ? IrisFrame.band : ccIsland.y + ccIsland.height + IrisFrame.bodyAir
        width: ccRoot.plateWidth
        height: ccColumn.implicitHeight + Math.round(28 * ccRoot.d)
        ColumnLayout {
            id: ccColumn
            x: Math.round(14 * ccRoot.d); y: Math.round(14 * ccRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(10 * ccRoot.d)
            IrisText { id: ccTitle; text: Translation.tr("Control Center"); font.weight: IrisStyle.weight(Font.DemiBold); font.pixelSize: Math.round((IrisStyle.typeHeadline) / Math.max(1, IrisStyle.typeScale))}
            Item {
                id: ccGrid
                readonly property real gap: Math.round(8 * ccRoot.d)
                readonly property real cell: (width - (ccRoot.columns - 1) * gap) / ccRoot.columns
                readonly property real unit: Math.round((ccRoot.opt("nihil.controlCenter.labels", false) ? 70 : 64) * ccRoot.d)
                Layout.fillWidth: true
                readonly property real fullHeight: ccRoot.packed.rows * unit + Math.max(0, ccRoot.packed.rows - 1) * gap
                implicitHeight: ccRoot.shownRows * unit + Math.max(0, ccRoot.shownRows - 1) * gap
                Repeater {
                    id: tiles
                    model: ccRoot.ids
                    Rectangle {
                        id: block
                        required property string modelData
                        required property int index
                        readonly property var spot: ccRoot.packed.placed[block.modelData]
                        readonly property string kind: IrisControlOptions.kindOf(block.modelData)
                        readonly property bool wide: !["media", "level", "levels", "platter"].includes(block.kind) && block.spot.w > 1
                        readonly property bool grouped: block.kind === "levels" || block.kind === "platter"
                        readonly property bool upright: block.spot.h > block.spot.w
                        // A control drawn inside the platter, by its id (the scene points at it there).
                        function discOf(id: string): Item {
                            const i = block.kind === "platter" ? Array.from(IrisControlOptions.platterIds).indexOf(id) : -1
                            return i >= 0 ? discs.itemAt(i) : null
                        }
                        readonly property Item platter: platterGrid
                        visible: block.spot.row + block.spot.h <= ccRoot.shownRows
                        x: Math.round(block.spot.col * (ccGrid.cell + ccGrid.gap))
                        y: Math.round(block.spot.row * (ccGrid.unit + ccGrid.gap))
                        width: Math.round(block.spot.w * ccGrid.cell + (block.spot.w - 1) * ccGrid.gap)
                        height: Math.round(block.spot.h * ccGrid.unit + (block.spot.h - 1) * ccGrid.gap)
                        radius: 0
                        readonly property bool keyed: ccRoot.skinned && block.kind === "toggle" && !block.wide
                        color: block.kind === "levels" || block.keyed ? "transparent"
                            : block.index === 0 && block.kind === "toggle" && !block.wide ? IrisStyle.accent : IrisStyle.fillQuiet
                        StandIn {
                            anchors.fill: parent
                            visible: block.keyed
                            part: "controlTile"
                            skinData: ({ shape: ccRoot.round ? "disc" : "tile", control: ({ lit: block.index === 0, ready: true,
                                glyph: IrisControlOptions.glyphOf(block.modelData), label: "" }) })
                        }
                        clip: true
                        Grid {
                            id: platterGrid
                            visible: block.kind === "platter"
                            anchors.centerIn: parent
                            columns: block.spot.w > 2 ? 4 : 2
                            spacing: Math.round(10 * ccRoot.d)
                            Repeater {
                                id: discs
                                model: IrisControlOptions.platterIds
                                Rectangle {
                                    required property string modelData
                                    required property int index
                                    width: Math.round(38 * ccRoot.d)
                                    height: width
                                    radius: 0
                                    color: ccRoot.skinned ? "transparent" : index === 0 ? IrisStyle.accent : IrisStyle.fill
                                    MaterialSymbol { visible: !ccRoot.skinned; anchors.centerIn: parent; text: IrisControlOptions.glyphOf(parent.modelData); iconSize: Math.round(17 * ccRoot.d); color: parent.index === 0 ? IrisStyle.inkOnAccent : IrisStyle.text }
                                    StandIn {
                                        anchors.fill: parent
                                        visible: ccRoot.skinned
                                        part: "controlTile"
                                        skinData: ({ shape: "disc", control: ({ lit: parent.index === 0, ready: true, glyph: IrisControlOptions.glyphOf(parent.modelData), label: "" }) })
                                    }
                                }
                            }
                        }
                        Row {
                            visible: block.kind === "levels"
                            anchors.centerIn: parent
                            spacing: Math.round(10 * ccRoot.d)
                            Repeater {
                                model: IrisControlOptions.levelIds
                                Rectangle {
                                    required property string modelData
                                    width: Math.round(Math.min(46 * ccRoot.d, (block.width - 20 * ccRoot.d) / 3))
                                    height: block.height
                                    radius: 0
                                    color: ccRoot.skinned ? "transparent" : IrisStyle.fill
                                    StandIn {
                                        anchors.fill: parent
                                        visible: ccRoot.skinned && IrisDesign.has("meter")
                                        part: "meter"
                                        icon: IrisControlOptions.glyphOf(parent.modelData)
                                    }
                                    Rectangle { visible: !ccRoot.skinned; anchors.bottom: parent.bottom; width: parent.width; height: parent.height * 0.6; radius: parent.radius; color: IrisStyle.fillStrong }
                                    MaterialSymbol { visible: !ccRoot.skinned; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Math.round(10 * ccRoot.d); text: IrisControlOptions.glyphOf(parent.modelData); iconSize: Math.round(15 * ccRoot.d); color: IrisStyle.surface }
                                }
                            }
                        }
                        Rectangle {
                            visible: block.kind === "level"
                            y: block.upright ? parent.height * 0.4 : 0
                            width: block.upright ? parent.width : parent.width * 0.6
                            height: block.upright ? parent.height * 0.6 : parent.height
                            radius: 0
                            color: IrisStyle.fillStrong
                        }
                        MaterialSymbol {
                            visible: !block.wide && !block.grouped && block.kind !== "media" && !block.keyed
                            x: block.kind === "level" && !block.upright ? Math.round(14 * ccRoot.d) : Math.round((parent.width - width) / 2)
                            y: block.kind === "level" && block.upright ? parent.height - height - Math.round(14 * ccRoot.d) : Math.round((parent.height - height) / 2)
                            text: IrisControlOptions.glyphOf(block.modelData)
                            iconSize: Math.round(18 * ccRoot.d)
                            color: block.kind === "level" ? IrisStyle.surface : block.index === 0 ? IrisStyle.inkOnAccent : IrisStyle.text
                        }
                        RowLayout {
                            visible: block.wide || block.kind === "media"
                            anchors.fill: parent
                            anchors.margins: Math.round(10 * ccRoot.d)
                            spacing: Math.round(8 * ccRoot.d)
                            Rectangle {
                                Layout.alignment: block.kind === "media" && block.spot.h > 1 && !(block.spot.w > 2) ? Qt.AlignTop : Qt.AlignVCenter
                                implicitWidth: Math.round(30 * ccRoot.d)
                                implicitHeight: implicitWidth
                                radius: 0
                                color: block.kind === "media" ? IrisStyle.fillActive : IrisStyle.accent
                                border.width: IrisStyle.edgeWidth
                                border.color: IrisStyle.text
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: block.kind === "media" ? "music_note" : IrisControlOptions.glyphOf(block.modelData)
                                    iconSize: Math.round(16 * ccRoot.d)
                                    color: block.kind === "media" ? IrisStyle.subtext : IrisStyle.inkOnAccent
                                }
                            }
                            IrisText {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: block.kind === "media" ? (MprisController.titleOf(MprisController.activePlayer) || Translation.tr("Not playing"))
                                    : Translation.tr(IrisControlOptions.labelOf(block.modelData))
                                font.weight: IrisStyle.weight(Font.DemiBold)
                                font.pixelSize: Math.round((IrisStyle.typeMeta) / Math.max(1, IrisStyle.typeScale))
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                visible: ccRoot.listed && !ccRoot.trimmed
                implicitHeight: Math.round(52 * ccRoot.d)
                radius: 0
                color: IrisStyle.fillQuiet
                border.width: IrisStyle.edgeWidth
                border.color: IrisStyle.text
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(12 * ccRoot.d)
                    MaterialSymbol { text: "notifications"; iconSize: Math.round(17 * ccRoot.d); color: IrisStyle.subtext }
                    IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); Layout.fillWidth: true; text: Translation.tr("You're all caught up"); color: IrisStyle.subtext }
                }
            }
        }
    }
    OffState { visible: !ccRoot.on; text: Translation.tr("Control Center off") }

    // The page's parts: the Control Center whole, and the Hotspot and VPN controls where the layout has them, as a
    // tile of their own or a disc in the platter.
    spots: {
        const d = ccRoot.d
        const gx = ccPlate.x + ccColumn.x + ccGrid.x, gy = ccPlate.y + ccColumn.y + ccGrid.y
        const out = [{ group: "Control Center", x: ccPlate.x + ccColumn.x + ccTitle.x + ccTitle.width + 16 * d,
            y: ccPlate.y + ccColumn.y + ccTitle.y + ccTitle.height / 2,
            part: Qt.rect(ccPlate.x, ccPlate.y, ccPlate.width, ccPlate.height), radius: ccPlate.radius }]
        for (const [group, id] of [["Hotspot", "hotspot"], ["VPN", "vpn"]]) {
            for (let i = 0; i < tiles.count; i++) {
                const block = tiles.itemAt(i)
                if (!block || !block.visible) continue
                const disc = block.modelData === id ? null : block.discOf(id)
                if (block.modelData !== id && !disc) continue
                const r = disc ? Qt.rect(gx + block.x + block.platter.x + disc.x, gy + block.y + block.platter.y + disc.y, disc.width, disc.height)
                    : Qt.rect(gx + block.x, gy + block.y, block.width, block.height)
                out.push({ group: group, x: r.x + r.width - 5 * d, y: r.y + 5 * d, part: r, radius: disc ? disc.radius : block.radius })
                break
            }
        }
        return out
    }
    Caption {
        glyph: ccRoot.fromIsland ? "pill" : "web_asset"
        text: (ccRoot.fromIsland ? Translation.tr("Becomes the Island's controls page") : Translation.tr("Hangs from the Island as a panel")) + " · " + (ccRoot.round ? Translation.tr("round") : Translation.tr("tiles"))
    }
}
