pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.components

// One option page of the edit panel (Look, Island, Dock, Style): the same rows as Settings, split into its sections. Each
// section is a heading in the accent; only the open ones build their rows, so a page of thirty sections opens at once and
// reads as a list of names. A search finds a row in any section and opens the ones it is in.
Item {
    id: root

    // { section, only, order } of the page on show.
    property var page: ({})
    readonly property real d: IrisStyle.density
    readonly property string section: String(root.page.section ?? "")
    readonly property bool only: Boolean(root.page.only)
    readonly property var order: root.page.order ?? []
    readonly property var drawn: ["switch", "choice", "range", "text", "action"]

    readonly property var groups: {
        Config.revision
        const order = Array.from(root.order)
        const rank = spec => { const at = order.indexOf(String(spec.group ?? "")); return at < 0 ? order.length : at }
        const specs = IrisOptions.settings
            .filter(spec => spec.section === root.section
                && (!root.only || order.includes(String(spec.group ?? "")))
                && !spec.mirror && spec.shelf !== false
                && root.drawn.includes(spec.kind) && IrisOptions.shown(spec))
            .map((spec, at) => ({ spec: spec, at: at }))
            .sort((a, b) => rank(a.spec) - rank(b.spec) || a.at - b.at)
            .map(item => item.spec)
        const out = []
        for (const spec of specs) {
            const name = String(spec.group ?? "")
            let group = out.find(entry => entry.name === name)
            if (!group) { group = { name: name, specs: [] }; out.push(group) }
            group.specs.push(spec)
        }
        return out
    }

    // Accents and case aside: "cristal" finds "Cristal", "estilo" finds "Estilo".
    function fold(text: string): string {
        return String(text ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase()
    }
    readonly property string query: root.fold(search.text.trim())
    readonly property bool searching: root.query.length > 0
    readonly property var shownGroups: {
        if (!root.searching) return root.groups
        const out = []
        for (const group of root.groups) {
            const inName = root.fold(Translation.tr(group.name)).includes(root.query)
            const specs = inName ? group.specs : group.specs.filter(spec => root.fold([Translation.tr(String(spec.label ?? "")),
                Translation.tr(String(spec.caption ?? "")), String(spec.path ?? "")].join(" ")).includes(root.query))
            if (specs.length > 0) out.push({ name: group.name, specs: specs })
        }
        return out
    }

    // Which sections stand open, by page and name, for as long as the panel lives; a page seen for the first time opens
    // its first section.
    property var opened: ({})
    function isOpen(name: string): bool {
        if (root.searching) return true
        const mark = root.opened[root.section]
        if (mark === undefined) return root.groups.length > 0 && root.groups[0].name === name
        return Boolean(mark[name])
    }
    function toggle(name: string): void {
        const next = Object.assign({}, root.opened)
        const mark = Object.assign({}, next[root.section] ?? (root.groups.length > 0 ? { [root.groups[0].name]: true } : {}))
        mark[name] = !root.isOpen(name)
        next[root.section] = mark
        root.opened = next
    }
    onSectionChanged: { search.clear(); flick.contentY = 0 }
    function focusSearch(): void { search.focusInput() }
    // True when it had something to clear (Escape steps out of the search first).
    function clearSearch(): bool {
        if (search.text.length === 0 && !search.typing) return false
        search.clear()
        return true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(10 * root.d)

        IrisEditSearch {
            id: search
            Layout.fillWidth: true
            placeholder: Translation.tr("Search settings")
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: list.implicitHeight + Math.round(12 * root.d)
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: list
                width: flick.width
                spacing: Math.round(6 * root.d)

                Repeater {
                    model: root.shownGroups
                    delegate: Rectangle {
                        id: block
                        required property var modelData
                        required property int index
                        readonly property bool open: root.isOpen(block.modelData.name)
                        readonly property bool hovered: headArea.containsMouse
                        Layout.fillWidth: true
                        implicitHeight: blockColumn.implicitHeight
                        radius: IrisStyle.radiusTile
                        color: block.open ? IrisStyle.fillQuiet : block.hovered ? IrisStyle.fillHover : "transparent"
                        border.width: block.open ? 1 : 0
                        border.color: IrisStyle.hairline
                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }

                        ColumnLayout {
                            id: blockColumn
                            width: parent.width
                            spacing: 0

                            Item {
                                Layout.fillWidth: true
                                implicitHeight: Math.round(40 * root.d)
                                MouseArea {
                                    id: headArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !root.searching
                                    onClicked: root.toggle(block.modelData.name)
                                    Accessible.role: Accessible.Button
                                    Accessible.name: Translation.tr(block.modelData.name)
                                }
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Math.round(12 * root.d)
                                    anchors.rightMargin: Math.round(10 * root.d)
                                    spacing: Math.round(8 * root.d)
                                    IrisText {
                                        Layout.fillWidth: true
                                        text: block.modelData.name.length > 0 ? Translation.tr(block.modelData.name) : Translation.tr("General")
                                        color: block.open || block.hovered ? IrisStyle.accent : IrisStyle.text
                                        font.pixelSize: IrisStyle.typeBody
                                        font.weight: IrisStyle.weight(Font.DemiBold)
                                        elide: Text.ElideRight
                                    }
                                    IrisText {
                                        text: String(block.modelData.specs.length)
                                        color: IrisStyle.textTertiary
                                        font.pixelSize: IrisStyle.typeMeta
                                        font.features: ({ "tnum": 1 })
                                    }
                                    MaterialSymbol {
                                        visible: !root.searching
                                        text: "expand_more"
                                        iconSize: Math.round(18 * root.d)
                                        color: block.open ? IrisStyle.accent : IrisStyle.textSecondary
                                        rotation: block.open ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: IrisStyle.duration(200); easing.type: IrisStyle.feedbackEasing } }
                                    }
                                }
                            }

                            // Built only while open: a closed section costs its heading.
                            Loader {
                                id: body
                                Layout.fillWidth: true
                                Layout.leftMargin: Math.round(6 * root.d)
                                Layout.rightMargin: Math.round(6 * root.d)
                                Layout.bottomMargin: body.active ? Math.round(6 * root.d) : 0
                                active: block.open
                                visible: body.active
                                sourceComponent: IrisSheetRows {
                                    specs: block.modelData.specs
                                    firstNumber: 1
                                }
                                onLoaded: if (!root.searching) reveal.restart()
                                NumberAnimation {
                                    id: reveal
                                    target: body.item
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: IrisStyle.duration(160)
                                    easing.type: IrisStyle.feedbackEasing
                                }
                            }
                        }
                    }
                }

                IrisText {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(18 * root.d)
                    visible: root.searching && root.shownGroups.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    text: Translation.tr("Nothing matches")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeBody
                }
            }
        }
    }
}
