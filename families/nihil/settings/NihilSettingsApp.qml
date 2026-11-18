pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import qs.services
import qs.modules.common
import qs.modules.nihil
import qs.modules.nihil.style
import "NihilOptions.js" as Options
import "../state/NihilProfiles.js" as Profiles

// NiHiL's Settings, a window of its own over the family's field: the pages down the side, a search that reaches every
// option, and the page. Every row comes from NihilOptions.js.
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
        for (const row of root.everyRow)
            updates["nihil." + row.key] = root.factory(row.key)
        Config.setNestedValues(updates)
    }

    visible: true
    title: Translation.tr("NiHiL Settings")
    width: 1120
    height: 760
    minimumWidth: 860
    minimumHeight: 520
    color: NihilStyle.base
    onClosing: Qt.quit()

    // How NiHiL came: a fresh copy of its options, never written to.
    NihilConfigSchema { id: factoryValues }

    NFieldPaint {
        anchors.fill: parent
        form: Config.options?.nihil?.field?.form ?? 1
        seed: Config.options?.nihil?.field?.seed ?? 0.37
        glow: Config.options?.nihil?.field?.glow ?? 1
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

        Column {
            id: side
            x: NihilStyle.s(16)
            y: NihilStyle.s(20)
            width: NihilStyle.s(232)
            spacing: NihilStyle.s(4)

            NText {
                x: NihilStyle.s(10)
                bottomPadding: NihilStyle.s(10)
                text: "NiHiL"
                font.pixelSize: NihilStyle.textTitle
                font.weight: Font.Light
            }

            NField {
                id: search
                width: side.width
                glyph: "search"
                placeholder: Translation.tr("Search options")
                clearable: true
                onEdited: text => root.query = text
            }

            Item {
                width: 1
                height: NihilStyle.s(10)
            }

            Repeater {
                model: Options.pages

                delegate: MouseArea {
                    id: entry

                    required property var modelData
                    readonly property bool here: root.query.length === 0 && root.pageId === entry.modelData.id

                    width: side.width
                    height: NihilStyle.s(42)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        search.clear()
                        root.query = ""
                        root.pageId = entry.modelData.id
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: NihilStyle.rKey
                        color: entry.here ? NihilStyle.pieceRaised : entry.containsMouse ? NihilStyle.piece : "transparent"
                        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                    }
                    NIcon {
                        id: mark
                        x: NihilStyle.s(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.glyph
                        size: NihilStyle.s(20)
                        color: entry.here ? NihilStyle.accent : NihilStyle.ink
                    }
                    NText {
                        anchors.left: mark.right
                        anchors.leftMargin: NihilStyle.s(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr(entry.modelData.title)
                        font.pixelSize: NihilStyle.textBody
                        font.weight: entry.here ? Font.Medium : Font.Normal
                    }
                }
            }
        }

        Item {
            id: stage
            anchors.left: side.right
            anchors.leftMargin: NihilStyle.s(12)
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            NText {
                id: heading
                x: NihilStyle.s(20)
                y: NihilStyle.s(20)
                text: root.query.length > 0 ? Translation.tr("Search") : Translation.tr(root.page.title)
                font.pixelSize: NihilStyle.textTitle
                font.weight: Font.Light
            }

            Loader {
                id: body
                anchors.fill: parent
                anchors.topMargin: heading.y + heading.height + NihilStyle.s(12)
                active: root.query.length === 0 || root.found.length > 0
                sourceComponent: root.query.length > 0 ? foundPage
                    : root.page.view === "profiles" ? profilesPage
                    : root.page.view === "about" ? aboutPage : optionsPage
            }

            Column {
                anchors.centerIn: parent
                visible: root.query.length > 0 && root.found.length === 0
                spacing: NihilStyle.s(6)

                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "search_off"
                    size: NihilStyle.s(36)
                    color: NihilStyle.inkSoft
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("No option by that name")
                    font.pixelSize: NihilStyle.textLarge
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
