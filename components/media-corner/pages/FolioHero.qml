pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/streams.js" as Streams

// Classic's and Folio's hero, as Folio's wallpaper card: the show's art blurred behind it, its picture on the left, what it is and
// its actions on the right, and under it a strip of what else trends, with All at its end. A thumbnail puts its show
// up front.
ClippingRectangle {
    id: root
    // What trends, in order; the strip shows up to six.
    property var shows: []
    property string status: ""
    property int index: 0
    readonly property var show: root.shows[Math.min(root.index, root.shows.length - 1)] ?? null
    readonly property real d: IrisStyle.density
    readonly property int pad: Math.round(14 * root.d)
    readonly property int stageHeight: Math.round(212 * root.d)
    readonly property bool compact: width < Math.round(620 * root.d)
    readonly property bool film: root.show?.type === "Movie" || Number(root.show?.episodes) === 1
    readonly property string art: String(root.show?.banner || root.show?.imageLarge || "")
    readonly property int count: Math.min(6, root.shows.length)
    readonly property real tileWidth: (width - 2 * root.pad - root.count * Math.round(10 * root.d)) / Math.max(1, root.count + 1)
    implicitHeight: root.stageHeight + (root.count > 1 ? root.pad + Math.round(root.tileWidth * 10 / 16) + root.pad : 0)
    radius: IrisStyle.radiusTile
    color: CornerSkin.card

    Item {
        id: stage
        width: parent.width
        height: root.stageHeight
        clip: true
        IrisImage {
            id: backdrop
            anchors.fill: parent
            anchors.margins: -Math.round(48 * root.d)
            source: root.art
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: backdrop
            source: backdrop
            visible: root.art.length > 0
            blurEnabled: true
            blur: 1
            blurMax: 48
            saturation: 0.15 // literal: Folio's quiet backdrop
        }
        Rectangle { anchors.fill: parent; color: IrisStyle.veilStrong }
        // Nothing to show yet: the Corner's mark holds the stage.
        CornerMark {
            visible: root.show === null
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(28 * root.d)
            size: Math.round(120 * root.d)
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(28 * root.d)
            spacing: Math.round(28 * root.d)
            ClippingRectangle {
                visible: !root.compact && root.show !== null
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(height * 16 / 9)
                radius: IrisStyle.radiusRow
                color: IrisStyle.veilStrong
                border.width: 1
                border.color: IrisStyle.hairlineOf(IrisStyle.inkOnDark)
                IrisImage { anchors.fill: parent; source: root.art; fillMode: Image.PreserveAspectCrop }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: String(root.show?.title ?? "")
                    onClicked: CornerState.openShow(root.show)
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: Math.round(6 * root.d)
                RowLayout {
                    spacing: Math.round(8 * root.d)
                    IrisText {
                        Layout.alignment: Qt.AlignBaseline
                        text: root.show ? Translation.tr("Trending now") : Translation.tr("Media Corner")
                        color: IrisStyle.inkOnDark
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    IrisText {
                        Layout.alignment: Qt.AlignBaseline
                        visible: root.show !== null
                        text: [root.show?.year, Translation.tr(String(root.show?.type ?? "")), Number(root.show?.score ?? 0) > 0 ? "★ " + Number(root.show.score).toFixed(1) : ""]
                            .filter(x => String(x ?? "").length > 0).join(" · ")
                        color: IrisStyle.inkOnDark
                        opacity: 0.72 // literal: facts over art, quieter than the title
                        font.pixelSize: IrisStyle.typeMeta
                    }
                }
                IrisText {
                    Layout.fillWidth: true
                    text: String(root.show?.title ?? root.status)
                    textFormat: Text.PlainText
                    color: IrisStyle.inkOnDark
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: root.show !== null
                    text: (root.show?.genres ?? []).slice(0, 4).map(genre => Translation.tr(genre)).join(" · ")
                    color: IrisStyle.inkOnDark
                    opacity: 0.72 // literal: facts over art, quieter than the title
                    font.family: IrisStyle.fontMono
                    font.pixelSize: IrisStyle.typeMeta
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: String(root.show?.description ?? "")
                    textFormat: Text.PlainText
                    color: IrisStyle.inkOnDark
                    opacity: 0.72 // literal: the synopsis over art, quieter than the title
                    font.pixelSize: IrisStyle.typeMeta
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
                Row {
                    visible: root.show !== null
                    Layout.topMargin: Math.round(6 * root.d)
                    spacing: Math.round(8 * root.d)
                    CornerPill {
                        tone: "art"
                        glyph: "play_arrow"
                        label: Translation.tr("Watch")
                        onClicked: {
                            CornerState.openShow(root.show)
                            CornerWatch.begin(Object.assign({}, root.show, { film: root.film }), { episode: 1 })
                        }
                    }
                    ArtKey {
                        readonly property bool saved: root.show !== null && Boolean(CornerWatch.watchlist[Streams.watchKey(root.show, null)])
                        glyph: saved ? "bookmark_remove" : "bookmark_add"
                        name: saved ? Translation.tr("Remove from want to watch") : Translation.tr("Want to watch")
                        onClicked: CornerWatch.toggleWatchlist(Object.assign({}, root.show, { film: root.film }))
                    }
                    ArtKey {
                        glyph: "info"
                        name: Translation.tr("Details")
                        onClicked: CornerState.openShow(root.show)
                    }
                }
            }
        }
    }

    // What else trends: one click puts it up front; All opens the whole list.
    Row {
        visible: root.count > 1
        x: root.pad
        y: root.stageHeight + root.pad
        spacing: Math.round(10 * root.d)
        Repeater {
            model: root.shows.slice(0, root.count)
            ClippingRectangle {
                id: thumb
                required property var modelData
                required property int index
                readonly property bool chosen: thumb.index === root.index
                width: root.tileWidth
                height: Math.round(root.tileWidth * 10 / 16)
                radius: IrisStyle.radiusRow
                color: CornerSkin.plate
                border.width: thumb.chosen ? 2 : 0
                border.color: IrisStyle.accent
                IrisImage {
                    anchors.fill: parent
                    anchors.margins: thumb.border.width
                    source: String(thumb.modelData.banner || thumb.modelData.imageLarge || thumb.modelData.image || "")
                    fillMode: Image.PreserveAspectCrop
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: String(thumb.modelData.title ?? "")
                    onClicked: root.index = thumb.index
                    Keys.onReturnPressed: root.index = thumb.index
                    Keys.onSpacePressed: root.index = thumb.index
                }
            }
        }
        IrisButton {
            width: root.tileWidth
            height: Math.round(root.tileWidth * 10 / 16)
            buttonRadius: IrisStyle.radiusRow
            buttonRadiusPressed: IrisStyle.radiusRow
            colBackground: IrisStyle.fillQuiet
            colBackgroundHover: IrisStyle.fillHover
            Accessible.name: Translation.tr("All")
            onClicked: CornerState.pick("anime:trending")
            Column {
                anchors.centerIn: parent
                spacing: Math.round(4 * root.d)
                MaterialSymbol { anchors.horizontalCenter: parent.horizontalCenter; text: "grid_view"; iconSize: Math.round(20 * root.d); color: IrisStyle.subtext }
                IrisText { anchors.horizontalCenter: parent.horizontalCenter; text: Translation.tr("All"); color: IrisStyle.subtext; font.pixelSize: IrisStyle.typeMeta }
            }
        }
    }

    // A round key over the art.
    component ArtKey: IrisButton {
        id: key
        required property string glyph
        required property string name
        implicitWidth: Math.round(36 * root.d)
        implicitHeight: Math.round(36 * root.d)
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        colBackground: IrisStyle.veilStrong
        colBackgroundHover: IrisStyle.veilHeavy
        Accessible.name: key.name
        MaterialSymbol { anchors.centerIn: parent; text: key.glyph; fill: 1; iconSize: Math.round(18 * root.d); color: IrisStyle.inkOnDark }
        StyledToolTip { text: key.name; extraVisibleCondition: key.buttonHovered }
    }
}
