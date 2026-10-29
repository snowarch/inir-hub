import qs
import QtQuick
import Quickshell
import qs.services
import qs.modules.ii.settings
import qs.modules.common

// Material's Settings while it is the one in use: its page names for everyone who opens a page by name, and the
// overlay when Settings opens inside the shell.
Scope {
    id: root

    readonly property bool overlay: Config.options?.settingsUi?.overlayMode ?? false

    Binding {
        target: GlobalStates
        property: "settingsPageKeys"
        value: SettingsPageRegistry.pages.map(page => page.key)
    }

    Component.onCompleted: DevNavigation.registerSettingsPages(SettingsPageRegistry.pages)
    // Another family's Settings has its own names, or none.
    Component.onDestruction: {
        GlobalStates.settingsPageKeys = []
        DevNavigation.registerSettingsPages([])
    }

    LazyLoader {
        active: root.overlay
        component: SettingsOverlay {}
    }
}
