pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.iris.widgets

// You in Prism: your name on the tab, the machine on the flap, your picture and the hour's greeting in the pane, the
// lock, Settings and the session as keys on the foot (worded when the three words fit, glyphs otherwise).
PrismFolder {
    id: root

    readonly property string name: SystemInfo.displayName || SystemInfo.username || "user"
    readonly property string host: {
        const distro = String(SystemInfo.distroId ?? "").trim()
        const hostName = root.widget.showHostname ? String(SystemInfo.hostname ?? "") : ""
        return hostName.length > 0 ? hostName : distro.length > 0 && distro !== "unknown" ? distro : ""
    }
    readonly property string greeting: {
        const hour = DateTime.clock.date.getHours()
        return hour < 5 ? Translation.tr("Good night") : hour < 12 ? Translation.tr("Good morning")
            : hour < 19 ? Translation.tr("Good afternoon") : Translation.tr("Good evening")
    }
    readonly property string shellName: String(Quickshell.env("SHELL") ?? "").split("/").pop() || "sh"
    readonly property bool avatar: Boolean(root.widget.showAvatar ?? true)

    tabGlyph: "person"
    tabText: root.name
    flapText: root.host

    // ── the pane: picture and greeting ──
    FaceAvatar {
        id: picture
        visible: root.avatar
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: root.pick(48, 56, 92)
        height: width
    }
    Column {
        x: root.avatar ? picture.x + picture.width + root.pick(10, 14, 18) : root.inset
        width: root.width - root.inset - x
        y: Math.round(root.paneMiddle - height / 2)
        FaceText {
            face: root
            width: parent.width
            text: root.greeting
            size: root.type(14, 18, 24)
            weight: Font.Bold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: root.px(11)
        }
        FaceText {
            visible: !root.small
            face: root
            width: parent.width
            text: Translation.tr("On for %1").arg(DateTime.uptime || "--")
            color: root.inkSecondary
            size: root.type(11.5, 13, 15)
            weight: Font.Medium
            elide: Text.ElideRight
        }
        FaceText {
            visible: root.large
            face: root
            width: parent.width
            text: root.shellName + " · " + IrisFaceData.capitalized(String(SystemInfo.desktopEnvironment || "Wayland").split(":")[0].toLowerCase())
            color: root.inkTertiary
            size: 13
            weight: Font.Medium
            elide: Text.ElideRight
        }
    }

    // ── the foot: the three keys ──
    Row {
        id: keys
        readonly property real keyWidth: (root.innerWidth - 2 * keys.spacing) / 3
        readonly property bool roomy: lockKey.wordedWidth <= keys.keyWidth && settingsKey.wordedWidth <= keys.keyWidth && sessionKey.wordedWidth <= keys.keyWidth
        x: root.inset
        y: Math.round(root.large ? root.height - root.inset - height : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.dp(8)
        FaceAction {
            id: lockKey
            face: root
            width: keys.keyWidth
            height: root.pick(32, 34, 40)
            worded: keys.roomy
            glyph: "lock"
            name: Translation.tr("Lock")
            onActivated: root.widget.lockScreen()
        }
        FaceAction {
            id: settingsKey
            face: root
            width: keys.keyWidth
            height: lockKey.height
            worded: keys.roomy
            glyph: "settings"
            name: Translation.tr("Settings")
            onActivated: GlobalStates.openSettings()
        }
        FaceAction {
            id: sessionKey
            face: root
            width: keys.keyWidth
            height: lockKey.height
            worded: keys.roomy
            glyph: "power_settings_new"
            name: Translation.tr("Session")
            danger: true
            onActivated: GlobalStates.sessionOpen = true
        }
    }
}
