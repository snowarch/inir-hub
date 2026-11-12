import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import "docker.js" as Docker

// RAM and CPU limits for the selected running container. A slider applies after
// a short pause; preset keys apply at once. Docker updates are queued in the
// backend so two changes never race.

ColumnLayout {
    id: root

    property var backend
    property var container
    property real scaleFactor: 1
    property color ink: "white"
    property color accent: "white"
    property string numbersFamily: ""

    property int memValue: 0
    property real cpuValue: 0
    property int memPending: -1
    property real cpuPending: -1

    spacing: Math.round(3 * root.scaleFactor)

    function syncValues(): void {
        root.memValue = root.backend.memoryLimitMb(root.container)
        root.cpuValue = root.backend.cpuLimit(root.container)
    }

    onContainerChanged: {
        root.memPending = -1
        root.cpuPending = -1
        memDebounce.stop()
        cpuDebounce.stop()
        root.syncValues()
    }

    Component.onCompleted: root.syncValues()

    Connections {
        target: root.backend
        function onMemOverridesChanged() {
            if (!memSlider.pressed && root.memPending < 0) root.memValue = root.backend.memoryLimitMb(root.container)
        }
        function onCpuOverridesChanged() {
            if (!cpuSlider.pressed && root.cpuPending < 0) root.cpuValue = root.backend.cpuLimit(root.container)
        }
        function onSnapshotChanged() {
            if (!memSlider.pressed && root.memPending < 0) root.memValue = root.backend.memoryLimitMb(root.container)
            if (!cpuSlider.pressed && root.cpuPending < 0) root.cpuValue = root.backend.cpuLimit(root.container)
        }
    }

    Timer {
        id: memDebounce
        interval: 350
        onTriggered: {
            if (root.memPending < 0) return
            root.backend.setMemoryLimit(root.container, root.memPending)
            root.memPending = -1
        }
    }

    Timer {
        id: cpuDebounce
        interval: 350
        onTriggered: {
            if (root.cpuPending < 0) return
            root.backend.setCpuLimit(root.container, root.cpuPending)
            root.cpuPending = -1
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * root.scaleFactor)
        MaterialSymbol {
            text: "tune"
            fill: 1
            iconSize: Math.round(13 * root.scaleFactor)
            color: root.accent
        }
        StyledText {
            text: Translation.tr("LIMITS")
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            font.weight: Font.DemiBold
            color: ColorUtils.applyAlpha(root.ink, 0.5)
        }
        Item { Layout.fillWidth: true }
        StyledText {
            visible: root.backend.limitBusy
            text: Translation.tr("applying…")
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: root.accent
        }
    }

    // ── RAM ──────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        StyledText {
            text: Translation.tr("RAM")
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.ink, 0.65)
        }
        Item { Layout.fillWidth: true }
        StyledText {
            text: Docker.formatMb(root.memValue)
            font.family: root.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            font.weight: Font.DemiBold
            color: root.ink
        }
    }
    StyledSlider {
        id: memSlider
        Layout.fillWidth: true
        from: root.backend.memMin
        to: Math.max(root.backend.memMin, root.backend.hostMemMb)
        stepSize: root.backend.memStep
        value: root.memValue
        enabled: !root.backend.limitBusy
        onMoved: {
            root.memValue = value
            root.memPending = value
            memDebounce.restart()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * root.scaleFactor)
        Repeater {
            model: [
                { label: "256 MB", value: 256 },
                { label: "512 MB", value: 512 },
                { label: "1 GB", value: 1024 },
                { label: Translation.tr("Host"), value: root.backend.hostMemMb }
            ]
            delegate: RippleButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Math.round(22 * root.scaleFactor)
                buttonRadius: Math.round(6 * root.scaleFactor)
                buttonText: modelData.label
                enabled: !root.backend.limitBusy
                colBackground: ColorUtils.applyAlpha(root.ink, 0.06)
                colBackgroundHover: ColorUtils.applyAlpha(root.accent, 0.14)
                colRipple: ColorUtils.applyAlpha(root.accent, 0.22)
                onClicked: {
                    root.memValue = modelData.value
                    root.backend.setMemoryLimit(root.container, modelData.value)
                }
            }
        }
    }

    // ── CPU ──────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        StyledText {
            text: Translation.tr("CPU")
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.ink, 0.65)
        }
        Item { Layout.fillWidth: true }
        StyledText {
            text: root.cpuValue.toFixed(1) + " " + Translation.tr("cores")
            font.family: root.numbersFamily
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            font.weight: Font.DemiBold
            color: root.ink
        }
    }
    StyledSlider {
        id: cpuSlider
        Layout.fillWidth: true
        from: root.backend.cpuMin
        to: Math.max(root.backend.cpuMin, root.backend.cpuMax)
        stepSize: 0.1
        value: root.cpuValue
        enabled: !root.backend.limitBusy
        onMoved: {
            root.cpuValue = value
            root.cpuPending = value
            cpuDebounce.restart()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(4 * root.scaleFactor)
        Repeater {
            model: [
                { label: "0.5", value: 0.5 },
                { label: "1", value: 1 },
                { label: "2", value: 2 },
                { label: Translation.tr("Host"), value: root.backend.hostCpuCount }
            ]
            delegate: RippleButton {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Math.round(22 * root.scaleFactor)
                buttonRadius: Math.round(6 * root.scaleFactor)
                buttonText: modelData.label
                enabled: !root.backend.limitBusy
                colBackground: ColorUtils.applyAlpha(root.ink, 0.06)
                colBackgroundHover: ColorUtils.applyAlpha(root.accent, 0.14)
                colRipple: ColorUtils.applyAlpha(root.accent, 0.22)
                onClicked: {
                    root.cpuValue = modelData.value
                    root.backend.setCpuLimit(root.container, modelData.value)
                }
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.backend.limitNotice.length > 0
        text: root.backend.limitNotice
        elide: Text.ElideRight
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
        color: root.accent
    }
    StyledText {
        Layout.fillWidth: true
        visible: root.backend.limitError.length > 0
        text: root.backend.limitError
        wrapMode: Text.WordWrap
        font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
        color: Appearance.colors.colError
    }
}
