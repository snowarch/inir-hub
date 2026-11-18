pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.nihil.style
import "../style/DotGlyphs.js" as DotGlyphs

// The weather. Small: a round piece, the sky in dots, the temperature and one word. Medium and large: the forecast
// card: the sky, the temperature in the signal colour, today's high and low, the place and the word, then the days
// with their skies, highs in the signal colour and lows in ink.
NihilFace {
    id: root

    readonly property var wx: Weather.data ?? ({})
    readonly property bool has: Weather.hasData ?? false
    readonly property string temp: String(root.wx.temp ?? "--").replace(/[^0-9-]/g, "") || "--"
    readonly property string word: root.has ? Weather.describeWeather(root.wx.wCode, Weather.isNightNow()) : Translation.tr("No weather")
    readonly property string sky: DotGlyphs.iconFor(root.wx.wCode ?? "113", root.has && Weather.isNightNow())
    readonly property var days: Array.from(root.wx.forecast ?? []).slice(0, root.large ? 7 : 5)
    function figure(value): string { return String(value ?? "").replace(/[^0-9-]/g, "") }

    // Small.
    Rectangle {
        visible: root.small
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: NihilStyle.piece
        Column {
            anchors.centerIn: parent
            spacing: root.dp(6)
            DotText { anchors.horizontalCenter: parent.horizontalCenter; icon: root.sky; dot: root.dp(4); spacing: root.dp(1.6) }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                font.pixelSize: root.dp(34)
                text: root.temp
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                font.pixelSize: root.dp(11)
                font.capitalization: Font.AllUppercase
                color: NihilStyle.inkSoft
                text: root.word
            }
        }
    }

    // Medium and large.
    Rectangle {
        visible: !root.small
        anchors.fill: parent
        radius: root.radius
        color: NihilStyle.piece

        Row {
            id: now
            x: root.dp(16); y: root.dp(14)
            spacing: root.dp(10)
            DotText { anchors.verticalCenter: parent.verticalCenter; icon: root.sky; dot: root.dp(3.4); spacing: root.dp(1.2) }
            DotText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.temp
                dot: root.dp(4)
                spacing: root.dp(1)
                fuse: true
                color: NihilStyle.accent
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                NText { figures: true; font.pixelSize: root.dp(10); text: `H ${root.figure(root.wx.tempMax)}` }
                NText { figures: true; font.pixelSize: root.dp(10); text: `L ${root.figure(root.wx.tempMin)}` }
            }
        }
        Column {
            anchors.right: parent.right
            anchors.rightMargin: root.dp(16)
            anchors.verticalCenter: now.verticalCenter
            NText {
                anchors.right: parent.right
                width: Math.min(implicitWidth, root.width * 0.42)
                horizontalAlignment: Text.AlignRight
                figures: true
                font.bold: true
                font.pixelSize: root.dp(11)
                text: Weather.showVisibleCity ? Weather.visibleCity : ""
            }
            NText {
                anchors.right: parent.right
                figures: true
                font.pixelSize: root.dp(11)
                color: NihilStyle.accent
                text: root.word
            }
        }

        Row {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.dp(14) }
            visible: root.days.length > 0
            Repeater {
                model: root.days
                delegate: Column {
                    id: day
                    required property var modelData
                    width: parent.width / Math.max(1, root.days.length)
                    spacing: root.dp(5)
                    NText { anchors.horizontalCenter: parent.horizontalCenter; figures: true; font.pixelSize: root.dp(11); text: String(day.modelData.dayName ?? "").slice(0, 3) }
                    DotText { anchors.horizontalCenter: parent.horizontalCenter; icon: DotGlyphs.iconFor(day.modelData.code, false); dot: root.dp(2.4); spacing: root.dp(0.8) }
                    NText { anchors.horizontalCenter: parent.horizontalCenter; figures: true; font.pixelSize: root.dp(10); color: NihilStyle.accent; text: root.figure(day.modelData.hi) }
                    NText { anchors.horizontalCenter: parent.horizontalCenter; figures: true; font.pixelSize: root.dp(10); text: root.figure(day.modelData.lo) }
                }
            }
        }
        NText {
            visible: root.days.length === 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.dp(20)
            figures: true
            font.pixelSize: root.dp(12)
            color: NihilStyle.inkSoft
            text: Weather.enabled ? Translation.tr("Waiting for the forecast") : Translation.tr("Weather is off in Settings")
        }
    }
}
