pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.components

ColumnLayout {
    id: root

    readonly property real d: IrisStyle.settingsDensity
    readonly property var presets: NiriAnimationPresets.presets
    readonly property string activeId: NiriAnimationPresets.activeId

    spacing: Math.round(10 * root.d)
    Component.onCompleted: NiriAnimationPresets.ensure()

    // Every tile draws its opening on one clock, so a quick preset reads quick beside a slow one at rest: the longest
    // opening and a little air after it.
    readonly property real span: 1.15 * Math.max(0.1, ...root.presets.map(preset =>
        NiriAnimationPresets.easingSeconds(preset?.types?.["window-open"])))

    GridLayout {
        id: grid
        Layout.fillWidth: true
        visible: root.presets.length > 0
        columns: width >= 3 * Math.round(150 * root.d) ? 3 : 2
        columnSpacing: Math.round(8 * root.d)
        rowSpacing: Math.round(12 * root.d)

        Repeater {
            model: root.presets

            Item {
                id: tile
                required property var modelData
                readonly property bool on: root.activeId === tile.modelData.id
                readonly property bool busy: NiriAnimationPresets.applying && NiriAnimationPresets.pendingId === tile.modelData.id
                property real clock: 0
                property bool playOnce: false
                readonly property var frame: tile.clock > 0 ? NiriAnimationPresets.demoFrame(tile.modelData, tile.clock) : ({ opacity: 1, scale: 1, x: 0 })
                readonly property bool playing: tile.clock > 0
                // At rest the tile draws its motion: a window opening, as how far it is there against time, the figure
                // under it. A bounce rises past the line it lands on, a quick one is there at once; six identical stills
                // (and the column slide, whose springs barely differ) said nothing.
                readonly property var slide: {
                    const open = tile.modelData?.types?.["window-open"]
                    const ends = NiriAnimationPresets.easingSeconds(open)
                    const out = []
                    for (let i = 0; i <= 64; i++) {
                        const t = root.span * i / 64
                        out.push(t >= ends ? 1 : NiriAnimationPresets.curveValue(open, t / ends))
                    }
                    return out
                }

                Layout.fillWidth: true
                Layout.preferredHeight: stage.height + Math.round(6 * root.d) + title.implicitHeight + detail.implicitHeight

                FrameAnimation {
                    running: tile.visible && (hover.hovered || tile.playOnce)
                    onTriggered: {
                        tile.clock += frameTime
                        if (tile.frame.done) {
                            tile.clock = 0
                            tile.playOnce = false
                        }
                    }
                    onRunningChanged: if (!running) tile.clock = 0
                }

                Rectangle {
                    id: stage
                    width: parent.width
                    height: Math.round(70 * root.d)
                    radius: 0
                    color: tile.on ? IrisStyle.fillActive : hover.hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                    border.width: IrisStyle.edgeWidth
                    border.color: IrisStyle.text
                    scale: tap.pressed ? IrisStyle.pressScale(0.97) : 1
                    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }

                    readonly property real pad: Math.round(12 * root.d)
                    readonly property real column: Math.round((width - 3 * pad) / 2)

                    // Where the window starts and where it lands, and its path between them.
                    Item {
                        id: chart
                        anchors.fill: parent
                        anchors.margins: stage.pad
                        opacity: tile.playing ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                        readonly property real low: chart.height
                        readonly property real high: Math.round(chart.height * 0.3)
                        Rectangle { width: chart.width; height: 1; y: chart.high; color: IrisStyle.hairline }
                        Rectangle { width: chart.width; height: 1; y: chart.low - 1; color: IrisStyle.hairline }
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: tile.on ? IrisStyle.accent : IrisStyle.subtext
                                strokeWidth: Math.max(1.5, 2 * root.d)
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                joinStyle: ShapePath.RoundJoin
                                PathPolyline {
                                    path: tile.slide.map((v, i) => Qt.point(chart.width * i / Math.max(1, tile.slide.length - 1),
                                        chart.low - 1 - v * (chart.low - 1 - chart.high)))
                                }
                            }
                        }
                    }
                    Repeater {
                        model: 2
                        Rectangle {
                            opacity: tile.playing ? 1 : 0
                            required property int index
                            x: stage.pad + index * (stage.column + stage.pad)
                            y: stage.pad
                            width: stage.column
                            height: stage.height - 2 * stage.pad
                            radius: 0
                            color: IrisStyle.fill
                            border.width: IrisStyle.edgeWidth
                            border.color: IrisStyle.text
                        }
                    }
                    Rectangle {
                        visible: tile.playing
                        x: stage.pad + tile.frame.x * (stage.column + stage.pad)
                        y: stage.pad
                        width: stage.column
                        height: stage.height - 2 * stage.pad
                        radius: 0
                        opacity: tile.frame.opacity
                        scale: tile.frame.scale
                        color: tile.on ? IrisStyle.accent : IrisStyle.textTertiary

                        Rectangle {
                            x: Math.round(6 * root.d)
                            y: Math.round(6 * root.d)
                            width: parent.width * 0.45
                            height: Math.round(3 * root.d)
                            radius: 0
                            color: tile.on ? IrisStyle.inkOnAccent : IrisStyle.surface
                            opacity: 0.55
                        }
                    }
                }

                RowLayout {
                    id: title
                    anchors.top: stage.bottom
                    anchors.topMargin: Math.round(6 * root.d)
                    width: parent.width
                    spacing: Math.round(6 * root.d)
                    IrisText {
                        Layout.fillWidth: true
                        text: tile.busy ? Translation.tr("Applying…") : tile.modelData.name
                        color: tile.on ? IrisStyle.text : IrisStyle.subtext
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.DemiBold)
                        elide: Text.ElideRight
                    }
                    IrisText {
                        text: Translation.tr("%1 ms").arg(NiriAnimationPresets.openFeelMs(tile.modelData))
                        color: IrisStyle.muted
                        font.pixelSize: IrisStyle.typeFootnote
                        font.features: ({ "tnum": 1 })
                    }
                }
                IrisText {
                    id: detail
                    anchors.top: title.bottom
                    width: parent.width
                    text: tile.modelData.description
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    // two lines: in Drawer's column one cut "Lands at once, then settles s…"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    id: tap
                    onTapped: {
                        tile.clock = 0
                        tile.playOnce = true
                        NiriAnimationPresets.apply(tile.modelData.id)
                    }
                }
                Accessible.role: Accessible.RadioButton
                Accessible.name: tile.modelData.name
                Accessible.description: tile.modelData.description
                Accessible.checked: tile.on
            }
        }
    }

    IrisText {
        Layout.fillWidth: true
        visible: text.length > 0
        wrapMode: Text.WordWrap
        color: NiriAnimationPresets.error.length > 0 ? IrisStyle.danger : IrisStyle.muted
        font.pixelSize: IrisStyle.typeMeta
        text: NiriAnimationPresets.error.length > 0 ? Translation.tr("Niri turned that preset down and kept your animations.")
            : !NiriAnimationPresets.loaded ? Translation.tr("Reading Niri's animations…")
            : root.activeId.length === 0 ? Translation.tr("Your own timing. Pick one to replace it.")
            : Translation.tr("Hover a preset to watch it. The figure is how long a window takes to open.")
    }
}
