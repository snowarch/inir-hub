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

    // Kiri cuts the frame's top-right and bottom-left: a widget docked there steps out along the diagonal until its own
    // cut runs parallel to the frame's, a breath away. Each corner is the least sum of its two gaps in the room.
    function frameCorners(): var {
        if (!IrisStyle.fieldChamfer || bandWidth() <= 0)
            return null
        const radius = Math.round(Number(Config.options?.iris?.surround?.radius ?? 22) * density())
        const keep = Math.round(IrisStyle.kiriCut * radius - IrisStyle.chamferCut - (2 - Math.SQRT2) * breath())
        return keep > 0 ? [0, keep, 0, keep] : null
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
            ShellLayoutController.applyInset(result, barEdge, height + margin * 2)
        }
        if (iris.dock?.enable ?? true) {
            result.dockEdge = barEdge === "bottom" ? "top" : "bottom"
            const icon = Math.max(28, Math.min(64, Number(iris.dock?.iconSize ?? 40))) * density
            const gap = (iris.dock?.notch ?? false) ? 0 : 10 * density
            ShellLayoutController.applyInset(result, result.dockEdge, icon + 18 * density + gap * 2)
        }
        const band = bandWidth()
        for (const edge of ["left", "top", "right", "bottom"])
            result[edge] = Math.max(result[edge], band)
        return result
    }
}
