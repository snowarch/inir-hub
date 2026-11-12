pragma ComponentBehavior: Bound

// The desktop shell for iNiR Docker. The shared backend polls Docker; the
// shared view draws it. The view is intentionally separate so a future family
// sidebar host can load the same content without a second implementation.

import QtQuick
import Quickshell
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
