pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// Tasks in Prism: how many are left on the flap, the first one in the pane as the thing to do now, the next ones on
// the foot. A disc marks one done; the plus writes a new one in the pane.
PrismFolder {
    id: root

    property bool adding: false
    readonly property var entries: {
        const pending = root.widget.taskEntries.filter(entry => !entry.done)
        const done = root.widget.showCompleted ? root.widget.taskEntries.filter(entry => entry.done) : []
        return pending.concat(done).slice(0, root.small ? 2 : root.medium ? 3 : 6)
    }
    readonly property var first: root.entries[0] ?? null
    readonly property int pending: root.widget.pendingCount
    function commit(text: string): void {
        if (text.trim().length > 0)
            Todo.addTask(text.trim())
        root.adding = false
    }
    function flip(entry: var): void {
        entry.done ? Todo.markUnfinished(entry.originalIndex) : Todo.markDone(entry.originalIndex)
    }
    Connections {
        target: GlobalStates
        function onWidgetEditModeChanged(): void { root.adding = false }
    }

    tabGlyph: "checklist"
    tabText: Translation.tr("Tasks")
    flapText: root.pending > 0 ? root.pending + " " + Translation.tr("left") : Translation.tr("All done")

    component Check: Rectangle {
        id: check
        required property var entry
        radius: width / 2
        color: Boolean(check.entry.done) ? root.shelf : "transparent"
        border.width: check.entry.done ? 0 : Math.max(1, root.dp(1.5))
        border.color: checkHover.hovered ? root.ink : root.inkTertiary
        MaterialSymbol {
            anchors.centerIn: parent
            visible: Boolean(check.entry.done)
            text: "check"
            iconSize: Math.round(check.width * 0.7)
            color: root.inkOnShelf
        }
        HoverHandler { id: checkHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.flip(check.entry) }
        Accessible.role: Accessible.CheckBox
        Accessible.checked: Boolean(check.entry.done)
        Accessible.name: String(check.entry.content ?? check.entry.text ?? "")
    }
    function nameOf(entry: var): string { return String(entry?.content ?? entry?.text ?? "") }

    // ── the pane: the task to do now, or the new one being written ──
    Item {
        visible: root.first !== null && !root.adding
        x: root.inset
        width: root.innerWidth - (plus.visible ? plus.width + root.dp(10) : 0)
        y: Math.round(root.paneMiddle - height / 2)
        height: Math.max(firstCheck.height, firstName.height)
        Check {
            id: firstCheck
            entry: root.first ?? ({})
            width: root.pick(22, 24, 30)
            height: width
            y: Math.round((parent.height - height) / 2)
        }
        FaceText {
            id: firstName
            face: root
            x: firstCheck.width + root.dp(10)
            width: parent.width - x
            y: Math.round((parent.height - height) / 2)
            text: root.nameOf(root.first)
            color: root.first?.done ? root.inkTertiary : root.ink
            font.strikeout: root.first?.done ?? false
            size: root.type(14, 17, 22)
            weight: Font.Bold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
    FaceText {
        visible: root.first === null && !root.adding
        face: root
        x: root.inset
        width: root.innerWidth - (plus.visible ? plus.width + root.dp(10) : 0)
        y: Math.round(root.paneMiddle - height / 2)
        text: Translation.tr("Nothing waiting on you")
        color: root.inkSecondary
        size: root.type(13, 16, 20)
        weight: Font.DemiBold
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }
    Rectangle {
        visible: root.adding
        x: root.inset
        width: root.innerWidth
        height: root.pick(32, 34, 40)
        y: Math.round(root.paneMiddle - height / 2)
        radius: height / 2
        color: root.fill
        TextInput {
            id: entry
            anchors.fill: parent
            anchors.leftMargin: root.dp(12)
            anchors.rightMargin: root.dp(12)
            verticalAlignment: TextInput.AlignVCenter
            color: root.ink
            selectionColor: root.accent
            selectedTextColor: root.onFill(root.accent)
            font.family: root.fontMain
            font.pixelSize: root.px(13)
            clip: true
            cursorDelegate: TextCursor { accent: IrisStyle.accent }
            Keys.onReturnPressed: root.commit(entry.text)
            Keys.onEnterPressed: root.commit(entry.text)
            Keys.onEscapePressed: root.adding = false
            onActiveFocusChanged: if (!activeFocus && text.trim().length === 0) root.adding = false
            FaceText {
                face: root
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.text.length === 0
                text: Translation.tr("New task")
                color: root.inkTertiary
                size: 13
            }
        }
    }
    Rectangle {
        id: plus
        visible: !root.adding && !root.small
        width: root.pick(30, 32, 38)
        height: width
        radius: width / 2
        x: root.width - root.inset - width
        y: Math.round(root.paneMiddle - height / 2)
        color: plusHover.hovered ? root.fillHover : root.fill
        MaterialSymbol {
            anchors.centerIn: parent
            text: "add"
            iconSize: Math.round(plus.width * 0.55)
            color: root.ink
        }
        HoverHandler { id: plusHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: {
                root.adding = true
                entry.forceActiveFocus()
            }
        }
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr("New task")
    }

    // ── the foot: what follows ──
    Column {
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.large ? root.footTop + root.dp(22) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.pick(6, 8, 12)
        Repeater {
            model: root.entries.slice(1, root.small ? 2 : root.medium ? 2 : 6)
            Item {
                id: task
                required property var modelData
                width: root.innerWidth
                height: root.pick(20, 22, 24)
                Check {
                    entry: task.modelData
                    width: root.pick(16, 18, 20)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                }
                FaceText {
                    face: root
                    x: root.pick(24, 28, 30)
                    width: parent.width - x
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.nameOf(task.modelData)
                    color: task.modelData.done ? root.inkTertiary : root.inkSecondary
                    font.strikeout: task.modelData.done
                    size: root.type(12, 13, 14.5)
                    weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }
    }
}
