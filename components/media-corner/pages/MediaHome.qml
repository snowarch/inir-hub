pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Home: one show up front (what is trending on AniList) and shelves of anime, films and series under it.
MediaPage {
    id: root
    required property var anime
    required property var movies
    readonly property bool prism: CornerState.options.style === "prism"

    property var hero: null
    property var featuredAnime: null
    property var featuredFilm: null
    function askHero(): void {
        if (root.hero !== null) return
        root.anime.page({ sort: "TRENDING_DESC" }, 1, (result, error) => {
            if (!root) return
            if (!error) { root.hero = result.items[0] ?? null; root.featuredAnime = result.items[1] ?? null }
        })
    }
    function askFilm(): void {
        if (root.featuredFilm !== null) return
        root.movies.page({ kind: "movie" }, 1, (result, error) => {
            if (!root) return
            if (!error) root.featuredFilm = result.items[0] ?? null
        })
    }
    Component.onCompleted: { root.askHero(); if (root.prism) root.askFilm() }
    Connections {
        target: CornerState
        function onAttemptChanged(): void { root.askHero(); if (root.prism) root.askFilm() }
    }

    readonly property var shelves: [
        { anime: true, title: Translation.tr("Airing now"), note: Translation.tr("Anime"), filter: { status: "RELEASING", sort: "POPULARITY_DESC" }, place: "anime:airing" },
        { anime: true, title: Translation.tr("Trending anime"), filter: { sort: "TRENDING_DESC" }, place: "anime:trending" },
        { anime: true, title: Translation.tr("This season"), filter: { season: root.anime.currentSeason(), year: new Date().getFullYear(), sort: "POPULARITY_DESC" }, place: "anime:season" },
        { title: Translation.tr("Popular films"), note: Translation.tr("Films and series"), filter: { kind: "movie" }, place: "movie:movies" },
        { title: Translation.tr("Popular series"), filter: { kind: "series" }, place: "movie:series" },
        { title: Translation.tr("Top rated films"), filter: { kind: "movie", catalog: "imdbRating" }, place: "movie:top" }
    ]
    // Why something is missing: a catalogue down (the other's shelves still show), or still asking.
    readonly property string down: Array.from(new Set([root.anime.down, root.movies.down])).filter(text => text.length > 0).join("  ·  ")
    readonly property string status: root.down.length > 0 ? root.down
        : root.hero === null ? Translation.tr("Asking %1…").arg("AniList") : ""

    IrisText {
        visible: root.prism
        Layout.fillWidth: true
        text: Translation.tr("Home")
        color: IrisStyle.text
        font.family: IrisStyle.fontTitle
        font.pixelSize: IrisStyle.typeTitleLarge
        font.weight: IrisStyle.weight(Font.Bold)
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.status.length > 0 && (!root.prism || root.hero !== null || root.down.length > 0)
        spacing: Math.round(12 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: root.status
            color: IrisStyle.muted
            wrapMode: Text.WordWrap
        }
        IrisButton {
            visible: root.down.length > 0
            quiet: true
            text: Translation.tr("Retry")
            onClicked: CornerState.attempt++
        }
    }

    // The hero: the show's banner behind its cover, its name, what it is about, and what to do with it.
    ClippingRectangle {
        id: hero
        objectName: "hero"
        readonly property var show: root.hero
        readonly property bool compact: root.width < Math.round(600 * root.d * Math.min(1.4, IrisStyle.typeScale))
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round((root.prism ? 232 : 250) * root.d)
        visible: root.prism || hero.show !== null
        radius: IrisStyle.radiusTile
        color: IrisStyle.fillQuiet

        IrisImage {
            anchors.fill: parent
            source: String(hero.show?.banner || hero.show?.imageLarge || "")
            fillMode: Image.PreserveAspectCrop
        }
        // Keep the words readable even when the catalogue supplies very bright art.
        Rectangle {
            anchors.fill: parent
            visible: root.prism
            color: Qt.alpha(IrisStyle.darkSurfaceOpaque, 0.46)
        }
        // The words sit on the left: the banner fades into the surface under them.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.prism ? IrisStyle.veilHeavy : IrisStyle.artVeilHeavy }
                GradientStop { position: 0.55; color: root.prism ? IrisStyle.veilStrong : IrisStyle.artVeil }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(18 * root.d)
            spacing: Math.round(18 * root.d)

            ClippingRectangle {
                id: heroCover
                visible: hero.show !== null && (!root.prism || !hero.compact)
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(height / 1.5)
                radius: IrisStyle.tileRadius(width * 0.5)
                color: IrisStyle.fillQuiet
                IrisImage { anchors.fill: parent; source: String(hero.show?.imageLarge ?? "") }
                MouseArea {
                    id: coverAction
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: String(hero.show?.title ?? "")
                    onClicked: CornerState.openShow(hero.show)
                    Keys.onReturnPressed: CornerState.openShow(hero.show)
                    Keys.onSpacePressed: CornerState.openShow(hero.show)
                }
                CornerFocusRing { on: coverAction.activeFocus }
            }

            ColumnLayout {
                objectName: "heroText"
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Math.round(6 * root.d)
                IrisText {
                    text: hero.show ? Translation.tr("Trending now") : Translation.tr("Media Corner")
                    color: root.prism ? IrisStyle.inkOnDark : IrisStyle.identity.green
                    font.pixelSize: IrisStyle.typeFootnote
                    font.weight: IrisStyle.weight(Font.Bold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: String(hero.show?.title ?? Translation.tr("Media Corner"))
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: root.prism ? 30 * IrisStyle.typeScale : IrisStyle.typeTitleLarge
                    font.letterSpacing: root.prism ? -0.6 : 0
                    color: root.prism ? IrisStyle.inkOnDark : IrisStyle.text
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    Layout.fillWidth: true
                    text: [hero.show?.year, Translation.tr(String(hero.show?.type ?? "")), (hero.show?.genres ?? []).slice(0, 3).map(g => Translation.tr(g)).join(" · "),
                           Number(hero.show?.score ?? 0) > 0 ? "★ " + Number(hero.show.score).toFixed(1) : ""].filter(x => String(x ?? "").length > 0).join("  ·  ")
                    color: root.prism ? Qt.alpha(IrisStyle.inkOnDark, 0.56) : IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: String(hero.show?.description ?? root.status)
                    color: root.prism ? Qt.alpha(IrisStyle.inkOnDark, 0.56) : IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeLabel
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 3
                }
                RowLayout {
                    id: actions
                    objectName: "heroActions"
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)
                    // Use the viewport, not a layout width that the two buttons themselves can enlarge.
                    readonly property real available: Math.max(0, root.width - 36 * root.d - (heroCover.visible ? heroCover.width + 18 * root.d : 0))
                    readonly property bool roomy: available >= playAction.implicitWidth + spacing + detailsAction.implicitWidth
                    IrisButton {
                        id: playAction
                        objectName: "heroPlay"
                        visible: root.prism && hero.show !== null
                        emphasized: true
                        foreground: IrisStyle.darkSurfaceOpaque
                        colBackground: IrisStyle.inkOnDark
                        colBackgroundHover: Qt.darker(IrisStyle.inkOnDark, 1.12)
                        buttonRadius: height / 2
                        buttonRadiusPressed: height / 2
                        implicitWidth: playLabel.implicitWidth + Math.round(30 * root.d)
                        Accessible.name: Translation.tr("Watch")
                        Row {
                            id: playLabel
                            anchors.centerIn: parent
                            spacing: Math.round(6 * root.d)
                            MaterialSymbol {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "play_arrow"
                                fill: 1
                                iconSize: Math.round(16 * root.d)
                                color: playAction.foreground
                            }
                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Translation.tr("Watch")
                                color: playAction.foreground
                                font.pixelSize: IrisStyle.typeLabel
                                font.weight: IrisStyle.weight(Font.DemiBold)
                            }
                        }
                        onClicked: {
                            CornerState.openShow(hero.show)
                            CornerWatch.begin(Object.assign({}, hero.show, { film: hero.show?.type === "Movie" || Number(hero.show?.episodes) === 1 }), { episode: 1 })
                        }
                    }
                    IrisButton {
                        visible: !root.prism && hero.show !== null
                        emphasized: true
                        text: Translation.tr("Details")
                        onClicked: CornerState.openShow(hero.show)
                    }
                    IrisButton {
                        id: detailsAction
                        objectName: "heroDetails"
                        visible: root.prism && hero.show !== null && actions.roomy
                        foreground: IrisStyle.inkOnDark
                        colBackground: IrisStyle.veilStrong
                        colBackgroundHover: IrisStyle.veilHeavy
                        buttonRadius: height / 2
                        buttonRadiusPressed: height / 2
                        text: Translation.tr("Details")
                        onClicked: CornerState.openShow(hero.show)
                    }
                    IrisIconButton {
                        visible: root.prism && hero.show !== null && !actions.roomy
                        materialIcon: "info"
                        foreground: IrisStyle.inkOnDark
                        quiet: false
                        colBackground: IrisStyle.veilStrong
                        colBackgroundHover: IrisStyle.veilHeavy
                        Accessible.name: Translation.tr("Details")
                        onClicked: CornerState.openShow(hero.show)
                    }
                }
            }
        }
    }

    RowLayout {
        visible: root.prism
        Layout.fillWidth: true
        spacing: Math.round(8 * root.d)
        Repeater {
            model: [root.featuredAnime, root.featuredFilm]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(150 * root.d)
                radius: IrisStyle.radiusCard
                color: IrisStyle.surfaceHighestOpaque
                border.width: 1
                border.color: Qt.alpha(IrisStyle.text, 0.08)
                clip: true
                IrisImage {
                    anchors.fill: parent
                    source: String(modelData?.banner || modelData?.imageLarge || "")
                    fillMode: Image.PreserveAspectCrop
                }
                Rectangle { anchors.fill: parent; color: IrisStyle.artVeilHeavy }
                IrisText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Math.round(18 * root.d)
                    text: String(modelData?.title ?? root.status)
                    color: IrisStyle.inkOnDark
                    font.pixelSize: IrisStyle.typeTitle
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: modelData !== null
                    activeFocusOnTab: enabled
                    Accessible.role: Accessible.Button
                    Accessible.name: String(modelData?.title ?? "")
                    onClicked: CornerState.openShow(modelData)
                    Keys.onReturnPressed: CornerState.openShow(modelData)
                    Keys.onSpacePressed: CornerState.openShow(modelData)
                }
            }
        }
    }
    Repeater {
        model: root.shelves
        MediaRow {
            required property var modelData
            store: modelData.anime ? root.anime : root.movies
            title: modelData.title
            note: modelData.note ?? ""
            filter: modelData.filter
            allPlace: modelData.place
        }
    }
}
