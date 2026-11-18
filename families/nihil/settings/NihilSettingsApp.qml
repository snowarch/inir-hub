pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil
import qs.modules.nihil.style
import "NihilOptions.js" as Options
import "../state/NihilProfiles.js" as Profiles

// NiHiL's Settings: a pane of glass with the search and the pages, and the page itself beside it under a quiet head.
// Every row comes from NihilOptions.js.
Window {
    id: root

    property string pageId: "profiles"
    property string query: ""

    readonly property var page: Options.pages.find(item => item.id === root.pageId) ?? Options.pages[0]
    // Every row search can find: NiHiL's own, and each compositor group as the running compositor offers it.
    readonly property var everyRow: {
        CompositorConfig.revision
        const rows = Options.allRows()
        for (const page of Options.pages)
            for (const section of page.sections ?? [])
                if (section.group)
                    for (const spec of CompositorRows.of(section.group))
                        rows.push({ type: "compositor", spec: spec, label: spec.label, note: spec.description ?? "", page: page.title, section: section.title })
        return rows.filter(row => root.shown(row))
    }
    readonly property var found: {
        const words = root.query.trim().toLowerCase().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0)
            return []
        return root.everyRow.filter(row => {
            const text = [Translation.tr(row.label), Translation.tr(row.note), Translation.tr(row.section), row.label, row.key ?? ""].join(" ").toLowerCase()
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

    function openMenu(row: Item, anchor: Item): void {
        menu.show(row, anchor)
    }

    // A row with `when` shows only while what it depends on holds: a path on ("path"), off ("!path"), at a value
    // ("path=value"), or more than one screen ("#screens").
    function shown(row: var): bool {
        const when = String(row.when ?? "")
        if (when.length === 0) return true
        if (when === "#screens") return Quickshell.screens.length > 1
        if (when.startsWith("!")) return Config.getNestedValue(when.slice(1), false) !== true
        const at = when.indexOf("=")
        if (at > 0) return String(Config.getNestedValue(when.slice(0, at), "")) === when.slice(at + 1)
        return Config.getNestedValue(when, false) === true
    }

    function act(name: string): void {
        const inir = Quickshell.shellPath("scripts/inir")
        if (name === "wallpapers") Quickshell.execDetached([inir, "wallpaperSelector", "open"])
        else if (name === "nextWallpaper") Quickshell.execDetached([inir, "wallpaperSelector", "next"])
    }

    // Restores NiHiL's own options; the shell's and the compositor's settings are left as they are.
    function restoreAll(): void {
        const updates = { "nihil.profile": root.factory("profile") }
        for (const row of Options.allRows().filter(item => !item.base && item.type !== "compositor" && item.type !== "action"))
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

    Component.onCompleted: CompositorConfig.ensure()

    NFieldPaint {
        anchors.fill: parent
        form: Config.options?.nihil?.field?.form ?? 0
        seed: Config.options?.nihil?.field?.seed ?? 0.37
        glow: (Config.options?.nihil?.field?.glow ?? 1) * 0.45
    }


    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (menu.shown)
                menu.close()
            else if (root.query.length > 0)
                search.clear()
        }

        // The side: the family's name, the search, and every page with its glyph. The page on show sits on a raised
        // plate of glass.
        NGlass {
            id: side
            x: NihilStyle.s(12)
            y: NihilStyle.s(12)
            width: NihilStyle.s(244)
            height: parent.height - NihilStyle.s(24)
            radius: NihilStyle.rPanel

            Column {
                id: index
                x: NihilStyle.s(14)
                y: NihilStyle.s(18)
                width: parent.width - NihilStyle.s(28)
                spacing: NihilStyle.s(2)

                Row {
                    x: NihilStyle.s(8)
                    height: NihilStyle.s(34)
                    spacing: NihilStyle.s(8)
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: NihilStyle.s(22)
                        height: width
                        radius: NihilStyle.r(7)
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0; color: NihilStyle.specB }
                            GradientStop { position: 1; color: NihilStyle.specA }
                        }
                    }
                    NText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NiHiL"
                        font.pixelSize: NihilStyle.textLarge
                        font.weight: Font.DemiBold
                    }
                }
                Item { width: 1; height: NihilStyle.s(10) }

                NField {
                    id: search
                    width: parent.width
                    glyph: "search"
                    placeholder: Translation.tr("Search options")
                    clearable: true
                    onEdited: text => root.query = text
                }

                Item { width: 1; height: NihilStyle.s(12) }

                Repeater {
                    model: Options.pages

                    delegate: MouseArea {
                        id: entry

                        required property var modelData
                        readonly property bool here: root.query.length === 0 && root.pageId === entry.modelData.id
                        readonly property real lead: entry.modelData.heading ? NihilStyle.s(34) : 0

                        width: index.width
                        height: NihilStyle.s(36) + entry.lead
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            search.clear()
                            root.query = ""
                            root.pageId = entry.modelData.id
                        }

                        // The pages of the computer itself start under their own quiet heading.
                        NLabel {
                            visible: entry.lead > 0
                            x: NihilStyle.s(10)
                            y: NihilStyle.s(14)
                            text: Translation.tr(entry.modelData.heading ?? "")
                            color: NihilStyle.inkFaint
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: entry.lead
                            radius: NihilStyle.rKey
                            color: entry.here ? NihilStyle.chosen : entry.containsMouse ? NihilStyle.piece : "transparent"
                            border.width: entry.here ? 1 : 0
                            border.color: NihilStyle.hair
                            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                        }
                        NIcon {
                            id: glyph
                            x: NihilStyle.s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: entry.lead / 2
                            text: entry.modelData.glyph ?? "tune"
                            size: NihilStyle.s(18)
                            color: entry.here ? NihilStyle.accent : NihilStyle.inkSoft
                        }
                        NText {
                            anchors.left: glyph.right
                            anchors.leftMargin: NihilStyle.s(10)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: entry.lead / 2
                            text: Translation.tr(entry.modelData.title)
                            color: entry.here || entry.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
                            font.weight: entry.here ? Font.DemiBold : Font.Medium
                        }
                    }
                }
            }

            NLabel {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: NihilStyle.s(22)
                text: Translation.tr("Saved as you go")
                color: NihilStyle.inkFaint
            }
        }

        Item {
            id: stage
            anchors.left: side.right
            anchors.leftMargin: NihilStyle.s(36)
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(36)
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            // The page's head: its name and one line on what it holds.
            Column {
                id: hero
                y: NihilStyle.s(34)
                width: parent.width
                spacing: NihilStyle.s(6)

                NDisplay {
                    width: parent.width
                    text: root.query.length > 0 ? Translation.tr("Results") : Translation.tr(root.page.title)
                    size: NihilStyle.s(30)
                }
                NText {
                    width: parent.width
                    text: root.query.length > 0
                        ? (root.found.length === 1 ? Translation.tr("1 option matches") : Translation.tr("%1 options match").arg(root.found.length))
                        : Translation.tr(root.page.summary ?? "")
                    color: NihilStyle.inkSoft
                    font.pixelSize: NihilStyle.textBody
                }
            }

            Loader {
                id: body
                anchors.fill: parent
                anchors.topMargin: hero.y + hero.height + NihilStyle.s(22)
                active: root.query.length === 0 || root.found.length > 0
                sourceComponent: root.query.length > 0 ? foundPage
                    : root.page.view === "profiles" ? profilesPage
                    : root.page.view === "about" ? aboutPage : optionsPage
            }

            Column {
                anchors.centerIn: parent
                visible: root.query.length > 0 && root.found.length === 0
                spacing: NihilStyle.s(8)

                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "search_off"
                    size: NihilStyle.s(32)
                    color: NihilStyle.inkFaint
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("No option by that name")
                    font.pixelSize: NihilStyle.textLarge
                    font.weight: Font.Medium
                }
                NLabel {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("Try another word")
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
            onPicked: value => menu.row?.write(value)
        }
    }
}
