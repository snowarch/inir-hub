import QtQuick
import qs
import qs.modules.iris.prism.core

// What the shell asks Prism for, the same in both hosts (over the desktop or as a window): a page of Prism's own, or
// the classic Settings for one it has not. Lives inside the host while it is built.
QtObject {
    id: root
    signal opened()

    function take(): void {
        const key = String(GlobalStates.settingsOverlayRequestedKey ?? "")
        const section = String(GlobalStates.settingsOverlayRequestedSection ?? "")
        if (key.length === 0 && section.length === 0) return
        const alias = { home: "general", island: "bar" }
        const head = section.split("/")[0]
        const wanted = PrismModel.ids.includes(key) ? key : (alias[head] ?? head)
        if (section.length > 0 && !PrismModel.ids.includes(wanted)) {
            // The classic Settings reads the same request when it loads.
            PrismState.classicVisit = true
            return
        }
        if (wanted.length > 0) PrismState.go(wanted)
        GlobalStates.settingsOverlayRequestedSection = ""
        GlobalStates.settingsOverlayRequestedPage = -1
        GlobalStates.settingsOverlayRequestedKey = ""
        GlobalStates.settingsOverlayCurrentPage = GlobalStates.settingsPageKeys.indexOf("iris")
    }
    Component.onCompleted: root.take()
    readonly property Connections watch: Connections {
        target: GlobalStates
        function onSettingsOverlayRequestedKeyChanged() { root.take() }
        function onSettingsOverlayOpenChanged() {
            if (GlobalStates.settingsOverlayOpen) {
                GlobalStates.settingsOverlayCurrentPage = GlobalStates.settingsPageKeys.indexOf("iris")
                root.opened()
            } else {
                PrismState.reset()
                PrismModel.undo = null
            }
        }
    }
}
