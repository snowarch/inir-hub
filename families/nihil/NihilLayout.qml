import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.nihil.style
import qs.services

// NiHiL's persistent surfaces for ShellLayoutController: the floating bar, top or bottom.
QtObject {
    readonly property var surfaces: [
        {
            id: "nihilBar",
            families: ["nihil"],
            kind: "edge",
            labelKey: "Taskbar",
            icon: "toolbar",
            layoutScope: "enabledOutputs",
            slots: ["top", "bottom"],
            editableProperties: [],
            collisionPolicy: "validated",
            resetScopes: ["surface", "family"]
        }
    ]
    readonly property var rebuilds: ["nihilBar"]

    function surfaceState(surfaceId: string, desc: var, outputName: string): var {
        if (surfaceId !== "nihilBar")
            return null
        return {
            ok: true,
            id: surfaceId,
            slot: (Config.options?.nihil?.bar?.bottom ?? true) ? "bottom" : "top",
            scope: desc.layoutScope,
            outputName: outputName,
            enabledOutputs: Config.options?.nihil?.bar?.screenList ?? [],
            source: "nihil.bar.bottom"
        }
    }
    function moveSurface(surfaceId: string, slot: string): bool {
        if (surfaceId !== "nihilBar")
            return false
        Config.setNestedValue("nihil.bar.bottom", slot === "bottom")
        return true
    }
    function resetSlot(surfaceId: string): string { return surfaceId === "nihilBar" ? "bottom" : "" }
    function desktopInsets(outputName: string, result: var): var {
        if (!ShellLayoutController.panelEnabled("nBar") || (Config.options?.nihil?.bar?.autoHide ?? false)
                || !ShellLayoutController.outputEnabled(Config.options?.nihil?.bar?.screenList ?? [], outputName))
            return result
        result.barEdge = (Config.options?.nihil?.bar?.bottom ?? true) ? "bottom" : "top"
        result.barThickness = NihilStyle.barZone
        ShellLayoutController.applyInset(result, result.barEdge, result.barThickness)
        return result
    }
}
