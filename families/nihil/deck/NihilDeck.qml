pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The deck: one pane of glass beside the rail that holds every page of NiHiL, the way a visionOS window holds its tabs.
// The side lists the pages, the person and the ways out; the rest is the page, and the pane takes each page's size as
// it moves between them. Alt and a figure, or Ctrl and Tab, move between pages from the keyboard.
FocusScope {
    id: deck

    required property var screen
    // The page on show, and whether the deck is wanted at all.
    required property string page
    property bool open: false
    // Room the deck may take on its screen.
    property real roomWidth: 1600
    property real roomHeight: 900

    readonly property var modules: Config.options?.nihil?.modules
    readonly property bool compact: (Config.options?.nihil?.deck?.sidebar ?? "full") === "icons"
    readonly property real sideWidth: deck.compact ? NihilStyle.s(72) : NihilStyle.s(220)
    readonly property real pad: NihilStyle.s(10)

    function panelOn(id: string): bool { return (Config.options?.enabledPanels ?? []).includes(id) }
    // Every page the deck offers, in order; each one can be turned off.
    readonly property var entries: [
        { id: "apps", glyph: "apps", name: Translation.tr("Apps"), on: deck.panelOn("nOverview") },
        { id: "control", glyph: "tune", name: Translation.tr("Control"), on: deck.panelOn("nControl") },
        { id: "today", glyph: "calendar", name: Translation.tr("Today"), on: deck.panelOn("nToday") },
        { id: "media", glyph: "music", name: Translation.tr("Media"), on: deck.modules?.media ?? true },
        { id: "focus", glyph: "timer", name: Translation.tr("Focus"), on: deck.modules?.focus ?? true },
        { id: "clipboard", glyph: "clipboard", name: Translation.tr("Clipboard"), on: deck.panelOn("nClipboard") },
        { id: "wallpapers", glyph: "image", name: Translation.tr("Wallpapers"), on: deck.panelOn("nWallpapers") }
    ].filter(entry => entry.on)
    readonly property var sources: ({
        apps: "../apps/NihilLauncher.qml",
        control: "../control/NihilControl.qml",
        today: "../today/NihilToday.qml",
        media: "../media/NihilMedia.qml",
        focus: "../focus/NihilFocus.qml",
        clipboard: "../clipboard/NihilClipboard.qml",
        wallpapers: "../wallpapers/NihilWallpapers.qml"
    })

    // What the pane holds: it keeps the last page while it folds away.
    property string carried: ""
    onPageChanged: if (deck.page.length > 0) deck.carried = deck.page
    readonly property var pageItem: pageLoader.item
    readonly property real pageWidth: Math.min(Math.max(deck.pageItem?.implicitWidth ?? NihilStyle.s(640), NihilStyle.s(520)),
        deck.roomWidth - deck.sideWidth - deck.pad * 2)
    readonly property real pageHeight: Math.min(Math.max(deck.pageItem?.implicitHeight ?? NihilStyle.s(560), NihilStyle.s(520)),
        deck.roomHeight - deck.pad * 2)

    implicitWidth: deck.sideWidth + deck.pageWidth + deck.pad * 2
    implicitHeight: deck.pageHeight + deck.pad * 2

    readonly property alias glass: pane

    Keys.onEscapePressed: NihilState.dismiss()
    Keys.onPressed: event => {
        const ctrl = event.modifiers & Qt.ControlModifier
        if (ctrl && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            deck.step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
            event.accepted = true
        } else if (ctrl && (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)) {
            deck.step(event.key === Qt.Key_PageDown ? 1 : -1)
            event.accepted = true
        } else if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            const entry = deck.entries[event.key - Qt.Key_1]
            if (entry) NihilState.show(entry.id)
            event.accepted = true
        }
    }
    function step(by: int): void {
        const list = deck.entries
        if (list.length === 0) return
        const at = Math.max(0, list.findIndex(entry => entry.id === deck.page))
        NihilState.show(list[(at + by + list.length) % list.length].id)
    }

    NGlass {
        id: pane
        anchors.fill: parent
        radius: NihilStyle.rSheet
        tracks: true
    }
    // Takes the press, so a click on the pane's glass does not close it.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    // The side: the pages, then the person and the ways out.
    Item {
        id: side
        x: deck.pad
        y: deck.pad
        width: deck.sideWidth - deck.pad
        height: parent.height - deck.pad * 2

        Rectangle {
            anchors.fill: parent
            radius: NihilStyle.rSheet - deck.pad
            color: NihilStyle.piece
        }

        Column {
            id: nav
            x: NihilStyle.s(8)
            y: NihilStyle.s(12)
            width: parent.width - NihilStyle.s(16)
            spacing: NihilStyle.s(2)

            // NiHiL's name over its pages.
            Row {
                visible: !deck.compact
                height: NihilStyle.s(40)
                leftPadding: NihilStyle.s(8)
                spacing: NihilStyle.s(10)
                NMark { anchors.verticalCenter: parent.verticalCenter; size: NihilStyle.s(22) }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "NiHiL"
                    font.pixelSize: NihilStyle.textLarge
                    font.weight: Font.DemiBold
                }
            }
            Item { visible: !deck.compact; width: 1; height: NihilStyle.s(6) }

            Repeater {
                model: deck.entries
                MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool chosen: deck.page === row.modelData.id
                    readonly property color ink: row.chosen ? NihilStyle.accentInk : NihilStyle.ink
                    width: nav.width
                    height: NihilStyle.s(42)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.PageTab
                    Accessible.name: row.modelData.name
                    onClicked: NihilState.show(row.modelData.id)
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: row.chosen ? NihilStyle.accent : row.containsMouse ? NihilStyle.pieceRaised : "transparent"
                        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                    }
                    NIcon {
                        x: deck.compact ? (parent.width - width) / 2 : NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.glyph
                        size: NihilStyle.s(19)
                        color: row.ink
                    }
                    NText {
                        visible: !deck.compact
                        x: NihilStyle.s(46)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - NihilStyle.s(40)
                        text: row.modelData.name
                        font.weight: row.chosen ? Font.DemiBold : Font.Medium
                        color: row.ink
                    }
                    // Its key, once the pointer is on it.
                    NText {
                        visible: !deck.compact && row.index < 9 && (row.containsMouse || row.chosen)
                        anchors.right: parent.right
                        anchors.rightMargin: NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Alt " + (row.index + 1)
                        font.pixelSize: NihilStyle.textLabel
                        color: Qt.alpha(row.ink, 0.5)
                    }
                }
            }
        }

        Column {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: NihilStyle.s(10)
            x: NihilStyle.s(8)
            width: parent.width - NihilStyle.s(16)
            spacing: NihilStyle.s(8)

            // The person at this machine.
            Row {
                visible: !deck.compact
                width: parent.width
                leftPadding: NihilStyle.s(6)
                spacing: NihilStyle.s(10)
                Rectangle {
                    id: avatar
                    width: NihilStyle.s(34)
                    height: width
                    radius: width / 2
                    color: NihilStyle.pieceRaised
                    clip: true
                    NText {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: String(SystemInfo.displayName || SystemInfo.username).charAt(0).toUpperCase()
                        font.weight: Font.DemiBold
                    }
                    Image {
                        id: face
                        anchors.fill: parent
                        source: "file://" + Directories.userAvatarPathRicersAndWeirdSystems
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: face.status === Image.Ready
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - avatar.width - NihilStyle.s(20)
                    NText {
                        width: parent.width
                        text: SystemInfo.displayName || SystemInfo.username
                        font.weight: Font.Medium
                    }
                    NText {
                        width: parent.width
                        text: Translation.tr("Up %1").arg(DateTime.uptime)
                        font.pixelSize: NihilStyle.textLabel
                        color: NihilStyle.inkFaint
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: NihilStyle.s(6)
                NButton {
                    icon: "gear"
                    label: deck.compact ? "" : Translation.tr("Settings")
                    width: deck.compact ? parent.width : implicitWidth
                    onClicked: {
                        NihilState.dismiss()
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                    }
                }
                NButton {
                    icon: "lock"
                    width: deck.compact ? parent.width : implicitWidth
                    Accessible.name: Translation.tr("Lock")
                    onClicked: {
                        NihilState.dismiss()
                        Session.lock()
                    }
                }
                NButton {
                    icon: "power"
                    width: deck.compact ? parent.width : implicitWidth
                    Accessible.name: Translation.tr("Power")
                    onClicked: NihilState.toggle("power")
                }
            }
        }
    }

    // The page.
    Item {
        id: holder
        x: deck.sideWidth + deck.pad
        y: deck.pad
        width: parent.width - x - deck.pad
        height: parent.height - deck.pad * 2
        clip: true

        Loader {
            id: pageLoader
            width: deck.pageWidth
            height: deck.pageHeight
            active: deck.carried.length > 0
            source: deck.sources[deck.carried] ?? ""
            opacity: 0
            onLoaded: {
                pageLoader.item.screen = deck.screen
                pageLoader.item.flipped = false
                pageLoader.item.room = Qt.binding(() => deck.roomHeight - deck.pad * 2)
                pageLoader.item.open = Qt.binding(() => deck.open && deck.page === deck.carried)
                arrive.restart()
                deck.forceActiveFocus()
                pageLoader.item.forceActiveFocus()
            }
            ParallelAnimation {
                id: arrive
                NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: NihilStyle.calm; easing.type: Easing.OutCubic }
                NumberAnimation { target: pageLoader; property: "y"; from: NihilStyle.s(10); to: 0; duration: NihilStyle.calm; easing.type: Easing.OutCubic }
            }
        }
    }
}
