pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

// The Greeting (his 11-06 Nothing OS reference): the time as large as the plate lets it, the date under it and a word
// for the part of the day with the weather beside it. Under Nothing the time is its dot matrix, the date spaced
// capitals and the greeting ends on the signal dot; under Apple the same three lines in its own voice.
Item {
    id: view
    required property var face
    required property date now
    required property string timeText

    readonly property bool label: view.face.nothing ?? false
    readonly property int hour: view.now.getHours()
    readonly property string greeting: view.hour >= 5 && view.hour < 12 ? Translation.tr("Good morning")
        : view.hour >= 12 && view.hour < 18 ? Translation.tr("Good afternoon")
        : view.hour >= 18 && view.hour < 22 ? Translation.tr("Good evening") : Translation.tr("Good night")
    readonly property string dateLine: view.label
        ? Translation.locale.toString(view.now, view.face.small ? "ddd d MMM" : "dddd d MMMM yyyy").replace(/\./g, "").toUpperCase()
        : IrisFaceData.capitalized(Translation.locale.toString(view.now, view.face.small ? "ddd d MMM" : "dddd, d MMMM").replace(/\./g, ""))
    readonly property string temp: {
        const value = String(Weather.data?.temp ?? "")
        return Weather.enabled && value.length > 0 && !value.startsWith("--") ? value : ""
    }

    // Sized from the room through a ruler at a known size, never from its own width.
    IrisClock {
        id: ruler
        visible: false
        text: view.timeText
        pixelSize: 100
        weight: view.face.figureWeight
        family: view.face.fontNumbers
    }
    readonly property real figure: Math.max(view.face.px(24), Math.floor(Math.min(view.width * 100 / Math.max(1, ruler.implicitWidth),
        view.height * (view.face.small ? 0.5 : view.face.large ? 0.6 : 0.56))))

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: view.face.dp(view.label ? 8 : 4)
        IrisClock {
            Layout.maximumWidth: view.width
            text: view.timeText
            pixelSize: view.figure
            weight: view.face.figureWeight
            color: view.face.ink
            separatorColor: view.face.highlight
            family: view.face.fontNumbers
        }
        FaceText {
            face: view.face
            Layout.fillWidth: true
            text: view.dateLine
            color: view.label ? view.face.ink : view.face.heading
            size: view.label ? (view.face.small ? 10.5 : 12) : (view.face.small ? 13 : 15)
            weight: view.label ? Font.Medium : Font.DemiBold
            font.family: view.label ? view.face.fontLabel : view.face.fontMain
            font.letterSpacing: view.label ? view.face.px(12) * 0.16 : 0
        }
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: view.face.dp(7)
            FaceText {
                face: view.face
                Layout.fillWidth: false
                Layout.maximumWidth: view.width - weather.implicitWidth - view.face.dp(20)
                text: view.label ? view.greeting.toUpperCase() : view.greeting
                color: view.face.inkSecondary
                size: view.label ? (view.face.small ? 10.5 : 12) : (view.face.small ? 12.5 : 14)
                weight: view.label ? Font.Medium : Font.Normal
                font.family: view.label ? view.face.fontLabel : view.face.fontMain
                font.letterSpacing: view.label ? view.face.px(12) * 0.16 : 0
            }
            Rectangle {
                visible: view.label
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: view.face.dp(7)
                Layout.preferredHeight: view.face.dp(7)
                radius: width / 2
                color: view.face.signal
            }
            Item { Layout.fillWidth: true }
            FaceText {
                id: weather
                face: view.face
                visible: view.temp.length > 0 && !view.face.small
                text: view.temp
                color: view.face.inkSecondary
                size: view.label ? 12 : 14
                weight: Font.DemiBold
                font.family: view.label ? view.face.fontLabel : view.face.fontMain
            }
        }
    }
}
