pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Sky: the Island's body is the sky outside this minute. The sun crosses it from one end to the other, low and warm at
// the ends, the moon rises in its real phase at its real hour, and the weather is painted in it (Picture.qml).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real clockAt: Math.round(16 * root.d)
    // Past the widest time, not this one: the sun's path doesn't jump when a digit does.
    readonly property real clockEnd: root.clockAt + Math.max(clock.width, widest.width)
    readonly property real contentWidth: Math.round(316 * root.d)
    readonly property date now: DateTime.clock.date

    readonly property real clock: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property real rise: Math.max(0, IrisFaceData.dayShare(Weather.data?.sunrise)) || 0.25
    readonly property real fall: Math.max(0, IrisFaceData.dayShare(Weather.data?.sunset)) || 0.79
    readonly property string glyph: (Weather.enabled ? (Icons.getWeatherIcon(Weather.data?.wCode, false) ?? "clear_day") : "clear_day")
    readonly property var weather: ({
        clear_day: [0, 0, 0, 0, 0], partly_cloudy_day: [0.46, 0, 0, 0, 0], cloud: [0.86, 0, 0, 0, 0], foggy: [0.5, 0, 0, 0.85, 0],
        rainy: [0.92, 1, 0, 0, 0.2], cloudy_snowing: [0.8, 0.3, 0.7, 0, 0], weather_snowy: [0.8, 0, 1, 0, 0],
        weather_hail: [0.9, 0.7, 0.5, 0, 0.3], thunderstorm: [1, 1, 0, 0, 1]
    })[root.glyph] ?? [0.3, 0, 0, 0, 0]

    
    ShaderEffect {
        id: painting
        width: Math.max(1, root.island?.compactTargetWidth ?? root.width)
        height: root.island?.compactHeight ?? 42
        readonly property size dims: Qt.size(width, height)
        readonly property real sun: (root.clock - root.rise) / Math.max(0.01, root.fall - root.rise)
        readonly property real phase: Weather.moonAge / 29.530588853
        // The moon crosses the sky about six hours either side of its meridian, a day later each lap of its phase.
        readonly property real moonAt: ((root.clock - (0.5 + painting.phase) % 1 + 1.5) % 1 - 0.5) / 0.5 + 0.5
        readonly property real south: Number(Weather.location?.lat ?? 0) < 0 ? 1 : 0
        readonly property real pathFrom: (root.clockEnd + Math.round(26 * root.d)) / painting.width
        readonly property real pathTo: 1 - (Math.round(20 * root.d) + (root.island?.barPieceReserve ?? 0)) / painting.width
        property real cover: root.weather[0]
        Behavior on cover { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(1400); velocity: -1 } }
        property real rain: root.weather[1]
        Behavior on rain { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(1400); velocity: -1 } }
        property real snow: root.weather[2]
        Behavior on snow { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(1400); velocity: -1 } }
        property real fog: root.weather[3]
        Behavior on fog { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(1400); velocity: -1 } }
        readonly property real storm: root.weather[4]
        readonly property real wash: IrisStyle.scheme === "light" ? 0.52 : 0
        readonly property real drift: (Math.floor(root.now.getTime() / 60000) % 100000) * 0.004
        fragmentShader: Qt.resolvedUrl("sky.frag.qsb")
    }

    TextMetrics {
        id: widest
        font.family: root.family
        font.pixelSize: root.figure
        font.weight: IrisStyle.figureWeight
        text: "88:88"
    }
    IrisClock {
        id: clock
        x: root.clockAt
        anchors.verticalCenter: parent.verticalCenter
        pixelSize: root.figure
        family: root.family
        color: IrisStyle.scheme === "light" ? IrisStyle.text : "#ffffff" // iris-literal: ink over a painting
        separatorColor: clock.color
    }
}
