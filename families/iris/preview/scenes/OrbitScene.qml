pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.preview.parts

// Orbit as it opens: the workspace you are on with its windows, its neighbours peeking above and below as far as you
// let them, its name, and the shelf of recent windows when it is on.
PreviewScene {
    id: orbitRoot
    subject: Qt.rect(orbitPlate.x, orbitPlate.y, orbitPlate.width, orbitPlate.height)
    readonly property bool on: orbitRoot.opt("iris.orbit.enable", true) === true
    readonly property bool fromIsland: String(orbitRoot.opt("iris.orbit.opens", "island")) === "island"
    readonly property real peek: Math.max(0, Number(orbitRoot.opt("iris.orbit.peek", 56)))
    readonly property bool wallpapered: orbitRoot.opt("iris.orbit.wallpaper", true) === true
    readonly property bool names: String(orbitRoot.opt("iris.orbit.labels", "full")) === "full"
    readonly property bool recent: orbitRoot.opt("iris.orbit.showRecent", true) === true
    readonly property int recentCount: Math.max(2, Math.min(8, Number(orbitRoot.opt("iris.orbit.recentCount", 5))))
    readonly property real naturalWidth: Math.round(640 * orbitRoot.d)
    readonly property real naturalHeight: Math.round(360 * orbitRoot.d)
    narrowest: Math.round(400 * orbitRoot.d)
    lowest: Math.round(240 * orbitRoot.d)

    IslandPill {
        id: orbitIsland
        visible: orbitRoot.fromIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: IrisFrame.band
    }
    Plate {
        id: orbitPlate
        surface: "orbit"
        opacity: orbitRoot.on ? 1 : 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        y: orbitRoot.fromIsland ? orbitIsland.y + orbitIsland.height + IrisStyle.weld : Math.round(28 * orbitRoot.d)
        width: Math.round(orbitRoot.width * 0.7)
        height: orbitColumn.implicitHeight + Math.round(28 * orbitRoot.d)
        ColumnLayout {
            id: orbitColumn
            x: Math.round(14 * orbitRoot.d)
            y: Math.round(14 * orbitRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(8 * orbitRoot.d)
            Repeater {
                id: workspaces
                // The neighbours show as much as Neighbours lets them; Hidden leaves the workspace you are on alone.
                model: orbitRoot.peek > 0 ? [-1, 0, 1] : [0]
                ClippingRectangle {
                    id: card
                    required property int modelData
                    readonly property bool current: card.modelData === 0
                    readonly property Item tag: nameTag
                    Layout.fillWidth: true
                    Layout.preferredHeight: card.current ? Math.round(150 * orbitRoot.d) : Math.round(Math.min(70, orbitRoot.peek) * 0.5 * orbitRoot.d)
                    radius: IrisStyle.radiusTile
                    color: IrisStyle.fillQuiet
                    opacity: card.current ? 1 : 0.6
                    border.width: card.current ? 2 : 0
                    border.color: IrisStyle.accent
                    IrisImage {
                        visible: orbitRoot.wallpapered
                        anchors.fill: parent
                        source: orbitRoot.wallpaper
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: Math.round(8 * orbitRoot.d)
                        Repeater {
                            model: card.current ? [0.3, 0.42, 0.22] : [0.36, 0.3]
                            Rectangle {
                                required property real modelData
                                width: Math.round(card.width * modelData)
                                height: Math.round(card.height * 0.66)
                                radius: IrisStyle.radiusChip
                                color: IrisStyle.surfaceOpaque
                                border.width: 1
                                border.color: IrisStyle.border
                            }
                        }
                    }
                    Rectangle {
                        id: nameTag
                        visible: card.current && orbitRoot.on
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: Math.round(8 * orbitRoot.d)
                        width: workspaceName.implicitWidth + Math.round(16 * orbitRoot.d)
                        height: Math.round(22 * orbitRoot.d)
                        radius: IrisStyle.capsule(height)
                        color: IrisStyle.veilHeavy
                        IrisText {
                            id: workspaceName
                            anchors.centerIn: parent
                            text: orbitRoot.names ? "2 · " + Translation.tr("Workspace") : "2"
                            color: IrisStyle.onMedia
                            font.pixelSize: Math.round((IrisStyle.typeMeta) / Math.max(1, IrisStyle.typeScale))
                            font.weight: IrisStyle.weight(Font.DemiBold)
                        }
                    }
                }
            }
            Row {
                id: shelf
                visible: orbitRoot.recent
                spacing: Math.round(6 * orbitRoot.d)
                Repeater {
                    model: orbitRoot.recentCount
                    Rectangle {
                        width: Math.round(46 * orbitRoot.d)
                        height: Math.round(30 * orbitRoot.d)
                        radius: IrisStyle.radiusChip
                        color: IrisStyle.fill
                    }
                }
            }
        }
    }

    OffState { visible: !orbitRoot.on; text: Translation.tr("Orbit off") }

    // The page's parts: Orbit whole, the workspace you are on at its size, its name as Look writes it, the shelf.
    spots: {
        const d = orbitRoot.d, gap = 16 * d
        const px = orbitPlate.x + orbitColumn.x, py = orbitPlate.y + orbitColumn.y
        const out = [{ group: "Orbit", x: orbitPlate.x + orbitPlate.width + gap, y: orbitPlate.y + 18 * d,
            part: Qt.rect(orbitPlate.x, orbitPlate.y, orbitPlate.width, orbitPlate.height), radius: orbitPlate.radius }]
        const card = workspaces.count > 0 ? workspaces.itemAt(orbitRoot.peek > 0 ? 1 : 0) : null
        if (card) {
            out.push({ group: "Size", x: px + card.x + card.width - 18 * d, y: py + card.y + 18 * d,
                part: Qt.rect(px + card.x, py + card.y, card.width, card.height), radius: card.radius })
            const tag = card.tag
            if (tag && tag.visible)
                out.push({ group: "Look", x: px + card.x + tag.x + tag.width + gap, y: py + card.y + tag.y + tag.height / 2,
                    part: Qt.rect(px + card.x + tag.x, py + card.y + tag.y, tag.width, tag.height), radius: tag.radius })
        }
        if (shelf.visible)
            out.push({ group: "Shelf", x: px + shelf.x + shelf.width + gap, y: py + shelf.y + shelf.height / 2,
                part: Qt.rect(px + shelf.x - 3 * d, py + shelf.y - 3 * d, shelf.width + 6 * d, shelf.height + 6 * d), radius: 8 * d })
        return out
    }

    Caption {
        glyph: "workspaces"
        text: orbitRoot.on ? [orbitRoot.fromIsland ? Translation.tr("The Island") : Translation.tr("Floating"),
            orbitRoot.recent ? Translation.tr("Recent windows") + " " + orbitRoot.recentCount : ""].filter(part => part.length > 0).join(" · ")
            : Translation.tr("Off")
    }
}
