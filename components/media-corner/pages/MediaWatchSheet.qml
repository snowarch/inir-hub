pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/sources.js" as Sources

// Watch's page, in place of the title: what it found in the person's sources, and how opening mpv is going. As soon as
// mpv's window is there, CornerWatch closes it (and the overlay). Escape or the arrow leaves it, and stops an opening.
MediaPage {
    id: root
    // A web source went to the browser.
    signal followed()
    readonly property var webs: CornerSources.webs
    readonly property bool nothingAdded: CornerSources.list.length === 0
    readonly property string status: CornerWatch.mpvMissing ? Translation.tr("mpv isn't installed. Install the package mpv to watch here")
        : CornerWatch.phase === "finding" ? Translation.tr("Looking in your sources…")
        : CornerWatch.phase === "launching" ? (CornerWatch.slow ? Translation.tr("mpv is still opening it…") : Translation.tr("Opening mpv…"))
        : root.nothingAdded ? Translation.tr("You have no sources yet")
        : CornerWatch.streams.length === 0 && root.webs.length === 0 ? Translation.tr("Your sources have nothing for this")
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

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * root.d)
        IrisIconButton {
            materialIcon: "arrow_back"
            Accessible.name: Translation.tr("Back")
            onClicked: CornerState.sheet = false
        }
        IrisText {
            Layout.fillWidth: true
            text: CornerWatch.episode ? Translation.tr("%1, episode %2").arg(CornerWatch.title).arg(CornerWatch.episode.episode) : CornerWatch.title
            textFormat: Text.PlainText
            font.family: IrisStyle.fontTitle
            font.pixelSize: IrisStyle.typeTitle
            font.weight: IrisStyle.weight(Font.Bold)
            elide: Text.ElideRight
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: root.status.length > 0
        text: root.status
        color: IrisStyle.muted
        wrapMode: Text.WordWrap
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.error.length > 0
        text: CornerWatch.error
        textFormat: Text.PlainText
        color: IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.subtitleError.length > 0
        text: CornerWatch.subtitleError
        color: IrisStyle.muted
        wrapMode: Text.WordWrap
    }
    IrisButton {
        visible: root.nothingAdded
        text: Translation.tr("Add a source")
        onClicked: CornerState.pick("sources")
    }
    IrisGroupTitle {
        visible: CornerWatch.subtitles.length > 0
        text: Translation.tr("Subtitles")
    }
    Choice {
        visible: CornerWatch.subtitles.length > 0
        glyph: "subtitles_off"
        main: Translation.tr("No subtitles")
        side: CornerWatch.selectedSubtitle === null ? "✓" : ""
        onClicked: CornerWatch.selectedSubtitle = null
    }
    Repeater {
        model: CornerWatch.subtitles
        Choice {
            required property var modelData
            glyph: "subtitles"
            main: String(modelData.name) + " · " + String(modelData.lang)
            side: CornerWatch.selectedSubtitle === modelData ? "✓" : String(modelData.source)
            onClicked: CornerWatch.selectedSubtitle = modelData
        }
    }
    Repeater {
        model: CornerWatch.mpvMissing ? [] : CornerWatch.streams
        Choice {
            required property var modelData
            glyph: "play_arrow"
            main: String(modelData.name)
            side: String(modelData.source)
            onClicked: CornerWatch.play(modelData)
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
            main: Translation.tr("Open in %1").arg(String(modelData.name))
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
