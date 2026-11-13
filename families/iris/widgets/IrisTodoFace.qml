pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style

IrisWidgetFace {
    id: root
    designFace: IrisDesign.skin("widgetTodo")

    property bool adding: false
    readonly property int capacity: root.small ? 3 : root.medium ? 4 : 7
    readonly property var entries: {
        const pending = root.widget.taskEntries.filter(entry => !entry.done)
        const done = root.widget.showCompleted ? root.widget.taskEntries.filter(entry => entry.done) : []
        return pending.concat(done).slice(0, root.capacity)
    }
    readonly property int pending: root.widget.pendingCount
    // Progress (his 11-06 reference): what is done out of all of it as the figure, and a segment per task lit as each
    // one is done; past twelve tasks the segments become one bar.
    readonly property bool progressStyle: String(root.widget.familyOption("face", "list")) === "progress"
    readonly property int total: Todo.list.length
    readonly property int finished: root.widget.completedCount
    readonly property string figure: root.progressStyle ? root.finished + "/" + root.total : String(root.pending)
    readonly property bool figureShown: root.progressStyle ? root.total > 0 : root.pending > 0
    readonly property bool empty: !root.adding && root.entries.length === 0

    function beginAdding(): void {
        root.adding = true
    }
    function commit(text: string): void {
        if (text.trim().length > 0)
            Todo.addTask(text.trim())
        root.adding = false
    }

    Connections {
        target: GlobalStates
        function onWidgetEditModeChanged(): void { root.adding = false }
    }

    component Task: RowLayout {
        id: task
        required property var modelData
        spacing: root.dp(root.large ? 12 : 9)
        HoverHandler { id: taskHover }
        Rectangle {
            Layout.preferredWidth: root.dp(root.large ? 22 : 18)
            Layout.preferredHeight: root.dp(root.large ? 22 : 18)
            radius: IrisStyle.capsule(width)
            color: task.modelData.done ? root.accent : "transparent"
            border.width: task.modelData.done ? 0 : Math.max(1.5, root.dp(1.6))
            border.color: checkHover.hovered ? root.accent : root.fillActive
            MaterialSymbol {
                anchors.centerIn: parent
                visible: task.modelData.done
                text: "check"
                iconSize: parent.width * 0.78
                color: root.onFill(root.accent)
            }
            HoverHandler { id: checkHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                gesturePolicy: TapHandler.WithinBounds
                onTapped: task.modelData.done ? Todo.markUnfinished(task.modelData.originalIndex)
                    : Todo.markDone(task.modelData.originalIndex)
            }
            Accessible.role: Accessible.CheckBox
            Accessible.checked: task.modelData.done
            Accessible.name: task.modelData.content
        }
        FaceText {
            face: root
            Layout.fillWidth: true
            text: task.modelData.content
            color: task.modelData.done ? root.inkTertiary : root.ink
            size: root.large ? 16 : 13
            font.strikeout: task.modelData.done
        }
        MaterialSymbol {
            visible: taskHover.hovered && !root.small
            text: "close"
            iconSize: root.px(15)
            color: removeHover.hovered ? root.danger : root.inkTertiary
            HoverHandler { id: removeHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Todo.deleteItem(task.modelData.originalIndex) }
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Delete")
        }
    }

    component Tasks: ColumnLayout {
        id: tasks
        spacing: root.dp(root.large ? 14 : 7)
        Connections {
            target: root
            function onAddingChanged(): void {
                if (root.adding && tasks.visible)
                    Qt.callLater(() => entry.forceActiveFocus())
                else
                    entry.text = ""
            }
        }
        Repeater {
            model: root.adding ? [] : root.entries
            Task { Layout.fillWidth: true; Layout.fillHeight: false }
        }
        // Nothing left: a done mark and how to start again, centred in the room the list would take.
        Item {
            visible: root.empty
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: done.implicitHeight
            FaceBlank {
                id: done
                face: root
                // Large has room to lose it in: there it waits right under its head, where the first row would be.
                y: root.large ? root.dp(24) : Math.round((parent.height - height) / 2)
                width: parent.width
                glyph: "check"
                title: Translation.tr("All done")
                detail: Translation.tr("Nothing waiting on you")
            }
        }
        Rectangle {
            visible: root.adding
            Layout.fillWidth: true
            Layout.preferredHeight: root.dp(34)
            radius: root.innerRadius
            color: root.fill
            TextInput {
                cursorDelegate: TextCursor { accent: IrisStyle.accent }
                id: entry
                anchors.fill: parent
                anchors.leftMargin: root.dp(10)
                anchors.rightMargin: root.dp(10)
                verticalAlignment: TextInput.AlignVCenter
                color: root.ink
                selectionColor: root.accent
                selectedTextColor: root.onFill(root.accent)
                font.family: root.fontMain
                font.pixelSize: root.px(13)
                clip: true
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
    }

    // What is left is the figure, in ink with its word a step down; a zero beside "All done" said it twice, louder.
    component Count: ColumnLayout {
        spacing: 0
        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "checklist"
            text: Translation.tr("Tasks")
        }
        Row {
            visible: root.figureShown
            spacing: root.dp(5)
            FaceFigure {
                id: left
                face: root
                text: root.figure
                size: root.progressStyle ? 32 : 38
            }
            FaceText {
                face: root
                visible: !root.progressStyle
                anchors.baseline: left.baseline
                text: Translation.tr("left")
                color: root.inkSecondary
                size: 15
                weight: Font.DemiBold
            }
        }
        Segments { Layout.fillWidth: true; Layout.topMargin: root.dp(6) }
    }

    component Segments: Item {
        id: segments
        readonly property int count: Math.min(root.total, 12)
        readonly property real gap: root.dp(root.total > 12 ? 0 : 3)
        visible: root.progressStyle && root.total > 0
        implicitHeight: root.dp(6)
        Rectangle {
            visible: root.total > 12
            width: parent.width
            height: parent.height
            radius: IrisStyle.capsule(height)
            color: root.fillQuiet
            Rectangle {
                width: parent.width * root.finished / Math.max(1, root.total)
                height: parent.height
                radius: parent.radius
                color: root.accent
            }
        }
        Row {
            visible: root.total <= 12
            spacing: segments.gap
            Repeater {
                model: root.total <= 12 ? segments.count : 0
                Rectangle {
                    required property int index
                    width: (segments.width - segments.gap * (segments.count - 1)) / segments.count
                    height: segments.height
                    id: segment
                    radius: IrisStyle.capsule(height)
                    color: root.fillQuiet
                    // A task done fills its segment along its length; one undone drains it.
                    Rectangle {
                        width: segment.index < root.finished ? segment.width : 0
                        height: segment.height
                        radius: segment.radius
                        color: root.accent
                        Behavior on width {
                            enabled: IrisStyle.motionEnabled && root.moving
                            SmoothedAnimation { velocity: root.dp(160) }
                        }
                    }
                }
            }
        }
    }

    component Add: FaceAction {
        face: root
        glyph: "add"
        name: Translation.tr("New task")
        tint: root.accent
        onActivated: root.beginAdding()
    }

    ColumnLayout {
        visible: root.small
        anchors.fill: parent
        spacing: root.dp(8)
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            FaceHeader {
                face: root
                Layout.fillWidth: true
                glyph: "checklist"
                text: Translation.tr("Tasks")
            }
            FaceFigure {
                face: root
                visible: root.figureShown
                text: root.figure
                size: 22
            }
        }
        Segments { Layout.fillWidth: true }
        Tasks { Layout.fillWidth: true; Layout.fillHeight: root.empty }
        Item { Layout.fillHeight: true; visible: !root.empty }
    }

    RowLayout {
        visible: root.medium
        anchors.fill: parent
        spacing: root.dp(16)
        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: root.contentWidth * 0.26
            Layout.fillHeight: true
            Count { Layout.fillHeight: false; Layout.fillWidth: true }
            Item { Layout.fillHeight: true }
            Add {}
        }
        Tasks {
            Layout.fillWidth: true
            Layout.fillHeight: root.empty
            Layout.alignment: Qt.AlignTop
        }
    }

    ColumnLayout {
        visible: root.large
        anchors.fill: parent
        spacing: root.dp(10)
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            FaceHeader {
                face: root
                Layout.fillWidth: true
                glyph: "checklist"
                text: Translation.tr("Tasks")
            }
            FaceFigure {
                face: root
                visible: root.figureShown
                text: root.figure
                size: 26
            }
        }
        Segments { Layout.fillWidth: true }
        Tasks { Layout.fillWidth: true; Layout.fillHeight: root.empty }
        Item { Layout.fillHeight: true; visible: !root.empty }
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            Add {}
            FaceText {
                face: root
                Layout.fillWidth: true
                text: Translation.tr("New task")
                color: root.accent
                size: 13
                weight: Font.DemiBold
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.beginAdding() }
            }
        }
    }
}
