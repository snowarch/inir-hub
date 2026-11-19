import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.nihil.style

// What NiHiL hands the base as its part `style`: its tokens for shared surfaces, and the room its panel takes.
QtObject {
    readonly property QtObject style: NihilShared {}

    function insets(screen: var): var {
        const insets = ({ left: 0, top: 0, right: 0, bottom: 0 })
        const panel = Config.options?.nihil?.panel
        const outputs = Array.from(panel?.screenList ?? [])
        const listed = outputs.length === 0 || outputs.includes(screen?.name ?? "")
        if ((Config.options?.enabledPanels ?? []).includes("nBar") && (GlobalStates.barOpen ?? true) && listed
                && (panel?.visibility ?? "always") === "always")
            insets[(panel?.position ?? "top") === "bottom" ? "bottom" : "top"] = NihilStyle.barHeight
        return insets
    }
}
