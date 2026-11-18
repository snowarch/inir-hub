pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// The temperature as the one large thing, what the sky is doing under it and, with room, the day's facts.
NihilWidgetFace {
    id: root

    readonly property var sky: Weather.data ?? ({})
    readonly property bool ready: Weather.enabled && !String(root.sky.temp ?? "--").startsWith("--")
    readonly property bool night: Weather.isNightNow()
    readonly property var facts: [
        { name: Translation.tr("Feels like"), value: root.sky.tempFeelsLike ?? "" },
        { name: Translation.tr("Humidity"), value: root.sky.humidity ?? "" },
        { name: Translation.tr("Wind"), value: root.sky.wind ?? "" },
        { name: Translation.tr("Sunrise"), value: root.sky.sunrise ?? "" },
        { name: Translation.tr("Sunset"), value: root.sky.sunset ?? "" },
        { name: Translation.tr("Rain"), value: root.sky.precip ?? "" }
    ]

    FaceBlank {
        visible: !root.ready
        face: root
        glyph: Weather.enabled ? "timer" : "sun"
        title: Weather.enabled ? Translation.tr("Waiting for the forecast") : Translation.tr("Weather is off")
        detail: Weather.enabled ? Translation.tr("It appears once it arrives") : Translation.tr("Turn it on in the shell's settings")
    }

    Item {
        anchors.fill: parent
        visible: root.ready

        NIcon {
            anchors.right: parent.right
            anchors.top: parent.top
            text: root.night ? "moon" : "sun"
            size: root.dp(root.small ? 18 : 22)
            color: NihilStyle.inkSoft
        }
        NSpark {
            anchors.right: parent.right
            anchors.rightMargin: root.dp(root.small ? 22 : 28)
            anchors.top: parent.top
            size: root.dp(14)
        }

        Column {
            width: parent.width
            spacing: root.dp(2)

            NDisplay {
                text: root.widget.temperatureText ?? root.sky.temp
                bloom: 0.7
                size: root.dp(root.small ? 54 : 72)
            }
            NLabel {
                width: parent.width
                strong: true
                text: Weather.describeWeather(root.sky.wCode, root.night)
            }
            NLabel {
                width: parent.width
                visible: Weather.showVisibleCity || Weather.stale
                text: Weather.stale ? Weather.updatedLabel : Weather.visibleCity
            }
        }

        Grid {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: !root.small
            columns: root.large ? 2 : 3
            rowSpacing: root.dp(8)

            Repeater {
                model: root.large ? root.facts : root.facts.slice(0, 3)

                delegate: Column {
                    id: fact
                    required property var modelData
                    width: parent.width / (root.large ? 2 : 3)
                    spacing: root.dp(3)

                    Rectangle { width: parent.width - root.dp(8); height: 1; color: NihilStyle.hair }
                    NLabel {
                        width: parent.width
                        text: fact.modelData.name
                    }
                    NText {
                        width: parent.width
                        figures: true
                        text: fact.modelData.value
                        elide: Text.ElideRight
                        font.pixelSize: root.dp(14)
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
