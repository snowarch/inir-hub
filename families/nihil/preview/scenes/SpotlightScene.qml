pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.frame
import qs.modules.nihil.components
import qs.modules.nihil.pieces
import qs.modules.nihil.preview.parts

PreviewScene {
    id: spotRoot
    subject: Qt.rect(spotPlate.x, spotPlate.y, spotPlate.width, spotPlate.height)
    readonly property bool on: spotRoot.opt("nihil.modules.palette", true)
    readonly property bool fromIsland: String(spotRoot.opt("nihil.palette.opens", "floating")) === "island"
    readonly property bool hints: spotRoot.opt("nihil.palette.showHints", true)
    readonly property int results: Math.max(3, Math.min(14, Number(spotRoot.opt("nihil.palette.maxResults", 8))))
    readonly property real plateWidth: Math.max(420, Math.min(900, Number(spotRoot.opt("nihil.palette.width", 640)))) * spotRoot.d
    readonly property var apps: (TaskbarApps.apps ?? []).filter(app => app && !app.separator && String(app.appId ?? "").length > 0 && app.appId !== "SEPARATOR")
    readonly property real naturalWidth: spotRoot.plateWidth + Math.round(80 * spotRoot.d)
    readonly property real naturalHeight: spotPlate.y + spotPlate.height + Math.round(24 * spotRoot.d)
    readonly property bool cropBottom: true
    IslandPill {
        id: spotIsland
        visible: spotRoot.fromIsland
        anchors.horizontalCenter: parent.horizontalCenter
        y: IrisFrame.band
    }
    Plate {
        id: spotPlate
        surface: "spotlight"
        opacity: spotRoot.on ? 1 : 0.35
        anchors.horizontalCenter: parent.horizontalCenter
        y: spotRoot.fromIsland ? spotIsland.y + spotIsland.height + IrisStyle.weld : Math.round(40 * spotRoot.d)
        width: spotRoot.plateWidth
        height: spotColumn.implicitHeight + Math.round(28 * spotRoot.d)
        ColumnLayout {
            id: spotColumn
            x: Math.round(14 * spotRoot.d); y: Math.round(14 * spotRoot.d)
            width: parent.width - 2 * x
            spacing: Math.round(6 * spotRoot.d)
            // A plate Design (AIRISU) writes the query large on a ruled line, as its Spotlight does; NiHiL keeps its field.
            Item {
                id: ruled
                visible: IrisStyle.plateSelection
                Layout.fillWidth: true
                implicitHeight: Math.round(46 * spotRoot.d)
                IrisText {
                    anchors.left: parent.left
                    anchors.bottom: rule.top
                    anchors.bottomMargin: Math.round(4 * spotRoot.d)
                    text: Translation.tr("Search apps, files and actions")
                    color: IrisStyle.textTertiary
                    font.family: IrisStyle.fontTitle
                    font.weight: IrisStyle.weight(Font.ExtraBold)
                    font.pixelSize: Math.round((IrisStyle.typeHeadline) / Math.max(1, IrisStyle.typeScale))
                }
                Rectangle { id: rule; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: IrisStyle.textTertiary }
            }
            Rectangle {
                id: field
                visible: !IrisStyle.plateSelection
                Layout.fillWidth: true
                implicitHeight: Math.round(40 * spotRoot.d)
                radius: 0
                color: IrisStyle.fillQuiet
                border.width: IrisStyle.edgeWidth
                border.color: IrisStyle.text
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(14 * spotRoot.d)
                    spacing: Math.round(8 * spotRoot.d)
                    MaterialSymbol { text: "search"; iconSize: Math.round(18 * spotRoot.d); color: IrisStyle.muted }
                    IrisText { text: Translation.tr("Search apps, files and actions"); color: IrisStyle.muted; font.pixelSize: Math.round((IrisStyle.typeLabel) / Math.max(1, IrisStyle.typeScale))}
                }
            }
            Row {
                id: hintRow
                visible: spotRoot.hints
                spacing: Math.round(6 * spotRoot.d)
                Repeater {
                    model: [";  " + Translation.tr("Clipboard"), "=  " + Translation.tr("Calculator"), "/  " + Translation.tr("Actions"), ":  " + Translation.tr("Emoji")]
                    Rectangle {
                        required property string modelData
                        width: hintLabel.implicitWidth + Math.round(18 * spotRoot.d)
                        height: Math.round(24 * spotRoot.d)
                        radius: 0
                        color: IrisStyle.fillQuiet
                        border.width: IrisStyle.edgeWidth
                        border.color: IrisStyle.text
                        IrisText { id: hintLabel; anchors.centerIn: parent; text: parent.modelData; color: IrisStyle.subtext; font.pixelSize: Math.round((IrisStyle.typeFootnote) / Math.max(1, IrisStyle.typeScale))}
                    }
                }
            }
            // The section head and the current row as the engine draws them, in the Design's own parts when it has them.
            Item {
                id: topHead
                readonly property string title: Translation.tr("Top hit")
                readonly property var tint: null
                Layout.fillWidth: true
                Layout.topMargin: Math.round(4 * spotRoot.d)
                implicitHeight: headSkin.active ? (headSkin.item?.implicitHeight ?? 0) : headText.implicitHeight
                IrisSkin { id: headSkin; part: "sectionTab"; host: topHead }
                IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); id: headText; visible: !headSkin.active; text: topHead.title; role: IrisText.Meta }
            }
            Repeater {
                model: spotRoot.results
                RowLayout {
                    id: hit
                    required property int index
                    readonly property var app: spotRoot.apps[hit.index % Math.max(1, spotRoot.apps.length)] ?? null
                    Layout.fillWidth: true
                    spacing: Math.round(10 * spotRoot.d)
                    Rectangle {
                        id: hitRow
                        Layout.fillWidth: true
                        implicitHeight: Math.round(36 * spotRoot.d)
                        radius: 0
                        color: hit.index === 0 ? IrisStyle.rowSelectionFill : "transparent"
                        IrisSkin { visible: hit.index === 0; part: "listMark"; host: hitRow }
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(8 * spotRoot.d)
                            anchors.rightMargin: Math.round(10 * spotRoot.d)
                            spacing: Math.round(10 * spotRoot.d)
                            IrisText {
                                visible: IrisStyle.indexed
                                text: IrisStyle.indexLabel(hit.index)
                                color: hit.index === 0 ? IrisStyle.rowSelectionInk : IrisStyle.textTertiary
                                font.family: IrisStyle.fontNumbers
                                font.pixelSize: Math.round((IrisStyle.typeMeta) / Math.max(1, IrisStyle.typeScale))
                                font.weight: IrisStyle.weight(Font.DemiBold)
                            }
                            SmartAppIcon { implicitSize: Math.round(24 * spotRoot.d); icon: IrisPieces.appIcon(hit.app?.appId ?? ""); fallback: "application-x-executable" }
                            IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale));
                                Layout.fillWidth: true
                                text: DesktopEntries.heuristicLookup(hit.app?.appId ?? "")?.name ?? String(hit.app?.appId ?? Translation.tr("Result"))
                                elide: Text.ElideRight
                            }
                            IrisText { text: hit.index === 0 ? Translation.tr("Open") : Translation.tr("App"); color: IrisStyle.muted; font.pixelSize: Math.round((IrisStyle.typeMeta) / Math.max(1, IrisStyle.typeScale))}
                        }
                    }
                }
            }
        }
    }
    OffState { visible: !spotRoot.on; text: Translation.tr("Spotlight off") }

    // The page's parts: Spotlight whole, its number at the empty end of the field, and the prefixes' shortcuts.
    spots: {
        const d = spotRoot.d
        const px = spotPlate.x + spotColumn.x, py = spotPlate.y + spotColumn.y
        const query = field.visible ? field : ruled
        const out = [{ group: "Spotlight", x: px + query.x + query.width - 22 * d, y: py + query.y + query.height / 2,
            part: Qt.rect(spotPlate.x, spotPlate.y, spotPlate.width, spotPlate.height), radius: spotPlate.radius }]
        if (hintRow.visible)
            out.push({ group: "Prefixes", x: px + hintRow.x + hintRow.width + 16 * d, y: py + hintRow.y + hintRow.height / 2,
                part: Qt.rect(px + hintRow.x - 3 * d, py + hintRow.y - 3 * d, hintRow.width + 6 * d, hintRow.height + 6 * d), radius: 15 * d })
        return out
    }
    Caption {
        glyph: spotRoot.fromIsland ? "pill" : "web_asset"
        text: Translation.tr("%1 results").arg(spotRoot.results) + " · " + (spotRoot.fromIsland ? Translation.tr("grows out of the Island") : Translation.tr("floats over the screen"))
    }
}
