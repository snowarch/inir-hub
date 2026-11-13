pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

IrisWidgetFace {
    id: root

    readonly property bool analog: String(root.widget.familyOption("face", "analog")) === "analog"
    readonly property bool hourStyle: String(root.widget.familyOption("face", "analog")) === "hour"
    readonly property bool greetingStyle: String(root.widget.familyOption("face", "analog")) === "greeting"
    readonly property bool seconds: Boolean(root.widget.familyOption("seconds", true))
    readonly property bool week: Boolean(root.widget.familyOption("week", true))
    readonly property var now: clock.date
    readonly property string timePattern: {
        const format = String(root.widget.timeFormat ?? "system")
        if (format === "24h") return "HH:mm"
        if (format === "12h") return "h:mm AP"
        return String(Config.options?.time?.format ?? "hh:mm").replace(/:ss/, "")
    }
    readonly property string timeText: Translation.locale.toString(root.now, root.timePattern)
    readonly property string weekday: {
        const name = Translation.locale.toString(root.now, "dddd")
        return name.charAt(0).toUpperCase() + name.slice(1)
    }
    readonly property string longDate: Translation.locale.toString(root.now, "d MMMM")

    // A Design may print its own clock (AIRISU's date stamp): the dial and the figures step aside for it.
    designFace: root.hourStyle || root.greetingStyle ? "" : IrisDesign.skin("widgetClock")
    padding: root.analog && root.small ? root.dp(8) : root.edgePad

    SystemClock {
        id: clock
        precision: root.analog && root.seconds && root.moving ? SystemClock.Seconds : SystemClock.Minutes
    }

    FaceDial {
        id: dial
        visible: root.analog && !root.designed
        face: root
        // Large: the dial leads above the week; medium: beside the date. Placed by x/y: anchors switched per size
        // left the dial at the old size's width after a size change (10-23).
        width: root.small ? parent.width : root.large ? Math.min(parent.width, parent.height - footer.height - root.dp(14)) : parent.height
        height: width
        x: root.large ? Math.round((parent.width - width) / 2) : 0
        y: root.large ? 0 : Math.round((parent.height - height) / 2)
        time: root.now
        seconds: root.seconds
        caption: root.small ? Translation.locale.toString(root.now, "ddd d").replace(/\./g, "")
            : root.large ? Translation.locale.toString(root.now, "d MMM").replace(/\./g, "") : ""
    }

    ColumnLayout {
        id: column
        visible: (!root.analog || root.medium) && !root.designed && !root.hourStyle && !root.greetingStyle
        anchors.left: root.analog ? dial.right : parent.left
        anchors.leftMargin: root.analog ? root.dp(18) : 0
        anchors.right: parent.right
        // Beside a dial the column spans the dial's height: the date on its top line, the week on its bottom one, so
        // the card keeps the same air at every edge instead of a short block floating in the middle.
        readonly property bool spans: root.analog && root.medium
        y: root.large || column.spans ? 0 : Math.round((parent.height - height) / 2)
        height: column.spans ? parent.height : implicitHeight
        spacing: root.dp(2)

        // The week strip says the weekday wherever it shows.
        FaceText {
            face: root
            visible: root.small
            Layout.fillWidth: true
            text: root.weekday
            color: root.highlight
            size: root.small ? 13 : 14
            weight: Font.DemiBold
        }
        // Beside a dial the hour is already read: the figure there is the date, its month a step down.
        Row {
            visible: root.analog
            spacing: root.dp(6)
            FaceFigure {
                id: dateFigure
                face: root
                text: root.now.getDate()
                size: column.spans ? 48 : 40
            }
            FaceText {
                face: root
                anchors.baseline: dateFigure.baseline
                text: IrisFaceData.capitalized(Translation.locale.standaloneMonthName(root.now.getMonth()))
                color: root.inkSecondary
                size: 16
                weight: Font.DemiBold
            }
        }
        IrisClock {
            visible: !root.analog
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth
            text: root.timeText
            pixelSize: root.px(root.small ? 42 : root.large ? 86 : 58)
            weight: root.figureWeight
            color: root.ink
            separatorColor: root.highlight
            family: root.fontNumbers
        }
        FaceText {
            face: root
            visible: !root.analog
            Layout.fillWidth: true
            text: root.longDate
            color: root.inkSecondary
            size: root.small ? 12.5 : 13.5
        }
        Item { visible: column.spans; Layout.fillHeight: true }
        Week {
            Layout.fillHeight: false
            visible: !root.small && !root.large && root.week
            Layout.fillWidth: true
            Layout.topMargin: root.dp(6)
        }
    }

    // Large: the week as the foot, under the dial or the big digits.
    ColumnLayout {
        id: footer
        visible: root.large && !root.designed && root.week && !root.hourStyle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: root.dp(10)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.hairline
        }
        Week { Layout.fillHeight: false; Layout.fillWidth: true }
    }

    Loader {
        anchors.fill: parent
        active: root.hourStyle
        sourceComponent: Component { HourView {} }
    }

    Loader {
        active: root.greetingStyle
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.visible ? footer.top : parent.bottom
        anchors.bottomMargin: footer.visible ? root.dp(12) : 0
        sourceComponent: Component {
            ClockGreeting {
                face: root
                now: root.now
                timeText: root.timeText
            }
        }
    }

    // The Hour: the time as large as the plate lets it, the day under it as one line from midnight to midnight with now
    // on it and the sun's two marks. A person glances for the time, then for how much light is left.
    component HourView: Item {
        id: hour
        readonly property real sunrise: IrisFaceData.dayShare(Weather.data?.sunrise)
        readonly property real sunset: IrisFaceData.dayShare(Weather.data?.sunset)
        readonly property real nowAt: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
        readonly property string temp: {
            const value = String(Weather.data?.temp ?? "")
            return Weather.enabled && value.length > 0 && !value.startsWith("--") ? value : ""
        }
        // From the room, never from its own width: the ruler says what the time takes at a known size.
        IrisClock {
            id: ruler
            visible: false
            text: root.timeText
            pixelSize: 100
            weight: root.figureWeight
            family: root.fontNumbers
        }
        readonly property real figure: {
            const room = (root.medium ? hour.width * 0.68 : hour.width) * 100 / Math.max(1, ruler.implicitWidth)
            const tall = root.medium ? hour.height - dayLine.height - root.dp(14) : hour.height * 0.42
            return Math.floor(Math.min(room, tall))
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            // Small and large head the time with the day; medium has the room beside it.
            RowLayout {
                id: largeHead
                visible: !root.medium
                Layout.fillHeight: false
                Layout.fillWidth: true
                spacing: root.dp(8)
                FaceText {
                    face: root
                    Layout.fillWidth: true
                    text: root.large ? root.weekday : IrisFaceData.capitalized(Translation.locale.toString(root.now, "ddd d").replace(/\./g, ""))
                    color: root.heading
                    size: root.small ? 12.5 : 15
                    weight: Font.DemiBold
                }
                FaceText {
                    face: root
                    visible: hour.temp.length > 0
                    text: hour.temp
                    color: root.inkSecondary
                    size: root.small ? 12.5 : 15
                    weight: Font.DemiBold
                }
            }
            RowLayout {
                visible: !root.large
                Layout.fillHeight: false
                Layout.fillWidth: true
                spacing: root.dp(10)
                IrisClock {
                    Layout.alignment: Qt.AlignVCenter
                    text: root.timeText
                    pixelSize: hour.figure
                    weight: root.figureWeight
                    color: root.ink
                    separatorColor: root.highlight
                    family: root.fontNumbers
                }
                Item { visible: root.medium; Layout.fillWidth: true }
                ColumnLayout {
                    visible: root.medium
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignVCenter
                    spacing: root.dp(1)
                    FaceText {
                        face: root
                        Layout.alignment: Qt.AlignRight
                        text: IrisFaceData.capitalized(Translation.locale.toString(root.now, "ddd d").replace(/\./g, ""))
                        color: root.heading
                        size: 14
                        weight: Font.DemiBold
                    }
                    FaceText {
                        face: root
                        visible: hour.temp.length > 0
                        Layout.alignment: Qt.AlignRight
                        text: hour.temp
                        color: root.inkSecondary
                        size: 14
                        weight: Font.DemiBold
                    }
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Loader {
                    anchors.fill: parent
                    active: root.large
                    sourceComponent: Component { StackedHour {} }
                }
            }
            DayLine {
                id: dayLine
                Layout.fillHeight: false
                Layout.fillWidth: true
                sunrise: hour.sunrise
                sunset: hour.sunset
                nowAt: hour.nowAt
            }
        }
    }

    // Large: the hour over the minutes, as big as the plate lets them; the date beside the hour, what comes beside the minutes.
    component StackedHour: Item {
        id: stack
        readonly property var parts: root.timeText.match(/^(\d+)\D+(\d+)\s*(.*)$/) ?? ["", root.timeText, "", ""]
        // Set by their digits, not their line boxes: a line of this face is half as tall again as its figures.
        readonly property real digitHeight: 0.72
        readonly property real gap: root.dp(14)
        readonly property real size: Math.floor(Math.min((stack.height - stack.gap) / (2 * stack.digitHeight + 0.4), stack.width * 0.56 / 1.24))
        readonly property real digits: Math.round(stack.size * stack.digitHeight)
        readonly property real rise: Math.round((stack.height - 2 * stack.digits - stack.gap) / 2)
        readonly property var next: IrisFaceData.upcomingEvents(root.now, 2)[0] ?? null
        readonly property real column: Math.max(hourFigure.width, minuteRow.width) + root.dp(14)
        FaceFigure {
            id: hourFigure
            y: stack.rise + stack.digits - baselineOffset
            text: stack.parts[1]
            size: stack.size / root.t
            rolls: false
            face: root
        }
        Row {
            id: minuteRow
            y: stack.rise + 2 * stack.digits + stack.gap - minuteFigure.baselineOffset
            spacing: root.dp(4)
            FaceFigure {
                id: minuteFigure
                text: stack.parts[2]
                size: stack.size / root.t
                tone: root.highlight
                rolls: false
                face: root
            }
            FaceText {
                face: root
                visible: stack.parts[3].length > 0
                anchors.baseline: minuteFigure.baseline
                text: stack.parts[3]
                color: root.inkSecondary
                size: 18
                weight: Font.DemiBold
            }
        }
        FaceText {
            face: root
            x: stack.column
            y: Math.round(stack.rise + (stack.digits - height) / 2)
            width: stack.width - x
            text: root.longDate
            color: root.inkSecondary
            size: 14
            weight: Font.DemiBold
        }
        Column {
            x: stack.column
            y: Math.round(stack.rise + stack.digits + stack.gap + (stack.digits - height) / 2)
            width: stack.width - x
            visible: stack.next !== null
            FaceText {
                face: root
                width: parent.width
                text: IrisFaceData.eventTitle(stack.next)
                size: 13.5
                weight: Font.DemiBold
            }
            FaceText {
                face: root
                width: parent.width
                text: IrisFaceData.eventWhen(stack.next, root.now)
                color: root.inkSecondary
                size: 12
            }
        }
    }

    // The day from midnight to midnight: gone in the accent, the sun's stretch a step up from the night, its two marks named.
    component DayLine: Item {
        id: line
        required property real sunrise
        required property real sunset
        required property real nowAt
        readonly property bool sunKnown: line.sunrise >= 0 && line.sunset > line.sunrise
        readonly property real thick: root.dp(root.large ? 6 : 4)
        readonly property real tickOver: root.dp(3)
        implicitHeight: line.thick + 2 * line.tickOver + (line.sunKnown ? riseLabel.height + root.dp(2) : 0)
        Rectangle {
            y: line.tickOver
            width: parent.width
            height: line.thick
            radius: height / 2
            color: root.fill
        }
        Rectangle {
            visible: line.sunKnown
            x: Math.round(parent.width * line.sunrise)
            y: line.tickOver
            width: Math.round(parent.width * (line.sunset - line.sunrise))
            height: line.thick
            color: root.fillActive
        }
        Rectangle {
            y: line.tickOver
            width: Math.max(height, Math.round(parent.width * line.nowAt))
            height: line.thick
            radius: height / 2
            color: root.accent
        }
        Repeater {
            model: line.sunKnown ? [line.sunrise, line.sunset] : []
            Rectangle {
                required property real modelData
                x: Math.round(line.width * modelData)
                width: Math.max(1, root.dp(1))
                height: line.thick + 2 * line.tickOver
                color: root.inkSecondary
            }
        }
        SunLabel { id: riseLabel; at: line.sunrise }
        SunLabel { at: line.sunset }
    }
    component SunLabel: FaceText {
        id: sun
        required property real at
        readonly property real room: parent.width
        face: root
        visible: sun.at >= 0
        x: Math.max(0, Math.min(sun.room - width, Math.round(sun.room * sun.at - width / 2)))
        y: parent.implicitHeight - height
        text: IrisFaceData.clockText(new Date(2024, 0, 1, 0, Math.round(sun.at * 1440)))
        color: root.inkTertiary
        size: 10.5
        font.family: root.fontNumbers
        font.features: ({ "tnum": 1 })
    }

    // The week, today as the chosen capsule.
    component Week: RowLayout {
        spacing: root.dp(3)
        Repeater {
            model: 7
            Rectangle {
                id: weekday
                required property int index
                readonly property bool today: weekday.index === (root.now.getDay() + 6) % 7
                Layout.fillWidth: true
                implicitHeight: root.dp(20)
                radius: height / 2
                color: weekday.today ? (root.nothing ? root.signal : IrisStyle.accentFill) : "transparent"
                FaceText {
                    face: root
                    anchors.centerIn: parent
                    // 2024-01-01 was a Monday: its week gives the locale's day names in order.
                    text: Translation.locale.toString(new Date(2024, 0, 1 + weekday.index), "ddd").replace(/\./g, "").slice(0, 2)
                    size: 10.5
                    weight: weekday.today ? Font.DemiBold : Font.Medium
                    color: weekday.today ? (root.nothing ? IrisStyle.onTintFor(root.signal) : IrisStyle.inkOnAccentFill)
                        : weekday.index >= 5 ? root.inkTertiary : root.inkSecondary
                }
            }
        }
    }
}
