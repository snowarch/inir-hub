pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.settings
import "../state"

// The Corner's own settings, drawn with Settings' rows (IrisSetting) but kept in the Corner's file
// (~/.config/inir/plugins/anime-corner.json); keys and tokens stay in the system keyring. Quality, the subtitle look
// and skipping intros are iRiS's own Anime settings, shared with the Continue bubble: a row opens them there.
Item {
    id: root
    readonly property real d: IrisStyle.density

    function opt(name: string, fallback: var): var { return CornerState.options[name] ?? fallback }
    function row(spec: var): var {
        return Object.assign({ section: "anime-corner", target: "anime-corner" }, spec, spec.option ? {
            state: () => root.opt(spec.option, spec.fallback),
            set: value => CornerState.set(spec.option, value)
        } : {})
    }

    readonly property var groups: [
        { title: "Watch", rows: [
            root.row({ label: "Audio", description: "The language they speak. Japanese is the original; each dub plays from the sites that have it.", option: "audio", kind: "choice", fallback: "ja",
                choices: [{label:"Japanese",value:"ja"},{label:"English",value:"en"},{label:"Latin American Spanish",value:"es-419"},{label:"Brazilian Portuguese",value:"pt-BR"},{label:"French",value:"fr"},{label:"German",value:"de"},{label:"Italian",value:"it"},{label:"Russian",value:"ru"},{label:"Hindi",value:"hi"},{label:"Tamil",value:"ta"},{label:"Telugu",value:"te"}] }),
            root.row({ label: "Subtitles", description: "With Japanese audio, the language of the subtitles in the picture. Automatic follows iNiR's language where a site has it, else English.", option: "subs", kind: "choice", fallback: "auto",
                showIf: () => root.opt("audio", "ja") === "ja",
                choices: [{label:"Automatic",value:"auto"},{label:"English",value:"en"},{label:"Spanish",value:"es"},{label:"Brazilian Portuguese",value:"pt-BR"},{label:"French",value:"fr"},{label:"German",value:"de"},{label:"Italian",value:"it"},{label:"Arabic",value:"ar"}] }),
            root.row({ label: "Source", description: "Ask shows every source that has the episode, with its quality and subtitles. A source plays first when it has the episode; when it doesn't, the best other one does.", option: "source", kind: "choice", fallback: "ask",
                choices: [{label:"Ask every time",value:"ask"},{label:"Best available",value:"auto"}]
                    .concat(CornerWatch.sources.map(s => ({ label: String(s.name || s.id), value: String(s.id) })))
                    .concat([{label:"ani-cli",value:"anicli"}]) }),
            root.row({ label: "Quality, subtitle look and intros", description: "Shared with iRiS's Continue bubble, in Settings › Anime.", kind: "action", button: "Open", run: () => { CornerState.open = false; GlobalStates.openSettingsAt("iris", "anime") } })
        ] },
        { title: "Sources", rows: [
            root.row({ label: "Your sources", description: "The Corner comes with none. Add a Stremio add-on by its address, or put source files (Python, see the Corner's README) in the sources folder.", kind: "list", view: Qt.resolvedUrl("AnimeSourcesList.qml"), summary: false }),
            root.row({ label: "Check the sources", description: "Tries every source now on one well-known show and says which ones play.", kind: "action", button: "Check", run: () => CornerWatch.checkSources() })
        ] },
        { title: "Subtitles online", rows: [
            root.row({ label: "OpenSubtitles key", description: "Your free API key from opensubtitles.com › Profile › API consumers. Kept in your system keyring, never in a settings file.", kind: "text", secret: true, placeholder: "Paste your API key",
                state: () => { CornerWatch.loadKeys(); return CornerWatch.keyOf("opensubtitles") }, set: value => CornerWatch.setKey("opensubtitles", String(value ?? "")) }),
            root.row({ label: "SubDL key", description: "Your free API key from subdl.com › Panel › API. Kept in your system keyring, never in a settings file.", kind: "text", secret: true, placeholder: "Paste your API key",
                state: () => { CornerWatch.loadKeys(); return CornerWatch.keyOf("subdl") }, set: value => CornerWatch.setKey("subdl", String(value ?? "")) })
        ] },
        { title: "Accounts", rows: [
            root.row({ label: "Your accounts", description: "Connect AniList or MyAnimeList: My list in the Anime Corner, and each episode you finish marked on it. Tokens stay in your system keyring.", kind: "list", view: Qt.resolvedUrl("AnimeAccountsList.qml"), summary: false }),
            root.row({ label: "AniList client ID", description: "Create a free app at anilist.co › Settings › Developer with the redirect URL https://anilist.co/api/v2/oauth/pin, then paste its ID.", option: "anilistClientId", kind: "text", fallback: "", placeholder: "12345" }),
            root.row({ label: "MyAnimeList client ID", description: "Create a free app at myanimelist.net › Account › API (type: other) with the redirect URL http://127.0.0.1:47823/callback, then paste its Client ID.", option: "malClientId", kind: "text", fallback: "", placeholder: "Client ID" }),
            root.row({ label: "Mark episodes as watched", description: "When you finish an episode, your connected lists move to it.", option: "syncProgress", kind: "switch", fallback: true }),
            root.row({ label: "Public AniList user", description: "Without connecting: My list reads this user's public AniList list.", option: "anilistUser", kind: "text", fallback: "", placeholder: "User name" }),
            root.row({ label: "Public MyAnimeList user", description: "Without connecting: My list reads this user's public MyAnimeList list.", option: "malUser", kind: "text", fallback: "", placeholder: "User name" })
        ] },
        { title: "The Corner", rows: [
            root.row({ label: "New episode alerts", description: "A notification when a show you follow, or one you are watching on your list, airs a new episode. Its Watch button opens the show.", option: "notify", kind: "switch", fallback: false }),
            root.row({ label: "Open in a window", description: "A window of its own instead of over the desktop.", option: "windowed", kind: "switch", fallback: false }),
            root.row({ label: "In the app launcher", description: "An entry named Anime Corner in the launcher's search, so it can be pinned to the Dock too.", option: "launcher", kind: "switch", fallback: true })
        ] }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(12 * root.d)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("Settings")
                font.family: IrisStyle.fontTitle
                font.pixelSize: IrisStyle.typeTitle
                font.weight: IrisStyle.weight(Font.Bold)
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("Kept in the Corner's own file; removing it leaves your settings as they were.")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                elide: Text.ElideRight
            }
        }
        Flickable {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: list.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            ColumnLayout {
                id: list
                width: scroller.width
                spacing: Math.round(18 * root.d)
                Repeater {
                    model: root.groups
                    ColumnLayout {
                        id: group
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.d)
                        IrisText {
                            text: Translation.tr(group.modelData.title)
                            color: IrisStyle.textSecondary
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(Font.DemiBold)
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: rows.implicitHeight + Math.round(8 * root.d)
                            radius: IrisStyle.radiusTile
                            color: IrisStyle.fillQuiet
                            ColumnLayout {
                                id: rows
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(4 * root.d) }
                                spacing: 0
                                Repeater {
                                    model: group.modelData.rows
                                    IrisSetting {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        spec: modelData
                                        visible: modelData.showIf ? modelData.showIf() : true
                                        last: index === group.modelData.rows.length - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
