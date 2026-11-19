pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import "NihilOptions.js" as Options

// NiHiL's Settings while it is the one in use: its page names for everyone who opens a page by name, and the overlay
// when Settings opens over the desktop (`nihil.settings.overlay`).
Scope {
    id: root

    readonly property bool overlay: Config.options?.nihil?.settings?.overlay ?? false

    Binding {
        target: GlobalStates
        property: "settingsPageKeys"
        value: Options.pages.map(page => page.id)
    }
    Component.onDestruction: GlobalStates.settingsPageKeys = []

    LazyLoader {
        active: root.overlay && GlobalStates.settingsOverlayOpen

        component: NPopup {
            id: popup

            open: GlobalStates.settingsOverlayOpen
            namespace: "nihilSettings"
            blurPieces: [card.region]
            onDismissed: GlobalStates.settingsOverlayOpen = false

            function follow(): void {
                const key = GlobalStates.settingsOverlayRequestedKey
                view.goTo(key.length > 0 ? key : GlobalStates.settingsOverlayRequestedPage)
            }
            Component.onCompleted: popup.follow()

            Connections {
                target: GlobalStates
                function onSettingsOverlayRequestedKeyChanged() { popup.follow() }
                function onSettingsOverlayRequestedPageChanged() { popup.follow() }
            }
            Binding {
                target: GlobalStates
                property: "settingsOverlayCurrentPage"
                value: view.pageIndex
            }

            // The desktop stays in sight behind a light veil, so a change shows on it as it is made.
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(NihilStyle.void_, 0.38)
            }

            NGlass {
                id: card
                anchors.centerIn: parent
                width: Math.min(NihilStyle.s(1260), parent.width - NihilStyle.s(96))
                height: Math.min(NihilStyle.s(830), parent.height - NihilStyle.s(96))
                radius: NihilStyle.rSheet
                tint: Qt.alpha(NihilStyle.void_, Math.max(0.86, NihilStyle.glassOpacity))

                // A click on the card's own glass stays in it.
                MouseArea { anchors.fill: parent }

                NihilSettingsView {
                    id: view
                    anchors.fill: parent
                    windowed: false
                    focus: true
                    onCloseRequested: GlobalStates.settingsOverlayOpen = false
                    onWindowRequested: key => {
                        Quickshell.execDetached(["env", "QS_SETTINGS_PAGE=" + key, Quickshell.shellPath("scripts/inir"), "settings-window"])
                        GlobalStates.setSettingsOverlay(false)
                        GlobalStates.settingsOverlayOpen = false
                    }
                }
            }
        }
    }
}
