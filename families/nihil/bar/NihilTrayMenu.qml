pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.nihil.style

// A tray app's own menu on NiHiL's glass: its entries, marks, icons and submenus (walked in place, with a way back),
// under the icon that asked. Arrows move, Enter takes, Left goes back; a click outside or Escape closes it.
Item {
    id: root

    property var item: null
    property var screen: null
    // The icon's centre on its screen, and the panel edge the menu hangs from.
    property point at: Qt.point(0, 0)
    property bool fromBottom: false
    property var trail: []
    property int lit: -1

    readonly property var handle: root.item?.menu ?? null
    readonly property var current: root.trail.length > 0 ? root.trail[root.trail.length - 1] : root.handle
    readonly property bool open: root.item !== null

    function show(item: var, screen: var, at: point, fromBottom: bool): void {
        root.trail = []
        root.lit = -1
        root.screen = screen
        root.at = at
        root.fromBottom = fromBottom
        root.item = item
    }
    function close(): void { root.item = null; root.trail = [] }
    // An entry the app already took back (a new layout, or the app went away): its wrapper outlives it.
    function alive(entry: var): bool { return !!entry && typeof entry.triggered === "function" }
    function label(text: string): string {
        return String(text ?? "").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_")
    }
    function take(row: var): void {
        if (!row || row.type || row.enabled === false) return
        if (row.back) { root.trail = root.trail.slice(0, -1); root.lit = -1; return }
        if (row.submenu) { root.trail = root.trail.concat([row.entry]); root.lit = -1; return }
        if (root.alive(row.entry)) row.entry.triggered()
        root.close()
    }
    function step(by: int): void {
        const rows = root.rows
        for (let i = 1; i <= rows.length; i++) {
            const at = (Math.max(root.lit, by > 0 ? -1 : 0) + by * i + rows.length * 4) % rows.length
            if (!rows[at].type && rows[at].enabled !== false) { root.lit = at; return }
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.current
    }
    // Holds the whole menu while a submenu shows, or the runtime lets the root go and the submenu with it.
    QsMenuOpener {
        menu: root.handle
    }

    readonly property var rows: {
        const rows = []
        if (root.trail.length > 0) {
            rows.push({ back: true, text: root.label(root.trail[root.trail.length - 1]?.text ?? "") || Translation.tr("Back") })
            rows.push({ type: "separator" })
        }
        for (const entry of opener.children?.values ?? []) {
            if (!entry) continue
            if (entry.isSeparator) {
                if (rows.length > 0 && rows[rows.length - 1].type !== "separator") rows.push({ type: "separator" })
                continue
            }
            rows.push({
                entry,
                text: root.label(entry.text),
                image: String(entry.icon ?? ""),
                enabled: entry.enabled,
                mark: entry.buttonType === QsMenuButtonType.RadioButton ? "radio"
                    : entry.buttonType === QsMenuButtonType.CheckBox ? "check" : "",
                checked: entry.checkState === Qt.Checked,
                submenu: entry.hasChildren
            })
        }
        while (rows.length > 0 && rows[rows.length - 1].type === "separator") rows.pop()
        return rows
    }
    readonly property bool marked: root.rows.some(row => row.mark || row.image || row.back)
    readonly property string title: String(root.item?.tooltipTitle || root.item?.title || root.item?.id || "")

    // A layout the app replaces under the open menu: a submenu whose entry is gone falls back to the top.
    onRowsChanged: if (root.trail.some(entry => !root.alive(entry))) root.trail = []

    property bool lingering: false
    onOpenChanged: if (!root.open) { root.lingering = true; linger.restart() }
    Timer { id: linger; interval: NihilStyle.calm + 60; onTriggered: root.lingering = false }

    LazyLoader {
        active: root.open || root.lingering

        NPopup {
            id: popup
            open: root.open
            screen: root.screen
            namespace: "nihil-tray-menu"
            blurPieces: [card.region]
            onDismissed: root.close()

            NGlass {
                id: card
                readonly property real edge: NihilStyle.s(8)
                width: NihilStyle.s(260)
                height: column.implicitHeight + NihilStyle.s(12)
                radius: NihilStyle.rCard
                tint: NihilStyle.menuTint
                tracks: true
                x: NihilStyle.clamp(root.at.x - width / 2, edge, popup.width - width - edge)
                y: root.fromBottom ? popup.height - NihilStyle.barHeight - height - NihilStyle.s(6)
                    : NihilStyle.barHeight + NihilStyle.s(6)

                // Clicks on the card stay on the card.
                MouseArea { anchors.fill: parent }

                focus: true
                Keys.onUpPressed: root.step(-1)
                Keys.onDownPressed: root.step(1)
                Keys.onReturnPressed: root.take(root.rows[root.lit])
                Keys.onEnterPressed: root.take(root.rows[root.lit])
                Keys.onRightPressed: if (root.rows[root.lit]?.submenu) root.take(root.rows[root.lit])
                Keys.onLeftPressed: if (root.trail.length > 0) { root.trail = root.trail.slice(0, -1); root.lit = -1 }

                Column {
                    id: column
                    x: NihilStyle.s(6)
                    y: NihilStyle.s(6)
                    width: parent.width - NihilStyle.s(12)

                    // The app's name over its entries.
                    Item {
                        width: parent.width
                        height: NihilStyle.s(34)
                        visible: root.trail.length === 0 && root.title.length > 0
                        Image {
                            id: appIcon
                            x: NihilStyle.s(10)
                            anchors.verticalCenter: parent.verticalCenter
                            width: NihilStyle.s(16)
                            height: width
                            sourceSize: Qt.size(width * 2, height * 2)
                            source: root.item ? TrayService.getSafeIcon(root.item) : ""
                        }
                        NText {
                            x: NihilStyle.s(36)
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - NihilStyle.s(10)
                            text: root.title
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        visible: root.trail.length === 0 && root.title.length > 0 && root.rows.length > 0
                        x: NihilStyle.s(10)
                        width: parent.width - NihilStyle.s(20)
                        height: 1
                        color: NihilStyle.line
                    }
                    Item { width: 1; height: NihilStyle.s(4); visible: root.trail.length === 0 && root.title.length > 0 }

                    Repeater {
                        model: root.rows
                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property bool line: row.modelData.type === "separator"
                            readonly property bool usable: !row.line && row.modelData.enabled !== false
                            width: column.width
                            height: row.line ? NihilStyle.s(9) : NihilStyle.s(32)

                            Rectangle {
                                visible: row.line
                                anchors.verticalCenter: parent.verticalCenter
                                x: NihilStyle.s(10)
                                width: parent.width - NihilStyle.s(20)
                                height: 1
                                color: NihilStyle.line
                            }

                            MouseArea {
                                id: hit
                                anchors.fill: parent
                                visible: !row.line
                                enabled: row.usable
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onContainsMouseChanged: if (hit.containsMouse) root.lit = row.index
                                onClicked: root.take(row.modelData)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: NihilStyle.r(9)
                                    color: NihilStyle.chosen
                                    visible: root.lit === row.index
                                }

                                // The entry's own mark: a check, a radio dot, its icon, or the way back.
                                Item {
                                    id: mark
                                    x: NihilStyle.s(10)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: NihilStyle.s(16)
                                    height: width
                                    visible: root.marked
                                    NIcon {
                                        anchors.centerIn: parent
                                        visible: row.modelData.back || (row.modelData.mark === "check" && row.modelData.checked)
                                        text: row.modelData.back ? "chevron_left" : "check"
                                        size: NihilStyle.s(15)
                                        color: row.modelData.back ? NihilStyle.inkSoft : NihilStyle.accent
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: row.modelData.mark === "radio"
                                        width: NihilStyle.s(12)
                                        height: width
                                        radius: width / 2
                                        color: "transparent"
                                        border.width: row.modelData.checked ? 0 : 1
                                        border.color: NihilStyle.inkFaint
                                        Rectangle {
                                            anchors.centerIn: parent
                                            visible: row.modelData.checked === true
                                            width: parent.width
                                            height: width
                                            radius: width / 2
                                            color: NihilStyle.accent
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: NihilStyle.s(4)
                                                height: width
                                                radius: width / 2
                                                color: NihilStyle.accentInk
                                            }
                                        }
                                    }
                                    Image {
                                        anchors.fill: parent
                                        visible: !row.modelData.mark && !row.modelData.back && row.modelData.image?.length > 0
                                        sourceSize: Qt.size(width * 2, height * 2)
                                        source: visible ? row.modelData.image : ""
                                        asynchronous: true
                                    }
                                }

                                NText {
                                    x: root.marked ? NihilStyle.s(36) : NihilStyle.s(12)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - x - NihilStyle.s(row.modelData.submenu ? 30 : 12)
                                    text: row.modelData.text ?? ""
                                    color: row.modelData.back ? NihilStyle.inkSoft : NihilStyle.ink
                                    opacity: row.usable ? 1 : 0.4
                                    elide: Text.ElideRight
                                }
                                NIcon {
                                    anchors.right: parent.right
                                    anchors.rightMargin: NihilStyle.s(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: row.modelData.submenu === true
                                    text: "chevron_right"
                                    size: NihilStyle.s(14)
                                    color: NihilStyle.inkSoft
                                }
                            }
                        }
                    }

                    // An app that offers no entries still says so, instead of an empty card.
                    NText {
                        visible: root.rows.length === 0
                        x: NihilStyle.s(12)
                        height: NihilStyle.s(32)
                        verticalAlignment: Text.AlignVCenter
                        text: Translation.tr("No actions")
                        color: NihilStyle.inkSoft
                    }
                }
            }
        }
    }
}
