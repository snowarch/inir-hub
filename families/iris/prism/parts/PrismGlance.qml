pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A glance the person put in the side column (iris.appearance.settingsAside): the day's weather, what comes next (the
// calendar's events, then open tasks) or how the machine is doing. With nothing to say it is not there (`shown`).
Item {
    id: root
    property string kind: "forecast"
    property bool active: true
    readonly property bool shown: body.item?.shown ?? false
    implicitHeight: body.item?.implicitHeight ?? 0

    Loader {
        id: body
        width: root.width
        sourceComponent: root.kind === "forecast" ? forecast : root.kind === "agenda" ? agenda : root.kind === "vitals" ? vitals : null
    }

    component Head: PrismText {
        width: parent?.width ?? 0
        bottomPadding: PrismTheme.dp(6)
        font.pixelSize: PrismTheme.row
        font.weight: Font.DemiBold
        font.letterSpacing: -PrismTheme.row * 0.01
    }

    // The weather where the person is: now, large, then the hours ahead in five steps.
    Component {
        id: forecast
        Column {
            id: sky
            readonly property var reading: Weather.data ?? ({})
            readonly property string temp: String(sky.reading.temp ?? "")
            // "--°C" is the service before its first answer; a real reading below zero starts with one minus only.
            readonly property bool shown: Weather.enabled && sky.temp.length > 0 && !sky.temp.startsWith("--")
            readonly property var hours: Array.from(sky.reading.hourly ?? []).slice(0, 5)
            readonly property string high: String(sky.reading.tempMax ?? "")
            readonly property string low: String(sky.reading.tempMin ?? "")
            spacing: 0
            Head { text: Weather.showVisibleCity ? Weather.visibleCity : Translation.tr("Forecast") }
            Item {
                width: parent.width
                height: PrismTheme.dp(48)
                PrismGlyph {
                    id: now
                    anchors.verticalCenter: parent.verticalCenter
                    text: Icons.getWeatherIcon(String(sky.reading.wCode ?? "113"), Weather.isNightNow())
                    iconSize: PrismTheme.dp(30)
                    color: PrismTheme.accentInk
                }
                PrismText {
                    id: degrees
                    anchors.left: now.right
                    anchors.leftMargin: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: sky.temp.replace(/[CF]$/, "")
                    // The reading the glance is for, in the accent's ink.
                    color: PrismTheme.accentInk
                    figures: true
                    font.pixelSize: PrismTheme.title
                    font.weight: Font.Medium
                    font.letterSpacing: -PrismTheme.title * 0.02
                }
                Column {
                    anchors.left: degrees.right
                    anchors.leftMargin: PrismTheme.dp(12)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: PrismTheme.dp(1)
                    PrismText {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: String(sky.reading.description ?? "")
                        font.pixelSize: PrismTheme.body
                        font.weight: Font.Medium
                    }
                    PrismText {
                        visible: sky.high.length > 0 && sky.low.length > 0
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: "↑ " + sky.high.replace(/[CF]$/, "") + "   ↓ " + sky.low.replace(/[CF]$/, "")
                        color: PrismTheme.ink2
                        figures: true
                        font.pixelSize: PrismTheme.small
                    }
                }
            }
            Row {
                visible: sky.hours.length > 0
                width: parent.width
                topPadding: PrismTheme.dp(8)
                Repeater {
                    model: sky.hours
                    delegate: Column {
                        id: hour
                        required property var modelData
                        required property int index
                        width: sky.width / Math.max(1, sky.hours.length)
                        spacing: PrismTheme.dp(4)
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: String(hour.modelData.label ?? "")
                            // The hour that comes next reads first.
                            color: hour.index === 0 ? PrismTheme.accentInk : PrismTheme.ink3
                            font.weight: hour.index === 0 ? Font.DemiBold : Font.Normal
                            figures: true
                            font.pixelSize: PrismTheme.caption
                        }
                        PrismGlyph {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Icons.getWeatherIcon(String(hour.modelData.code ?? "113"), hour.modelData.isNight ?? false)
                            iconSize: PrismTheme.dp(17)
                            color: PrismTheme.ink2
                        }
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: String(hour.modelData.temp ?? "").replace(/[CF]$/, "")
                            figures: true
                            font.pixelSize: PrismTheme.small
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }

    // What comes next: the calendar's next events, each on its day's stamp, then the tasks still open; a press on a
    // task's ring marks it done.
    Component {
        id: agenda
        Column {
            id: next
            readonly property var events: Events.getUpcomingEvents(7).slice(0, 3)
            readonly property var tasks: Array.from(Todo.list ?? []).map((task, index) => ({ content: String(task?.content ?? ""), done: task?.done === true, index: index }))
                .filter(task => !task.done && task.content.length > 0).slice(0, 3)
            readonly property bool shown: next.events.length + next.tasks.length > 0
            spacing: 0
            Head { text: Translation.tr("Up next") }
            Repeater {
                model: next.events
                delegate: Item {
                    id: event
                    required property var modelData
                    readonly property date when: new Date(event.modelData.dateTime)
                    width: next.width
                    height: PrismTheme.dp(44)
                    Column {
                        id: stamp
                        width: PrismTheme.dp(30)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: -PrismTheme.dp(1)
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: Translation.locale.toString(event.when, "ddd")
                            color: PrismTheme.ink3
                            font.pixelSize: PrismTheme.caption
                            font.weight: Font.DemiBold
                        }
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: String(event.when.getDate())
                            color: PrismTheme.accentInk
                            figures: true
                            font.pixelSize: PrismTheme.head
                            font.weight: Font.DemiBold
                        }
                    }
                    Column {
                        anchors.left: stamp.right
                        anchors.leftMargin: PrismTheme.dp(12)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(1)
                        PrismText {
                            width: parent.width
                            text: String(event.modelData.title ?? "")
                            font.pixelSize: PrismTheme.body
                            font.weight: Font.Medium
                        }
                        PrismText {
                            width: parent.width
                            text: Translation.locale.toString(event.when, Translation.locale.timeFormat(Locale.ShortFormat))
                            color: PrismTheme.ink2
                            figures: true
                            font.pixelSize: PrismTheme.small
                        }
                    }
                }
            }
            Repeater {
                model: next.tasks
                delegate: Item {
                    id: task
                    required property var modelData
                    width: next.width
                    height: PrismTheme.dp(32)
                    PrismGlyph {
                        id: ring
                        x: (PrismTheme.dp(30) - width) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: ringArea.containsMouse ? "check_circle" : "radio_button_unchecked"
                        iconSize: PrismTheme.dp(18)
                        color: ringArea.containsMouse ? PrismTheme.accentInk : PrismTheme.ink3
                        MouseArea {
                            id: ringArea
                            anchors.fill: parent
                            anchors.margins: -PrismTheme.dp(6)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr("Done")
                            onClicked: Todo.markDone(task.modelData.index)
                        }
                    }
                    PrismText {
                        anchors.left: parent.left
                        anchors.leftMargin: PrismTheme.dp(42)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: task.modelData.content
                        color: PrismTheme.ink2
                        font.pixelSize: PrismTheme.body
                    }
                }
            }
        }
    }

    // How the machine is doing: each measure a name, its value and a hairline of white light as long as it.
    Component {
        id: vitals
        Column {
            id: machine
            readonly property bool shown: true
            // Read only while the column is on screen.
            readonly property bool live: root.active
            onLiveChanged: machine.live ? ResourceUsage.keepAlive(machine) : ResourceUsage.releaseKeepAlive(machine)
            Component.onCompleted: if (machine.live) ResourceUsage.keepAlive(machine)
            Component.onDestruction: ResourceUsage.releaseKeepAlive(machine)
            // The measures by name only: each line reads its own value, so a new reading moves its bar instead of
            // building the lines again (a list of readings changed with every sample and rebuilt them each time).
            readonly property bool hasTemp: ResourceUsage.maxTemp > 0
            readonly property var measures: machine.hasTemp ? ["cpu", "memory", "temp"] : ["cpu", "memory"]
            spacing: 0
            Head { text: Translation.tr("Vitals") }
            Repeater {
                model: machine.measures
                delegate: Item {
                    id: measure
                    required property string modelData
                    readonly property real level: measure.modelData === "cpu" ? ResourceUsage.cpuUsage
                        : measure.modelData === "memory" ? ResourceUsage.memoryUsedPercentage : ResourceUsage.tempPercentage
                    width: machine.width
                    height: PrismTheme.dp(36)
                    PrismText {
                        anchors.left: parent.left
                        anchors.right: value.left
                        anchors.rightMargin: PrismTheme.dp(8)
                        y: PrismTheme.dp(6)
                        text: measure.modelData === "cpu" ? Translation.tr("Processor")
                            : measure.modelData === "memory" ? Translation.tr("Memory") : Translation.tr("Temperature")
                        font.pixelSize: PrismTheme.body
                        font.weight: Font.Medium
                    }
                    PrismText {
                        id: value
                        anchors.right: parent.right
                        y: PrismTheme.dp(6)
                        text: measure.modelData === "temp" ? ResourceUsage.maxTemp + "°" : Math.round(measure.level * 100) + "%"
                        color: PrismTheme.accentInk
                        figures: true
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        y: parent.height - PrismTheme.dp(8)
                        width: parent.width
                        height: PrismTheme.dp(3)
                        radius: height / 2
                        color: PrismTheme.fillPress
                        Rectangle {
                            width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, measure.level)))
                            height: parent.height
                            radius: parent.radius
                            // The graphs' one mark: the person's accent.
                            color: PrismTheme.mark
                            Behavior on width { NumberAnimation { duration: PrismTheme.ms(420); easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }
}
