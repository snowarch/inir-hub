import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The hour, thin and large, and the day under it.
NihilWidgetFace {
    id: root

    readonly property string format: root.widget.timeFormat ?? "system"
    readonly property string pattern: root.format === "24h" ? "HH:mm" : root.format === "12h" ? "hh:mm AP"
        : (Config.options?.time?.format ?? "hh:mm")
    readonly property date now: DateTime.clock.date
    readonly property string written: Qt.locale().toString(root.now, root.pattern)
    readonly property string hour: root.written.replace(/\s*[AaPp][Mm]$/, "")
    readonly property string period: root.written.slice(root.hour.length).trim()
    readonly property bool weatherShown: root.large && Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: root.dp(2)

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.dp(6)

            NText {
                id: figure
                figures: true
                text: root.hour
                font.weight: Font.Light
                font.pixelSize: Math.min(root.contentHeight * (root.small ? 0.56 : 0.62),
                    root.contentWidth / Math.max(3, root.hour.length * 0.62 + (root.period.length > 0 ? 1.4 : 0)))
            }
            NText {
                anchors.baseline: figure.baseline
                visible: root.period.length > 0
                text: root.period
                font.pixelSize: figure.font.pixelSize * 0.26
                color: NihilStyle.inkSoft
            }
        }
        NText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: Translation.locale.toString(root.now, root.small ? "ddd d" : "dddd, d MMMM")
            elide: Text.ElideRight
            font.pixelSize: root.dp(root.small ? 13 : 15)
            color: NihilStyle.inkSoft
        }
        NText {
            width: parent.width
            visible: root.weatherShown
            topPadding: root.dp(6)
            horizontalAlignment: Text.AlignHCenter
            text: `${Weather.data?.temp ?? ""}  ${Weather.describeWeather(Weather.data?.wCode, Weather.isNightNow())}`
            elide: Text.ElideRight
            font.pixelSize: root.dp(13)
            color: NihilStyle.inkSoft
        }
    }
}
