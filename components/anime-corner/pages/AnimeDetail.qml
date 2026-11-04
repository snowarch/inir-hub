pragma ComponentBehavior: Bound
import QtQuick
import qs
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.pieces
import qs.modules.iris.state
import "../state"

// One show in full, over the page it was opened from: banner, what it is about, where to watch it and what AniList
// recommends next to it. ani-cli's questions answer in the Continue card embedded here, so no terminal is needed.
Flickable {
    id: root
    required property AnimeCornerData store
    property var show: null
    // One narrow column (Pocket): a smaller cover and banner.
    property bool compact: false
    signal back()
    signal openShow(var show)
    signal openSection(string id)

    readonly property real d: IrisStyle.density
    // The AniList page in full (recommendations, banner); the poster's own data meanwhile.
    property var full: null
    readonly property var s: root.full ?? root.show ?? ({})
    readonly property bool followed: IrisPieces.animeFollows(Number(root.s.id ?? 0))
    readonly property string watchTitle: String(root.s.titleRomaji || root.s.title || "")
    // ani-cli's history entry: the one a Continue poster carries, else the one whose title matches this show's.
    readonly property var watch: root.show?.watch ?? CornerWatch.entryFor([root.s.titleRomaji, root.s.title, root.s.titleJapanese])
    readonly property string resumeEpisode: root.watch ? CornerWatch.stateOf(root.watch).episode : ""
    // How many to list: AniList's count, what has aired of a running show, or one past the furthest you have been.
    readonly property int episodeCount: {
        const total = Number(root.s.episodes)
        if (total > 0) return total
        const aired = Number(root.s.nextEpisode ?? 0) - 1
        if (aired > 0) return aired
        if (!root.watch) return 0
        const seen = Object.keys(CornerWatch.progress?.[CornerWatch.progressKey(root.watch)] ?? {}).map(Number).filter(n => isFinite(n))
        return Math.max(Number(root.watch.episode) || 0, ...seen, 0) + 1
    }
    // The synopsis opens at five lines.
    property bool readMore: false

    onShowChanged: {
        root.full = null
        root.readMore = false
        root.contentY = 0
        const id = Number(root.show?.id ?? 0)
        if (id > 0) root.store.detail(id, (result, error) => { if (!error && Number(root.show?.id ?? 0) === id) root.full = result }, root.voices)
    }
    // The cast's voices in the language the person watches in; AniList has no Russian or Indian dub credits.
    readonly property string voices: ({ en: "ENGLISH", "es-419": "SPANISH", "pt-BR": "PORTUGUESE", fr: "FRENCH", de: "GERMAN", it: "ITALIAN" })[CornerWatch.audio] ?? "JAPANESE"

    function fmtStatus(status: string): string {
        return ({ RELEASING: Translation.tr("Airing"), FINISHED: Translation.tr("Finished"), NOT_YET_RELEASED: Translation.tr("Not yet aired"),
            CANCELLED: Translation.tr("Cancelled"), HIATUS: Translation.tr("On hiatus") })[status] ?? status
    }

    contentHeight: column.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    IrisScrollFeel {}
    ScrollBar.vertical: IrisScrollBar {}

    ColumnLayout {
        id: column
        width: root.width
        spacing: Math.round(18 * root.d)

        // Banner, with the cover overlapping its foot and the name beside it.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round((root.compact ? 280 : 360) * root.d)

            ClippingRectangle {
                id: banner
                width: parent.width
                height: Math.round((root.compact ? 170 : 240) * root.d)
                radius: IrisStyle.radiusTile
                color: IrisStyle.fillQuiet
                IrisImage {
                    anchors.fill: parent
                    source: String(root.s.banner || root.s.imageLarge || "")
                    fillMode: Image.PreserveAspectCrop
                }
                Rectangle {
                    anchors.fill: parent
                    // The banner melts into the sheet, so the name under it reads on one ground.
                    gradient: Gradient {
                        GradientStop { position: 0.3; color: "transparent" }
                        GradientStop { position: 1; color: IrisStyle.surfaceOpaque }
                    }
                }
                // On a plate, so it reads over any banner; Pocket has its own ‹ in the head.
                Rectangle {
                    visible: !root.compact
                    anchors { left: parent.left; top: parent.top; margins: Math.round(10 * root.d) }
                    width: backButton.width + Math.round(4 * root.d)
                    height: width
                    radius: width / 2
                    color: IrisStyle.artVeilHeavy
                    IrisIconButton {
                        id: backButton
                        anchors.centerIn: parent
                        materialIcon: "arrow_back"
                        Accessible.name: Translation.tr("Back")
                        onClicked: root.back()
                    }
                }
            }

            IrisBodyShadow {
                x: cover.x
                y: cover.y + Math.round(8 * root.d)
                width: cover.width
                height: cover.height
                radius: cover.radius
                blur: 24 * root.d
                spread: -4 * root.d
                color: IrisStyle.shadow
            }
            ClippingRectangle {
                id: cover
                x: Math.round(22 * root.d)
                anchors.bottom: parent.bottom
                width: Math.round((root.compact ? 104 : 160) * root.d)
                height: Math.round(width * 1.5)
                radius: IrisStyle.radiusTile
                color: IrisStyle.fillQuiet
                border.width: 1
                border.color: IrisStyle.hairline
                IrisImage { anchors.fill: parent; source: String(root.s.imageLarge || root.s.image || "") }
            }

            ColumnLayout {
                anchors { left: cover.right; leftMargin: Math.round(18 * root.d); right: parent.right; top: banner.bottom; topMargin: Math.round(12 * root.d); bottom: parent.bottom }
                spacing: Math.round(4 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: String(root.s.title ?? "")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.weight(Font.Bold)
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: [root.s.titleRomaji, root.s.titleJapanese].filter(t => t && t !== root.s.title).join(" · ")
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                Item { Layout.fillHeight: true }
                // Wraps in a narrow column (Pocket) instead of cutting its last button.
                Flow {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)
                    // Where you were, when you have been here; else ani-cli's search.
                    IrisButton {
                        emphasized: true
                        visible: CornerWatch.hasSources || !CornerWatch.sourcesKnown || ["en", ""].includes(CornerWatch.audio === "ja" ? CornerWatch.subs : CornerWatch.audio)
                        enabled: CornerWatch.canTarget && CornerWatch.canStart && (root.watch !== null || root.watchTitle.length > 0)
                        text: root.resumeEpisode.length > 0 ? Translation.tr("Continue · Ep %1").arg(root.resumeEpisode) : Translation.tr("Watch")
                        onClicked: {
                            CornerWatch.lookFor(root.s)
                            root.watch ? CornerWatch.resume(root.watch) : CornerWatch.search(root.watchTitle)
                        }
                    }
                    IrisChip {
                        glyph: "translate"
                        label: CornerWatch.watchLine
                        Accessible.description: Translation.tr("Change it in the Corner's Settings")
                        onClicked: CornerState.place = "settings"
                    }
                    IrisChip {
                        glyph: "bookmark"
                        label: root.followed ? Translation.tr("Following") : Translation.tr("Follow")
                        selected: root.followed
                        enabled: Number(root.s.id ?? 0) > 0
                        onClicked: IrisPieces.animeToggleFollow(Number(root.s.id))
                    }
                    // Where it streams officially, from AniList: opens the service in the browser.
                    Repeater {
                        model: Array.from(root.s.streaming ?? []).slice(0, 4)
                        IrisChip {
                            required property var modelData
                            glyph: "play_circle"
                            label: String(modelData.site)
                            Accessible.description: Translation.tr("Watch it on %1").arg(String(modelData.site))
                            onClicked: Qt.openUrlExternally(String(modelData.url))
                        }
                    }
                    IrisChip {
                        glyph: "open_in_new"
                        label: Translation.tr("AniList")
                        enabled: String(root.s.url ?? "").length > 0
                        onClicked: Qt.openUrlExternally(String(root.s.url))
                    }
                }
            }
        }

        // No sources: where to add one, under the official links.
        IrisText {
            Layout.fillWidth: true
            visible: CornerWatch.sourcesKnown && !CornerWatch.hasSources
            text: Array.from(root.s.streaming ?? []).length > 0
                ? Translation.tr("Watch it on the services above, or add your own source in the Corner's Settings › Sources")
                : Translation.tr("No sources yet: add one in the Corner's Settings › Sources")
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
            wrapMode: Text.WordWrap
        }

        // No ani-cli: say so where the button would have worked.
        IrisText {
            Layout.fillWidth: true
            visible: !CornerWatch.canTarget
            text: Translation.tr("Watching needs python3 and mpv installed")
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
            wrapMode: Text.WordWrap
        }

        // The facts, in one line each.
        Flow {
            Layout.fillWidth: true
            spacing: Math.round(18 * root.d)
            Repeater {
                model: [
                    { label: Translation.tr("Score"), value: Number(root.s.score ?? 0) > 0 ? "★ " + Number(root.s.score).toFixed(1) : "" },
                    { label: Translation.tr("Format"), value: Translation.tr(String(root.s.type ?? "")) },
                    { label: Translation.tr("Episodes"), value: String(root.s.episodes ?? "") === "?" ? "" : String(root.s.episodes ?? "") },
                    { label: Translation.tr("Length"), value: Number(root.s.duration ?? 0) > 0 ? Translation.tr("%1 min").arg(root.s.duration) : "" },
                    { label: Translation.tr("Status"), value: root.fmtStatus(String(root.s.status ?? "")) },
                    { label: Translation.tr("Season"), value: [Translation.tr(AnimeService.getSeasonDisplayName(String(root.s.season ?? ""))), root.s.year].filter(x => String(x ?? "").length > 0).join(" ") },
                    { label: Translation.tr("Studio"), value: (root.s.studios ?? []).join(", ") },
                    { label: Translation.tr("Next"), value: Number(root.s.nextEpisode ?? 0) > 0 ? Translation.tr("Ep %1 in %2").arg(root.s.nextEpisode).arg(IrisPieces.animeWait(root.s.airingAt)) : "" }
                ].filter(fact => String(fact.value).length > 0)
                delegate: ColumnLayout {
                    required property var modelData
                    spacing: 0
                    IrisText { text: modelData.label; color: IrisStyle.muted; font.pixelSize: IrisStyle.typeFootnote }
                    IrisText { text: modelData.value; font.pixelSize: IrisStyle.typeLabel; font.weight: IrisStyle.weight(Font.DemiBold) }
                }
            }
        }

        // Each genre opens its own list.
        Flow {
            Layout.fillWidth: true
            spacing: Math.round(6 * root.d)
            Repeater {
                model: root.s.genres ?? []
                delegate: IrisChip {
                    required property string modelData
                    label: Translation.tr(modelData)
                    onClicked: root.openSection("genre:" + modelData)
                }
            }
        }

        IrisText {
            id: synopsis
            Layout.fillWidth: true
            visible: text.length > 0
            text: String(root.s.description ?? "")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeBody
            wrapMode: Text.WordWrap
            lineHeight: 1.15
            maximumLineCount: root.readMore ? 400 : 5
            elide: Text.ElideRight
        }
        IrisText {
            visible: synopsis.truncated || root.readMore
            text: root.readMore ? Translation.tr("Show less") : Translation.tr("Read more")
            color: IrisStyle.accent
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(Font.DemiBold)
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.readMore = !root.readMore }
        }

        // Any episode, to go back to one or skip ahead.
        AnimeEpisodes {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(6 * root.d)
            entry: root.watch
            title: root.watchTitle
            show: root.s
            count: root.episodeCount
        }

        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("Related")
            note: Translation.tr("Seasons, films and side stories")
            seeAll: false
            local: root.full?.relations ?? []
            onOpenShow: show => root.openShow(show)
        }

        // Who is in it, and who voices them in the language you watch in.
        ColumnLayout {
            Layout.fillWidth: true
            visible: (root.full?.characters ?? []).length > 0
            spacing: Math.round(8 * root.d)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                IrisText {
                    text: Translation.tr("Characters")
                    font.pixelSize: IrisStyle.typeHeadline
                    font.weight: IrisStyle.weight(Font.Bold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Voiced in %1").arg(CornerWatch.languageName(root.voices === "JAPANESE" ? "ja" : CornerWatch.audio))
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
            }
            ListView {
                id: cast
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(64 * root.d) + Math.ceil(IrisStyle.typeLabel * 1.35 + IrisStyle.typeFootnote * 1.4) + Math.round(6 * root.d)
                orientation: ListView.Horizontal
                spacing: Math.round(14 * root.d)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.full?.characters ?? []
                delegate: ColumnLayout {
                    id: person
                    required property var modelData
                    width: Math.round(96 * root.d)
                    spacing: Math.round(3 * root.d)
                    ClippingRectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.round(64 * root.d)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: IrisStyle.fillQuiet
                        border.width: person.modelData.main ? 2 : 0
                        border.color: IrisStyle.accent
                        IrisImage { anchors.fill: parent; source: /^https:\/\//.test(person.modelData.image) ? person.modelData.image : "" }
                    }
                    IrisText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: person.modelData.name
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        font.pixelSize: IrisStyle.typeLabel
                    }
                    IrisText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: person.modelData.voice
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                    }
                }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse
                    acceptedModifiers: Qt.ShiftModifier
                    onWheel: event => cast.flick(event.angleDelta.y * 8, 0)
                }
            }
        }

        AnimeRow {
            Layout.fillWidth: true
            store: root.store
            title: Translation.tr("If you liked it…")
            note: Translation.tr("Recommended on AniList")
            seeAll: false
            local: root.full?.recommendations ?? []
            onOpenShow: show => root.openShow(show)
        }
        Item { Layout.preferredHeight: Math.round(8 * root.d) }
    }
}
