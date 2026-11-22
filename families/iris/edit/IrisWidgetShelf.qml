pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.shared.background.edit
import qs.modules.shared.background.widgets
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.widgets
import qs.modules.iris.components

// iRiS's face on the shared shelf: its pages slide a segmented thumb (the widgets, the Island, the Dock, the look, saved
// desktops), the search is Spotlight's matcher and finds a kind by name too, the plates are concentric with the drawer's body.
WidgetShelf {
    id: root

    property real bodyRadius: IrisStyle.radius

    // The page someone asked for (Settings' Desktops row), taken once and cleared: cleared from a binding's own change
    // it was a binding loop.
    Component.onCompleted: root.takeAsked()
    Connections {
        target: GlobalStates
        function onDesktopShelfPageChanged() { root.takeAsked() }
    }
    function takeAsked(): void {
        const asked = GlobalStates.desktopShelfPage
        if (asked.length === 0 || !root.pages.some(entry => entry.value === asked)) return
        root.goTo(asked)
        GlobalStates.desktopShelfPage = ""
    }

    // An option page is an area of Settings, the same rows, so either place shows the other's change. `order` names the
    // groups that lead it: Look is the widgets' own groups of Desktop, the design first; Style leads with the design,
    // colour and type, and the long lists (each app's colours) come last (his 11-20: the fonts sat past sixty rows).
    pages: [
        { value: "widgets", label: Translation.tr("Widgets") },
        { value: "look", label: Translation.tr("Look"), section: "desktop", only: true,
            order: ["Design", "Accents", "Material", "Legibility", "Widgets"] },
        { value: "bar", label: Translation.tr("Island") },
        { value: "dock", label: Translation.tr("Dock") },
        { value: "appearance", label: Translation.tr("Style"),
            order: ["Design", "Scheme", "Accent", "Faces", "Text", "Material", "Glass", "Shape", "Highlight", "Intensity", "Signal", "Look",
                "Presets", "Edges", "Light", "Icons", "Wallpaper tint", "Colour theme", "Day and night", "Dark look", "Ink look",
                "Light look", "Texture", "Frame", "Menus", "Badges", "Previews", "Customize", "Adaptive"] },
        { value: "presets", label: Translation.tr("Presets") }
    ]
    // The option page on show, for the head's chapters.
    property Item optionsBoard: null

    entries: {
        const list = IrisFaceData.galleryEntries.concat(IrisFaceData.otherEntries).map(entry => IrisSearch.prepare({
            key: entry.key, glyph: entry.glyph, name: entry.label, english: entry.english, tint: entry.tint,
            words: [entry.key, DesktopWidgetRegistry.keywordsOf(entry.key), root.categoryNames[DesktopWidgetRegistry.categoryOf(entry.key)] ?? "",
                DesktopWidgetRegistry.categoryOf(entry.key)].join(" "), category: DesktopWidgetRegistry.categoryOf(entry.key) }))
        for (const custom of (CustomWidgets.ready ? CustomWidgets.widgets : []))
            list.push(IrisSearch.prepare({ key: "custom." + custom.id, glyph: custom.icon || "widgets", name: custom.name,
                english: custom.name, tint: DesktopWidgetRegistry.customTint, words: DesktopWidgetRegistry.customWords(custom),
                category: DesktopWidgetRegistry.customCategory(custom) }))
        return list
    }

    face: QtObject {
        readonly property real d: IrisStyle.density
        readonly property color ink: IrisStyle.text
        readonly property color subtext: IrisStyle.subtext
        readonly property color muted: IrisStyle.muted
        readonly property color accent: IrisStyle.accent
        readonly property color inkOnAccent: IrisStyle.inkOnAccent
        readonly property color fillQuiet: IrisStyle.fillQuiet
        readonly property color fillActive: IrisStyle.fillActive
        readonly property color raised: IrisStyle.raised
        readonly property color hairline: IrisStyle.hairline
        readonly property color hairlineStrong: IrisStyle.hairlineStrong
        readonly property color danger: IrisStyle.signal
        readonly property string fontMain: IrisStyle.fontMain
        readonly property real typeMeta: IrisStyle.typeMeta
        readonly property real typeBody: IrisStyle.typeBody
        readonly property real plateRadius: IrisStyle.concentric(root.bodyRadius, root.pad, Math.round(10 * IrisStyle.density))
        readonly property var morphCurve: IrisStyle.morphCurve
        readonly property int feedbackEasing: IrisStyle.feedbackEasing
        function duration(ms: int): int { return IrisStyle.duration(ms) }
        function pressScale(s: real): real { return IrisStyle.pressScale(s) }
        function weight(w: int): int { return IrisStyle.weight(w) }
        function score(query: string, entry: var): real { return IrisSearch.score(query, entry) }
        function pageOf(page: string): Component { return ["look", "bar", "dock", "appearance"].includes(page) ? optionsPage : null }
        readonly property Component optionsPage: Component {
            IrisShelfOptions {
                id: options
                readonly property var entry: root.pages.find(page => page.value === root.page) ?? ({})
                section: String(options.entry.section ?? root.page)
                order: options.entry.order ?? []
                only: Boolean(options.entry.only)
                Component.onCompleted: root.optionsBoard = options
            }
        }
        readonly property Component head: Component {
            Item {
                id: head
                property var shelf: null
                readonly property real d: IrisStyle.density
                function focusSearch(): void { searchInput.forceActiveFocus() }
                function dropSearch(): void { searchInput.focus = false }

                // Undo and redo walk the arrangement (and a worn preset), the way back is always at hand.
                Row {
                    id: history
                    y: Math.round((head.height - height) / 2)
                    spacing: Math.round(2 * head.d)
                    IrisIconButton {
                        implicitWidth: head.height
                        materialIcon: "undo"
                        iconSize: Math.round(17 * head.d)
                        enabled: DesktopEditHistory.undoStack.length > 0
                        opacity: enabled ? 1 : 0.35
                        Accessible.name: Translation.tr("Undo")
                        onClicked: DesktopEditHistory.undo()
                    }
                    IrisIconButton {
                        implicitWidth: head.height
                        materialIcon: "redo"
                        iconSize: Math.round(17 * head.d)
                        enabled: DesktopEditHistory.redoStack.length > 0
                        opacity: enabled ? 1 : 0.35
                        Accessible.name: Translation.tr("Redo")
                        onClicked: DesktopEditHistory.redo()
                    }
                }
                IrisSegmented {
                    id: pageTabs
                    x: history.width + Math.round(14 * head.d)
                    y: Math.round((head.height - height) / 2)
                    width: Math.min(pageTabs.fitWidth, head.width - pageTabs.x - searchBox.width - tail.width - Math.round(20 * head.d))
                    options: head.shelf?.pages ?? []
                    current: head.shelf?.page ?? "widgets"
                    accessibleName: Translation.tr("Shelf pages")
                    onPicked: value => head.shelf.goTo(value)
                }

                // An option page's groups, where the search sits on the widgets: a tap turns to one, the lit ones are on show.
                // Those that do not fit wait in the menu at the end, which names a group on show when it is one of them.
                Item {
                    id: chapters
                    readonly property var list: head.shelf?.optionsBoard?.chapters ?? []
                    readonly property var lit: head.shelf?.optionsBoard?.onShow ?? []
                    readonly property bool crowded: chapterRow.width > chapters.width
                    // The menu's room is set aside, not measured: sized by the group it names, the chips that fit beside it
                    // went round in a loop.
                    readonly property real reserve: Math.round(132 * head.d)
                    readonly property real limit: chapters.crowded ? chapters.width - chapters.reserve - chapterRow.spacing : chapters.width
                    // The chips past the room, for the menu, and where it sits: after the last chip that fits.
                    readonly property var hidden: {
                        chapterRow.width
                        const out = []
                        for (let at = 0; at < chipRepeater.count; at++) {
                            const chip = chipRepeater.itemAt(at)
                            if (chip && chip.x + chip.width > chapters.limit) out.push({ value: chip.modelData, label: chip.label })
                        }
                        return out
                    }
                    readonly property real overflowX: {
                        chapterRow.width
                        let end = 0
                        for (let at = 0; at < chipRepeater.count; at++) {
                            const chip = chipRepeater.itemAt(at)
                            if (chip && chip.x + chip.width <= chapters.limit) end = chip.x + chip.width + chapterRow.spacing
                        }
                        return end
                    }
                    visible: !(head.shelf?.onWidgets ?? true) && head.shelf?.page !== "presets" && chapters.list.length > 1
                    x: pageTabs.x + pageTabs.width + Math.round(14 * head.d)
                    width: Math.max(0, (notice.text.length > 0 ? notice.x : tail.x) - chapters.x - Math.round(12 * head.d))
                    height: head.height
                    clip: true
                    Accessible.role: Accessible.PageTabList
                    Accessible.name: Translation.tr("Sections")
                    Row {
                        id: chapterRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(2 * head.d)
                        Repeater {
                            id: chipRepeater
                            model: chapters.list
                            delegate: IrisChip {
                                id: chapterChip
                                required property string modelData
                                readonly property bool fits: chapterChip.x + chapterChip.width <= chapters.limit
                                implicitHeight: head.height - Math.round(4 * head.d)
                                label: Translation.tr(chapterChip.modelData)
                                selected: chapters.lit.includes(chapterChip.modelData)
                                quiet: !chapterChip.selected
                                opacity: chapterChip.fits ? 1 : 0
                                enabled: chapterChip.fits
                                onClicked: head.shelf.optionsBoard?.open(chapterChip.modelData)
                            }
                        }
                    }
                    IrisPopupButton {
                        id: overflow
                        maxWidth: chapters.reserve
                        visible: chapters.crowded
                        x: chapters.overflowX
                        anchors.verticalCenter: parent.verticalCenter
                        options: chapters.hidden
                        current: chapters.hidden.find(item => chapters.lit.includes(item.value))?.value ?? ""
                        otherText: Translation.tr("More")
                        accessibleName: Translation.tr("More")
                        onPicked: value => head.shelf.optionsBoard?.open(String(value))
                    }
                }

                // What the shelf just did (saved, worn, undone), where the search sits on the other pages.
                IrisLabel {
                    id: notice
                    anchors.right: tail.left
                    anchors.rightMargin: Math.round(12 * head.d)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !(head.shelf?.onWidgets ?? true)
                    text: DesktopEditHistory.notice
                    opacity: text.length > 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                }

                Rectangle {
                    id: searchBox
                    visible: head.shelf?.onWidgets ?? true
                    anchors.right: tail.left
                    anchors.rightMargin: Math.round(8 * head.d)
                    width: Math.round(240 * head.d)
                    height: head.height
                    radius: IrisStyle.capsule(height)
                    color: searchInput.activeFocus ? IrisStyle.fillActive : IrisStyle.fillQuiet
                    border.width: searchInput.activeFocus ? 1 : 0
                    border.color: IrisStyle.accent
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                    MaterialSymbol {
                        id: searchGlyph
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(10 * head.d)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        iconSize: Math.round(16 * head.d)
                        color: IrisStyle.muted
                    }
                    TextInput {
                        cursorDelegate: TextCursor { accent: IrisStyle.accent }
                        id: searchInput
                        anchors.left: searchGlyph.right
                        anchors.leftMargin: Math.round(6 * head.d)
                        anchors.right: clearGlyph.visible ? clearGlyph.left : parent.right
                        anchors.rightMargin: Math.round(10 * head.d)
                        anchors.verticalCenter: parent.verticalCenter
                        text: GlobalStates.widgetSearchText
                        onTextEdited: GlobalStates.widgetSearchText = searchInput.text
                        onActiveFocusChanged: if (head.shelf) head.shelf.searchFocused = searchInput.activeFocus
                        color: IrisStyle.text
                        selectionColor: IrisStyle.tintFillHover(IrisStyle.accent)
                        selectedTextColor: IrisStyle.text
                        font.family: IrisStyle.fontMain
                        font.pixelSize: IrisStyle.typeMeta
                        clip: true
                        Accessible.name: Translation.tr("Search widgets")
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) head.shelf.move(1)
                            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) head.shelf.move(-1)
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) head.shelf.takeHighlighted()
                            else if (event.key === Qt.Key_Escape) head.shelf.escapeSearch()
                            else return
                            event.accepted = true
                        }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: Translation.tr("Search widgets")
                            color: IrisStyle.muted
                            font.pixelSize: IrisStyle.typeMeta
                        }
                    }
                    MaterialSymbol {
                        id: clearGlyph
                        anchors.right: parent.right
                        anchors.rightMargin: Math.round(8 * head.d)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: GlobalStates.widgetSearchText.length > 0
                        text: "close"
                        iconSize: Math.round(14 * head.d)
                        color: IrisStyle.muted
                        TapHandler { onTapped: { GlobalStates.widgetSearchText = ""; searchInput.forceActiveFocus() } }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                    TapHandler { onTapped: searchInput.forceActiveFocus() }
                    HoverHandler { cursorShape: Qt.IBeamCursor }
                }

                Row {
                    id: tail
                    anchors.right: parent.right
                    y: Math.round((head.height - height) / 2)
                    spacing: Math.round(4 * head.d)
                    readonly property bool gridOn: Config.options?.background?.widgets?.editGrid?.snap ?? true
                    readonly property string plates: DesktopWidgetOptions.everyState("showBackground")
                    readonly property string outlines: DesktopWidgetOptions.everyState("showBorder")
                    // Every widget's background or outline away or back in one tap, the same switches Material's edit
                    // mode and each widget's own rows use: lit while any widget still shows it.
                    IrisIconButton {
                        implicitWidth: head.height
                        visible: tail.plates !== ""
                        materialIcon: tail.plates !== "false" ? "layers" : "layers_clear"
                        iconSize: Math.round(16 * head.d)
                        selected: tail.plates !== "false"
                        Accessible.name: selected ? Translation.tr("Hide every background") : Translation.tr("Show every background")
                        onClicked: DesktopWidgetOptions.setEvery("showBackground", !selected)
                    }
                    IrisIconButton {
                        implicitWidth: head.height
                        visible: tail.outlines !== ""
                        materialIcon: "border_style"
                        iconSize: Math.round(16 * head.d)
                        selected: tail.outlines !== "false"
                        Accessible.name: selected ? Translation.tr("Hide every outline") : Translation.tr("Show every outline")
                        onClicked: DesktopWidgetOptions.setEvery("showBorder", !selected)
                    }
                    IrisIconButton {
                        implicitWidth: head.height
                        materialIcon: "grid_4x4"
                        iconSize: Math.round(16 * head.d)
                        selected: tail.gridOn
                        Accessible.name: tail.gridOn ? Translation.tr("Snap to grid: on") : Translation.tr("Snap to grid: off")
                        onClicked: Config.setNestedValue("background.widgets.editGrid.snap", !tail.gridOn)
                    }
                    IrisIconButton {
                        id: settingsButton
                        implicitWidth: head.height
                        materialIcon: "tune"
                        iconSize: Math.round(16 * head.d)
                        Accessible.name: Translation.tr("Widget settings")
                        onClicked: GlobalStates.openSettingsAt("iris", head.shelf && !head.shelf.onWidgets && head.shelf.page !== "presets" ? head.shelf.page : "widgets")
                    }
                    // Leaves with the desktop as it was when the mode opened; quiet until something changed.
                    IrisButton {
                        implicitHeight: head.height
                        text: Translation.tr("Cancel")
                        enabled: DesktopEditHistory.changed
                        opacity: enabled ? 1 : 0.38
                        onClicked: DesktopEditHistory.cancel()
                    }
                    IrisButton {
                        implicitHeight: head.height
                        text: Translation.tr("Done")
                        emphasized: true
                        onClicked: GlobalStates.setWidgetEditMode(false)
                    }
                }
            }
        }
    }
}
