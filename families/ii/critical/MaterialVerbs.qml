import QtQuick
import qs
import qs.modules.common

// How Material answers the shell's shared verbs: with the pill bar's own launcher on Super+Space, the overview keys
// open that launcher instead of the overview. Any other verb falls through to the shared surfaces.
QtObject {
    id: root

    readonly property bool pillLauncher: (Config.options?.material?.bar?.appearanceStyle ?? "classic") === "pill"
        && (Config.options?.material?.bar?.pill?.superSpaceLauncher ?? "overview") === "pill"

    function _launcher(command: string): var {
        return root.pillLauncher ? () => GlobalStates.pillSurfaceCommand(command, "launcher") : undefined
    }

    readonly property var verbs: ({
        owner: "ii",
        overview: {
            get toggle() { return root._launcher("toggle") },
            get open() { return root._launcher("open") },
            get close() { return root._launcher("close") }
        }
    })

    Component.onCompleted: GlobalStates.familyVerbs = root.verbs
    Component.onDestruction: if (GlobalStates.familyVerbs === root.verbs) GlobalStates.familyVerbs = ({})
}
