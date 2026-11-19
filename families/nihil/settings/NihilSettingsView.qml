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

// NiHiL's Settings, built like the dashboard: a plate down the side with the search and the pages, the page beside it in
// grouped plates of rows.
// Every row comes from NihilOptions.js. The same view is its own window (NihilSettingsApp) and the overlay over the
// desktop (NihilSettingsHost); `windowed` tells which, and the head's buttons ask the holder to switch or close.
Item {
    id: root

    property bool windowed: true
    readonly property int pageIndex: Options.pages.findIndex(item => item.id === root.pageId)
    readonly property bool maximized: root.Window.window?.visibility === Window.Maximized
    signal closeRequested()
    signal overlayRequested(int index)
    signal windowRequested(string key)

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

    // A page by its id or its number; anything else leaves the page as it is.
    function goTo(page: var): void {
        const number = parseInt(page)
        const found = !isNaN(number) ? Options.pages[number] : Options.pages.find(item => item.id === String(page))
        if (!found)
            return
        search.clear()
        root.query = ""
        root.pageId = found.id
    }

    function toggleMaximized(): void {
        const window = root.Window.window
        if (window)
            window.visibility = root.maximized ? Window.Windowed : Window.Maximized
    }

    focus: true

    // How NiHiL came: a fresh copy of its options, never written to.
    NihilConfigSchema { id: factoryValues }

    Component.onCompleted: CompositorConfig.ensure()

    // Escape first closes what is open in here; then it goes on to whoever holds this view (the overlay closes).
    Keys.onEscapePressed: event => {
        if (menu.shown)
            menu.close()
        else if (root.query.length > 0)
            search.clear()
        else
            event.accepted = false
    }

    // The top of the sheet moves the window, and a double click fills the screen with it.
    WindowGrip {
        width: parent.width
        height: NihilStyle.s(76)
        enabled: root.windowed
        onMaximize: root.toggleMaximized()
    }

    // The side: the family's name, the search, and every page, on a plate of its own. The page on show wears the accent.
    Item {
        id: side
        width: NihilStyle.s(268)
        height: parent.height

        Rectangle {
            anchors.fill: parent
            anchors.margins: NihilStyle.s(10)
            anchors.rightMargin: 0
            radius: NihilStyle.radiusWindow - NihilStyle.s(10)
            color: NihilStyle.fill
        }

        Row {
            x: NihilStyle.s(30)
            y: NihilStyle.s(28)
            height: NihilStyle.s(32)
            spacing: NihilStyle.s(12)
            NLogo {
                anchors.verticalCenter: parent.verticalCenter
                size: NihilStyle.s(20)
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                text: "NiHiL"
                font.pixelSize: NihilStyle.textLarge
                font.weight: Font.DemiBold
            }
        }

        NField {
            id: search
            x: NihilStyle.s(20)
            y: NihilStyle.s(82)
            width: parent.width - NihilStyle.s(30)
            height: NihilStyle.s(40)
            radius: height / 2
            glyph: "search"
            glyphSize: NihilStyle.s(16)
            textSize: NihilStyle.textSmall
            textWeight: Font.Normal
            placeholder: Translation.tr("Search options")
            clearable: true
            onEdited: text => root.query = text
        }

        NScroller {
            id: index
            x: NihilStyle.s(20)
            y: NihilStyle.s(134)
            width: parent.width - NihilStyle.s(30)
            height: parent.height - y - NihilStyle.s(20)
            spacing: NihilStyle.s(2)

            Repeater {
                model: Options.pages

                delegate: MouseArea {
                    id: entry

                    required property var modelData
                    readonly property bool here: root.query.length === 0 && root.pageId === entry.modelData.id
                    readonly property real lead: entry.modelData.heading ? NihilStyle.s(36) : 0

                    width: index.innerWidth
                    height: NihilStyle.s(44) + entry.lead
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        search.clear()
                        root.query = ""
                        root.pageId = entry.modelData.id
                    }

                    // The pages of the computer itself start under their own quiet heading.
                    NText {
                        visible: entry.lead > 0
                        x: NihilStyle.s(14)
                        y: NihilStyle.s(12)
                        text: Translation.tr(entry.modelData.heading ?? "")
                        font.pixelSize: NihilStyle.textCaption
                        color: NihilStyle.textTertiary
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: entry.lead
                        radius: height / 2
                        color: entry.here ? NihilStyle.accent : NihilStyle.fillHover
                        visible: entry.here || entry.containsMouse
                        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                    }
                    NIcon {
                        id: glyph
                        x: NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: entry.lead / 2
                        text: entry.modelData.glyph ?? "tune"
                        size: NihilStyle.s(18)
                        color: entry.here ? NihilStyle.accentText : NihilStyle.textSecondary
                    }
                    NText {
                        anchors.left: glyph.right
                        anchors.leftMargin: NihilStyle.s(16)
                        anchors.right: parent.right
                        anchors.rightMargin: NihilStyle.s(10)
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: entry.lead / 2
                        text: Translation.tr(entry.modelData.title)
                        elide: Text.ElideRight
                        font.pixelSize: NihilStyle.textBody
                        color: entry.here ? NihilStyle.accentText : entry.containsMouse ? NihilStyle.text : NihilStyle.textSecondary
                        font.weight: entry.here ? Font.DemiBold : Font.Medium
                    }
                }
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

        // The page's name; a search says how much it found beside it.
        NDisplay {
            id: title
            y: NihilStyle.s(26)
            width: Math.min(implicitWidth, parent.width - controls.width - count.implicitWidth - NihilStyle.s(32))
            text: root.query.length > 0 ? Translation.tr("Results") : Translation.tr(root.page.title)
            size: NihilStyle.s(34)
            font.weight: Font.Bold
        }
        NText {
            id: summary
            anchors.top: title.bottom
            anchors.topMargin: NihilStyle.s(2)
            width: parent.width
            visible: root.query.length === 0
            text: Translation.tr(root.page.summary ?? "")
            font.pixelSize: NihilStyle.textBody
            color: NihilStyle.textSecondary
        }
        NText {
            id: count
            anchors.left: title.right
            anchors.leftMargin: NihilStyle.s(12)
            anchors.baseline: title.baseline
            visible: root.query.length > 0
            text: root.found.length === 1 ? Translation.tr("1 option matches") : Translation.tr("%1 options match").arg(root.found.length)
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.textSecondary
        }

        // How Settings is held: over the desktop or in its own window, and closed from here in either.
        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: -NihilStyle.s(10)
            y: NihilStyle.s(26)
            spacing: NihilStyle.s(2)

            NButton {
                icon: root.windowed ? "layers" : "open"
                tone: "transparent"
                Accessible.name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open as a window")
                onClicked: root.windowed ? root.overlayRequested(root.pageIndex) : root.windowRequested(root.pageId)
            }
            NButton {
                visible: root.windowed
                icon: root.maximized ? "restore" : "maximize"
                tone: "transparent"
                Accessible.name: root.maximized ? Translation.tr("Restore") : Translation.tr("Maximize")
                onClicked: root.toggleMaximized()
            }
            NButton {
                icon: "close"
                tone: "transparent"
                Accessible.name: Translation.tr("Close")
                onClicked: root.closeRequested()
            }
        }

        Loader {
            id: body
            anchors.fill: parent
            anchors.topMargin: NihilStyle.s(118)
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
                color: NihilStyle.textTertiary
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
            leadsWithLight: root.page.id === "appearance"
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
