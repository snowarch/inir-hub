import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The hour, tight and large, with the weekday over it in the accent and the date, and the weather with room, under it.
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

    NText {
        anchors.left: parent.left
        anchors.top: parent.top
        text: Translation.locale.toString(root.now, "dddd")
        font.pixelSize: root.dp(13)
        font.weight: Font.DemiBold
        color: NihilStyle.accent
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.dp(2)
        spacing: root.dp(6)
        NDisplay {
            id: figure
            text: root.hour
            size: Math.min(root.contentHeight * (root.small ? 0.5 : 0.56), root.contentWidth / Math.max(2.6, root.hour.length * 0.62))
        }
        NText {
            anchors.baseline: figure.baseline
            visible: root.period.length > 0
            text: root.period
            font.pixelSize: root.dp(14)
            font.weight: Font.DemiBold
            color: NihilStyle.inkSoft
        }
    }

    NText {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: Translation.locale.toString(root.now, root.small ? "d MMM" : "d MMMM")
        font.pixelSize: root.dp(13)
        color: NihilStyle.inkSoft
    }
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.weatherShown
        spacing: root.dp(4)
        NText {
            anchors.verticalCenter: parent.verticalCenter
            text: String(Weather.data?.temp ?? "")
            font.pixelSize: root.dp(13)
            color: NihilStyle.inkSoft
        }
    }
}
