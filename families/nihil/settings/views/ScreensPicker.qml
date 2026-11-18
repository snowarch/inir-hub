pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Which screens carry the bar: all of them, or the ones the person lights.
Flow {
    id: root

    readonly property var chosen: Array.from(Config.options?.nihil?.bar?.screenList ?? [])
    function flip(name: string): void {
        const next = root.chosen.includes(name) ? root.chosen.filter(entry => entry !== name) : root.chosen.concat([name])
        Config.setNestedValue("nihil.bar.screenList", next)
    }

    spacing: NihilStyle.s(6)

    NKey {
        width: NihilStyle.s(120)
        height: NihilStyle.s(36)
        lit: root.chosen.length === 0
        label: Translation.tr("All screens")
        onClicked: Config.setNestedValue("nihil.bar.screenList", [])
    }
    Repeater {
        model: Quickshell.screens
        NKey {
            required property var modelData
            width: NihilStyle.s(120)
            height: NihilStyle.s(36)
            lit: root.chosen.includes(modelData.name)
            label: modelData.name
            onClicked: root.flip(modelData.name)
        }
    }
}
