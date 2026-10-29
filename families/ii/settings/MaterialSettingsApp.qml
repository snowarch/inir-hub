pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.ii.settings
import qs.modules.common
import qs.modules.common.widgets

// Material Settings in its own window (`inir settings-window`, settingsUi.overlayMode off). Same body as the overlay.
ApplicationWindow {
    id: root

    visible: true
    onClosing: Qt.quit()
    title: "Settings — iNiR"
    minimumWidth: 760
    minimumHeight: 520
    width: 1240
    height: 820
    color: Config.ready ? SettingsMaterialPreset.windowColor : "transparent"

    Component.onCompleted: {
        Quickshell.watchFiles = false
        Config.readWriteDelay = 0 // Settings sets one value at a time: no delay needed
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                ThemeService.applyCurrentTheme()
        }
    }

    SettingsChrome {
        id: chrome
        anchors.fill: parent
        visible: Config.ready
        focus: true
        windowed: true
        onCloseRequested: root.close()

        // A number or a page's key (`inir settingsNav open hub`), and a part of it.
        function applyStart(): void {
            if (!Persistent.ready)
                return
            const env = Quickshell.env("QS_SETTINGS_PAGE") ?? ""
            const number = parseInt(env)
            const index = !isNaN(number) ? number : env.length > 0 ? chrome.pages.findIndex(page => page.key === env) : -1
            const section = Quickshell.env("QS_SETTINGS_SECTION") || ""
            if (index >= 0 || section.length > 0)
                chrome.openPage(index, section)
        }
        Component.onCompleted: Qt.callLater(applyStart)
        Connections {
            target: Persistent
            function onReadyChanged() { Qt.callLater(chrome.applyStart) }
        }
    }
}
