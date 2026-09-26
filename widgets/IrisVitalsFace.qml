pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.style
import qs.modules.iris.bar.island

IrisWidgetFace {
    id: root

    readonly property var resources: Array.from(root.widget._resourceModel ?? [])
    readonly property var loads: root.resources.filter(entry => ["cpu", "mem", "gpu"].includes(entry.key))
    readonly property var heats: root.resources.filter(entry => ["temp", "gpuTemp"].includes(entry.key))
    readonly property bool hasDisk: root.resources.some(entry => entry.key === "disk")
    readonly property bool diskAlone: root.hasDisk && root.resources.length === 1
    readonly property real contentHeight: Math.floor(Math.max(0, root.height - root.padding * 2))
    readonly property real sectionGap: root.dp(root.small ? 8 : 14)
    readonly property real heatHeight: root.dp(root.small ? 24 : root.medium ? 28 : 66)
    readonly property real diskHeight: root.dp(root.small ? 23 : root.medium ? 25 : 36)
    readonly property real loadHeight: root.contentHeight
        - (root.heats.length ? root.heatHeight + root.sectionGap : 0)
        - (root.hasDisk ? root.diskHeight + root.sectionGap : 0)
    readonly property real orbitSize: root.medium ? Math.min(root.contentHeight, root.dp(126))
        : Math.round(Math.min(root.loadHeight, root.contentWidth * (root.small ? 0.54 : 0.61)))

    function level(key: string): real {
        return Math.max(0, Math.min(1, Number(root.widget._getValue(key)) || 0))
    }
    function tint(key: string): color {
        if (root.level(key) >= 0.85)
            return root.danger
        return key === "cpu" ? root.accent
            : key === "mem" || key === "temp" || key === "gpuTemp" ? root.warm
            : key === "gpu" ? root.ink : root.inkSecondary
    }
    function name(entry: var): string {
        return entry.key === "temp" ? Translation.tr("CPU heat")
            : entry.key === "gpuTemp" ? Translation.tr("GPU heat") : entry.label
    }
    function figure(key: string): string {
        return String(root.widget._getDisplayText(key)).replace(/[%°C]/g, "")
    }
    function unit(key: string): string {
        return key === "temp" || key === "gpuTemp" ? "°C" : "%"
    }
    function history(key: string): var {
        const values = key === "cpu" ? ResourceUsage.cpuUsageHistory
            : key === "mem" ? ResourceUsage.memoryUsageHistory
            : key === "gpu" ? ResourceUsage.gpuUsageHistory
            : key === "temp" ? ResourceUsage.cpuTempHistory
            : key === "gpuTemp" ? ResourceUsage.gpuTempHistory : []
        return Array.from(values ?? []).slice(-40)
    }

    component Reading: Row {
        id: reading
        required property string key
        property real figureSize: 24
        property color ink: root.tint(reading.key)
        spacing: root.dp(1)

        FaceFigure {
            id: number
            face: root
            text: root.figure(reading.key)
            size: reading.figureSize
            color: reading.ink
        }
        FaceText {
            face: root
            text: root.unit(reading.key)
            size: Math.max(8, reading.figureSize * 0.45)
            color: reading.ink
            y: Math.round(number.baselineOffset - baselineOffset)
        }
    }

    component Trace: Shape {
        id: trace
        required property string key
        readonly property var samples: root.history(trace.key)
        readonly property var line: trace.samples.map((value, i) => Qt.point(
            trace.width * i / Math.max(1, trace.samples.length - 1),
            trace.height - 1 - Math.max(0, Math.min(1, Number(value) || 0)) * (trace.height - 2)))
        visible: trace.samples.length >= 2
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: IrisStyle.tintFill(root.tint(trace.key))
            PathPolyline { path: [Qt.point(0, trace.height)].concat(trace.line, [Qt.point(trace.width, trace.height)]) }
        }
        ShapePath {
            strokeColor: root.tint(trace.key)
            strokeWidth: root.dp(1.5)
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathPolyline { path: trace.line }
        }
    }

    component Orbits: Item {
        id: orbits
        readonly property real stroke: width * (root.loads.length === 1 ? 0.105 : 0.085)
        readonly property real step: orbits.stroke * 1.4

        Repeater {
            model: root.loads
            ProgressRing {
                required property var modelData
                required property int index
                anchors.centerIn: parent
                width: orbits.width - index * orbits.step * 2
                height: width
                stroke: orbits.stroke
                progress: root.level(modelData.key)
                tint: root.tint(modelData.key)
                Behavior on progress {
                    NumberAnimation {
                        duration: IrisStyle.moveDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: IrisStyle.moveCurve
                    }
                }
            }
        }
    }

    component LoadReading: Item {
        id: load
        required property var entry
        property real figureSize: root.small ? 16 : root.medium ? 25 : 30
        implicitHeight: root.small ? Math.max(value.height, label.height)
            : value.height + (label.visible ? label.height : 0) + (root.large ? root.dp(13) : 0)

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: load.implicitHeight
            Reading {
                id: value
                key: load.entry.key
                figureSize: load.figureSize
                x: root.small ? parent.width - width : 0
            }
            FaceText {
                id: label
                face: root
                visible: root.widget.showLabels
                width: root.small ? Math.max(0, value.x - root.dp(2)) : parent.width
                text: load.entry.label
                size: root.small ? 8 : 11
                color: root.inkSecondary
                y: root.small ? Math.round((value.height - height) / 2) : value.height
            }
            Trace {
                visible: root.large && samples.length >= 2
                key: load.entry.key
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: root.dp(10)
            }
        }
    }

    component HeatReadings: Row {
        id: temperatures
        spacing: root.dp(root.small ? 8 : 18)

        Repeater {
            model: root.heats
            Item {
                id: heat
                required property var modelData
                width: Math.floor((temperatures.width - temperatures.spacing * (root.heats.length - 1)) / Math.max(1, root.heats.length))
                height: temperatures.height
                readonly property bool expanded: root.large || root.loads.length === 0

                FaceText {
                    id: label
                    face: root
                    visible: root.widget.showLabels
                    width: parent.width
                    text: heat.expanded ? root.name(heat.modelData) : heat.modelData.label
                    size: root.small ? 9 : 11
                    color: root.inkSecondary
                }
                Reading {
                    key: heat.modelData.key
                    x: heat.expanded ? 0 : heat.width - width
                    y: heat.expanded ? (label.visible ? label.height + root.dp(3) : 0) : label.height - height
                    figureSize: heat.expanded ? (root.small ? 24 : 32) : root.small ? 14 : 18
                    ink: root.level(key) >= 0.85 ? root.danger : root.ink
                }
                Trace {
                    visible: root.large && samples.length >= 2
                    key: heat.modelData.key
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: root.dp(16)
                }
            }
        }
    }

    component Capacity: Item {
        id: capacity
        readonly property real trackHeight: root.dp(root.diskAlone ? 12 : root.small ? 5 : 7)

        FaceText {
            face: root
            visible: root.widget.showLabels
            text: Translation.tr("Disk")
            size: root.small ? 9 : 11
            color: root.inkSecondary
        }
        Reading {
            key: "disk"
            anchors.right: parent.right
            figureSize: root.diskAlone ? 42 : root.small ? 13 : root.medium ? 15 : 21
            ink: root.level(key) >= 0.85 ? root.danger : root.ink
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: capacity.trackHeight
            radius: height / 2
            color: root.fill
            Rectangle {
                width: parent.width * root.level("disk")
                height: parent.height
                radius: height / 2
                color: root.tint("disk")
            }
        }
    }

    FaceText {
        face: root
        visible: root.resources.length === 0
        anchors.centerIn: parent
        text: Translation.tr("Choose what to watch")
        color: root.inkTertiary
        size: 12.5
    }

    Item {
        id: composition
        anchors.fill: parent
        visible: root.resources.length > 0
        readonly property real detailsX: root.medium && root.loads.length ? root.orbitSize + root.dp(20) : 0
        readonly property real detailsWidth: width - detailsX

        Orbits {
            visible: root.loads.length > 0
            width: root.orbitSize
            height: width
            y: Math.round(root.medium ? (composition.height - height) / 2 : (root.loadHeight - height) / 2)
        }

        Grid {
            id: loadValues
            visible: root.loads.length > 0
            x: root.medium ? composition.detailsX : root.orbitSize + root.dp(root.small ? 8 : 22)
            y: root.medium ? 0 : Math.round((root.loadHeight - height) / 2)
            width: composition.width - x
            columns: root.medium ? Math.max(1, root.loads.length) : 1
            spacing: root.dp(root.small ? 2 : 5)

            Repeater {
                model: root.loads
                LoadReading {
                    required property var modelData
                    entry: modelData
                    width: Math.floor((loadValues.width - (loadValues.columns - 1) * loadValues.spacing) / loadValues.columns)
                    height: root.small && root.loads.length > 1
                        ? Math.floor(root.loadHeight / root.loads.length - loadValues.spacing)
                        : implicitHeight
                    figureSize: root.small ? 16 : root.medium ? 25 : 30
                }
            }
        }

        HeatReadings {
            visible: root.heats.length > 0
            x: composition.detailsX
            width: composition.detailsWidth
            height: root.loads.length ? root.heatHeight : Math.max(root.heatHeight, root.contentHeight * 0.45)
            y: root.loads.length ? root.loadHeight + root.sectionGap
                : Math.round((root.contentHeight - height - (root.hasDisk ? root.diskHeight + root.sectionGap : 0)) / 2)
        }

        Capacity {
            visible: root.hasDisk
            x: composition.detailsX
            width: composition.detailsWidth
            height: root.diskAlone ? root.dp(80) : root.diskHeight
            y: root.diskAlone ? Math.round((composition.height - height) / 2) : composition.height - height
        }
    }
}
