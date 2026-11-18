pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// A page: its name in dots, one line on what it holds, then its sections, in two columns when there is room.
NScroller {
    id: root

    required property var page
    property string jump: ""
    signal landed()

    readonly property real columnGap: NihilStyle.s(16)
    readonly property bool twoUp: root.innerWidth >= NihilStyle.s(780)
    readonly property real columnWidth: root.twoUp ? (root.innerWidth - root.columnGap) / 2 : root.innerWidth
    readonly property var wide: (root.page?.sections ?? []).filter(section => section.wide === true)
    readonly property var split: {
        const columns = [[], []]
        const load = [0, 0]
        for (const section of (root.page?.sections ?? []).filter(entry => entry.wide !== true)) {
            const side = root.twoUp && load[1] < load[0] ? 1 : 0
            columns[side].push(section)
            load[side] += section.rows.reduce((sum, row) => sum + (row.weight ?? 1), 1)
        }
        return columns
    }
    // The dot face has capitals and figures only: a name in another script stays in type.
    readonly property string plainTitle: String(root.page?.label ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase()
    readonly property bool dotted: /^[A-Z0-9 .,:!?'%+\-\/]+$/.test(root.plainTitle)
    readonly property var defaults: SettingsModel.defaultsOf(root.page)
    readonly property bool anyMoved: Object.keys(root.defaults).some(key => Config.getNestedValue(key, root.defaults[key]) !== root.defaults[key])

    spacing: NihilStyle.s(18)
    topPad: NihilStyle.s(22)
    bottomPad: NihilStyle.s(34)
    sidePad: NihilStyle.s(6)

    function findRow(item: Item, key: string): Item {
        if (item.rowKey === key || item.sectionKey === key) return item
        for (const child of item.children) {
            const found = root.findRow(child, key)
            if (found) return found
        }
        return null
    }
    function land(): void {
        if (root.jump.length === 0) return
        const target = root.findRow(root, root.jump)
        root.landed()
        if (!target) return
        root.reveal(target)
        if (target.flash) target.flash()
    }
    onPageChanged: { root.toTop(); arrive.restart(); Qt.callLater(root.land) }
    onJumpChanged: Qt.callLater(root.land)
    Component.onCompleted: Qt.callLater(root.land)

    NumberAnimation { id: arrive; target: root; property: "opacity"; from: 0; to: 1; duration: NihilStyle.calm }

    Item {
        width: root.innerWidth
        height: heading.implicitHeight

        Column {
            id: heading
            width: parent.width - restore.width - NihilStyle.s(16)
            spacing: NihilStyle.s(10)
            DotText {
                visible: root.dotted
                text: root.plainTitle
                dot: NihilStyle.s(5)
                color: NihilStyle.heading
                fitWidth: heading.width
            }
            NText {
                visible: !root.dotted
                width: heading.width
                text: String(root.page?.label ?? "")
                font.pixelSize: NihilStyle.textTitle
                font.weight: Font.DemiBold
                color: NihilStyle.heading
            }
            NText {
                width: heading.width
                text: String(root.page?.line ?? "")
                font.pixelSize: NihilStyle.textLarge
                color: NihilStyle.inkSoft
            }
        }
        NConfirm {
            id: restore
            visible: root.anyMoved
            anchors.right: parent.right
            anchors.bottom: heading.bottom
            width: implicitWidth
            height: implicitHeight
            glyph: "undo"
            label: Translation.tr("Restore page")
            onConfirmed: Config.setNestedValues(root.defaults)
        }
    }

    Repeater {
        model: root.wide
        PageSection {
            required property var modelData
            section: modelData
            width: root.innerWidth
        }
    }

    Row {
        spacing: root.columnGap
        Repeater {
            model: root.twoUp ? 2 : 1
            Column {
                id: column
                required property int index
                width: root.columnWidth
                spacing: NihilStyle.s(18)
                Repeater {
                    model: root.split[column.index]
                    PageSection {
                        required property var modelData
                        section: modelData
                        width: root.columnWidth
                    }
                }
            }
        }
    }
}
