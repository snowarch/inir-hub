import QtQuick
import qs
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model

// What the shell asks Prism for, the same in both hosts (over the desktop or as a window): an area of iRiS Settings by
// its key or "section/group", which is a page of Prism (and a group of it). Lives inside the host while it is built.
QtObject {
    id: root
    signal opened()

    function take(): void {
        const key = String(GlobalStates.settingsOverlayRequestedKey ?? "")
        const section = String(GlobalStates.settingsOverlayRequestedSection ?? "")
        if (key.length === 0 && section.length === 0) return
        const alias = { home: "general", island: "bar", hub: "system" }
        const parts = section.split("/")
        const head = parts[0].split("|")[0]
        const group = String(parts[1] ?? "").split("|")[0]
        // An area read as chapters opens on the chapter holding the group asked for.
        const area = PrismModel.ids.includes(key) ? key : (alias[key] ?? alias[head] ?? head)
        const wanted = group.length > 0 ? PrismModel.pageOf(area, group) : area
        if (PrismModel.ids.includes(wanted)) {
            PrismState.go(wanted)
            if (group.length > 0) PrismState.pickGroup(wanted, group)
        }
        GlobalStates.settingsOverlayRequestedSection = ""
        GlobalStates.settingsOverlayRequestedPage = -1
        GlobalStates.settingsOverlayRequestedKey = ""
        GlobalStates.settingsOverlayCurrentPage = GlobalStates.settingsPageKeys.indexOf("iris")
    }
    Component.onCompleted: root.take()
    readonly property Connections watch: Connections {
        target: GlobalStates
        function onSettingsOverlayRequestedKeyChanged() { root.take() }
        function onSettingsOverlayRequestedSectionChanged() { root.take() }
        function onSettingsOverlayOpenChanged() {
            if (GlobalStates.settingsOverlayOpen) {
                GlobalStates.settingsOverlayCurrentPage = GlobalStates.settingsPageKeys.indexOf("iris")
                root.opened()
            } else {
                PrismState.reset()
                IrisOptions.forget()
            }
        }
    }
}
