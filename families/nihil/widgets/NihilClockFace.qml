import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The hour set as a poster's title, the day on a rule under it.
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

    NLabel {
        anchors.left: parent.left
        anchors.top: parent.top
        text: root.period.length > 0 ? root.period : Translation.locale.toString(root.now, "dddd")
    }
    NSpark {
        anchors.right: parent.right
        anchors.top: parent.top
        size: root.dp(16)
    }

    NDisplay {
        id: figure
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.dp(4)
        text: root.hour
        bloom: 0.7
        size: Math.min(root.contentHeight * (root.small ? 0.62 : 0.72), root.contentWidth / Math.max(2.4, root.hour.length * 0.44))
    }

    NRule {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        start: Translation.locale.toString(root.now, root.small ? "ddd d" : "ddd d MMM")
        middle: root.small ? "" : "⋈"
        end: root.weatherShown ? String(Weather.data?.temp ?? "") : Translation.locale.toString(root.now, "yyyy")
    }
}
