pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.services
import qs.modules.common
import qs.modules.nihil
import qs.modules.nihil.style
import "NihilOptions.js" as Options
import "../state/NihilProfiles.js" as Profiles

// NiHiL's Settings as a printed index over the family's field: the pages numbered down a pane of glass, a search that
// reaches every option, and each page opened under its own poster head. Every row comes from NihilOptions.js.
Window {
    id: root

    property string pageId: "profiles"
    property string query: ""

    readonly property var page: Options.pages.find(item => item.id === root.pageId) ?? Options.pages[0]
    readonly property var everyRow: Options.allRows()
    readonly property var found: {
        const words = root.query.trim().toLowerCase().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0)
            return []
        return root.everyRow.filter(row => {
            const text = [Translation.tr(row.label), Translation.tr(row.note), Translation.tr(row.section), row.label].join(" ").toLowerCase()
            return words.every(word => text.includes(word))
        })
    }
    readonly property var foundSections: {
        const bySection = []
        for (const row of root.found) {
            const title = Translation.tr(row.page) + ", " + Translation.tr(row.section)
            let section = bySection.find(item => item.title === title)
            if (!section) {
                section = { title: title, rows: [] }
                bySection.push(section)
            }
            section.rows.push(row)
        }
        return bySection
    }

    // A list option arrives as a QML list; rows compare and write plain arrays.
    function plain(value: var): var {
        return value !== null && typeof value === "object" && value.length !== undefined ? Array.from(value) : value
    }

    function read(key: string): var {
        return root.plain(key.split(".").reduce((node, part) => node?.[part], Config.options?.nihil))
    }

    function factory(key: string): var {
        return root.plain(key.split(".").reduce((node, part) => node?.[part], factoryValues))
    }

    function write(key: string, value: var): void {
        const updates = {}
        updates["nihil." + key] = value
        if (Profiles.keys.includes(key))
            updates["nihil.profile"] = "custom"
        Config.setNestedValues(updates)
    }

    // Where a level's slider starts once it stops being automatic.
    function levelStart(option: var): real {
        const factoryValue = root.factory(option.key)
        if (factoryValue !== option.fit)
            return factoryValue
        const middle = (option.from + option.to) / 2
        return Number((Math.round(middle / option.step) * option.step).toFixed(3))
    }

    function openMenu(option: var, anchor: Item): void {
        menu.show(option, anchor, root.read(option.key))
    }

    function restoreAll(): void {
        const updates = { "nihil.profile": root.factory("profile") }
        for (const row of root.everyRow.filter(item => item.type !== "compositor"))
            updates["nihil." + row.key] = root.factory(row.key)
        Config.setNestedValues(updates)
    }

    visible: true
    title: Translation.tr("NiHiL Settings")
    width: 1120
    height: 760
    minimumWidth: 860
    minimumHeight: 520
    color: NihilStyle.void_
    onClosing: Qt.quit()

    // How NiHiL came: a fresh copy of its options, never written to.
    NihilConfigSchema { id: factoryValues }

    NFieldPaint {
        anchors.fill: parent
        form: Config.options?.nihil?.field?.form ?? 0
        seed: Config.options?.nihil?.field?.seed ?? 0.37
        glow: (Config.options?.nihil?.field?.glow ?? 1) * 0.7
    }

    readonly property int pageIndex: Options.pages.findIndex(item => item.id === root.page.id)
    readonly property int rowCount: (root.page.sections ?? []).reduce((sum, section) => sum + section.rows.length, 0)

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (menu.shown)
                menu.close()
            else if (root.query.length > 0)
                search.clear()
        }

        // The index: the family's mark, the search, then every page as a numbered line of the condensed face. The page
        // on show is set in bone with a line of light beside it; the rest wait in faint ink.
        NGlass {
            id: side
            x: NihilStyle.s(12)
            y: NihilStyle.s(12)
            width: NihilStyle.s(264)
            height: parent.height - NihilStyle.s(24)
            radius: NihilStyle.rPanel

            Column {
                id: index
                x: NihilStyle.s(20)
                y: NihilStyle.s(22)
                width: parent.width - NihilStyle.s(40)
                spacing: NihilStyle.s(2)

                Item {
                    width: parent.width
                    height: mark.height
                    NDisplay {
                        id: mark
                        text: "NiHiL"
                        size: NihilStyle.s(40)
                        bloom: 0.8
                    }
                    NSpark { x: mark.width - size * 0.2; y: -size * 0.15; size: NihilStyle.s(18) }
                }
                NLabel {
                    bottomPadding: NihilStyle.s(16)
                    text: Translation.tr("Settings")
                }

                NField {
                    id: search
                    width: parent.width
                    glyph: "search"
                    placeholder: Translation.tr("Search options")
                    clearable: true
                    onEdited: text => root.query = text
                }

                Item { width: 1; height: NihilStyle.s(14) }
                Rectangle { width: parent.width; height: 1; color: NihilStyle.hair }
                Item { width: 1; height: NihilStyle.s(6) }

                Repeater {
                    model: Options.pages

                    delegate: MouseArea {
                        id: entry

                        required property var modelData
                        required property int index
                        readonly property bool here: root.query.length === 0 && root.pageId === entry.modelData.id

                        width: index.width
                        height: NihilStyle.s(40)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            search.clear()
                            root.query = ""
                            root.pageId = entry.modelData.id
                        }

                        NSpectrum {
                            vertical: true
                            x: -NihilStyle.s(20)
                            anchors.verticalCenter: parent.verticalCenter
                            width: NihilStyle.s(2)
                            height: parent.height - NihilStyle.s(14)
                            opacity: entry.here ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
                        }
                        NLabel {
                            id: number
                            anchors.verticalCenter: parent.verticalCenter
                            width: NihilStyle.s(30)
                            text: String(entry.index + 1).padStart(2, "0")
                            color: entry.here ? NihilStyle.ink : NihilStyle.inkFaint
                        }
                        NDisplay {
                            anchors.left: number.right
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(entry.modelData.title)
                            elide: Text.ElideRight
                            size: NihilStyle.s(22)
                            bloom: entry.here ? 0.6 : 0
                            color: entry.here ? NihilStyle.ink : entry.containsMouse ? NihilStyle.inkSoft : NihilStyle.inkFaint
                        }
                    }
                }
            }

            NRule {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: NihilStyle.s(20)
                start: Translation.tr("Restore all")
                end: "▶ ⋈ ◀"
                MouseArea {
                    width: parent.width / 2
                    height: parent.height
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.restoreAll()
                }
            }
        }

        Item {
            id: stage
            anchors.left: side.right
            anchors.leftMargin: NihilStyle.s(28)
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(28)
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // The page's poster head: its number, its name set large with bloom, and a rule saying what it holds.
            Item {
                id: hero
                y: NihilStyle.s(24)
                width: parent.width
                height: heading.height + NihilStyle.s(40)

                NLabel {
                    text: root.query.length > 0 ? Translation.tr("Search")
                        : String(root.pageIndex + 1).padStart(2, "0") + "  /  " + String(Options.pages.length).padStart(2, "0")
                }
                NDisplay {
                    id: heading
                    y: NihilStyle.s(14)
                    width: parent.width - specimen.width - NihilStyle.s(20)
                    text: root.query.length > 0 ? root.query : Translation.tr(root.page.title)
                    elide: Text.ElideRight
                    size: NihilStyle.s(84)
                    bloom: 0.9
                }
                NSpark { x: Math.min(heading.contentWidth, heading.width) - size * 0.2; y: NihilStyle.s(8); size: NihilStyle.s(30) }

                // The material as it is set now: a square of the family's glass with its light, its spark and its type.
                NGlass {
                    id: specimen
                    anchors.right: parent.right
                    y: NihilStyle.s(4)
                    width: NihilStyle.s(132)
                    height: NihilStyle.s(96)
                    radius: NihilStyle.rCard
                    ignite: 0.6
                    spark: 1
                    NIcon {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: NihilStyle.s(12)
                        text: root.query.length > 0 ? "search" : (root.page.glyph ?? "tune")
                        size: NihilStyle.s(18)
                    }
                    NDisplay {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: NihilStyle.s(12)
                        text: "Aa"
                        capitals: false
                        size: NihilStyle.s(34)
                        bloom: 0.6
                    }
                }

                NRule {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    start: root.query.length > 0
                        ? Translation.tr("%1 found").arg(root.found.length)
                        : root.rowCount > 0 ? Translation.tr("%1 options").arg(root.rowCount) : Translation.tr(root.page.title)
                    middle: "⋈"
                    end: Translation.tr("Saved as you go")
                }
            }

            Loader {
                id: body
                anchors.fill: parent
                anchors.topMargin: hero.y + hero.height + NihilStyle.s(8)
                active: root.query.length === 0 || root.found.length > 0
                sourceComponent: root.query.length > 0 ? foundPage
                    : root.page.view === "profiles" ? profilesPage
                    : root.page.view === "about" ? aboutPage : optionsPage
            }

            Column {
                anchors.centerIn: parent
                visible: root.query.length > 0 && root.found.length === 0
                spacing: NihilStyle.s(6)

                NDisplay {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("Nothing")
                    size: NihilStyle.s(56)
                    color: NihilStyle.inkFaint
                    bloom: 0
                }
                NLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("No option by that name")
                }
            }
        }

        Component {
            id: optionsPage
            OptionsPage {
                sections: root.page.sections
                host: root
            }
        }
        Component {
            id: foundPage
            OptionsPage {
                sections: root.foundSections
                host: root
            }
        }
        Component {
            id: profilesPage
            ProfilesView {}
        }
        Component {
            id: aboutPage
            AboutView {
                host: root
            }
        }

        ChoiceMenu {
            id: menu
            anchors.fill: parent
            onPicked: value => root.write(menu.option.key, value)
        }
    }
}
