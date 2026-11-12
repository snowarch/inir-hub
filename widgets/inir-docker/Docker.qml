pragma ComponentBehavior: Bound

// The desktop shell for iNiR Docker. The shared backend polls Docker; the
// shared view draws it. The view is intentionally separate so a future family
// sidebar host can load the same content without a second implementation.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.shared.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.inir-docker"
    defaultConfig: ({
        placementStrategy: "free",
        widgetScale: 100,
        widgetOpacity: 100,
        colorMode: "auto",
        dim: 0,
        showBackground: true,
        backgroundOpacity: 0.16,
        borderWidth: 1,
        borderOpacity: 0.2,
        cornerRadius: -1,
        useBlur: false,
        x: 320,
        y: 200,
        refreshSeconds: 3,
        maxContainers: 6,
        showStopped: true,
        showSummary: true,
        showSparkline: true,
        filter: ""
    })
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 360
    resizeMinHeight: 190
    widgetSurfaceEnabled: true

    readonly property int pad: Math.round(14 * root.scaleFactor)

    implicitWidth: Math.round(420 * root.scaleFactor)
    implicitHeight: Math.max(Math.round(190 * root.scaleFactor),
        desktopView.implicitHeight + root.pad * 2)

    DockerBackend {
        id: backend
        active: root.visible && (root.motionActive || root.snapshot === null)
    }

    function _findContainer(id): var {
        return backend.containers.find(container => container.fullId === id || container.name === id) ?? null
    }

    /// Select and control Docker containers from scripts and keybinds.
    ///
    /// ```kdl
    /// Super+D { spawn "inir" "ipc" "inir-docker" "select" "web"; }
    /// ```
    IpcHandler {
        target: "inir-docker"
        // One desktop widget exists per screen; only the focused screen answers
        // IPC so the target is never registered twice.
        enabled: root.outputName === (GlobalStates.focusedScreen?.name ?? root.outputName)

        /// Choose a container by name or full ID.
        function select(id: string): string {
            const container = root._findContainer(id)
            if (!container) return "no container " + id
            backend.selectContainer(container)
            return container.name
        }

        /// Set a running container's RAM limit in MiB.
        function memory(id: string, mb: int): string {
            const container = root._findContainer(id)
            if (!container) return "no container " + id
            if (!backend.canAdjustLimits(container)) return "start " + container.name + " first"
            backend.setMemoryLimit(container, mb)
            return container.name + " memory " + mb + " MiB"
        }

        /// Set a running container's CPU limit in cores.
        function cpu(id: string, cores: string): string {
            const container = root._findContainer(id)
            if (!container) return "no container " + id
            if (!backend.canAdjustLimits(container)) return "start " + container.name + " first"
            backend.setCpuLimit(container, Number(cores))
            return container.name + " cpu " + cores
        }

        /// Print the selected or named container's limits and daemon capacity as JSON.
        function limits(id: string): string {
            const container = root._findContainer(id) ?? backend.selected
            if (!container) return "no container"
            return JSON.stringify({
                name: container.name,
                memoryMb: backend.memoryLimitMb(container),
                cpuCores: backend.cpuLimit(container),
                hostMemoryMb: backend.hostMemMb,
                hostCpuCount: backend.hostCpuCount
            })
        }
    }

    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    DockerView {
        id: desktopView
        anchors.fill: parent
        anchors.margins: root.pad
        backend: backend
        scaleFactor: root.scaleFactor
        ink: root.widgetInk
        accent: root.widgetAccentVisible
        numbersFamily: root.widgetNumbersFamily
    }
}
