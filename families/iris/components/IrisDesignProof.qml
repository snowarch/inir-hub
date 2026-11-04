pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.iris.style
import qs.modules.iris.polkit
import qs.modules.iris.lock
import qs.modules.iris.regionSelector

// A proof of the active Design (校正刷り): iRiS's own controls as it wears them, the whole lock and the engine's
// authentication and snip, drawn on stand-ins and saved as one image; `inir iris proof <file.png>`. The window sits
// under everything and takes no input.
PanelWindow {
    id: root
    property string target: ""
    signal done(string result)

    readonly property real d: IrisStyle.density
    readonly property int labelWidth: Math.round(120 * root.d)

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:irisProof"
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    anchors.top: true
    implicitWidth: sheet.width
    implicitHeight: sheet.height
    color: "transparent"
    mask: Region {}

    Rectangle {
        id: sheet
        readonly property int pad: Math.round(32 * root.d)
        width: grid.implicitWidth + 2 * sheet.pad
        height: grid.implicitHeight + 2 * sheet.pad
        color: IrisStyle.bodySurface

        Column {
            id: grid
            x: sheet.pad
            y: sheet.pad
            spacing: Math.round(18 * root.d)
            IrisControlSpecimen {}
            // The whole lock as the real surface draws it, on a context that never asks PAM and with no keys: the
            // proof's window takes no input, so nothing here can lock or hold the session.
            Row {
                spacing: Math.round(32 * root.d)
                Text {
                    width: root.labelWidth
                    text: "lock · whole"
                    color: IrisStyle.textSecondary
                    font.family: IrisStyle.fontMono
                    font.pixelSize: IrisStyle.typeMeta
                }
                Item {
                    width: 960
                    height: 540
                    clip: true
                    IrisLockSurface {
                        width: 1920
                        height: 1080
                        scale: 0.5
                        transformOrigin: Item.TopLeft
                        context: lockStandIn
                        editing: false
                    }
                }
            }
            Row {
                spacing: Math.round(32 * root.d)
                Text {
                    width: root.labelWidth
                    text: "engine · auth, snip"
                    color: IrisStyle.textSecondary
                    font.family: IrisStyle.fontMono
                    font.pixelSize: IrisStyle.typeMeta
                }
                Item {
                    width: Math.round(380 * root.d)
                    height: Math.round(380 * root.d)
                    IrisPolkitContent {
                        anchors.fill: parent
                        service: root.polkitStandIn
                    }
                }
                IrisOptionsToolbar {
                    action: 0
                    selectionMode: 0
                }
            }
        }
    }

    // The lock's stand-in context: nothing typed, nothing checked, nothing unlocked.
    QtObject {
        id: lockStandIn
        signal shouldReFocus()
        signal unlocked(targetAction: var)
        signal failed()
        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false
        property bool fingerprintsConfigured: false
        function clearText(): void { lockStandIn.currentText = "" }
        function resetClearTimer(): void {}
        function tryUnlock(): void {}
    }
    // Engine surfaces a Design dresses from the inside, drawn on stand-ins: the authentication dialog and the snip
    // toolbar. Nothing here reaches polkit or the region selector.
    readonly property var polkitStandIn: ({ flow: null, interactionAvailable: true, batteryChargeLimitRequest: false,
        actionLabel: "Install software", cleanMessage: "Authentication is required to install a package on this system.",
        cleanPrompt: "Password", submit: () => {}, cancel: () => {} })

    Timer {
        interval: 900
        running: root.target.length > 0
        onTriggered: {
            const target = root.target
            const ok = sheet.grabToImage(result => root.done(result.saveToFile(target) ? target : "could not save " + target))
            if (!ok) root.done("could not grab")
        }
    }
}
