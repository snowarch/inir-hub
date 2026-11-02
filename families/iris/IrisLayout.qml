import QtQuick
import qs
import qs.modules.common
import qs.services
import qs.modules.iris.style

// The room iRiS's chrome takes on the desktop, for ShellLayoutController: the Island owns one horizontal edge, the Dock
// the opposite one, the frame's band every edge. Mirrors bar/IrisBar.qml and dock/IrisDock.qml from config.
QtObject {
    id: root

    function density(): real {
        return Math.max(0.8, Math.min(1.35, Number(Config.options?.iris?.appearance?.density ?? 1)))
    }

    function bandWidth(): real {
        const iris = Config.options?.iris ?? {}
        if (!(iris.surround?.enable ?? false))
            return 0
        return Math.max(1, Math.round(Number(iris.surround?.thickness ?? 10) * density()))
    }

    // Where widgets rest: a breath inside the frame's band (inside the screen's edge with no frame), so one pushed into
    // a corner docks in it instead of running under the band.
    function breath(): real {
        return Math.round(12 * density())
    }
    function frameBand(): real {
        return bandWidth() + breath()
    }

    function desktopInsets(outputName: string, result: var): var {
        const iris = Config.options?.iris ?? {}
        const density = root.density()
        const barEdge = String(iris.bar?.position ?? "top") === "bottom" ? "bottom" : "top"
        result.barEdge = barEdge
        if (ShellLayoutController.panelEnabled("irisBar")
                && ShellLayoutController.outputEnabled(iris.bar?.screenList ?? [], outputName)
                && (GlobalStates.barOpen ?? true)) {
            const height = Math.max(32, Math.round(Number(iris.bar?.height ?? 42) * density))
            const margin = (iris.bar?.notch ?? false) ? 0 : Math.round(Number(iris.bar?.margin ?? 8) * density)
            result.barThickness = height + margin * 2
            ShellLayoutController.applyInset(result, barEdge, result.barThickness)
        }
        if (iris.dock?.enable ?? true) {
            result.dockEdge = barEdge === "bottom" ? "top" : "bottom"
            const icon = Math.max(28, Math.min(64, Number(iris.dock?.iconSize ?? 40))) * density
            const gap = (iris.dock?.notch ?? false) ? 0 : 10 * density
            result.dockThickness = Math.round(icon + 18 * density + gap * 2)
            ShellLayoutController.applyInset(result, result.dockEdge, result.dockThickness)
        }
        const band = bandWidth()
        for (const edge of ["left", "top", "right", "bottom"])
            result[edge] = Math.max(result[edge], band)
        return result
    }
}
