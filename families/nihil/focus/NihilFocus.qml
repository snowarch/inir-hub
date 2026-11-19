pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style

// Focus: the work at hand. The tasks on one side; on the other a timer you start in one press (Pomodoro or a
// countdown) and a note that saves as you write. Everything lives in the shell's own Todo, timers and notepad, so
// it is the same list and the same note in every family.
FocusScope {
    id: root

    property var screen: null
    property bool open: false

    readonly property real pad: NihilStyle.s(24)
    property string mode: TimerService.countdownRunning && !TimerService.pomodoroRunning ? "countdown" : "pomodoro"
    readonly property bool pomodoro: root.mode === "pomodoro"
    readonly property bool running: root.pomodoro ? TimerService.pomodoroRunning && !TimerService.pomodoroPaused
        : TimerService.countdownRunning && !TimerService.countdownPaused
    readonly property int remaining: root.pomodoro ? TimerService.pomodoroSecondsLeft : TimerService.countdownSecondsLeft
    readonly property int lap: root.pomodoro ? TimerService.pomodoroLapDuration : TimerService.countdownDuration
    readonly property var tasks: Todo.list.map((item, index) => ({ content: item.content, done: item.done, index }))
        .sort((a, b) => Number(a.done) - Number(b.done))
    readonly property int pending: Todo.list.filter(item => !item.done).length


    function clock(seconds: int): string {
        const s = Math.max(0, seconds)
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // The tasks.
    Item {
        id: tasksSide
        x: root.pad
        y: root.pad
        width: (root.width - root.pad * 3) * 0.52
        height: root.height - root.pad * 2

        NDisplay {
            id: tasksTitle
            size: NihilStyle.textHeadline
            text: Translation.tr("Tasks")
        }
        NText {
            anchors.left: tasksTitle.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.baseline: tasksTitle.baseline
            text: root.pending > 0 ? Translation.tr("%1 to do").arg(root.pending) : Translation.tr("All done")
            color: NihilStyle.textSecondary
        }
        NButton {
            anchors.right: parent.right
            anchors.verticalCenter: tasksTitle.verticalCenter
            visible: Todo.list.some(item => item.done)
            label: Translation.tr("Clear done")
            onClicked: Todo.clearCompleted()
        }

        NField {
            id: newTask
            anchors.top: tasksTitle.bottom
            anchors.topMargin: NihilStyle.s(16)
            width: parent.width
            height: NihilStyle.s(44)
            glyph: "add"
            placeholder: Translation.tr("Add a task and press Enter")
            focus: true
            onEntered: {
                const task = newTask.text.trim()
                if (task.length === 0) return
                Todo.addTask(task)
                newTask.clear()
            }
        }

        ListView {
            id: list
            anchors.top: newTask.bottom
            anchors.topMargin: NihilStyle.s(10)
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            spacing: NihilStyle.s(2)
            model: root.tasks
            boundsBehavior: Flickable.StopAtBounds
            add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: NihilStyle.durationMedium } }
            displaced: Transition { NumberAnimation { property: "y"; duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic } }

            delegate: MouseArea {
                id: task
                required property var modelData
                width: list.width
                height: NihilStyle.s(46)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: task.modelData.done ? Todo.markUnfinished(task.modelData.index) : Todo.markDone(task.modelData.index)
                Rectangle {
                    anchors.fill: parent
                    radius: NihilStyle.radiusSmall
                    color: task.containsMouse ? NihilStyle.fill : "transparent"
                }
                // The check: a ring, solid in the light once done.
                Rectangle {
                    id: check
                    x: NihilStyle.s(12)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(22)
                    height: width
                    radius: width / 2
                    color: task.modelData.done ? NihilStyle.accent : "transparent"
                    border.width: task.modelData.done ? 0 : NihilStyle.s(2)
                    border.color: NihilStyle.textTertiary
                    Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                    NIcon {
                        anchors.centerIn: parent
                        visible: task.modelData.done
                        text: "check"
                        size: NihilStyle.s(14)
                        weight: 2.6
                        color: NihilStyle.accentText
                    }
                }
                NText {
                    anchors.left: check.right
                    anchors.leftMargin: NihilStyle.s(12)
                    anchors.right: remove.left
                    anchors.rightMargin: NihilStyle.s(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: task.modelData.content
                    color: task.modelData.done ? NihilStyle.textTertiary : NihilStyle.text
                    font.strikeout: task.modelData.done
                }
                NButton {
                    id: remove
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(6)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(30)
                    height: width
                    icon: "close"
                    iconSize: NihilStyle.s(14)
                    tone: "transparent"
                    opacity: task.containsMouse || remove.containsMouse ? 1 : 0
                    Accessible.name: Translation.tr("Remove")
                    onClicked: Todo.deleteItem(task.modelData.index)
                }
            }

            NEmpty {
                anchors.centerIn: parent
                visible: list.count === 0
                icon: "check"
                title: Translation.tr("Nothing to do yet")
                note: Translation.tr("Type a task above and press Enter")
            }
        }
    }

    // The timer.
    Rectangle {
        id: timerCard
        x: tasksSide.x + tasksSide.width + root.pad
        y: root.pad
        width: root.width - x - root.pad
        height: (root.height - root.pad * 3) * 0.56
        radius: NihilStyle.radiusCard
        color: NihilStyle.fill

        NSegmented {
            x: NihilStyle.s(14)
            y: NihilStyle.s(14)
            width: parent.width - NihilStyle.s(28)
            height: NihilStyle.s(34)
            options: [
                { value: "pomodoro", label: Translation.tr("Pomodoro") },
                { value: "countdown", label: Translation.tr("Countdown") }
            ]
            current: root.mode
            onPicked: value => root.mode = value
        }

        // The time left, inside a ring of what has gone.
        Item {
            id: dial
            anchors.centerIn: parent
            anchors.verticalCenterOffset: NihilStyle.s(8)
            width: Math.min(parent.width * 0.62, parent.height - NihilStyle.s(130))
            height: width
            Canvas {
                id: ring
                anchors.fill: parent
                readonly property real share: root.lap > 0 ? 1 - root.remaining / root.lap : 0
                readonly property color track: NihilStyle.border
                readonly property color highlighted: NihilStyle.accent
                onShareChanged: requestPaint()
                onTrackChanged: requestPaint()
                onHighlightedChanged: requestPaint()
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    const c = width / 2, r = width / 2 - NihilStyle.s(4)
                    ctx.reset()
                    ctx.lineCap = "round"
                    ctx.lineWidth = NihilStyle.s(5)
                    ctx.strokeStyle = String(ring.track)
                    ctx.beginPath(); ctx.arc(c, c, r, 0, Math.PI * 2); ctx.stroke()
                    if (ring.share <= 0) return
                    ctx.strokeStyle = String(ring.highlighted)
                    ctx.beginPath(); ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * ring.share); ctx.stroke()
                }
            }
            Column {
                anchors.centerIn: parent
                NDisplay {
                    anchors.horizontalCenter: parent.horizontalCenter
                    size: NihilStyle.s(40)
                    text: root.clock(root.remaining)
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.pomodoro ? Translation.tr("Countdown")
                        : TimerService.pomodoroLongBreak ? Translation.tr("Long break")
                        : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus")
                    font.pixelSize: NihilStyle.textSmall
                    color: NihilStyle.textSecondary
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(14)
            spacing: NihilStyle.s(8)
            NButton {
                visible: !root.pomodoro && !TimerService.countdownRunning
                icon: "remove"
                Accessible.name: Translation.tr("A minute less")
                onClicked: TimerService.adjustCountdownDuration(-60)
            }
            NButton {
                highlighted: true
                icon: root.running ? "pause" : "play"
                label: root.running ? Translation.tr("Pause") : Translation.tr("Start")
                onClicked: root.pomodoro ? TimerService.togglePomodoro() : TimerService.toggleCountdown()
            }
            NButton {
                visible: !root.pomodoro && !TimerService.countdownRunning
                icon: "add"
                Accessible.name: Translation.tr("A minute more")
                onClicked: TimerService.adjustCountdownDuration(60)
            }
            NButton {
                visible: root.pomodoro ? TimerService.pomodoroRunning : TimerService.countdownRunning
                icon: "restart"
                Accessible.name: Translation.tr("Reset")
                onClicked: root.pomodoro ? TimerService.resetPomodoro() : TimerService.resetCountdown()
            }
        }
    }

    // The note.
    Rectangle {
        x: timerCard.x
        y: timerCard.y + timerCard.height + root.pad
        width: timerCard.width
        height: root.height - y - root.pad
        radius: NihilStyle.radiusCard
        color: NihilStyle.fill

        NText {
            id: noteTitle
            x: NihilStyle.s(16)
            y: NihilStyle.s(12)
            text: Notepad.tabs[Notepad.currentTab]?.title ?? Translation.tr("Note")
            font.weight: Font.DemiBold
        }
        Flickable {
            id: noteFlick
            anchors.fill: parent
            anchors.topMargin: NihilStyle.s(40)
            anchors.margins: NihilStyle.s(16)
            clip: true
            contentHeight: note.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            TextEdit {
                id: note
                width: noteFlick.width
                text: Notepad.text
                wrapMode: TextEdit.Wrap
                color: NihilStyle.text
                selectionColor: Qt.alpha(NihilStyle.accent, 0.4)
                selectedTextColor: NihilStyle.text
                font.family: NihilStyle.fontFamily
                font.pixelSize: NihilStyle.textBody
                onTextChanged: if (note.activeFocus && note.text !== Notepad.text) saveNote.restart()
                Timer { id: saveNote; interval: 400; onTriggered: Notepad.setTextValue(note.text) }
                NText {
                    visible: note.text.length === 0 && !note.activeFocus
                    text: Translation.tr("Write something down")
                    color: NihilStyle.textTertiary
                }
            }
        }
    }
}
