pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style

// Sender identity for a notification, shared by banners, Control Center and
// Today: the notification's own image (with the app as a corner badge), the
// app's real icon (theme name, path or desktop entry), or — when the sender
// publishes nothing that resolves — an app-icon-shaped iRiS tile whose glyph
// and tint follow what the notification is about. Never the missing-icon
// texture.
Item {
    id: root

    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property string summary: ""
    property bool critical: false
    property bool showImage: true
    property real size: 38

    implicitWidth: root.size
    implicitHeight: root.size

    // Senders often pass a theme icon *name* as the image. That is identity,
    // not artwork: it never becomes a picture (an unresolved one would paint the
    // missing-texture checkerboard) and competes as an app icon instead.
    readonly property string themedImage: {
        const themed = root.image.match(/^image:\/\/icon\/(.+)$/)
        return themed ? decodeURIComponent(themed[1]) : ""
    }
    readonly property bool hasImage: root.showImage && root.image.length > 0 && root.themedImage.length === 0
    // The shell's own notifications carry the iRiS insignia on a black tile —
    // the family's own identity, never a borrowed desktop entry or vendor mark.
    readonly property bool fromShell: /^(inir|iris|quickshell|illogical)/i.test(root.appName)
    readonly property string resolvedIcon: {
        if (root.fromShell) return ""
        const candidates = [root.appIcon, root.themedImage, AppSearch.lookupDesktopEntry(root.appName)?.icon ?? ""]
        for (const icon of candidates) {
            const name = String(icon ?? "")
            if (name.length === 0) continue
            if (name.startsWith("/") || name.startsWith("file:") || AppSearch.iconExists(name)) return name
        }
        return ""
    }
    readonly property var semantic: {
        const text = (root.appName + " " + root.appIcon + " " + root.summary).toLowerCase()
        const rules = [
            [/screenshot|screen shot|captur/, "screenshot_region", "#0a84ff"],
            [/record/, "videocam", "#ff375f"],
            [/battery|charg|power/, "battery_charging_full", "#34c759"],
            [/bluetooth/, "bluetooth", "#0a84ff"],
            [/network|wi-?fi|ethernet|vpn|connect/, "wifi", "#0a84ff"],
            [/volume|audio|sound|microphone/, "volume_up", "#ff9f0a"],
            [/bright|display|monitor/, "light_mode", "#ff9f0a"],
            [/update|upgrade|package|pacman|flatpak/, "system_update", "#5e5ce6"],
            [/download/, "download", "#30b0c7"],
            [/mail/, "mail", "#0a84ff"],
            [/message|chat|discord|telegram|vesktop|signal|whatsapp/, "chat_bubble", "#34c759"],
            [/calendar|event|remind|meeting/, "event", "#ff3b30"],
            [/timer|pomodoro|alarm|stopwatch/, "timer", "#ff9f0a"],
            [/music|spotify|player|song|track/, "music_note", "#ff375f"],
            [/clipboard|copied|copy/, "content_paste", "#8e8e93"],
            [/wallpaper|theme|colou?r/, "palette", "#bf5af2"],
            [/inir|iris|shell|quickshell/, "auto_awesome", "#bf5af2"]
        ]
        for (const rule of rules)
            if (rule[0].test(text)) return { glyph: rule[1], tint: rule[2] }
        return { glyph: "notifications", tint: "#8e8e93" }
    }

    ClippingRectangle {
        anchors.fill: parent
        visible: root.hasImage
        radius: Math.round(root.width * 0.26)
        color: IrisStyle.surfaceHigh
        Image {
            anchors.fill: parent
            source: root.hasImage ? root.image : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize: Qt.size(root.width * 2, root.height * 2)
        }
    }

    // The badge sits on the image's corner; alone it is the whole identity.
    Item {
        id: identity
        readonly property real extent: root.hasImage ? Math.round(root.width * 0.48) : root.width
        width: identity.extent
        height: identity.extent
        x: root.hasImage ? root.width - identity.extent + Math.round(root.width * 0.1) : 0
        y: root.hasImage ? root.height - identity.extent + Math.round(root.height * 0.1) : 0

        SmartAppIcon {
            anchors.fill: parent
            visible: root.resolvedIcon.length > 0
            icon: root.resolvedIcon
            fallback: "application-x-executable"
            iconSize: identity.extent
        }
        Rectangle {
            anchors.fill: parent
            visible: root.resolvedIcon.length === 0
            id: tile
            radius: Math.round(width * 0.26)
            readonly property bool insignia: root.fromShell && !root.critical
            readonly property color base: root.critical ? IrisStyle.danger : tile.insignia ? IrisStyle.surfaceHigh : root.semantic.tint
            border.width: root.hasImage || tile.insignia ? Math.max(1, Math.round(root.width * 0.04)) : 0
            border.color: tile.insignia ? IrisStyle.hairlineStrong : IrisStyle.surface
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(tile.base, 1.18) }
                GradientStop { position: 1; color: tile.base }
            }
            IrisMark {
                anchors.centerIn: parent
                visible: tile.insignia
                implicitSize: Math.round(tile.width * 0.7)
            }
            MaterialSymbol {
                visible: !tile.insignia
                anchors.centerIn: parent
                text: root.critical ? "priority_high" : root.semantic.glyph
                fill: 1
                iconSize: Math.round(parent.width * 0.56)
                color: "#ffffff"
            }
        }
    }
}
