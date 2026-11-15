pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Every day: the places one click away, as Settings' tiles (a glyph in a circle, a name over what it holds).
ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    readonly property var tiles: [
        { id: "anime:airing", icon: "live_tv", title: Translation.tr("Airing now"), detail: Translation.tr("Anime") },
        { id: "anime:trending", icon: "trending_up", title: Translation.tr("Trending"), detail: Translation.tr("Anime") },
        { id: "anime:season", icon: "eco", title: Translation.tr("This season"), detail: Translation.tr("Anime") },
        { id: "movie:movies", icon: "movie", title: Translation.tr("Films"), detail: Translation.tr("Films and series") },
        { id: "movie:series", icon: "tv", title: Translation.tr("Series"), detail: Translation.tr("Films and series") },
        { id: "schedule", icon: "event", title: Translation.tr("Upcoming episodes"), detail: Translation.tr("Library") }
    ]
    spacing: Math.round(10 * root.d)
    CornerHeading { eyebrow: Translation.tr("Browse"); title: Translation.tr("Every day") }
    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(1, Math.min(3, Math.floor(width / Math.round(200 * root.d))))
        columnSpacing: Math.round(10 * root.d)
        rowSpacing: Math.round(10 * root.d)
        Repeater {
            model: root.tiles
            IrisButton {
                id: tile
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Math.round(56 * root.d)
                colBackground: CornerSkin.card
                colBackgroundHover: IrisStyle.fillHover
                buttonRadius: height / 2
                buttonRadiusPressed: height / 2
                Accessible.name: tile.modelData.title
                onClicked: CornerState.pick(tile.modelData.id)
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(8 * root.d)
                    anchors.rightMargin: Math.round(16 * root.d)
                    spacing: Math.round(10 * root.d)
                    Rectangle {
                        Layout.preferredWidth: Math.round(40 * root.d)
                        Layout.preferredHeight: Math.round(40 * root.d)
                        radius: width / 2
                        color: CornerSkin.plate
                        MaterialSymbol { anchors.centerIn: parent; text: tile.modelData.icon; fill: 1; iconSize: Math.round(20 * root.d); color: IrisStyle.text }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        IrisText { Layout.fillWidth: true; text: tile.modelData.title; font.pixelSize: IrisStyle.typeLabel; font.weight: IrisStyle.weight(Font.DemiBold); elide: Text.ElideRight }
                        IrisText { Layout.fillWidth: true; text: tile.modelData.detail; color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeMeta; elide: Text.ElideRight }
                    }
                }
            }
        }
    }
}
