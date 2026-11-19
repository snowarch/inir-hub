pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The right column (his 11-19: "del lado derecho nuevo mejorado"): what differs from how iNiR ships it, on the page
// open (Home and a search: everywhere), each a press away with its own way back, and what is playing at the foot.
// It says nothing the page already says.
Item {
    id: root
    property bool active: true
    property string pageId: ""
    // Home and a search list every change, each with its page.
    property bool everywhere: false
    signal reach(var row)

    readonly property var changes: {
        const all = Array.from(PrismModel.changes)
        return root.everywhere ? all : all.filter(row => row.page === root.pageId)
    }
    readonly property bool restorable: !root.everywhere && PrismModel.restorableOf(root.pageId) > 0
    readonly property real pad: PrismTheme.dp(14)

    // The keys that reach this page's own things, as the compositor binds them now (one per action, a handful at most).
    readonly property var keyMatch: ({
        general: /"settings"|cheatsheet/, capture: /"region"|screenshot/, sound: /"audio"|equalizer/, player: /"mpris"/,
        display: /"brightness"/, lock: /"lock"/, wallpaper: /wallpaperSelector/, spotlight: /"overview"/
    })
    readonly property var keys: {
        const match = root.keyMatch[root.everywhere ? "general" : root.pageId]
        if (!match) return []
        const seen = {}
        const out = []
        for (const bind of NiriKeybinds.allBinds ?? []) {
            const raw = String(bind.action_raw ?? "")
            if (bind.commented || raw.length === 0 || seen[raw] || !match.test(String(bind.key_combo ?? "") + " " + raw)) continue
            seen[raw] = true
            out.push({ combo: String(bind.key_combo), say: root.sayOf(raw, String(bind.description || bind.action || raw)) })
            if (out.length >= 5) break
        }
        return out
    }
    // The compositor's binds are read once, the first time a page with keys of its own opens.
    readonly property bool wantsKeys: root.active && root.keyMatch[root.everywhere ? "general" : root.pageId] !== undefined
    onWantsKeysChanged: if (root.wantsKeys && (NiriKeybinds.allBinds ?? []).length === 0) NiriKeybinds.reload()
    Component.onCompleted: if (root.wantsKeys && (NiriKeybinds.allBinds ?? []).length === 0) NiriKeybinds.reload()
    // iNiR's own verbs said as a person would; any other bind keeps its own description.
    readonly property var verbs: [
        [/"region" "menu"/, "Screenshot, text or recording"], [/"region" "ocr"/, "Copy text from the screen"],
        [/"region" "search"/, "Search what is on the screen"], [/"region" "record/, "Record the screen"],
        [/screenshot-screen/, "Screenshot of the whole screen"], [/screenshot-window/, "Screenshot of a window"], [/^screenshot\b/, "Screenshot"],
        [/"equalizer"/, "Equalizer"], [/"audio" "volumeUp"/, "Volume up"], [/"audio" "volumeDown"/, "Volume down"],
        [/"audio" "mute"/, "Mute"], [/"audio" "micMute"/, "Mute the microphone"], [/"brightness" "increment"/, "Brighter"],
        [/"brightness" "decrement"/, "Dimmer"], [/"mpris" "playPause"/, "Play or pause"], [/"mpris" "next"/, "Next track"],
        [/"mpris" "previous"/, "Previous track"], [/"lock"/, "Lock the screen"], [/wallpaperSelector/, "Wallpaper picker"],
        [/"overview"/, "Search apps and more"], [/"settings"/, "Settings"], [/cheatsheet/, "Every key at a glance"]
    ]
    function sayOf(raw: string, fallback: string): string {
        const known = root.verbs.find(([match]) => match.test(raw))
        return known ? known[1] : fallback
    }
    // A combo as caps: Mod is the Super key; media and screen keys wear their glyph.
    readonly property var keyGlyphs: ({
        XF86AudioRaiseVolume: "volume_up", XF86AudioLowerVolume: "volume_down", XF86AudioMute: "volume_off", XF86AudioMicMute: "mic_off",
        XF86MonBrightnessUp: "brightness_high", XF86MonBrightnessDown: "brightness_low", XF86AudioPlay: "play_arrow",
        XF86AudioPause: "pause", XF86AudioNext: "skip_next", XF86AudioPrev: "skip_previous"
    })
    function capsOf(combo: string): var {
        return combo.split("+").filter(part => part.length > 0).map(part => ({
            glyph: String(root.keyGlyphs[part] ?? ""),
            text: part === "Mod" || part === "Super" ? Translation.tr("Super") : part === "Comma" ? "," : part === "Slash" ? "/"
                : part === "Return" ? Translation.tr("Enter") : part === "Space" ? Translation.tr("Space") : part
        }))
    }

    Item {
        id: head
        x: root.pad
        y: PrismTheme.dp(30)
        width: root.width - 2 * root.pad
        height: PrismTheme.dp(28)
        PrismText {
            anchors.left: parent.left
            anchors.right: back.visible ? back.left : parent.right
            anchors.rightMargin: PrismTheme.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            text: root.everywhere ? Translation.tr("Your changes") : Translation.tr("Changed here")
            font.pixelSize: PrismTheme.row
            font.weight: Font.DemiBold
            font.letterSpacing: -PrismTheme.row * 0.01
        }
        // The page back to iNiR's, in one change Ctrl+Z takes back.
        PrismText {
            id: back
            visible: root.restorable
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("Restore all")
            color: backArea.containsMouse ? PrismTheme.ink : PrismTheme.accentInk
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
            MouseArea {
                id: backArea
                anchors.fill: parent
                anchors.margins: -PrismTheme.dp(6)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: back.text
                onClicked: PrismModel.restore(root.pageId)
            }
        }
    }

    Flickable {
        id: scroll
        y: head.y + head.height + PrismTheme.dp(6)
        width: root.width
        height: (player.visible ? player.y - PrismTheme.dp(14) : root.height - PrismTheme.dp(22)) - y
        contentHeight: stack.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Column {
            id: stack
            x: root.pad
            width: root.width - 2 * root.pad
            spacing: 0

            // Nothing changed: said once, quietly, with where changes will show.
            Column {
                visible: root.changes.length === 0
                width: parent.width
                topPadding: PrismTheme.dp(4)
                spacing: PrismTheme.dp(4)
                PrismText {
                    width: parent.width
                    text: root.everywhere ? Translation.tr("Everything is as iNiR ships it.") : Translation.tr("As iNiR ships it")
                    font.pixelSize: PrismTheme.body
                    font.weight: Font.Medium
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                }
                PrismText {
                    width: parent.width
                    text: root.everywhere ? Translation.tr("What you change shows up here.") : Translation.tr("What you change on this page shows up here.")
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                }
            }
            Repeater {
                // Keyed: a write elsewhere keeps the lines that stayed instead of rebuilding the list.
                model: ScriptModel { objectProp: "key"; values: root.changes }
                delegate: Item {
                    id: change
                    required property var modelData
                    readonly property bool pointed: changeArea.containsMouse || undo.hovered
                    readonly property string where: root.everywhere ? Translation.tr(String(PrismModel.page(change.modelData.page).name ?? "")) : ""
                    readonly property string now: { const _ = PrismModel.revision; return String(PrismModel.sayNow(change.modelData) ?? "") }
                    width: stack.width
                    height: Math.max(PrismTheme.dp(50), words.implicitHeight + PrismTheme.dp(16))
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -PrismTheme.dp(8)
                        anchors.rightMargin: -PrismTheme.dp(8)
                        radius: PrismTheme.dp(12)
                        color: changeArea.pressed ? PrismTheme.fillPress : change.pointed ? PrismTheme.fill : "transparent"
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                    }
                    // The changed row's own bar, as it wears it on its page.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: PrismTheme.dp(3)
                        height: PrismTheme.dp(16)
                        radius: width / 2
                        color: PrismTheme.mark
                    }
                    Column {
                        id: words
                        x: PrismTheme.dp(14)
                        width: parent.width - x - (change.pointed ? undo.width + PrismTheme.dp(6) : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(2)
                        PrismText {
                            width: parent.width
                            text: Translation.tr(String(change.modelData.label ?? ""))
                            font.pixelSize: PrismTheme.body
                            font.weight: Font.Medium
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        PrismText {
                            visible: text.length > 0
                            width: parent.width
                            text: [change.where, change.now].filter(part => part.length > 0).join("  ·  ")
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.small
                        }
                    }
                    MouseArea {
                        id: changeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Link
                        Accessible.name: Translation.tr(String(change.modelData.label ?? ""))
                        onClicked: root.reach(change.modelData)
                    }
                    // Its own way back to iNiR's value.
                    PrismRound {
                        id: undo
                        visible: change.pointed && PrismModel.restorable(change.modelData)
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: PrismTheme.dp(28)
                        ghost: true
                        glyph: "undo"
                        glyphSize: PrismTheme.dp(16)
                        Accessible.name: Translation.tr("Restore")
                        onClicked: PrismModel.restoreRow(change.modelData)
                    }
                }
            }

            // The keys: what each does, its combo as caps.
            Column {
                visible: root.keys.length > 0
                width: parent.width
                topPadding: PrismTheme.dp(26)
                spacing: PrismTheme.dp(2)
                PrismText {
                    width: parent.width
                    bottomPadding: PrismTheme.dp(6)
                    text: Translation.tr("Keys")
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.DemiBold
                    font.letterSpacing: -PrismTheme.row * 0.01
                }
                Repeater {
                    model: root.keys
                    delegate: Column {
                        id: key
                        required property var modelData
                        width: stack.width
                        topPadding: PrismTheme.dp(6)
                        bottomPadding: PrismTheme.dp(8)
                        spacing: PrismTheme.dp(6)
                        PrismText {
                            width: parent.width
                            text: Translation.tr(key.modelData.say)
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.small
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Flow {
                            width: parent.width
                            spacing: PrismTheme.dp(4)
                            Repeater {
                                model: root.capsOf(key.modelData.combo)
                                delegate: Rectangle {
                                    id: cap
                                    required property var modelData
                                    readonly property bool drawn: cap.modelData.glyph.length > 0
                                    width: Math.max(height, (cap.drawn ? capGlyph.width : capText.implicitWidth) + PrismTheme.dp(14))
                                    height: PrismTheme.dp(24)
                                    radius: PrismTheme.dp(7)
                                    color: PrismTheme.keyQuiet
                                    // Its lower lip: a key, not a chip.
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        x: cap.radius * 0.6
                                        width: parent.width - 2 * x
                                        height: 1
                                        color: PrismTheme.line
                                    }
                                    PrismText {
                                        id: capText
                                        visible: !cap.drawn
                                        anchors.centerIn: parent
                                        text: cap.modelData.text
                                        font.pixelSize: PrismTheme.small
                                        font.weight: Font.DemiBold
                                    }
                                    PrismGlyph {
                                        id: capGlyph
                                        visible: cap.drawn
                                        anchors.centerIn: parent
                                        text: cap.modelData.glyph
                                        iconSize: PrismTheme.dp(15)
                                        color: PrismTheme.ink
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PrismNowPlaying {
        id: player
        visible: player.playing
        x: root.pad
        width: root.width - 2 * root.pad
        height: Math.max(PrismTheme.dp(200), Math.min(width, root.height * 0.36))
        y: root.height - PrismTheme.dp(22) - height
        active: root.active && root.visible
    }
}
