import QtQuick
import qs
import qs.services
import qs.modules.nihil.state

// How NiHiL answers the shell's shared verbs: everything leads to its overview.
QtObject {
    id: root

    readonly property var verbs: ({
        owner: "nihil",
        overview: {
            toggle: () => NihilState.toggleOverview("windows"),
            open: () => NihilState.openOverview("windows"),
            close: () => NihilState.closeOverview(),
            clipboardToggle: () => { GlobalStates.clipboardOpen = !GlobalStates.clipboardOpen },
            actionOpen: () => NihilState.openOverview("search")
        },
        taskview: {
            toggle: () => NihilState.toggleOverview("windows"),
            open: () => NihilState.openOverview("windows"),
            close: () => NihilState.closeOverview()
        }
    })

    Component.onCompleted: GlobalStates.familyVerbs = root.verbs
    Component.onDestruction: if (GlobalStates.familyVerbs === root.verbs) GlobalStates.familyVerbs = ({})
}
