pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.preview
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A page's stage (his 11-14 pick, "B1"): one card, the page's live scene on top (the keyboard itself on Keyboard), a
// strip under it with what the scene shows and the page's two pills, then the legend: every group of the page
// numbered, its name and what it holds now, so what lives deep in a page reads at a glance and is one press away.
// Resting on a legend cell shows that group's own scene when it has one. A page with no scene, or with the animated
// previews turned off, wears Prism's still (the hero) in the scene's place: the legend is there on every page.
Item {
    id: root
    property var page: null
    // The page's groups as the sidebar indexes them: { title, changed, first, rows }.
    property var groups: []
    property string currentGroup: ""
    property int restorable: 0
    // What the still says when it stands in for the scene: the page's number, its rows, those changed, its lead.
    property int number: 1
    property int count: 0
    property var changed: []
    property var lead: []
    property bool active: true
    signal pickGroup(string title)
    signal restore()

    readonly property string area: String(root.page?.area ?? "")
    readonly property bool keyboard: root.page?.pageId === "keyboard"
    // Keys the drawn keyboard says left iNiR's (Keyboard only).
    readonly property int keysChanged: root.keys && keysStage.item ? keysStage.item.keyMap.changedCount : 0
    // The scene a group shows when resting on its cell (after a breath: a pass across the legend loads nothing).
    property string looking: ""
    property string resting: ""
    Timer { id: dwell; interval: 220; onTriggered: root.looking = root.resting }
    onPageChanged: { root.looking = ""; root.resting = "" }

    // Where a group's scene is found: under the area (appearance/Material) or under the chapter's own name
    // (colour/Scheme), as Classic's and Folio's stages name them.
    function spotOf(group: string): var {
        if (stage.sceneFor(root.area, group).length > 0) return { section: root.area, group: group }
        const own = String(root.page?.pageId ?? "")
        if (own !== root.area && stage.sceneFor(own, group).length > 0) return { section: own, group: group }
        return null
    }
    // The area's own page shows the area's scene; a chapter of it (Colour, Layout) its first group that has one.
    readonly property var baseSpot: {
        const own = String(root.page?.pageId ?? "")
        if (own === root.area) return { section: root.area, group: "" }
        for (const entry of root.groups) {
            const spot = root.spotOf(String(entry.first))
            if (spot) return spot
        }
        return stage.sceneFor(own, "").length > 0 ? { section: own, group: "" } : { section: "", group: "" }
    }
    readonly property var spot: (root.looking.length > 0 ? root.spotOf(root.looking) : null) ?? root.baseSpot
    // What stands on top: the keyboard itself, the live scene, or Prism's still.
    readonly property bool keys: root.keyboard && CompositorConfig.has("input", "keyboard.layout")
    readonly property bool live: !root.keys && stage.available
    readonly property bool still: !root.keys && !root.live
    readonly property bool staged: root.page !== null

    readonly property real pad: PrismTheme.dp(8)
    readonly property real inner: root.width - 2 * root.pad
    readonly property var facts: PrismModel.factsOf(String(root.page?.pageId ?? ""))

    visible: root.staged
    implicitHeight: root.staged ? card.height : 0

    Rectangle {
        id: card
        width: root.width
        height: body.implicitHeight + 2 * root.pad
        radius: PrismTheme.dp(24)
        color: PrismTheme.card

        Column {
            id: body
            x: root.pad
            y: root.pad
            width: root.inner

            IrisGroupPreview {
                id: stage
                visible: root.live
                width: root.inner
                height: root.live ? Math.round(Math.max(PrismTheme.dp(200), Math.min(PrismTheme.dp(320), root.inner * 0.34))) : 0
                radius: IrisStyle.concentric(card.radius, root.pad, IrisStyle.radiusChip)
                framed: false
                standIn: true
                captionOutside: true
                playing: root.active && root.visible && root.live
                section: root.keys ? "" : String(root.spot.section)
                group: String(root.spot.group)
                niriValue: (section, key) => CompositorConfig.value(IrisOptions.settings.find(spec => spec.comp === section && spec.key === key) ?? { comp: section, key: key })
                niriRevision: CompositorConfig.revision
            }

            // Keyboard: the keyboard itself, live, with the layouts under it; Super, Ctrl, Alt or Shift held shows
            // what each key does.
            Loader {
                id: keysStage
                active: root.keys
                visible: active
                width: root.inner
                sourceComponent: Item {
                    readonly property var keyMap: map
                    width: root.inner
                    implicitHeight: map.implicitHeight + 2 * PrismTheme.dp(18)
                    IrisKeyboardMap {
                        id: map
                        x: PrismTheme.dp(18)
                        y: PrismTheme.dp(18)
                        width: parent.width - 2 * x
                    }
                }
            }

            // No scene: the still, with the page's lead and its two pills on the art.
            Loader {
                active: root.still
                visible: active
                width: root.inner
                sourceComponent: PrismHero {
                    width: root.inner
                    corner: IrisStyle.concentric(card.radius, root.pad, IrisStyle.radiusChip)
                    page: root.page
                    number: root.number
                    count: root.count
                    changed: root.changed
                    restorable: root.restorable
                    lead: root.lead
                    onRestore: root.restore()
                }
            }

            // What the stage shows, the screen's own facts, and the page's two pills; nothing to say, no strip (the
            // still says them on its art).
            Item {
                visible: !root.still && (root.facts.length > 0 || (root.live && stage.caption.length > 0) || root.restorable > 0 || Boolean(root.page?.show) || root.keysChanged > 0)
                width: root.inner
                height: visible ? PrismTheme.dp(52) : PrismTheme.dp(4)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: PrismTheme.dp(12)
                    width: pills.x - x - PrismTheme.dp(16)
                    spacing: PrismTheme.dp(14)
                    clip: true
                    Repeater {
                        model: root.facts
                        delegate: Row {
                            required property var modelData
                            spacing: PrismTheme.dp(6)
                            PrismText { id: fact; text: modelData.say; color: PrismTheme.ink; font.pixelSize: PrismTheme.row; font.weight: Font.DemiBold }
                            PrismText { anchors.baseline: fact.baseline; text: modelData.label; color: PrismTheme.ink3; font.pixelSize: PrismTheme.small }
                        }
                    }
                    // A group rested on changes the caption with its scene: it fades across, never snaps.
                    PrismText {
                        id: captionSaid
                        readonly property string want: stage.caption
                        visible: root.live && stage.caption.length > 0
                        width: Math.max(0, parent.width - x)
                        elide: Text.ElideRight
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.body
                        Component.onCompleted: captionSaid.text = captionSaid.want
                        onWantChanged: if (PrismTheme.ms(1) === 0) captionSaid.text = captionSaid.want; else swapSaid.restart()
                        SequentialAnimation {
                            id: swapSaid
                            NumberAnimation { target: captionSaid; property: "opacity"; to: 0; duration: PrismTheme.ms(90); easing.type: IrisStyle.feedbackEasing }
                            ScriptAction { script: captionSaid.text = captionSaid.want }
                            NumberAnimation { target: captionSaid; property: "opacity"; to: 1; duration: PrismTheme.ms(200); easing.type: IrisStyle.feedbackEasing }
                        }
                    }
                }
                Row {
                    id: pills
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: PrismTheme.dp(4)
                    spacing: PrismTheme.dp(8)
                    // The keys left iNiR's: all of them back at once (each one alone from its own panel).
                    PrismPill {
                        visible: root.keysChanged > 0
                        tone: "quiet"
                        glyph: "keyboard"
                        text: root.keysChanged === 1 ? Translation.tr("Restore 1 key") : Translation.tr("Restore %1 keys").arg(root.keysChanged)
                        onClicked: keysStage.item.keyMap.restoreKeys()
                    }
                    PrismPill {
                        visible: root.restorable > 0
                        tone: "quiet"
                        glyph: "restart_alt"
                        text: Translation.tr("Restore defaults")
                        onClicked: root.restore()
                    }
                    PrismPill {
                        visible: Boolean(root.page?.show)
                        tone: "solid"
                        glyph: "play_arrow"
                        text: Translation.tr(String(root.page?.show?.label ?? ""))
                        onClicked: PrismModel.runShow(root.page)
                    }
                }
            }

            // The legend: each group numbered, named, with what it holds now; a press goes to it, resting shows it.
            Grid {
                id: legend
                visible: root.groups.length > 1
                readonly property int fit: Math.max(2, Math.min(6, Math.floor(root.inner / PrismTheme.dp(168))))
                // Rows of even length: seven groups on six columns left one alone, so the columns split them evenly.
                readonly property int lines: Math.ceil(root.groups.length / legend.fit)
                columns: Math.ceil(root.groups.length / Math.max(1, legend.lines))
                readonly property real cell: Math.floor(root.inner / Math.max(1, legend.columns))
                width: root.inner
                HoverHandler {
                    onHoveredChanged: if (!hovered) { root.resting = ""; dwell.restart() }
                }
                Repeater {
                    model: root.groups
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool here: root.currentGroup === String(cell.modelData.title)
                        readonly property var glance: root.glanceOf(cell.modelData)
                        width: legend.cell
                        height: PrismTheme.dp(72)
                        // A hairline between neighbours on one line, as the reference's columns.
                        Rectangle {
                            visible: cell.index % legend.columns !== 0
                            x: 0
                            y: PrismTheme.dp(16)
                            width: 1
                            height: parent.height - 2 * y
                            color: PrismTheme.line
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: PrismTheme.dp(3)
                            radius: PrismTheme.dp(14)
                            color: tap.pressed ? PrismTheme.fillPress : hover.hovered ? PrismTheme.fillHover : "transparent"
                            Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: IrisStyle.feedbackEasing } }
                        }
                        Column {
                            x: PrismTheme.dp(16)
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 2 * x
                            spacing: PrismTheme.dp(3)
                            Row {
                                spacing: PrismTheme.dp(6)
                                PrismText {
                                    mono: true
                                    text: String(cell.index + 1).padStart(2, "0")
                                    color: cell.here ? PrismTheme.accentInk : PrismTheme.ink3
                                    font.pixelSize: PrismTheme.caption
                                }
                                Rectangle {
                                    visible: Boolean(cell.modelData.changed)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: PrismTheme.dp(5)
                                    height: width
                                    radius: width / 2
                                    color: PrismTheme.accent
                                }
                            }
                            PrismText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: Translation.tr(String(cell.modelData.title))
                                color: cell.here ? PrismTheme.accentInk : PrismTheme.ink
                                font.pixelSize: PrismTheme.row
                                font.weight: Font.DemiBold
                            }
                            Row {
                                width: parent.width
                                spacing: PrismTheme.dp(5)
                                PrismText {
                                    id: said
                                    width: Math.min(implicitWidth, parent.width)
                                    elide: Text.ElideRight
                                    text: cell.glance.say
                                    color: PrismTheme.ink2
                                    font.pixelSize: PrismTheme.small
                                    font.weight: Font.Medium
                                }
                                // The value's name goes whole or not at all: cut ("Expandir al pasar el p…") it said less
                                // than nothing.
                                PrismText {
                                    visible: implicitWidth <= parent.width - said.width - parent.spacing
                                    text: cell.glance.label
                                    color: PrismTheme.ink3
                                    font.pixelSize: PrismTheme.small
                                }
                            }
                        }
                        HoverHandler {
                            id: hover
                            cursorShape: Qt.PointingHandCursor
                            onHoveredChanged: if (hovered) { root.resting = String(cell.modelData.first); dwell.restart() }
                        }
                        TapHandler {
                            id: tap
                            onTapped: root.pickGroup(String(cell.modelData.title))
                        }
                    }
                }
            }
        }
    }

    // What a group holds now in one line: its own chip (the keyboard's layout), else the first value it chooses, with
    // that value's name beside it; a group of only actions or lists says how many settings it holds. A value the still
    // already says in big type is not said again.
    function glanceOf(entry: var): var {
        const _ = PrismModel.revision
        const told = root.still ? Array.from(root.lead) : []
        const rows = Array.from(entry?.rows ?? []).filter(row => !told.some(one => one === row || (one.spec !== undefined && one.spec === row.spec)))
        const chipRow = rows.find(row => typeof row.spec?.chip === "function")
        const chip = chipRow ? String(chipRow.spec.chip() ?? "") : ""
        if (chip.length > 0) return { say: chip, label: "" }
        for (const row of rows) {
            if (!["choice", "switch", "range"].includes(String(row.kind))) continue
            const said = String(PrismModel.sayNow(row) ?? "")
            // A row named like its group says only its value: "On Notch" under Notch said the name twice.
            if (said.length > 0) return { say: said, label: row.label === entry.title ? "" : Translation.tr(row.label) }
        }
        return { say: "", label: rows.length === 1 ? Translation.tr("One setting") : Translation.tr("%1 settings").arg(rows.length) }
    }
}
