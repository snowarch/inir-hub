pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/sources.js" as Sources
import "../state/watch.js" as Watch
import "../state/streams.js" as Streams
import "../state/subtitles.js" as Subtitles

// Watch's page, in place of the title: what it found in the person's sources, and how opening mpv is going. As soon as
// mpv's window is there, CornerWatch closes it (and the overlay). Escape or ‹ leaves it, and stops an opening.
// One step: the streams can be opened at once; the subtitles come preselected by the person's language and a menu
// over the streams changes them.
MediaPage {
    id: root
    // A web source went to the browser.
    signal followed()
    readonly property var webs: CornerSources.webs
    readonly property bool nothingAdded: CornerSources.list.length === 0
    property string sourceFilter: ""
    property bool sortStreams: false
    property var pendingStream: null
    readonly property real pendingResume: pendingStream ? CornerWatch.resumeAt(Streams.watchKey(CornerWatch.show, CornerWatch.episode)) : 0
    readonly property var sourceNames: Watch.sourceNames(CornerWatch.streams)
    readonly property var displayedStreams: Watch.displayedStreams(CornerWatch.streams, root.sourceFilter, root.sortStreams)
    readonly property bool sourceFailed: CornerWatch.mappingError || CornerWatch.sourceResults.some(result => result.state === "error" || result.state === "limited")
    readonly property bool sourceUnidentified: CornerWatch.sourceResults.some(result => result.state === "unidentified")
    Connections {
        target: CornerWatch
        function onShowChanged(): void { root.sourceFilter = ""; root.sortStreams = false; root.pendingStream = null }
        function onEpisodeChanged(): void { root.sourceFilter = ""; root.sortStreams = false; root.pendingStream = null }
    }
    readonly property string status: CornerWatch.mpvMissing ? Translation.tr("mpv isn't installed. Install the package mpv to watch here")
        : CornerWatch.phase === "finding" ? Translation.tr("Looking in your sources…")
        : CornerWatch.phase === "launching" ? (CornerWatch.slow ? Translation.tr("mpv is still opening it…") : Translation.tr("Opening mpv…"))
        : root.nothingAdded ? Translation.tr("You have no sources yet")
        : CornerWatch.streams.length === 0 && root.webs.length === 0 ? (root.sourceFailed ? Translation.tr("Request failed")
            : root.sourceUnidentified ? Translation.tr("Could not identify this title for this source")
            : Translation.tr("Your sources have nothing for this"))
        : ""

    spacing: Math.round(10 * root.d)

    component Choice: IrisButton {
        id: choice
        property string glyph: ""
        property string main: ""
        property string side: ""
        Layout.fillWidth: true
        implicitHeight: Math.round(46 * root.d)
        quiet: true
        Accessible.name: choice.main + (choice.side ? ", " + choice.side : "")
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(12 * root.d)
            anchors.rightMargin: Math.round(12 * root.d)
            spacing: Math.round(10 * root.d)
            MaterialSymbol {
                text: choice.glyph
                iconSize: Math.round(20 * root.d)
                color: IrisStyle.textSecondary
            }
            IrisText {
                Layout.fillWidth: true
                text: choice.main
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
            IrisText {
                text: choice.side
                textFormat: Text.PlainText
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
            }
        }
    }

    CornerHeading {
        page: true
        eyebrow: Translation.tr("Watch")
        title: CornerWatch.episode ? Translation.tr("%1, episode %2").arg(CornerWatch.title).arg(CornerWatch.episode.episode) : CornerWatch.title
    }
    IrisText {
        Layout.fillWidth: true
        visible: root.pendingStream !== null
        text: root.pendingStream ? Translation.tr("Open stream from %1 at %2?").arg(String(root.pendingStream.source)).arg(Streams.hostOf(root.pendingStream.url)) : ""
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
    }
    Flow {
        Layout.fillWidth: true
        visible: root.pendingStream !== null
        spacing: Math.round(6 * root.d)
        CornerPill {
            visible: root.pendingResume > 0
            enabled: CornerWatch.progressLoaded
            tone: "solid"
            glyph: "play_arrow"
            label: Translation.tr("Continue")
            onClicked: root.open(true)
        }
        CornerPill {
            enabled: CornerWatch.progressLoaded
            tone: root.pendingResume > 0 ? "quiet" : "solid"
            glyph: root.pendingResume > 0 ? "replay" : "play_arrow"
            label: root.pendingResume > 0 ? Translation.tr("Start from beginning") : Translation.tr("Open")
            onClicked: root.open(false)
        }
        CornerPill {
            label: Translation.tr("Cancel")
            onClicked: root.pendingStream = null
        }
    }
    // Opening takes the subtitles as they stand: the preselection, or what the menu changed it to.
    function open(resume: bool): void {
        const stream = root.pendingStream
        root.pendingStream = null
        if (!CornerWatch.subtitleChoiceMade) CornerWatch.chooseSubtitle(CornerWatch.selectedSubtitle)
        CornerWatch.play(stream, resume)
    }
    IrisText {
        Layout.fillWidth: true
        visible: root.status.length > 0
        text: root.status
        color: IrisStyle.muted
        wrapMode: Text.WordWrap
    }
    RowLayout {
        Layout.fillWidth: true
        visible: !CornerWatch.progressLoaded
        IrisText {
            Layout.fillWidth: true
            text: CornerWatch.progressLoadFailed ? Translation.tr("Could not load playback history") : Translation.tr("Looking…")
            wrapMode: Text.WordWrap
        }
        IrisButton {
            visible: CornerWatch.progressLoadFailed
            text: Translation.tr("Retry")
            onClicked: CornerWatch.retryProgressLoad()
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.error.length > 0 && CornerWatch.error !== Translation.tr("Request failed")
        text: CornerWatch.error
        textFormat: Text.PlainText
        color: IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    IrisButton {
        visible: CornerWatch.retryPlayback !== null && CornerWatch.phase === "choosing"
        enabled: CornerWatch.progressLoaded
        text: Translation.tr("Retry playback")
        onClicked: {
            const retry = CornerWatch.retryPlayback
            CornerWatch.play(retry.stream, retry.resume)
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.subtitleError.length > 0
        text: CornerWatch.subtitleError
        color: IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    CornerPill {
        visible: root.nothingAdded
        tone: "solid"
        glyph: "extension"
        label: Translation.tr("Add a source")
        onClicked: CornerState.pick("sources")
    }
    Repeater {
        model: CornerWatch.sourceResults
        IrisText {
            required property var modelData
            Layout.fillWidth: true
            text: String(modelData.name) + ": " + (modelData.state === "waiting" ? Translation.tr("Looking…")
                : modelData.state === "unidentified" ? Translation.tr("Could not identify this title for this source")
                : modelData.state === "unsupported" ? Translation.tr("Not available for this title")
                : modelData.state === "limited" ? CornerState.limitedText(modelData.retryAfter ?? "")
                : modelData.state === "error" ? Translation.tr("Request failed")
                : Translation.tr("%1 streams").arg(modelData.count))
            textFormat: Text.PlainText
            color: IrisStyle.muted
            wrapMode: Text.WordWrap
        }
    }
    // Subtitles: preselected by language, changed here before opening a stream.
    RowLayout {
        Layout.fillWidth: true
        visible: CornerWatch.subtitles.length > 0
        spacing: Math.round(10 * root.d)
        MaterialSymbol { text: "subtitles"; iconSize: Math.round(20 * root.d); color: IrisStyle.textSecondary }
        IrisText { Layout.fillWidth: true; text: Translation.tr("Subtitles"); font.weight: IrisStyle.weight(Font.DemiBold) }
        IrisPopupButton {
            enabled: CornerWatch.phase === "choosing"
            accessibleName: Translation.tr("Subtitles")
            options: [{ value: -1, label: Translation.tr("No subtitles") }].concat(CornerWatch.subtitles.map((subtitle, index) => ({ value: index,
                label: String(subtitle.name) + " · " + Subtitles.languageLabel(subtitle.lang) + (subtitle.hearingImpaired ? " · " + Translation.tr("Hearing impaired") : "") + (subtitle.source ? " · " + String(subtitle.source) : "") })))
            current: CornerWatch.subtitles.indexOf(CornerWatch.selectedSubtitle)
            onPicked: value => CornerWatch.chooseSubtitle(value >= 0 ? CornerWatch.subtitles[value] : null)
        }
    }
    Flow {
        Layout.fillWidth: true
        visible: CornerWatch.streams.length > 0 && !CornerWatch.mpvMissing
        spacing: Math.round(6 * root.d)
        IrisButton {
            text: Translation.tr("All sources")
            quiet: root.sourceFilter !== ""
            onClicked: root.sourceFilter = ""
        }
        Repeater {
            model: root.sourceNames
            IrisButton {
                required property string modelData
                text: modelData
                quiet: root.sourceFilter !== modelData
                onClicked: root.sourceFilter = modelData
            }
        }
        IrisButton {
            text: root.sortStreams ? Translation.tr("Original order") : Translation.tr("Sort by source and name")
            onClicked: root.sortStreams = !root.sortStreams
        }
    }
    Repeater {
        model: CornerWatch.mpvMissing ? [] : root.displayedStreams
        Choice {
            required property var modelData
            glyph: "play_arrow"
            main: String(modelData.name)
            side: String(modelData.source)
            enabled: CornerWatch.phase === "choosing" && CornerWatch.progressLoaded
            onClicked: { CornerWatch.retryPlayback = null; CornerWatch.error = ""; root.pendingStream = modelData; root.contentY = 0 }
        }
    }
    IrisGroupTitle {
        visible: root.webs.length > 0
        text: Translation.tr("On the web")
    }
    Repeater {
        model: root.webs
        Choice {
            required property var modelData
            glyph: "open_in_new"
            main: Translation.tr("Open in %1").arg(CornerSources.displayName(modelData))
            onClicked: {
                const url = Sources.webUrl(modelData.template, CornerWatch.title)
                if (!url || !Qt.openUrlExternally(url)) {
                    CornerWatch.error = Translation.tr("Could not open the web source")
                    return
                }
                CornerState.sheet = false
                root.followed()
            }
        }
    }
}
