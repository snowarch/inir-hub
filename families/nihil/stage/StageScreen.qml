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
import qs.modules.nihil.deck
import qs.modules.nihil.osd
import qs.modules.nihil.notifications

// What NiHiL stands on one screen: the rail along its edge, the deck beside it while a page is open, the level and
// what just arrived as tags of glass, and the hint that names the key under the pointer. One layer surface; the room
// the rail takes is held by a surface of its own, so the deck can stand over the desktop without moving a window.
// The compositor blurs exactly the pieces of glass on show.
Scope {
    id: stage

    required property var modelData
    readonly property string output: stage.modelData.name
    readonly property var nihil: Config.options?.nihil
    readonly property var panel: stage.nihil?.panel
    readonly property string edge: NihilStyle.railEdge
    readonly property bool vertical: NihilStyle.railVertical
    readonly property string visibility: stage.panel?.visibility ?? "always"
    readonly property var outputs: Array.from(stage.panel?.screenList ?? [])
    readonly property bool here: (GlobalStates.focusedScreen?.name ?? Quickshell.screens[0]?.name) === stage.output
    // A page opens where it was asked for: on the rail that was clicked, otherwise on the screen with the keys.
    readonly property bool asksHere: NihilState.askedOn.length > 0 ? NihilState.askedOn === stage.output : stage.here
    function panelOn(id: string): bool { return (Config.options?.enabledPanels ?? []).includes(id) }

    readonly property var workspace: NihilState.workspacesOn(stage.output).find(ws => ws.is_active)
    readonly property bool bare: NihilState.windowsOn(stage.workspace?.id).length === 0
    readonly property bool fullscreen: GameMode.hasFullscreenOnOutput(stage.output)
    readonly property bool railOn: stage.panelOn("nBar") && (stage.nihil?.modules?.panel ?? true) && (GlobalStates.barOpen ?? true)
        && (stage.outputs.length === 0 || stage.outputs.includes(stage.output))
    readonly property bool railWanted: stage.railOn && !stage.fullscreen && stage.visibility !== "hidden"
        && (stage.visibility === "always" || NihilState.overviewOpen || NihilState.deckOpen
            || (stage.visibility === "desktop" && stage.bare))
    readonly property bool clear: NihilState.overviewOpen && (stage.panel?.overviewStyle ?? "same") === "transparent"

    // The page stays on the screen it opened on.
    readonly property string asked: NihilState.page
    property string page: ""
    onAskedChanged: stage.page = stage.asked.length > 0 && (stage.page.length > 0 || stage.asksHere) ? stage.asked : ""

    property bool powerHere: false
    readonly property bool powerAsked: NihilState.powerOpen && stage.panelOn("nPower")
    onPowerAskedChanged: stage.powerHere = stage.powerAsked && stage.asksHere

    readonly property bool interactive: stage.page.length > 0 || stage.powerHere
    readonly property bool ownOverview: NihilState.overviewOpen && (!NihilState.nativeStage || NihilState.view !== "windows")
    readonly property bool overlaid: stage.powerHere || ((stage.interactive || osd.wanted || banners.wanted) && (stage.fullscreen || stage.ownOverview))

    // Holds the rail's room while the surface itself stays clear of the desktop's layout.
    PanelWindow {
        screen: stage.modelData
        visible: stage.railOn && stage.visibility === "always" && !stage.fullscreen
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: NihilStyle.railRoom
        implicitWidth: 1
        implicitHeight: 1
        anchors {
            top: stage.edge === "top"
            bottom: stage.edge === "bottom"
            left: stage.edge === "left"
            right: stage.edge === "right"
        }
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

        readonly property real gap: NihilStyle.s(10)
        readonly property real margin: NihilStyle.railFloats ? NihilStyle.railMargin : 0

        readonly property Region rest: Region {
            Region { item: railBox }
            Region { item: osdTag }
            Region { item: bannerTag }
        }

        // Only the glass on show is blurred.
        BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur ? glassZone : null
        Region {
            id: glassZone
            Region {
                x: railBox.x
                y: railBox.y
                width: railShown.value > 0.5 && !stage.clear ? railBox.width : 0
                height: railShown.value > 0.5 && !stage.clear ? railBox.height : 0
                radius: rail.glass.radius
            }
            Region {
                x: deckBox.x
                y: deckBox.y
                width: deckShown.value > 0.6 ? deckBox.width : 0
                height: deckShown.value > 0.6 ? deckBox.height : 0
                radius: NihilStyle.rSheet
            }
            Region {
                x: osdTag.x
                y: osdTag.y
                width: osdTag.opacity > 0.6 ? osdTag.width : 0
                height: osdTag.opacity > 0.6 ? osdTag.height : 0
                radius: osdGlass.radius
            }
            Region {
                x: bannerTag.x
                y: bannerTag.y
                width: bannerTag.opacity > 0.6 ? bannerTag.width : 0
                height: bannerTag.opacity > 0.6 ? bannerTag.height : 0
                radius: bannerGlass.radius
            }
        }

        // The rail slides out of its edge and back.
        NSpring { id: railShown; to: stage.railWanted ? 1 : 0; pace: 16 }
        readonly property real railRoom: NihilStyle.railRoom * railShown.value

        // A quiet dim behind the deck, so the page reads over anything.
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: deckShown.value * (stage.nihil?.deck?.dim ?? 0.22)
            visible: opacity > 0.002
        }

        // A click beside the deck or the ring closes it.
        MouseArea {
            anchors.fill: parent
            enabled: stage.interactive
            acceptedButtons: Qt.AllButtons
            onPressed: NihilState.dismiss()
        }

        Item {
            id: railBox
            readonly property real thick: NihilStyle.railThickness
            readonly property real away: (1 - railShown.value) * (thick + chassis.margin + NihilStyle.s(12))
            width: stage.vertical ? thick : chassis.width - chassis.margin * 2
            height: stage.vertical ? chassis.height - chassis.margin * 2 : thick
            x: stage.edge === "left" ? chassis.margin - railBox.away
                : stage.edge === "right" ? chassis.width - chassis.margin - width + railBox.away : chassis.margin
            y: stage.edge === "top" ? chassis.margin - railBox.away
                : stage.edge === "bottom" ? chassis.height - chassis.margin - height + railBox.away : chassis.margin
            visible: railShown.value > 0.01
            opacity: Math.min(1, railShown.value * 1.4)

            NihilRail {
                id: rail
                anchors.fill: parent
                output: stage.output
                screen: stage.modelData
                clear: stage.clear
            }
        }

        // The deck.
        NSpring { id: deckShown; to: stage.page.length > 0 ? 1 : 0; pace: 17 }
        Item {
            id: deckBox
            readonly property real lead: chassis.railRoom + chassis.gap
            readonly property real roomWidth: chassis.width - (stage.vertical ? deckBox.lead + chassis.gap : chassis.gap * 2)
            readonly property real roomHeight: chassis.height - (stage.vertical ? chassis.gap * 2 : deckBox.lead + chassis.gap)
            width: Math.min(deckLoader.item?.implicitWidth ?? 0, deckBox.roomWidth)
            height: Math.min(deckLoader.item?.implicitHeight ?? 0, deckBox.roomHeight)
            x: stage.edge === "left" ? deckBox.lead : stage.edge === "right" ? chassis.width - deckBox.lead - width : (chassis.width - width) / 2
            y: stage.edge === "top" ? deckBox.lead : stage.edge === "bottom" ? chassis.height - deckBox.lead - height : (chassis.height - height) / 2
            visible: deckShown.value > 0.01
            opacity: deckShown.value
            Behavior on width { enabled: deckShown.value > 0.98; NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: deckShown.value > 0.98; NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
            // It comes out of the rail.
            transform: [
                Scale {
                    origin.x: stage.edge === "right" ? deckBox.width : stage.edge === "left" ? 0 : deckBox.width / 2
                    origin.y: stage.edge === "bottom" ? deckBox.height : stage.edge === "top" ? 0 : deckBox.height / 2
                    xScale: 0.96 + 0.04 * deckShown.value
                    yScale: 0.96 + 0.04 * deckShown.value
                },
                Translate {
                    readonly property real slide: (1 - deckShown.value) * NihilStyle.s(-18)
                    x: stage.edge === "left" ? slide : stage.edge === "right" ? -slide : 0
                    y: stage.edge === "top" ? slide : stage.edge === "bottom" ? -slide : 0
                }
            ]

            Loader {
                id: deckLoader
                anchors.fill: parent
                active: stage.page.length > 0 || deckShown.value > 0.01
                sourceComponent: NihilDeck {
                    screen: stage.modelData
                    page: stage.page
                    open: stage.page.length > 0
                    roomWidth: deckBox.roomWidth
                    roomHeight: deckBox.roomHeight
                    focus: true
                }
                onLoaded: deckLoader.item.forceActiveFocus()
            }
        }

        // A tag stands in its corner of the screen, clear of the rail.
        function tagX(position: string, width: real): real {
            const left = chassis.gap + (stage.edge === "left" ? chassis.railRoom : 0)
            const right = chassis.width - chassis.gap - width - (stage.edge === "right" ? chassis.railRoom : 0)
            return position.endsWith("Left") ? left : position.endsWith("Right") ? right : (left + right) / 2
        }
        function tagY(position: string, height: real): real {
            const top = chassis.gap + (stage.edge === "top" ? chassis.railRoom : 0)
            const bottom = chassis.height - chassis.gap - height - (stage.edge === "bottom" ? chassis.railRoom : 0)
            return position.startsWith("top") ? top : position.startsWith("bottom") ? bottom : (top + bottom) / 2
        }
        // Which way a tag arrives from: the edge it stands nearest.
        function tagFrom(position: string): real { return position.startsWith("bottom") ? 1 : position === "center" ? 0 : -1 }

        Item {
            id: osdTag
            readonly property string position: osd.position === "off" ? "bottom" : osd.position
            width: osd.implicitWidth
            height: osd.implicitHeight
            x: chassis.tagX(osdTag.position, width)
            y: chassis.tagY(osdTag.position, height) + (1 - osdTag.opacity) * NihilStyle.s(14) * chassis.tagFrom(osdTag.position)
            opacity: osd.wanted ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: osd.wanted ? NihilStyle.calm : NihilStyle.slow; easing.type: Easing.OutCubic } }
            NGlass {
                id: osdGlass
                anchors.fill: parent
                radius: Math.min(NihilStyle.r(26), height / 2)
                ignite: 0.35
            }
            NihilOsd {
                id: osd
                screen: stage.modelData
                here: stage.here && stage.panelOn("nOsd") && (stage.nihil?.modules?.osd ?? true)
            }
        }

        Item {
            id: bannerTag
            readonly property string position: banners.position
            width: banners.implicitWidth
            height: banners.implicitHeight
            x: chassis.tagX(bannerTag.position, width)
            y: chassis.tagY(bannerTag.position, height) + (1 - bannerTag.opacity) * NihilStyle.s(18) * chassis.tagFrom(bannerTag.position)
            opacity: banners.wanted ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }
            NGlass {
                id: bannerGlass
                anchors.fill: parent
                radius: NihilStyle.r(26)
                tracks: true
            }
            NihilNotificationPopup {
                id: banners
                here: stage.here && stage.panelOn("nNotificationPopup") && (stage.nihil?.modules?.notifications ?? true)
            }
        }

        // The hint: the name of the key the pointer rests on, beside the rail, after a moment's warm-up. Once warm, the
        // next key names itself at once.
        property bool hintWarm: false
        Timer { id: warmUp; interval: 420; onTriggered: chassis.hintWarm = true }
        Timer { id: coolDown; interval: 520; onTriggered: chassis.hintWarm = false }
        Connections {
            target: rail
            function onHintChanged(): void {
                if (rail.hint) { coolDown.stop(); if (!chassis.hintWarm) warmUp.restart() }
                else { warmUp.stop(); coolDown.restart() }
            }
        }
        Item {
            id: hintTag
            readonly property var shown: rail.hint
            property string text: ""
            property point at: Qt.point(0, 0)
            onShownChanged: {
                if (!hintTag.shown?.item) return
                hintTag.text = hintTag.shown.text
                hintTag.at = hintTag.shown.item.mapToItem(chassis.contentItem, hintTag.shown.item.width / 2, hintTag.shown.item.height / 2)
            }
            readonly property real away: NihilStyle.railRoom + NihilStyle.s(10)
            width: hintText.implicitWidth + NihilStyle.s(24)
            height: NihilStyle.s(32)
            x: stage.edge === "left" ? hintTag.away : stage.edge === "right" ? chassis.width - hintTag.away - width
                : NihilStyle.clamp(hintTag.at.x - width / 2, chassis.gap, chassis.width - width - chassis.gap)
            y: stage.edge === "top" ? hintTag.away : stage.edge === "bottom" ? chassis.height - hintTag.away - height
                : NihilStyle.clamp(hintTag.at.y - height / 2, chassis.gap, chassis.height - height - chassis.gap)
            opacity: chassis.hintWarm && !!rail.hint && !stage.interactive ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
            Behavior on y { enabled: hintTag.visible && stage.vertical; NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
            Behavior on x { enabled: hintTag.visible && !stage.vertical; NumberAnimation { duration: NihilStyle.quick; easing.type: Easing.OutCubic } }
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: NihilStyle.menuTint
                border.width: 1
                border.color: NihilStyle.rimInk
            }
            NText {
                id: hintText
                anchors.centerIn: parent
                text: hintTag.text
                font.pixelSize: NihilStyle.textSmall
                font.weight: Font.Medium
            }
        }

        // The way out: the ring over the whole screen.
        NSpring { id: ringShown; to: stage.powerHere ? 1 : 0; pace: 12 }
        Loader {
            id: powerLoader
            anchors.fill: parent
            active: stage.powerHere || ringShown.value > 0.01
            source: "../power/NihilPower.qml"
            opacity: ringShown.value
            onLoaded: {
                powerLoader.item.flipped = Qt.binding(() => stage.edge === "bottom")
                powerLoader.item.open = Qt.binding(() => stage.powerHere)
                powerLoader.item.forceActiveFocus()
            }
        }
    }
}
