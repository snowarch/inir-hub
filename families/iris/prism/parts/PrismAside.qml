pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The right column (his 11-19: "del lado derecho nuevo mejorado"; 11-20: "customizable con otras cosas"): the blocks
// the person chose, in their order: who they are, the open page's own changes, keys and tip, what is playing, what comes
// next, the forecast, the machine. It says nothing the page already says.
Item {
    id: root
    property bool active: true
    property string pageId: ""
    // Home and a search list every change, each with its page.
    property bool everywhere: false
    signal reach(var row)
    signal pictureAsked()

    // What was changed on this page in this visit, newest first: Settings' own history (Ctrl+Z's, forgotten when Settings
    // closes), each row once and only while it holds another value than when the visit began. A page set up long ago
    // opens quiet (his 11-20: "que no aparezcan 300 cambios cada vez que entro"); its head keeps Restore defaults for the
    // rest. Home and a search list nothing (his 11-19: bloat).
    readonly property var visit: {
        if (root.everywhere) return ({ rows: [], before: ({}) })
        const _ = PrismModel.revision
        const own = ({})
        for (const row of PrismModel.rows)
            if (row.page === root.pageId && !PrismModel.virtual(row)) own[IrisOptions.rowKey(row.spec)] = row
        const before = ({})
        const order = []
        for (const entry of Array.from(IrisOptions.history)) {
            if (entry.kind !== "change" || !(entry.key in own)) continue
            if (!(entry.key in before)) before[entry.key] = entry.steps[0].before
            const at = order.indexOf(entry.key)
            if (at >= 0) order.splice(at, 1)
            order.push(entry.key)
        }
        const rows = order.reverse()
            .filter(key => !IrisOptions.same(before[key], IrisOptions.plain(IrisOptions.currentValue(own[key].spec))))
            .slice(0, 6).map(key => own[key])
        return ({ rows: rows, before: before })
    }
    readonly property var changes: root.visit.rows
    readonly property real pad: PrismTheme.dp(14)

    // The keys that reach this page's own things, as the compositor binds them now (one per action, a handful at most).
    readonly property var keyMatch: ({
        general: /"settings"|cheatsheet/, capture: /"region"|screenshot/, sound: /"audio"|equalizer/, player: /"mpris"/,
        display: /"brightness"/, lock: /"lock"/, wallpaper: /wallpaperSelector/, spotlight: /"overview"/,
        windows: /close-window|toggle-window-floating|fullscreen-window|maximize-column/,
        layout: /center-column|switch-preset-column-width|consume-or-expel-window-left/
    })
    readonly property var keys: {
        const match = root.everywhere ? undefined : root.keyMatch[root.pageId]
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
    readonly property bool wantsKeys: root.active && !root.everywhere && root.keyMatch[root.pageId] !== undefined
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
        [/"overview"/, "Search apps and more"], [/"settings"/, "Settings"], [/cheatsheet/, "Every key at a glance"],
        [/close-window/, "Close the window"], [/toggle-window-floating/, "Float or tile the window"],
        [/fullscreen-window/, "Fullscreen"], [/maximize-column/, "Fill the screen's width"],
        [/center-column/, "Centre the column"], [/switch-preset-column-width/, "Next column width"],
        [/consume-or-expel-window-left/, "Stack into the column at the left"]
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

    // What changed on the page, gathered by group. One line each: the name, and what it holds now at the line's end,
    // which gives way to its own restore while pointed.
    readonly property var sections: {
        const out = []
        for (const row of root.changes) {
            const title = String(row.section ?? "")
            let at = out.find(section => section.key === title)
            if (!at) {
                at = { key: title, title: title, glyph: "", rows: [] }
                out.push(at)
            }
            at.rows.push(row)
        }
        return out
    }
    // How the page's own thing is used, said once: the area's tip (IrisOptions), on the area's own page only, where it
    // speaks of what is on screen (a chapter's area tip would speak of another page).
    readonly property string tip: {
        if (root.everywhere || root.pageId === "general") return ""
        const page = PrismModel.page(root.pageId)
        if (!page || page.area !== root.pageId) return ""
        return String(IrisOptions.sectionById(root.pageId)?.tip ?? "")
    }
    // One group on a page needs no caption: the page already says where it is.
    readonly property bool captioned: root.sections.length > 1

    // The column is the person's (iris.appearance.settingsAside): the blocks they chose, in their order. The player,
    // when it is the last, stands at the foot, where the column ends.
    readonly property var known: ["profile", "page", "player", "agenda", "forecast", "vitals"]
    readonly property var blocks: {
        const ids = Array.from(Config.options?.iris?.appearance?.settingsAside ?? ["profile", "page", "player"], String)
        return ids.filter((id, at) => root.known.includes(id) && ids.indexOf(id) === at)
    }
    readonly property string playerForm: String(Config.options?.iris?.appearance?.settingsPlayer ?? "cover")
    readonly property bool pinned: root.blocks.length > 0 && root.blocks[root.blocks.length - 1] === "player"
    readonly property var parts: ({ profile: personBlock, page: pageBlock, player: playerBlock, agenda: agendaBlock, forecast: forecastBlock, vitals: vitalsBlock })

    // Whoever sits here (his 11-19: "algo de usuario"): their picture (a press gives it a new one), their name and the
    // day; the bell silences notifications.
    Component {
        id: personBlock
        Item {
            id: person
            readonly property bool shown: true
            implicitHeight: PrismTheme.dp(52)
            PrismAvatar {
                id: face
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(46)
                // Pointed, the picture offers a new one.
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: PrismTheme.spotScrim
                    opacity: faceArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    PrismGlyph {
                        anchors.centerIn: parent
                        text: "photo_camera"
                        iconSize: PrismTheme.dp(18)
                        color: PrismTheme.paper
                    }
                }
                MouseArea {
                    id: faceArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: Translation.tr("Profile picture")
                    onClicked: root.pictureAsked()
                }
            }
            Column {
                anchors.left: face.right
                anchors.leftMargin: PrismTheme.dp(12)
                anchors.right: bell.left
                anchors.rightMargin: PrismTheme.dp(8)
                anchors.verticalCenter: parent.verticalCenter
                spacing: PrismTheme.dp(2)
                PrismText {
                    width: parent.width
                    text: face.name
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.DemiBold
                    font.letterSpacing: -PrismTheme.row * 0.01
                }
                PrismText {
                    width: parent.width
                    readonly property string temp: Weather.enabled ? String(Weather.data?.temp ?? "") : ""
                    text: Translation.locale.toString(DateTime.clock.date, "dddd d MMM")
                        + (temp.length > 0 && !temp.startsWith("--") ? "  ·  " + temp : "")
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                }
            }
            PrismRound {
                id: bell
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(32)
                ghost: !Notifications.silent
                lit: Notifications.silent
                glyph: Notifications.silent ? "notifications_off" : "notifications"
                glyphSize: PrismTheme.dp(17)
                Accessible.name: Translation.tr("Do Not Disturb")
                onClicked: Config.setNestedValue("notifications.silent", !Notifications.silent)
            }
        }
    }

    // The page they read: what they changed on it, its keys and how its thing is used.
    Component {
        id: pageBlock
        Column {
            id: pageBox
            readonly property bool shown: root.changes.length > 0 || root.keys.length > 0 || root.tip.length > 0
            spacing: 0

            // What this visit changed on the page, while it holds: each line's way back is the value it had before.
            PrismText {
                visible: root.changes.length > 0
                width: parent.width
                height: PrismTheme.dp(30)
                verticalAlignment: Text.AlignVCenter
                text: Translation.tr("Changed here")
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
                font.letterSpacing: -PrismTheme.row * 0.01
            }
            Repeater {
                // Keyed: a write elsewhere keeps the groups and lines that stayed instead of rebuilding the list.
                model: ScriptModel { objectProp: "key"; values: root.sections }
                delegate: Column {
                    id: section
                    required property var modelData
                    required property int index
                    width: stack.width
                    topPadding: section.index === 0 ? PrismTheme.dp(4) : PrismTheme.dp(14)
                    Row {
                        visible: root.captioned
                        height: PrismTheme.dp(24)
                        spacing: PrismTheme.dp(6)
                        PrismGlyph {
                            visible: section.modelData.glyph.length > 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: section.modelData.glyph
                            iconSize: PrismTheme.dp(14)
                            color: PrismTheme.ink3
                        }
                        PrismText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, stack.width - PrismTheme.dp(20))
                            text: Translation.tr(section.modelData.title)
                            color: PrismTheme.ink3
                            font.pixelSize: PrismTheme.small
                            font.weight: Font.DemiBold
                            font.letterSpacing: PrismTheme.small * 0.02
                            elide: Text.ElideRight
                        }
                    }
                    Repeater {
                        model: ScriptModel { objectProp: "key"; values: section.modelData.rows }
                        delegate: Item {
                            id: change
                            required property var modelData
                            // A hover handler sees the pointer over the way back too, so the line never flickers under it.
                            readonly property bool pointed: lineHover.hovered
                            // A value outside the row's choices (an installed face) says itself.
                            readonly property string now: {
                                const _ = PrismModel.revision
                                const said = String(PrismModel.sayNow(change.modelData) ?? "")
                                const held = PrismModel.read(change.modelData)
                                return said.length > 0 ? said : typeof held === "string" ? held : ""
                            }
                            width: stack.width
                            height: PrismTheme.dp(34)
                            HoverHandler { id: lineHover }
                            Rectangle {
                                anchors.fill: parent
                                anchors.leftMargin: -PrismTheme.dp(8)
                                anchors.rightMargin: -PrismTheme.dp(8)
                                radius: PrismTheme.dp(10)
                                color: changeArea.pressed ? PrismTheme.fillPress : change.pointed ? PrismTheme.fill : "transparent"
                                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
                            }
                            // No changed bar here: every line of this list is a change, a bar on each would say it twenty times.
                            PrismText {
                                id: name
                                x: 0
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width - x - (said.visible ? Math.min(said.implicitWidth, parent.width * 0.42) + PrismTheme.dp(10) : 0)
                                    - (undo.visible ? undo.width + PrismTheme.dp(6) : 0))
                                text: Translation.tr(String(change.modelData.label ?? ""))
                                font.pixelSize: PrismTheme.body
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            // What it holds now, at the line's end; pointed, its way back stands there instead.
                            PrismText {
                                id: said
                                visible: change.now.length > 0 && !change.pointed
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, parent.width * 0.42)
                                horizontalAlignment: Text.AlignRight
                                text: change.now
                                color: PrismTheme.ink2
                                font.pixelSize: PrismTheme.small
                                figures: true
                                elide: Text.ElideRight
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
                            PrismRound {
                                id: undo
                                visible: change.pointed
                                anchors.right: parent.right
                                anchors.rightMargin: -PrismTheme.dp(4)
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: PrismTheme.dp(26)
                                ghost: true
                                glyph: "undo"
                                glyphSize: PrismTheme.dp(15)
                                Accessible.name: Translation.tr("Restore")
                                onClicked: IrisOptions.commit(change.modelData.spec, root.visit.before[IrisOptions.rowKey(change.modelData.spec)])
                            }
                        }
                    }
                }
            }

            // The keys: what each does at the left, its combo as caps at the right.
            Column {
                visible: root.keys.length > 0
                width: parent.width
                topPadding: root.changes.length > 0 ? PrismTheme.dp(24) : 0
                spacing: 0
                PrismText {
                    width: parent.width
                    bottomPadding: PrismTheme.dp(4)
                    text: Translation.tr("Keys")
                    font.pixelSize: PrismTheme.row
                    font.weight: Font.DemiBold
                    font.letterSpacing: -PrismTheme.row * 0.01
                }
                Repeater {
                    model: root.keys
                    delegate: Item {
                        id: key
                        required property var modelData
                        width: stack.width
                        height: Math.max(PrismTheme.dp(34), say.implicitHeight + PrismTheme.dp(12))
                        PrismText {
                            id: say
                            anchors.left: parent.left
                            anchors.right: caps.left
                            anchors.rightMargin: PrismTheme.dp(10)
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(key.modelData.say)
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.small
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                        Row {
                            id: caps
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: PrismTheme.dp(3)
                            Repeater {
                                model: root.capsOf(key.modelData.combo)
                                delegate: Rectangle {
                                    id: cap
                                    required property var modelData
                                    readonly property bool drawn: cap.modelData.glyph.length > 0
                                    width: Math.max(height, (cap.drawn ? capGlyph.width : capText.implicitWidth) + PrismTheme.dp(12))
                                    height: PrismTheme.dp(22)
                                    radius: PrismTheme.dp(6)
                                    // Light, the panel is already frost: a key stands in the card's white.
                                    color: PrismTheme.light ? PrismTheme.card : PrismTheme.keyQuiet
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
                                        font.pixelSize: PrismTheme.small - 1
                                        font.weight: Font.DemiBold
                                    }
                                    PrismGlyph {
                                        id: capGlyph
                                        visible: cap.drawn
                                        anchors.centerIn: parent
                                        text: cap.modelData.glyph
                                        iconSize: PrismTheme.dp(14)
                                        color: PrismTheme.ink
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Good to know: how the page's thing is used, a quiet line under a bulb.
            Row {
                visible: root.tip.length > 0
                width: parent.width
                topPadding: root.changes.length > 0 || root.keys.length > 0 ? PrismTheme.dp(24) : PrismTheme.dp(4)
                spacing: PrismTheme.dp(10)
                PrismGlyph {
                    id: bulb
                    text: "lightbulb"
                    iconSize: PrismTheme.dp(17)
                    color: PrismTheme.ink3
                }
                PrismText {
                    width: parent.width - bulb.width - parent.spacing
                    text: Translation.tr(root.tip)
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    lineHeight: 1.15
                    wrapMode: Text.WordWrap
                    maximumLineCount: 6
                }
            }
        }
    }

    Component {
        id: playerBlock
        PrismNowPlaying {
            readonly property bool shown: playing
            form: root.playerForm
            active: root.active && root.visible
        }
    }
    Component { id: agendaBlock; PrismGlance { kind: "agenda"; active: root.active && root.visible } }
    Component { id: forecastBlock; PrismGlance { kind: "forecast"; active: root.active && root.visible } }
    Component { id: vitalsBlock; PrismGlance { kind: "vitals"; active: root.active && root.visible } }

    Flickable {
        id: scroll
        y: PrismTheme.dp(60)
        width: root.width
        height: (player.visible ? player.y - PrismTheme.dp(16) : root.height - PrismTheme.dp(22)) - y
        contentHeight: stack.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Column {
            id: stack
            x: root.pad
            width: root.width - 2 * root.pad
            spacing: PrismTheme.dp(26)
            Repeater {
                model: root.blocks
                delegate: Loader {
                    id: block
                    required property string modelData
                    width: stack.width
                    visible: block.item?.shown ?? false
                    sourceComponent: block.modelData === "player" && root.pinned ? null : root.parts[block.modelData] ?? null
                }
            }
            // The column's own way to be arranged, quiet at its end.
            Item {
                width: parent.width
                height: PrismTheme.dp(24)
                Row {
                    id: arrangeLine
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: PrismTheme.dp(6)
                    PrismGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "tune"
                        iconSize: PrismTheme.dp(15)
                        color: arrange.containsMouse ? PrismTheme.accentInk : PrismTheme.ink3
                    }
                    PrismText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr("Customize")
                        color: arrange.containsMouse ? PrismTheme.accentInk : PrismTheme.ink3
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                }
                MouseArea {
                    id: arrange
                    anchors.fill: arrangeLine
                    anchors.margins: -PrismTheme.dp(6)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Link
                    Accessible.name: Translation.tr("Customize")
                    onClicked: {
                        PrismState.go("general")
                        PrismState.pickGroup("general", "Settings window")
                    }
                }
            }
        }
    }

    PrismNowPlaying {
        id: player
        visible: root.pinned && player.playing
        form: root.playerForm
        x: root.pad
        width: root.width - 2 * root.pad
        // The cover as itself: square while the column is tall enough, never under a third of it.
        height: player.bar ? player.implicitHeight : Math.max(PrismTheme.dp(220), Math.min(width * 1.08, root.height * 0.46))
        y: root.height - PrismTheme.dp(22) - height
        active: root.active && root.visible && root.pinned
    }
}
