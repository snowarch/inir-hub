pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Duo · Window: the time, and a window on the sky outside, ground at its foot: the sun on its real arc, the weather passing
// over it, the temperature, at night the moon in tonight's phase. The song never shows here: the Island's own bubble already holds it.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth
    readonly property real size: Math.round(root.h - 10 * root.d)
    readonly property real sunrise: IrisFaceData.dayShare(Weather.data?.sunrise)
    readonly property real sunset: IrisFaceData.dayShare(Weather.data?.sunset)
    readonly property real at: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property real rise: root.sunrise >= 0 ? root.sunrise : 0.25
    readonly property real fall: root.sunset >= 0 ? root.sunset : 0.79
    readonly property bool night: root.at < root.rise - 0.02 || root.at > root.fall + 0.02
    readonly property string hour: root.night ? "night" : root.at < root.rise + 0.04 ? "dawn" : root.at > root.fall - 0.04 ? "dusk" : "day"
    readonly property var skies: ({ // iris-literal: a painted sky, a picture and not a surface
        night: ["#0a1030", "#1e2c5c"], // iris-literal: painted sky
        dawn: ["#39477f", "#f4ab70"], // iris-literal: painted sky
        day: ["#1c58c0", "#6fb0ec"], // iris-literal: painted sky
        dusk: ["#3b2a70", "#f2764c"] // iris-literal: painted sky
    })
    readonly property string glyph: Icons.getWeatherIcon(Weather.data?.wCode, root.night) ?? ""
    readonly property bool overcast: /cloud|fog|foggy|rain|snow|storm|thunder|mist|haze|weather_/.test(root.glyph)
    // The sky goes grey behind cloud, by day; a clear night stays deep.
    readonly property color skyTop: root.overcast && !root.night ? Qt.tint(root.skies[root.hour][0], "#99808a98") : root.skies[root.hour][0] // iris-literal: cloud over a painted sky
    readonly property color skyFoot: root.overcast && !root.night ? Qt.tint(root.skies[root.hour][1], "#99c4c9d0") : root.skies[root.hour][1] // iris-literal: cloud over a painted sky
    readonly property string temperature: Weather.enabled && !String(Weather.data?.temp ?? "--").startsWith("--")
        ? String(Weather.data?.temp ?? "").replace(/[^\d-]/g, "") + "°" : ""
    readonly property real daylight: Math.max(0, Math.min(1, (root.at - root.rise) / Math.max(0.01, root.fall - root.rise)))

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(root.size * 2.5)
            height: root.size

            ClippingRectangle {
                id: window
                anchors.fill: parent
                radius: IrisStyle.radiusTile
                color: root.skyTop
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: root.skyTop; Behavior on color { enabled: IrisStyle.motionEnabled; ColorAnimation { duration: IrisStyle.duration(900) } } }
                        GradientStop { position: 1; color: root.skyFoot; Behavior on color { enabled: IrisStyle.motionEnabled; ColorAnimation { duration: IrisStyle.duration(900) } } }
                    }
                }
                Rectangle {
                    visible: !root.night
                    readonly property real glow: Math.round(root.size * 0.62)
                    x: Math.round(window.width * (0.08 + 0.56 * root.daylight)) - width / 2
                    y: Math.round(window.height * (0.84 - 0.6 * Math.sin(Math.PI * root.daylight))) - height / 2
                    Behavior on x { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(420); velocity: -1 } }
                    Behavior on y { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(420); velocity: -1 } }
                    width: glow
                    height: glow
                    radius: width / 2
                    color: root.overcast ? "#30fff4d6" : "#50fff4d6" // iris-literal: the sun's glow
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.58)
                        height: width
                        radius: width / 2
                        color: root.overcast ? "#e0fff6dc" : "#fff6dc" // iris-literal: the sun
                    }
                }
                Repeater {
                    model: root.night ? [[0.06, 0.3], [0.14, 0.16], [0.22, 0.46], [0.44, 0.2], [0.52, 0.52], [0.62, 0.14]] : []
                    Rectangle {
                        required property var modelData
                        x: Math.round(window.width * modelData[0])
                        y: Math.round(window.height * modelData[1])
                        width: 1
                        height: 1
                        color: "#c9d6ff" // iris-literal: a star
                    }
                }
                Canvas {
                    id: moon
                    visible: root.night
                    x: Math.round(window.width * 0.3)
                    y: Math.round((window.height - height) / 2 - 2 * root.d)
                    width: Math.round(root.size * 0.62)
                    height: width
                    // A step of about three hours: the shadow never moves faster than that.
                    readonly property real phase: Math.round(Weather.moonAge / 29.530588853 * 240) / 240
                    readonly property bool south: Number(Weather.location?.lat ?? 0) < 0
                    onPhaseChanged: requestPaint()
                    onSouthChanged: requestPaint()
                    onVisibleChanged: if (visible) requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        const r = width / 2 - 0.5
                        ctx.translate(width / 2, height / 2)
                        // earthshine: the dark limb stays faintly there
                        ctx.fillStyle = "rgba(190, 205, 255, 0.16)"
                        ctx.beginPath(); ctx.arc(0, 0, r, 0, 2 * Math.PI); ctx.fill()
                        if ((moon.phase < 0.5) === moon.south) ctx.scale(-1, 1)
                        ctx.save()
                        // the shadow's edge is a half ellipse, never a second disc
                        let k = Math.cos(2 * Math.PI * moon.phase)
                        if (Math.abs(k) < 0.01) k = 0.01
                        ctx.beginPath()
                        ctx.arc(0, 0, r, -Math.PI / 2, Math.PI / 2, false)
                        ctx.scale(k, 1)
                        ctx.arc(0, 0, r, Math.PI / 2, -Math.PI / 2, true)
                        ctx.restore()
                        const lit = ctx.createLinearGradient(0, -r, 0, r)
                        lit.addColorStop(0, "#fff8e6") // iris-literal: moonlight
                        lit.addColorStop(1, "#d9cfb6") // iris-literal: moonlight
                        ctx.fillStyle = lit
                        ctx.fill()
                        ctx.clip()
                        ctx.fillStyle = "rgba(128, 120, 104, 0.24)"
                        for (const sea of [[0.3, -0.32, 0.26], [-0.2, -0.1, 0.3], [0.12, 0.38, 0.2], [0.5, 0.18, 0.16]]) {
                            ctx.beginPath(); ctx.arc(sea[0] * r, sea[1] * r, sea[2] * r, 0, 2 * Math.PI); ctx.fill()
                        }
                    }
                }
                Repeater {
                    model: root.overcast ? [[-0.1, 0.68, 0.66, 0.2], [0.12, 0.54, 0.3, 0.3], [0.46, 0.8, 0.7, 0.18], [0.62, 0.68, 0.26, 0.26]] : []
                    Rectangle {
                        required property var modelData
                        x: Math.round(window.width * modelData[0])
                        y: Math.round(window.height * modelData[1])
                        width: Math.round(window.width * modelData[2])
                        height: Math.round(window.height * modelData[3])
                        radius: height / 2
                        color: root.night ? "#303c68" : "#eef1f5" // iris-literal: cloud
                    }
                }
                // The ground, so it reads as a place and not as a ball.
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.round(window.height * 0.16)
                    color: Qt.darker(root.skyFoot, root.night ? 1.6 : 2.2)
                }
                IrisText {
                    visible: root.temperature.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(8 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -Math.round(1 * root.d)
                    text: root.temperature
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(Font.Bold)
                    font.features: ({ "tnum": 1 })
                    color: "#ffffff" // iris-literal: ink over a painting
                }
            }
        }
    }
}
