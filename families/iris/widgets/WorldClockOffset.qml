pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Offset (his 11-06 reference, "Shibuya +4H"): one city leads with how far its clock stands from yours as the figure,
// its time and day under it, and the distance drawn: a ruler of the 24 hours around your now, your now its middle
// notch, the city's time in a capsule as far along as its clock runs ahead or behind, the hours between lit. A tap
// brings the next city to the lead; large lists every city under the ruler, a tap on one leads with it.
Item {
    id: view
    required property var face

    readonly property var cities: view.face.cities
    property int pick: 0
    readonly property int lead: Math.min(view.pick, Math.max(0, view.cities.length - 1))
    readonly property var city: view.cities[view.lead] ?? null
    readonly property color mark: view.face.highlight

    // Hours the city's clock runs ahead (+) or behind (-) yours, and the same folded into the ruler's 24 hours.
    function hoursOf(index: int): real {
        return ((WorldClock.offsetsMinutes[index] ?? 0) - view.face.localOffset) / 60
    }
    function folded(hours: real): real {
        return hours > 12 ? hours - 24 : hours < -12 ? hours + 24 : hours
    }
    function offsetWord(index: int): string {
        const hours = view.hoursOf(index)
        if (hours === 0) return Translation.tr("Same time")
        const size = Math.abs(hours) % 1 === 0 ? Math.abs(hours) : Math.abs(hours).toFixed(1)
        return Translation.tr("%1 h").arg((hours > 0 ? "+" : "−") + size)
    }
    function dayWord(index: int): string {
        const day = view.face.widget.cityDayDelta(index)
        return day > 0 ? Translation.tr("Tomorrow") : day < 0 ? Translation.tr("Yesterday") : Translation.tr("Today")
    }

    // The capsule slides from your now to the city's as the face shows or the lead changes.
    readonly property real reach: view.city ? view.folded(view.hoursOf(view.lead)) / 12 : 0
    IrisSpring { id: reachSpring; intent: "move"; to: view.reach }
    onLeadChanged: view.slide()
    Component.onCompleted: view.slide()
    function slide(): void {
        if (!IrisStyle.motionEnabled || !view.face.moving) return
        reachSpring.value = 0
        reachSpring.kick()
    }

    FaceText {
        face: view.face
        visible: view.cities.length === 0
        anchors.centerIn: parent
        text: Translation.tr("Add a city")
        color: view.face.inkTertiary
        size: 12.5
    }

    // The ruler: an hour's tick every step, longer every six; the hours between your now and the city's lit.
    component Ruler: Item {
        id: ruler
        property bool labelled: false
        readonly property real pad: view.face.dp(4)
        readonly property real half: ruler.width / 2 - ruler.pad
        readonly property real axis: view.face.dp(30)
        readonly property real markX: ruler.width / 2 + reachSpring.value * ruler.half
        implicitHeight: ruler.axis + view.face.dp(ruler.labelled ? 26 : 6)

        Repeater {
            model: 25
            Rectangle {
                required property int index
                readonly property real at: (index - 12) / 12
                readonly property bool major: index % 6 === 0
                readonly property bool between: (at > 0 && at <= reachSpring.value + 0.001) || (at < 0 && at >= reachSpring.value - 0.001)
                x: Math.round(ruler.width / 2 + at * ruler.half - width / 2)
                y: ruler.axis - height
                width: Math.max(1, Math.round(view.face.dp(1.5)))
                height: view.face.dp(major ? 11 : 6)
                radius: width / 2
                color: between ? view.mark : view.face.inkTertiary
            }
        }
        Rectangle {
            x: Math.min(ruler.width / 2, ruler.markX)
            y: ruler.axis + view.face.dp(3)
            width: Math.abs(ruler.markX - ruler.width / 2)
            height: view.face.dp(3)
            radius: height / 2
            color: Qt.alpha(view.mark, 0.5)
        }
        // Your now: the ink notch in the middle.
        Rectangle {
            x: Math.round(ruler.width / 2 - width / 2)
            y: ruler.axis - view.face.dp(17)
            width: Math.max(2, Math.round(view.face.dp(2)))
            height: view.face.dp(23)
            radius: width / 2
            color: view.face.ink
        }
        // The city's time, where its clock stands.
        Rectangle {
            id: capsule
            visible: view.city !== null && view.hoursOf(view.lead) !== 0
            x: Math.round(Math.max(0, Math.min(ruler.width - width, ruler.markX - width / 2)))
            y: 0
            width: capsuleText.implicitWidth + view.face.dp(12)
            height: view.face.dp(18)
            radius: IrisStyle.capsule(height)
            color: view.mark
            FaceText {
                id: capsuleText
                face: view.face
                anchors.centerIn: parent
                text: view.city?.time ?? ""
                color: view.face.onFill(view.mark)
                size: 11
                weight: Font.Bold
                font.family: view.face.fontNumbers
                font.features: ({ "tnum": 1 })
            }
        }
        Repeater {
            model: ruler.labelled ? [-12, -6, 0, 6, 12] : []
            FaceText {
                required property int modelData
                face: view.face
                x: Math.round(Math.max(0, Math.min(ruler.width - width, ruler.width / 2 + modelData / 12 * ruler.half - width / 2)))
                y: ruler.axis + view.face.dp(10)
                text: modelData === 0 ? Translation.tr("Here") : (modelData > 0 ? "+" : "−") + Math.abs(modelData)
                color: modelData === 0 ? view.face.ink : view.face.inkTertiary
                size: 10.5
                weight: modelData === 0 ? Font.DemiBold : Font.Medium
                font.family: modelData === 0 ? view.face.fontMain : view.face.fontNumbers
            }
        }
    }

    ColumnLayout {
        visible: view.city !== null
        anchors.fill: parent
        spacing: view.face.dp(2)

        // The lead: its name and whether it is day there; a tap moves the lead to the next city.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: head.implicitHeight
            RowLayout {
                id: head
                width: parent.width
                spacing: view.face.dp(6)
                FaceText {
                    face: view.face
                    Layout.fillWidth: true
                    text: view.city?.name ?? ""
                    size: view.face.large ? 15 : 13
                    weight: Font.DemiBold
                }
                MaterialSymbol {
                    text: view.city?.isDay ? "light_mode" : "dark_mode"
                    fill: 1
                    iconSize: view.face.px(16)
                    color: view.city?.isDay ? view.face.warm : view.face.inkSecondary
                }
            }
        }
        FaceFigure {
            face: view.face
            Layout.topMargin: view.face.dp(view.face.large ? 6 : 2)
            text: view.city ? view.offsetWord(view.lead) : ""
            size: view.face.large ? 64 : view.face.medium ? 44 : 38
            tone: view.face.ink
        }
        FaceText {
            face: view.face
            Layout.fillWidth: true
            text: view.city ? view.city.time + " · " + view.dayWord(view.lead) : ""
            color: view.face.inkSecondary
            size: 12
            font.features: ({ "tnum": 1 })
        }
        Item { Layout.fillHeight: true }
        Ruler {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            labelled: view.face.large
        }
        // Large: every city under the ruler, the lead in ink; a tap on one leads with it.
        Repeater {
            model: view.face.large ? view.cities : []
            Item {
                id: row
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: view.face.dp(30)
                Rectangle {
                    width: parent.width
                    height: 1
                    color: view.face.hairline
                }
                FaceText {
                    face: view.face
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width - rowTime.width - view.face.dp(12))
                    text: row.modelData.name
                    color: row.index === view.lead ? view.face.ink : view.face.inkSecondary
                    size: 12.5
                    weight: row.index === view.lead ? Font.DemiBold : Font.Medium
                }
                FaceText {
                    id: rowTime
                    face: view.face
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.time + "  " + view.offsetWord(row.index)
                    color: row.index === view.lead ? view.face.ink : view.face.inkTertiary
                    size: 12
                    font.family: view.face.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
                TapHandler {
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: view.pick = row.index
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    // Small and medium: a tap anywhere brings the next city to the lead.
    TapHandler {
        enabled: !view.face.large && view.cities.length > 1
        gesturePolicy: TapHandler.WithinBounds
        onTapped: view.pick = (view.lead + 1) % view.cities.length
    }
    HoverHandler {
        enabled: !view.face.large && view.cities.length > 1
        cursorShape: Qt.PointingHandCursor
    }
    Accessible.role: view.cities.length > 1 && !view.face.large ? Accessible.Button : Accessible.StaticText
    Accessible.name: view.cities.length > 1 && !view.face.large ? Translation.tr("Next city") : (view.city?.name ?? "")
}
