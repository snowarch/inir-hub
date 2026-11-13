import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.services
import qs.services.deferred
import qs.modules.waffle.state

// How Waffle answers the shell's shared verbs: Task View, its own clipboard and the Start search for the overview,
// its dev destinations; Orbit stays Material's. Cleared when Waffle goes.
QtObject {
    id: root

    function _search(prefix: string): void {
        LauncherSearch.ensurePrefix(prefix)
        GlobalStates.searchOpen = true
    }

    // What Waffle's Settings can change, for the shell's settings door: the rows of its search index that carry a
    // key, read the first time they are asked for.
    readonly property FileView _index: FileView {
        path: Qt.resolvedUrl("../settings/search-index.generated.json")
        preload: false
        blockAllReads: true
        printErrors: false
    }
    // Kept in a plain object: filling it while a binding reads it (Kira's chat buttons) must not notify that binding again.
    readonly property var _cache: ({ rows: null })
    function _settingsIndex(): var {
        if (root._cache.rows === null) {
            try {
                root._cache.rows = JSON.parse(root._index.text()).filter(row => row.key)
            } catch (e) {
                root._cache.rows = []
            }
        }
        return root._cache.rows
    }

    readonly property var verbs: ({
        owner: "waffle",
        settings: {
            index: () => root._settingsIndex()
        },
        // Leaving Waffle closes its panels, so they don't come back open with it.
        family: {
            leave: () => {
                WaffleState.actionCenterOpen = false
                WaffleState.notificationCenterOpen = false
                WaffleState.widgetsOpen = false
                WaffleState.altSwitcherOpen = false
                WaffleState.clipboardOpen = false
                WaffleState.taskViewOpen = false
            }
        },
        taskview: {
            toggle: () => { WaffleState.taskViewOpen = !WaffleState.taskViewOpen },
            open: () => { WaffleState.taskViewOpen = true },
            close: () => { WaffleState.taskViewOpen = false }
        },
        overview: {
            toggle: () => { GlobalStates.searchOpen = !GlobalStates.searchOpen },
            open: () => { GlobalStates.searchOpen = true },
            close: () => { GlobalStates.searchOpen = false },
            clipboardToggle: () => root._search(Config.options?.search?.prefix?.clipboard ?? ";"),
            actionOpen: () => root._search(Config.options?.search?.prefix?.action ?? "/")
        },
        dev: {
            open: surface => {
                switch (surface) {
                case "waffle-search":
                    LauncherSearch.query = DevNavigation.requestedView === "search" ? "a" : ""
                    GlobalStates.searchOpen = true
                    return true
                case "waffle-action-center": WaffleState.actionCenterOpen = true; return true
                case "waffle-notification-center": WaffleState.notificationCenterOpen = true; return true
                case "waffle-widgets": WaffleState.widgetsOpen = true; return true
                case "waffle-taskview": WaffleState.taskViewOpen = true; return true
                }
                return false
            },
            close: () => {
                WaffleState.actionCenterOpen = false
                WaffleState.notificationCenterOpen = false
                WaffleState.widgetsOpen = false
                WaffleState.taskViewOpen = false
            }
        },
        clipboard: {
            open: () => { WaffleState.clipboardOpen = true },
            close: () => { WaffleState.clipboardOpen = false },
            toggle: () => { WaffleState.clipboardOpen = !WaffleState.clipboardOpen }
        }
    })

    Component.onCompleted: GlobalStates.familyVerbs = root.verbs
    Component.onDestruction: if (GlobalStates.familyVerbs === root.verbs) GlobalStates.familyVerbs = ({})
}
