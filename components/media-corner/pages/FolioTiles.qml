pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Normal's «Every day», as Folio's tiles: a glyph in its tint and a name over what the place holds; the tile of what
// plays is lit with the accent.
ColumnLayout {
    id: root
    required property var anime
    readonly property real d: IrisStyle.density
    readonly property var latest: CornerWatch.latest?.entry ?? null
    readonly property bool playing: CornerWatch.current !== null
    readonly property var tiles: [
        { place: "", glyph: root.playing ? "graphic_eq" : "play_circle", tint: IrisStyle.identity.green, lit: root.playing,
          label: root.playing ? Translation.tr("Now playing") : Translation.tr("Continue"),
          value: String((root.playing ? CornerWatch.current.show?.title : root.latest?.show?.title) ?? Translation.tr("Find something to watch")) },
        { place: "anime:airing", glyph: "live_tv", tint: IrisStyle.identity.purple, label: Translation.tr("Airing now"), value: Translation.tr("Anime") },
        { place: "anime:trending", glyph: "trending_up", tint: IrisStyle.identity.pink, label: Translation.tr("Trending"), value: Translation.tr("Anime") },
        { place: "anime:season", glyph: "eco", tint: IrisStyle.identity.teal, label: Translation.tr("This season"),
          value: Translation.tr(root.anime.seasonName(root.anime.currentSeason())) + " " + new Date().getFullYear() },
        { place: "movie:movies", glyph: "movie", tint: IrisStyle.identity.orange, label: Translation.tr("Films"), value: Translation.tr("Popular") },
        { place: "movie:series", glyph: "tv", tint: IrisStyle.identity.blue, label: Translation.tr("Series"), value: Translation.tr("Popular") },
        { place: "schedule", glyph: "event", tint: IrisStyle.identity.indigo, label: Translation.tr("Upcoming episodes"), value: Translation.tr("Want to watch") },
        { place: "movie:top", glyph: "star", tint: IrisStyle.identity.yellow, label: Translation.tr("Top rated"), value: Translation.tr("Films and series") }
    ]
    function open(tile: var): void {
        if (tile.place.length > 0) { CornerState.pick(tile.place); return }
        if (root.playing) CornerState.openShow(CornerWatch.current.show)
        else if (root.latest) { CornerState.openShow(root.latest.show); CornerWatch.begin(root.latest.show, root.latest.episode ?? null) }
        else CornerState.pick("anime:trending")
    }
    spacing: Math.round(10 * root.d)

    CornerHeading { title: Translation.tr("Every day"); glyph: "bolt" }
    GridLayout {
        id: grid
        Layout.fillWidth: true
        readonly property int gap: Math.round(8 * root.d)
        columns: Math.max(2, Math.floor((width + gap) / (Math.round(208 * root.d * IrisStyle.typeScale) + gap)))
        columnSpacing: gap
        rowSpacing: gap
        Repeater {
            model: root.tiles
            IrisButton {
                id: tile
                required property var modelData
                readonly property color ink: tile.modelData.lit ? IrisStyle.inkOnLookPlate : IrisStyle.text
                Layout.fillWidth: true
                implicitHeight: Math.round(13 * root.d) + Math.round(18 * root.d) + Math.round(6 * root.d) + value.implicitHeight + Math.round(14 * root.d)
                buttonRadius: IrisStyle.radiusTile
                buttonRadiusPressed: IrisStyle.radiusTile
                colBackground: tile.modelData.lit ? IrisStyle.lookPlate : CornerSkin.card
                colBackgroundHover: tile.modelData.lit ? IrisStyle.lookPlate : IrisStyle.fillQuiet
                Accessible.name: tile.modelData.label + ", " + tile.modelData.value
                onClicked: root.open(tile.modelData)
                Row {
                    x: Math.round(14 * root.d)
                    y: Math.round(13 * root.d)
                    spacing: Math.round(7 * root.d)
                    IrisSquircle {
                        width: Math.round(18 * root.d)
                        height: width
                        tint: tile.modelData.tint
                        glyph: tile.modelData.glyph
                    }
                    IrisText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tile.modelData.label
                        color: tile.modelData.lit ? tile.ink : IrisStyle.iconHue(tile.modelData.tint)
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                }
                IrisText {
                    id: value
                    x: Math.round(14 * root.d)
                    y: Math.round(13 * root.d) + Math.round(18 * root.d) + Math.round(6 * root.d)
                    width: tile.width - x - Math.round(14 * root.d)
                    text: tile.modelData.value
                    textFormat: Text.PlainText
                    color: tile.ink
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeHeadline
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
                MaterialSymbol {
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(10 * root.d)
                    y: Math.round(11 * root.d)
                    text: "chevron_right"
                    iconSize: Math.round(18 * root.d)
                    color: tile.buttonHovered ? tile.ink : tile.modelData.lit ? tile.ink : IrisStyle.textTertiary
                }
            }
        }
    }
}
