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
// (~/.config/inir/plugins/movie-corner.json).
Item {
    id: root
    readonly property real d: IrisStyle.density

    function opt(name: string, fallback: var): var { return CornerState.options[name] ?? fallback }
    function row(spec: var): var {
        return Object.assign({ section: "movie-corner", target: "movie-corner" }, spec, spec.option ? {
            state: () => root.opt(spec.option, spec.fallback),
            set: value => CornerState.set(spec.option, value)
        } : {})
    }

    readonly property var groups: [
        { title: "Watch", rows: [
            root.row({ label: "Audio", description: "The language they speak. The original plays from every site; each dub from the sites that have it.", option: "audio", kind: "choice", fallback: "original",
                choices: [
                    { label: "Original audio", value: "original" },
                    { label: "Latin American Spanish", value: "es-419" },
                    { label: "Spain Spanish", value: "es-ES" }
                ] }),
            root.row({ label: "Subtitles", description: "With the original audio, the subtitles' language. Automatic follows iNiR's language.", option: "subs", kind: "choice", fallback: "auto",
                showIf: () => root.opt("audio", "original") === "original",
                choices: [
                    { label: "Automatic", value: "auto" },
                    { label: "None", value: "none" },
                    { label: "English", value: "en" },
                    { label: "Spanish", value: "es" },
                    { label: "Brazilian Portuguese", value: "pt-BR" },
                    { label: "French", value: "fr" },
                    { label: "German", value: "de" },
                    { label: "Italian", value: "it" },
                    { label: "Arabic", value: "ar" },
                    { label: "Russian", value: "ru" },
                    { label: "Turkish", value: "tr" },
                    { label: "Japanese", value: "ja" },
                    { label: "Korean", value: "ko" },
                    { label: "Chinese", value: "zh" },
                    { label: "Hindi", value: "hi" },
                    { label: "Indonesian", value: "id" },
                    { label: "Vietnamese", value: "vi" },
                    { label: "Polish", value: "pl" },
                    { label: "Ukrainian", value: "uk" },
                    { label: "Hebrew", value: "he" },
                    { label: "Dutch", value: "nl" }
                ] }),
            root.row({ label: "Source", description: "Ask shows every source that has it, with its picture and subtitles. A source plays first when it has it; when it doesn't, the best other one does.", option: "source", kind: "choice", fallback: "ask",
                choices: [
                    { label: "Ask every time", value: "ask" },
                    { label: "Best available", value: "auto" }
                ].concat(CornerWatch.sources_.map(s => ({ label: String(s.name || s.id), value: String(s.id) }))) })
        ] },
        { title: "Sources", rows: [
            root.row({ label: "Your sources", description: "The Corner comes with none. Add a Stremio add-on by its address, or put source files (Python, see the Corner's README) in the sources folder.", kind: "list", view: Qt.resolvedUrl("MovieSourcesList.qml"), summary: false }),
            root.row({ label: "Check the sources", description: "Tries every source now on one well-known film and says which ones play.", kind: "action", button: "Check", run: () => CornerWatch.checkSources() }),
            root.row({ label: "TMDB key", description: "Your free API key or read access token from themoviedb.org › Settings › API: a title's page then says where it streams officially. Kept in your system keyring, never in a settings file.", kind: "text", secret: true, placeholder: "Paste your API key",
                state: () => { CornerWatch.loadKeys(); return CornerWatch.secretOf("tmdb") }, set: value => CornerWatch.setKey("tmdb", String(value ?? "")) })
        ] },
        { title: "The Corner", rows: [
            root.row({ label: "In the app launcher", description: "An entry named Movie Corner in the launcher's search, so it can be pinned to the Dock too.", option: "launcher", kind: "switch", fallback: true }),
            root.row({ label: "Open in a window", description: "A window of its own instead of over the desktop.", option: "windowed", kind: "switch", fallback: false })
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
