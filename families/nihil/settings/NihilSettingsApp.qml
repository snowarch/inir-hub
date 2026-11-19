import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// NiHiL's Settings as its own window. It draws no frame of its own besides the view's head (move, fill the screen,
// close), so it looks the same under Niri and Umbriel, which leave decorations to the app.
Window {
    id: root

    visible: true
    title: Translation.tr("NiHiL Settings")
    width: 1260
    height: 830
    minimumWidth: 860
    minimumHeight: 520
    color: NihilStyle.void_
    onClosing: Qt.quit()

    NihilSettingsView {
        id: view
        anchors.fill: parent
        windowed: true
        onCloseRequested: root.close()
        // The shell opens the overlay on this page; this window has nothing left to show.
        onOverlayRequested: index => {
            Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "ipc", "settings", "openOverlayAt", String(index)])
            Qt.quit()
        }
        // `inir settingsNav open <page>` and the shell's own links name the page to start on.
        Component.onCompleted: {
            const start = Quickshell.env("QS_SETTINGS_PAGE") ?? ""
            if (start.length > 0)
                view.goTo(start)
        }
    }
}
