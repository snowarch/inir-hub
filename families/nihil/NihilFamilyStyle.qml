import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.nihil.style

// What NiHiL hands the base as its part `style` (modules/common/FamilyStyle.qml): the room its floating bar takes.
// Shared surfaces keep Material's tokens.
QtObject {
    function insets(screen: var): var {
        const insets = ({ left: 0, top: 0, right: 0, bottom: 0 })
        const bar = Config.options?.nihil?.bar
        const outputs = Array.from(bar?.screenList ?? [])
        const name = screen?.name ?? ""
        const listed = outputs.length === 0 || outputs.includes(name)
            || !outputs.some(output => Quickshell.screens.some(s => s?.name === output))
        if ((Config.options?.enabledPanels ?? []).includes("nBar") && (GlobalStates.barOpen ?? true) && listed
                && !(bar?.autoHide ?? false))
            insets[(bar?.bottom ?? true) ? "bottom" : "top"] = NihilStyle.barZone
        return insets
    }
}
