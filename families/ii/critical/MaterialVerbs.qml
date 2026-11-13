import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.ii.settings

// How Material answers the shell's shared verbs: with the pill bar's own launcher on Super+Space, the overview keys
// open that launcher instead of the overview. Any other verb falls through to the shared surfaces.
QtObject {
    id: root

    readonly property bool pillLauncher: (Config.options?.material?.bar?.appearanceStyle ?? "classic") === "pill"
        && (Config.options?.material?.bar?.pill?.superSpaceLauncher ?? "overview") === "pill"

    function _launcher(command: string): var {
        return root.pillLauncher ? () => GlobalStates.pillSurfaceCommand(command, "launcher") : undefined
    }

    // What Material's Settings can change, for the shell's settings door: the rows of its search index that carry a
    // key, read the first time they are asked for, kept to the pages its nav shows for Material on this compositor.
    readonly property FileView _index: FileView {
        path: Qt.resolvedUrl("../settings/settings-search-index.generated.json")
        preload: false
        blockAllReads: true
        printErrors: false
    }
    // Kept in a plain object: filling it while a binding reads it (Kira's chat buttons) must not notify that binding again.
    readonly property var _cache: ({ rows: null })
    function _settingsIndex(): var {
        if (root._cache.rows === null) {
            try {
                root._cache.rows = JSON.parse(root._index.text()).filter(row => row.key && ["", "ii"].includes(row.panelFamily ?? "")
                    && SettingsPageRegistry.searchable(row.pageIndex ?? -1, "ii") && SettingsPageRegistry.installed(row.pageIndex ?? -1))
            } catch (e) {
                root._cache.rows = []
            }
        }
        return root._cache.rows
    }

    readonly property var verbs: ({
        owner: "ii",
        settings: {
            index: () => root._settingsIndex()
        },
        overview: {
            get toggle() { return root._launcher("toggle") },
            get open() { return root._launcher("open") },
            get close() { return root._launcher("close") }
        }
    })

    Component.onCompleted: GlobalStates.familyVerbs = root.verbs
    Component.onDestruction: if (GlobalStates.familyVerbs === root.verbs) GlobalStates.familyVerbs = ({})
}
