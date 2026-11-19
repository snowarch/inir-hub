pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state
import qs.modules.nihil.bar
import qs.modules.nihil.osd
import qs.modules.nihil.notifications

// The sheet of one screen: the band along its edge, one slab pulled out of it for the page that is open, two tags for what
// comes and goes, and one light that travels to whatever is active. A single surface; the room the bar takes is held by
// a surface of its own, so the sheet can grow over the desktop without moving a window.
Scope {
    id: stage

    required property var modelData
    readonly property string output: stage.modelData.name
    readonly property var nihil: Config.options?.nihil
    readonly property var panel: stage.nihil?.panel
    readonly property bool flipped: (stage.panel?.position ?? "top") === "bottom"
    readonly property string visibility: stage.panel?.visibility ?? "always"
    readonly property var outputs: Array.from(stage.panel?.screenList ?? [])
    readonly property bool here: (GlobalStates.focusedScreen?.name ?? Quickshell.screens[0]?.name) === stage.output
    // A page opens where it was asked for: on the bar that was clicked, otherwise on the screen with the keys.
    readonly property bool asksHere: NihilState.askedOn.length > 0 ? NihilState.askedOn === stage.output : stage.here
    function panelOn(id: string): bool { return (Config.options?.enabledPanels ?? []).includes(id) }

    readonly property var workspace: NihilState.workspacesOn(stage.output).find(ws => ws.is_active)
    readonly property bool bare: NihilState.windowsOn(stage.workspace?.id).length === 0
    readonly property bool fullscreen: GameMode.hasFullscreenOnOutput(stage.output)
    readonly property bool barOn: stage.panelOn("nBar") && (stage.nihil?.modules?.panel ?? true) && (GlobalStates.barOpen ?? true)
        && (stage.outputs.length === 0 || stage.outputs.includes(stage.output))
    readonly property bool bandWanted: stage.barOn && !stage.fullscreen && stage.visibility !== "hidden"
        && (stage.visibility === "always" || NihilState.overviewOpen || (stage.visibility === "desktop" && stage.bare))
    readonly property bool clear: NihilState.overviewOpen && (stage.panel?.overviewStyle ?? "same") === "transparent"

    // The page stays on the screen it opened on.
    readonly property var pagePanels: ({ apps: "nOverview", control: "nControl", today: "nToday", clipboard: "nClipboard", wallpapers: "nWallpapers" })
    readonly property string asked: stage.panelOn(stage.pagePanels[NihilState.page] ?? "") ? NihilState.page : ""
    property string page: ""
    onAskedChanged: stage.page = stage.asked.length > 0 && (stage.page.length > 0 || stage.asksHere) ? stage.asked : ""
    // What the slab carries; it outlives the page while the slab folds away.
    property string carried: ""
    onPageChanged: if (stage.page.length > 0) stage.carried = stage.page

    property bool powerHere: false
    readonly property bool powerAsked: NihilState.powerOpen && stage.panelOn("nPower")
    onPowerAskedChanged: stage.powerHere = stage.powerAsked && stage.asksHere

    readonly property bool interactive: stage.page.length > 0 || stage.powerHere
    readonly property bool ownOverview: NihilState.overviewOpen && (!NihilState.nativeStage || NihilState.view !== "windows")
    readonly property bool tagged: osd.wanted || banners.wanted
    readonly property bool overlaid: stage.powerHere || ((stage.interactive || stage.tagged) && (stage.fullscreen || stage.ownOverview))

    // Holds the bar's room while the sheet itself stays clear of the desktop's layout.
    PanelWindow {
        screen: stage.modelData
        visible: stage.barOn && stage.visibility === "always"
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: NihilStyle.barHeight
        implicitWidth: 1
        implicitHeight: 1
        anchors { top: !stage.flipped; bottom: stage.flipped }
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:nihil-reserve"
        mask: Region {}
    }

    PanelWindow {
        id: chassis

        screen: stage.modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "quickshell:nihil-sheet"
        WlrLayershell.layer: stage.overlaid ? WlrLayer.Overlay : WlrLayer.Top
        WlrLayershell.keyboardFocus: stage.interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: stage.interactive ? null : rest

        // Everything below is measured from the edge the sheet hangs from; `onScreen` turns it into the window's y.
        function onScreen(y: real, height: real): real { return stage.flipped ? chassis.height - y - height : y }

        readonly property real bandTo: stage.bandWanted ? NihilStyle.barHeight : 0
        readonly property real band: bandSpring.value
        // Bodies start inside the band, so a body never shows its upper corners.
        readonly property real tuck: NihilStyle.s(24)
        readonly property real room: chassis.height - chassis.bandTo - NihilStyle.edge

        NSpring { id: bandSpring; to: chassis.bandTo; pace: 18 }

        // The slab.
        readonly property var pageItem: pageLoader.item
        readonly property real pageHeight: Math.min(chassis.pageItem?.implicitHeight ?? 0, chassis.room)
        readonly property real pageWidth: Math.min(chassis.pageItem?.implicitWidth ?? 0, chassis.width - NihilStyle.edge * 2)
        readonly property bool pageAtEnd: stage.carried === "control"
        readonly property bool folded: slabEnd.value - chassis.band < 1
        NSpring {
            id: slabX
            to: chassis.pageAtEnd ? chassis.width - chassis.pageWidth - NihilStyle.edge : (chassis.width - chassis.pageWidth) / 2
            snap: chassis.folded
            pace: 15
        }
        NSpring { id: slabWidth; to: chassis.pageWidth; snap: chassis.folded; pace: 15 }
        NSpring {
            id: slabEnd
            to: chassis.bandTo + (stage.page.length > 0 ? chassis.pageHeight : 0)
            pace: 15
        }
        // The page leaves once the slab has folded back into the band.
        readonly property bool slabGone: stage.page.length === 0 && slabEnd.value - chassis.band < 1
        onSlabGoneChanged: if (chassis.slabGone) stage.carried = ""
        readonly property real slabDrop: Math.max(0, slabEnd.value - chassis.band)
        readonly property real slabShare: NihilStyle.clamp(chassis.slabDrop / Math.max(1, chassis.pageHeight), 0, 1)

        // The tags.
        readonly property real tagAWidth: osd.implicitWidth
        readonly property real tagBWidth: banners.implicitWidth
        readonly property real tagAX: osd.atStart ? NihilStyle.edge : osd.atEnd ? chassis.width - chassis.tagAWidth - NihilStyle.edge
            : (chassis.width - chassis.tagAWidth) / 2
        readonly property real tagBX: banners.atStart ? NihilStyle.edge
            : stage.page.length > 0 && chassis.pageAtEnd ? slabX.to - chassis.tagBWidth - NihilStyle.edge
            : chassis.width - chassis.tagBWidth - NihilStyle.edge
        NSpring { id: tagAEnd; to: chassis.bandTo + (osd.wanted ? osd.implicitHeight : 0); pace: 20 }
        NSpring { id: tagBEnd; to: chassis.bandTo + (banners.wanted ? banners.implicitHeight : 0); pace: 18 }
        NSpring { id: tagBSlide; to: chassis.tagBX; snap: tagBEnd.value - chassis.band < 1; pace: 15 }

        // The way out: the band falls past the far edge and the whole screen is glass.
        NSpring { id: limbSpring; to: stage.powerHere ? 1 : 0; pace: 11 }
        readonly property real limbAt: chassis.height + NihilStyle.s(90)
        readonly property real limbRadius: chassis.width * 5

        // The light: where it is going, how far it reaches and how strong it is.
        readonly property var aim: {
            if (stage.powerHere)
                return { x: chassis.width / 2, y: chassis.limbAt, reach: NihilStyle.s(330), power: 0 }
            if (stage.page.length > 0)
                return { x: slabX.to + slabWidth.to / 2, y: slabEnd.to, reach: NihilStyle.clamp(slabWidth.to * 0.56, NihilStyle.s(220), NihilStyle.s(340)), power: 1 }
            if (osd.wanted)
                return { x: chassis.tagAX + osd.needle, y: tagAEnd.to, reach: NihilStyle.s(150), power: 1 }
            if (banners.wanted)
                return { x: chassis.tagBX + chassis.tagBWidth / 2, y: tagBEnd.to, reach: NihilStyle.s(180), power: 1 }
            return { x: bar.lightX, y: chassis.bandTo, reach: NihilStyle.s(170), power: stage.bandWanted ? 0.9 : 0 }
        }
        NSpring { id: lightXSpring; to: chassis.aim.x; pace: 12 }
        NSpring { id: lightYSpring; to: chassis.aim.y; pace: 12 }
        NSpring { id: reachSpring; to: chassis.aim.reach; pace: 10 }
        NSpring { id: veilSpring; to: stage.clear ? 0 : 1; pace: 12 }
        NSpring { id: powerSpring; to: chassis.aim.power; pace: 10 }

        readonly property real reachEnd: Math.max(slabEnd.value, tagAEnd.value, tagBEnd.value, chassis.band)

        readonly property Region rest: Region {
            Region { item: bandBox }
            Region { item: tagAFace }
            Region { item: tagBFace }
        }

        SheetBlur {
            window: chassis
            shape: ({
                width: chassis.width,
                height: chassis.height,
                flipped: stage.flipped,
                band: stage.clear ? 0 : chassis.band,
                full: limbSpring.value > 0.5,
                bodies: [
                    { x: slabX.value, width: slabWidth.value, reach: slabEnd.value, radius: NihilStyle.rSheet },
                    { x: chassis.tagAX, width: chassis.tagAWidth, reach: tagAEnd.value, radius: NihilStyle.r(24) },
                    { x: tagBSlide.value, width: chassis.tagBWidth, reach: tagBEnd.value, radius: NihilStyle.r(24) }
                ]
            })
        }

        NSheet {
            id: sheet
            width: parent.width
            height: limbSpring.value > 0.001 ? chassis.height : Math.min(chassis.height, chassis.reachEnd + NihilStyle.s(120))
            y: stage.flipped ? chassis.height - height : 0
            flipped: stage.flipped
            band: chassis.band
            slabRect: Qt.rect(slabX.value, chassis.band - chassis.tuck, slabWidth.value, slabEnd.value - chassis.band + chassis.tuck)
            tagARect: Qt.rect(chassis.tagAX, chassis.band - chassis.tuck, chassis.tagAWidth, tagAEnd.value - chassis.band + chassis.tuck)
            tagBRect: Qt.rect(tagBSlide.value, chassis.band - chassis.tuck, chassis.tagBWidth, tagBEnd.value - chassis.band + chassis.tuck)
            light: Qt.point(lightXSpring.value, lightYSpring.value)
            lightReach: reachSpring.value
            lightPower: powerSpring.value
            auroraRect: Qt.rect(slabX.value + slabWidth.value / 2, slabEnd.value,
                Math.max(slabWidth.value * 0.5, NihilStyle.s(300)), Math.min(NihilStyle.s(160), chassis.slabDrop * 0.42))
            auroraPower: chassis.slabShare
            limb: limbSpring.value
            limbAt: chassis.limbAt
            limbRadius: chassis.limbRadius
            veiled: veilSpring.value
        }

        // A click beside the slab closes it.
        MouseArea {
            anchors.fill: parent
            enabled: stage.interactive
            acceptedButtons: Qt.AllButtons
            onPressed: NihilState.dismiss()
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: NihilState.dismiss()

            // The slab's page.
            Item {
                id: slabFace
                x: slabX.value
                y: chassis.onScreen(chassis.band, height)
                width: slabWidth.value
                height: chassis.slabDrop
                clip: true
                visible: stage.carried.length > 0
                opacity: NihilStyle.clamp((chassis.slabShare - 0.35) / 0.55, 0, 1)

                // Takes the press, so a click on the page's glass does not close it.
                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                Loader {
                    id: pageLoader
                    y: stage.flipped ? slabFace.height - height : 0
                    width: chassis.pageWidth
                    height: chassis.pageHeight
                    active: stage.carried.length > 0
                    source: stage.carried === "apps" ? "../apps/NihilLauncher.qml"
                        : stage.carried === "control" ? "../control/NihilControl.qml"
                        : stage.carried === "today" ? "../today/NihilToday.qml"
                        : stage.carried === "clipboard" ? "../clipboard/NihilClipboard.qml"
                        : stage.carried === "wallpapers" ? "../wallpapers/NihilWallpapers.qml" : ""
                    onLoaded: {
                        keys.forceActiveFocus()
                        pageLoader.item.screen = stage.modelData
                        pageLoader.item.flipped = Qt.binding(() => stage.flipped)
                        pageLoader.item.room = Qt.binding(() => chassis.room)
                        pageLoader.item.open = Qt.binding(() => stage.page === stage.carried)
                    }
                }
            }

            Item {
                id: tagAFace
                x: chassis.tagAX
                y: chassis.onScreen(chassis.band, height)
                width: chassis.tagAWidth
                height: Math.max(0, tagAEnd.value - chassis.band)
                clip: true
                visible: height > 0.5
                NihilOsd {
                    id: osd
                    screen: stage.modelData
                    here: stage.here && stage.panelOn("nOsd") && (stage.nihil?.modules?.osd ?? true)
                    y: stage.flipped ? tagAFace.height - height : 0
                    opacity: NihilStyle.clamp(tagAFace.height / Math.max(1, osd.implicitHeight) * 1.6 - 0.5, 0, 1)
                }
            }

            Item {
                id: tagBFace
                x: tagBSlide.value
                y: chassis.onScreen(chassis.band, height)
                width: chassis.tagBWidth
                height: Math.max(0, tagBEnd.value - chassis.band)
                clip: true
                visible: height > 0.5
                NihilNotificationPopup {
                    id: banners
                    here: stage.here && stage.panelOn("nNotificationPopup") && (stage.nihil?.modules?.notifications ?? true)
                    y: stage.flipped ? tagBFace.height - height : 0
                    opacity: NihilStyle.clamp(tagBFace.height / Math.max(1, banners.implicitHeight) * 1.6 - 0.5, 0, 1)
                }
            }

            Item {
                id: bandBox
                y: chassis.onScreen(0, height)
                width: parent.width
                height: chassis.band
                clip: true
                opacity: (1 - limbSpring.value) * NihilStyle.clamp(chassis.band / NihilStyle.barHeight * 2 - 1, 0, 1)
                visible: opacity > 0.01
                NihilBar {
                    id: bar
                    width: parent.width
                    height: NihilStyle.barHeight
                    y: stage.flipped ? parent.height - height : 0
                    output: stage.output
                    screen: stage.modelData
                    flipped: stage.flipped
                }
            }

            Loader {
                id: powerLoader
                anchors.fill: parent
                active: stage.powerHere || limbSpring.value > 0.01
                source: "../power/NihilPower.qml"
                opacity: NihilStyle.clamp((limbSpring.value - 0.5) * 2, 0, 1)
                onLoaded: {
                    powerLoader.item.flipped = Qt.binding(() => stage.flipped)
                    powerLoader.item.open = Qt.binding(() => stage.powerHere)
                }
            }
        }
    }
}
