pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The dashboard: one pane of glass beside the bar that holds every page of NiHiL. The sidebar lists the pages, the
// person and the ways out; the rest is the page. The pane keeps one size for every page (`nihil.dashboard.width` and
// `height`, within the screen), so moving between pages never moves the frame. Alt and a number, or Ctrl and Tab, move
// between pages from the keyboard.
FocusScope {
    id: dashboard

    required property var screen
    // The page on show, and whether the dashboard is wanted at all.
    required property string page
    property bool open: false
    // Room the dashboard may take on its screen.
    property real roomWidth: 1600
    property real roomHeight: 900

    readonly property var modules: Config.options?.nihil?.modules
    readonly property bool compact: (Config.options?.nihil?.dashboard?.sidebar ?? "full") === "icons"
    readonly property real sideWidth: dashboard.compact ? NihilStyle.s(72) : NihilStyle.s(220)
    readonly property real pad: NihilStyle.s(10)

    function panelOn(id: string): bool { return (Config.options?.enabledPanels ?? []).includes(id) }
    // Every page the dashboard offers, in order; each one can be turned off.
    readonly property var entries: [
        { id: "apps", glyph: "apps", name: Translation.tr("Apps"), on: dashboard.panelOn("nOverview") },
        { id: "control", glyph: "tune", name: Translation.tr("Control"), on: dashboard.panelOn("nControl") },
        { id: "today", glyph: "calendar", name: Translation.tr("Today"), on: dashboard.panelOn("nToday") },
        { id: "media", glyph: "music", name: Translation.tr("Media"), on: dashboard.modules?.media ?? true },
        { id: "focus", glyph: "timer", name: Translation.tr("Focus"), on: dashboard.modules?.focus ?? true },
        { id: "clipboard", glyph: "clipboard", name: Translation.tr("Clipboard"), on: dashboard.panelOn("nClipboard") },
        { id: "wallpapers", glyph: "image", name: Translation.tr("Wallpapers"), on: dashboard.panelOn("nWallpapers") }
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
    onPageChanged: if (dashboard.page.length > 0) dashboard.carried = dashboard.page

    implicitWidth: Math.min(NihilStyle.s(Number(Config.options?.nihil?.dashboard?.width ?? 1180)), dashboard.roomWidth)
    implicitHeight: Math.min(NihilStyle.s(Number(Config.options?.nihil?.dashboard?.height ?? 680)), dashboard.roomHeight)

    readonly property alias glass: pane

    Keys.onEscapePressed: NihilState.dismiss()
    Keys.onPressed: event => {
        const ctrl = event.modifiers & Qt.ControlModifier
        if (ctrl && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            dashboard.step(event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1)
            event.accepted = true
        } else if (ctrl && (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)) {
            dashboard.step(event.key === Qt.Key_PageDown ? 1 : -1)
            event.accepted = true
        } else if ((event.modifiers & Qt.AltModifier) && event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            const entry = dashboard.entries[event.key - Qt.Key_1]
            if (entry) NihilState.show(entry.id)
            event.accepted = true
        }
    }
    function step(by: int): void {
        const list = dashboard.entries
        if (list.length === 0) return
        const at = Math.max(0, list.findIndex(entry => entry.id === dashboard.page))
        NihilState.show(list[(at + by + list.length) % list.length].id)
    }

    NGlass {
        id: pane
        anchors.fill: parent
        radius: NihilStyle.radiusWindow
        followPointer: true
    }
    // Takes the press, so a click on the pane's glass does not close it.
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

    // The side: the pages, then the person and the ways out.
    Item {
        id: side
        x: dashboard.pad
        y: dashboard.pad
        width: dashboard.sideWidth - dashboard.pad
        height: parent.height - dashboard.pad * 2

        Rectangle {
            anchors.fill: parent
            radius: NihilStyle.radiusWindow - dashboard.pad
            color: NihilStyle.fill
        }

        Column {
            id: nav
            x: NihilStyle.s(8)
            y: NihilStyle.s(12)
            width: parent.width - NihilStyle.s(16)
            spacing: NihilStyle.s(2)

            // NiHiL's name over its pages.
            Row {
                visible: !dashboard.compact
                height: NihilStyle.s(40)
                leftPadding: NihilStyle.s(8)
                spacing: NihilStyle.s(10)
                NLogo { anchors.verticalCenter: parent.verticalCenter; size: NihilStyle.s(22) }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "NiHiL"
                    font.pixelSize: NihilStyle.textLarge
                    font.weight: Font.DemiBold
                }
            }
            Item { visible: !dashboard.compact; width: 1; height: NihilStyle.s(6) }

            Repeater {
                model: dashboard.entries
                MouseArea {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool chosen: dashboard.page === row.modelData.id
                    readonly property color foreground: row.chosen ? NihilStyle.accentText : NihilStyle.text
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
                        color: row.chosen ? NihilStyle.accent : row.containsMouse ? NihilStyle.fillHover : "transparent"
                        Behavior on color { ColorAnimation { duration: NihilStyle.durationShort } }
                    }
                    NIcon {
                        x: dashboard.compact ? (parent.width - width) / 2 : NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.glyph
                        size: NihilStyle.s(19)
                        color: row.foreground
                    }
                    NText {
                        visible: !dashboard.compact
                        x: NihilStyle.s(46)
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - NihilStyle.s(40)
                        text: row.modelData.name
                        font.weight: row.chosen ? Font.DemiBold : Font.Medium
                        color: row.foreground
                    }
                    // Its key, once the pointer is on it.
                    NText {
                        visible: !dashboard.compact && row.index < 9 && (row.containsMouse || row.chosen)
                        anchors.right: parent.right
                        anchors.rightMargin: NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Alt " + (row.index + 1)
                        font.pixelSize: NihilStyle.textCaption
                        color: Qt.alpha(row.foreground, 0.5)
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
                visible: !dashboard.compact
                width: parent.width
                leftPadding: NihilStyle.s(6)
                spacing: NihilStyle.s(10)
                Rectangle {
                    id: avatar
                    width: NihilStyle.s(34)
                    height: width
                    radius: width / 2
                    color: NihilStyle.fillHover
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
                        source: Directories.userAvatarSourcePrimary
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
                        font.pixelSize: NihilStyle.textCaption
                        color: NihilStyle.textTertiary
                    }
                }
            }

            Flow {
                width: parent.width
                spacing: NihilStyle.s(6)
                NButton {
                    icon: "gear"
                    label: dashboard.compact ? "" : Translation.tr("Settings")
                    width: dashboard.compact ? parent.width : implicitWidth
                    onClicked: {
                        NihilState.dismiss()
                        Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "settings"])
                    }
                }
                NButton {
                    icon: "lock"
                    width: dashboard.compact ? parent.width : implicitWidth
                    Accessible.name: Translation.tr("Lock")
                    onClicked: {
                        NihilState.dismiss()
                        Session.lock()
                    }
                }
                NButton {
                    icon: "power"
                    width: dashboard.compact ? parent.width : implicitWidth
                    Accessible.name: Translation.tr("Power")
                    onClicked: NihilState.toggle("power")
                }
            }
        }
    }

    // The page.
    Item {
        id: holder
        x: dashboard.sideWidth + dashboard.pad
        y: dashboard.pad
        width: parent.width - x - dashboard.pad
        height: parent.height - dashboard.pad * 2
        clip: true

        Loader {
            id: pageLoader
            width: holder.width
            height: holder.height
            active: dashboard.carried.length > 0
            source: dashboard.sources[dashboard.carried] ?? ""
            opacity: 0
            onLoaded: {
                pageLoader.item.screen = dashboard.screen
                pageLoader.item.open = Qt.binding(() => dashboard.open && dashboard.page === dashboard.carried)
                arrive.restart()
                dashboard.forceActiveFocus()
                pageLoader.item.forceActiveFocus()
            }
            ParallelAnimation {
                id: arrive
                NumberAnimation { target: pageLoader; property: "opacity"; from: 0; to: 1; duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic }
                NumberAnimation { target: pageLoader; property: "y"; from: NihilStyle.s(10); to: 0; duration: NihilStyle.durationMedium; easing.type: Easing.OutCubic }
            }
        }
    }
}
