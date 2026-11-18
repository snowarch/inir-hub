import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.nihil.style
import qs.services

// NiHiL's persistent surface for ShellLayoutController: the panel, top or bottom.
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
        if (surfaceId !== "nihilBar") return null
        return {
            ok: true,
            id: surfaceId,
            slot: Config.options?.nihil?.panel?.position ?? "top",
            scope: desc.layoutScope,
            outputName: outputName,
            enabledOutputs: Config.options?.nihil?.panel?.screenList ?? [],
            source: "nihil.panel.position"
        }
    }
    function moveSurface(surfaceId: string, slot: string): bool {
        if (surfaceId !== "nihilBar") return false
        Config.setNestedValue("nihil.panel.position", slot)
        return true
    }
    function resetSlot(surfaceId: string): string { return surfaceId === "nihilBar" ? "top" : "" }
    function desktopInsets(outputName: string, result: var): var {
        if (!ShellLayoutController.panelEnabled("nBar") || (Config.options?.nihil?.panel?.visibility ?? "always") !== "always"
                || !ShellLayoutController.outputEnabled(Config.options?.nihil?.panel?.screenList ?? [], outputName))
            return result
        result.barEdge = Config.options?.nihil?.panel?.position ?? "top"
        result.barThickness = NihilStyle.barHeight
        ShellLayoutController.applyInset(result, result.barEdge, result.barThickness)
        return result
    }
}
