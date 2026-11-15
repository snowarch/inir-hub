pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import "IrisBinds.js" as IrisBinds

// Settings › Keyboard and Keyboard shortcuts: the keyboard drawn with what each key types in the layout in use (read
// from libxkbcommon by keymap.py, the same keymap the compositor builds), the space bar saying the layout's name. Hold
// Super, Ctrl, Alt or Shift on the drawing (or on the keyboard itself while the drawing has the focus) and each key says
// what it does with them, Niri's or Umbriel's binds alike; a key picked there is changed, moved or freed under it, and
// a free one takes any action the config already uses or a program. Under the keyboard on the Keyboard page, the
// layouts for the person's country as one tap each and every other found by its name. Raell Tech's page (his 11-14)
// is where it comes from.
Column {
    id: root

    property var spec: ({})
    // The shortcuts page opens on what Mod does; the Keyboard page on what the keys type.
    property var startHeld: []
    // The layouts under the drawing (Keyboard); the shortcuts page draws the keys and the bind under them alone.
    property bool choosing: true
    readonly property real d: IrisStyle.settingsDensity

    readonly property string layout: { CompositorConfig.revision; return String(CompositorConfig.value({ comp: "input", key: "keyboard.layout", fallback: "" }) ?? "") }
    readonly property string variant: { CompositorConfig.revision; return String(CompositorConfig.value({ comp: "input", key: "keyboard.variant", fallback: "" }) ?? "") }
    readonly property string options: { CompositorConfig.revision; return String(CompositorConfig.value({ comp: "input", key: "keyboard.options", fallback: "" }) ?? "") }
    // With several layouts the one in use now, as the compositor says.
    readonly property int group: Math.max(0, NiriService.currentKeyboardLayoutIndex)
    // With no layout line the compositor runs the system's and says it by name; keymap.py reads the names back to codes.
    readonly property string live: (NiriService.keyboardLayoutNames ?? []).join("\t")
    readonly property string asked: [root.layout, root.variant, root.options, root.group, Translation.languageCode, root.live].join("\u0001")
    onAskedChanged: readSoon.restart()
    Component.onCompleted: readSoon.restart()

    property var keys: ({})
    property var codes: ({})
    property bool iso: false
    property var layouts: []
    // Each layout in use, as codes: the config's lines, or what the compositor runs when it has none.
    property var using: []
    property var suggested: []
    property string failed: ""

    Timer { id: readSoon; interval: 120; onTriggered: { reader.running = false; reader.running = true } }
    Process {
        id: reader
        command: ["python3", "-I", String(Qt.resolvedUrl("keymap.py")).replace("file://", ""),
            root.layout, root.variant, root.options, String(root.group), Translation.languageCode, root.live]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const read = JSON.parse(text)
                    root.keys = read.keys ?? {}
                    root.codes = read.codes ?? {}
                    root.iso = read.iso === true
                    root.layouts = read.layouts ?? []
                    root.using = read.using ?? []
                    root.suggested = read.suggested ?? []
                    root.failed = ""
                } catch (error) { /* the error stream says why */ }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim().length > 0) root.failed = text.trim().split("\n").pop() }
    }

    // The layout in use by name, in the shell's language; the compositor's English name until the keymap is read.
    readonly property string inUse: {
        const now = root.using[root.group] ?? null
        const found = now ? root.layouts.find(entry => root.wearing(entry)) : null
        if (found) return found.name
        const names = NiriService.keyboardLayoutNames ?? []
        return String(names[root.group] ?? now?.layout ?? "")
    }
    onInUseChanged: IrisOptions.keyboardSaid = root.inUse

    function wear(entry: var): void {
        const layoutSpec = IrisOptions.settings.find(spec => spec.comp === "input" && spec.key === "keyboard.layout")
        const variantSpec = IrisOptions.settings.find(spec => spec.comp === "input" && spec.key === "keyboard.variant")
        if (!layoutSpec || !variantSpec) return
        // The tapped layout takes the place of the one in use; the person's other layouts stay.
        const list = root.using.length > 0 ? root.using.map(one => ({ layout: one.layout, variant: one.variant })) : [{}]
        list[Math.min(root.group, list.length - 1)] = { layout: entry.layout, variant: entry.variant }
        IrisOptions.commit(layoutSpec, list.map(one => one.layout).join(","))
        IrisOptions.commit(variantSpec, list.some(one => one.variant.length > 0) ? list.map(one => one.variant).join(",") : "")
    }
    function wearing(entry: var): bool {
        const now = root.using[root.group] ?? null
        return now !== null && now.layout === entry.layout && now.variant === entry.variant
    }

    // ── What the keys do ───────────────────────────────────────────────────────────────────────────────────────────
    // The compositor's Mod key: a drawn Super (or Alt, when Mod is Alt) is Mod.
    readonly property string modKey: { CompositorConfig.revision; return String(CompositorConfig.value({ comp: "input", key: "mod-key", fallback: "Super" }) || "Super") }
    readonly property var modOfCode: ({
        LWIN: root.modKey === "Super" ? "Mod" : "Super", RWIN: root.modKey === "Super" ? "Mod" : "Super",
        LALT: root.modKey === "Alt" ? "Mod" : "Alt", LCTL: "Ctrl", RCTL: "Ctrl", LFSH: "Shift", RTSH: "Shift"
    })
    property var held: Array.from(root.startHeld)
    // Modifiers held on the keyboard itself while the drawing has the focus: the drawing follows them while held.
    property var pressedMods: []
    readonly property var layerMods: root.pressedMods.length > 0 ? root.pressedMods : root.held
    readonly property bool doing: root.layerMods.length > 0
    property string picked: ""
    property string hovered: ""
    // A bind being moved: the next key picked on the drawing takes it.
    property var moving: null
    property var lit: ({})
    readonly property var bindIndex: {
        const out = {}
        for (const bind of NiriKeybinds.allBinds ?? []) {
            if (bind.commented) continue
            const key = IrisBinds.comboKey(bind.key_combo, root.modKey)
            if (!(key in out)) out[key] = bind
        }
        return out
    }
    function symAt(code: string): string { return IrisBinds.symOf(code, (root.keys[code] ?? [])[0]) }
    function bindAt(code: string): var { return root.bindIndex[IrisBinds.heldKey(root.layerMods, root.symAt(code))] ?? null }
    function nameOf(mod: string): string {
        return mod === "Mod" ? Translation.tr(root.modKey) : Translation.tr(mod)
    }
    function toggle(mod: string): void {
        const next = root.held.includes(mod) ? root.held.filter(one => one !== mod) : root.held.concat([mod])
        root.held = next
        root.picked = ""
    }
    // Every set of modifiers some bind uses, the busiest first: one press shows its layer.
    readonly property var layers: {
        const counts = {}
        for (const key of Object.keys(root.bindIndex)) {
            const mods = key.split("|")[0]
            if (mods.length > 0) counts[mods] = (counts[mods] ?? 0) + 1
        }
        return Object.keys(counts).sort((a, b) => counts[b] - counts[a]).slice(0, 6).map(mods => ({ mods: mods.split("+"), count: counts[mods] }))
    }
    function sameLayer(mods: var): bool {
        return mods.length === root.layerMods.length && mods.every(mod => root.layerMods.includes(mod))
    }

    // Rows in key units: the function row, then an ANSI board 15 wide (ISO: the key beside left Shift, Enter two rows
    // tall), with the navigation keys and arrows in a block of three at the right.
    readonly property var rows: [
        ["ESC", ["", 1], "FK01", "FK02", "FK03", "FK04", ["", 0.5], "FK05", "FK06", "FK07", "FK08", ["", 0.5], "FK09", "FK10", "FK11", "FK12"],
        ["TLDE", "AE01", "AE02", "AE03", "AE04", "AE05", "AE06", "AE07", "AE08", "AE09", "AE10", "AE11", "AE12", ["BKSP", 2]],
        [["TAB", 1.5], "AD01", "AD02", "AD03", "AD04", "AD05", "AD06", "AD07", "AD08", "AD09", "AD10", "AD11", "AD12", root.iso ? ["RTRN", 1.5] : ["BKSL", 1.5]],
        [["CAPS", 1.75], "AC01", "AC02", "AC03", "AC04", "AC05", "AC06", "AC07", "AC08", "AC09", "AC10", "AC11"].concat(root.iso ? ["BKSL", ["RTRN", 1.25]] : [["RTRN", 2.25]]),
        [["LFSH", root.iso ? 1.25 : 2.25]].concat(root.iso ? ["LSGT"] : [], ["AB01", "AB02", "AB03", "AB04", "AB05", "AB06", "AB07", "AB08", "AB09", "AB10"],
            root.keys.AB11 ? ["AB11", ["RTSH", 1.75]] : [["RTSH", 2.75]]),
        [["LCTL", 1.25], ["LWIN", 1.25], ["LALT", 1.25], ["SPCE", 6.25], ["RALT", 1.25], ["RWIN", 1.25], ["MENU", 1.25], ["RCTL", 1.25]]
    ]
    readonly property var block: [
        ["PRSC", 0, 0], ["INS", 0, 1], ["HOME", 1, 1], ["PGUP", 2, 1], ["DELE", 0, 2], ["END", 1, 2], ["PGDN", 2, 2],
        ["UP", 1, 4], ["LEFT", 0, 5], ["DOWN", 1, 5], ["RGHT", 2, 5]
    ]
    readonly property real wide: 18.25
    // Every key once, placed: a model of plain objects (nested arrays reach a delegate as lists, not JS arrays).
    readonly property var caps: {
        const out = []
        root.rows.forEach((row, line) => {
            let at = 0
            row.forEach(cap => {
                const code = Array.isArray(cap) ? cap[0] : cap
                const span = Array.isArray(cap) ? cap[1] : 1
                if (code.length > 0) out.push({ code: code, span: span, line: line, at: at })
                at += span
            })
        })
        root.block.forEach(cap => out.push({ code: cap[0], span: 1, line: cap[2], at: 15.25 + cap[1] }))
        return out
    }
    readonly property var named: ({
        BKSP: { glyph: "backspace" }, TAB: { glyph: "keyboard_tab" }, CAPS: { glyph: "keyboard_capslock" },
        RTRN: { glyph: "keyboard_return" }, LFSH: { glyph: "shift" }, RTSH: { glyph: "shift" }, MENU: { glyph: "menu" },
        UP: { glyph: "keyboard_arrow_up" }, DOWN: { glyph: "keyboard_arrow_down" }, LEFT: { glyph: "keyboard_arrow_left" },
        RGHT: { glyph: "keyboard_arrow_right" },
        LCTL: { text: Translation.tr("Ctrl") }, RCTL: { text: Translation.tr("Ctrl") }, LALT: { text: Translation.tr("Alt") },
        RALT: { text: Translation.tr("AltGr") }, LWIN: { text: Translation.tr("Super") }, RWIN: { text: Translation.tr("Super") },
        ESC: { text: Translation.tr("Esc") }, PRSC: { text: Translation.tr("PrtSc") }, INS: { text: Translation.tr("Ins") },
        HOME: { text: Translation.tr("Home") }, PGUP: { text: Translation.tr("PgUp") }, DELE: { text: Translation.tr("Del") },
        END: { text: Translation.tr("End") }, PGDN: { text: Translation.tr("PgDn") }
    })
    function sayOf(code: string): string {
        if (/^FK\d\d$/.test(code)) return "F" + Number(code.slice(2))
        const levels = root.keys[code] ?? []
        const base = String(levels[0] ?? "")
        return String(root.named[code]?.text ?? (base.length > 0 && base.toUpperCase() === String(levels[1] ?? "") ? levels[1] : base))
    }
    readonly property var codeOf: {
        const out = {}
        for (const name of Object.keys(root.codes)) out[root.codes[name]] = name
        return out
    }

    width: parent ? parent.width : 0
    spacing: Math.round(16 * root.d)

    // The layers a press shows: what the keys type, then each set of modifiers the binds use, with how many keys it has.
    Flow {
        width: root.width
        spacing: Math.round(6 * root.d)
        visible: root.layers.length > 0 && Object.keys(root.keys).length > 0
        IrisButton {
            text: Translation.tr("What keys type")
            selected: !root.doing
            quiet: root.doing
            onClicked: { root.held = []; root.picked = ""; root.moving = null }
        }
        Repeater {
            model: root.layers
            delegate: IrisButton {
                required property var modelData
                text: modelData.mods.map(mod => root.nameOf(mod)).join(" + ") + "  " + modelData.count
                selected: root.sameLayer(modelData.mods)
                quiet: !selected
                onClicked: { root.held = Array.from(modelData.mods); root.picked = "" }
            }
        }
    }

    Item {
        id: board
        readonly property real gap: Math.round(5 * root.d)
        width: Math.min(root.width, Math.round(1060 * root.d))
        readonly property real unit: (board.width + board.gap) / root.wide
        function lineY(line: int): real { return Math.round((line === 0 ? 0 : line + 0.25) * board.unit) }
        height: Math.round(board.unit * 6.25 - board.gap)
        visible: Object.keys(root.keys).length > 0
        activeFocusOnTab: true
        // The keyboard itself: a modifier held shows its layer, a key pressed lights its place and, with modifiers, picks
        // it (a key the compositor binds never reaches here: the compositor runs it).
        Keys.onPressed: event => {
            const code = root.codeOf[event.nativeScanCode] ?? ""
            const mods = []
            if (event.modifiers & Qt.MetaModifier) mods.push(root.modKey === "Super" ? "Mod" : "Super")
            if (event.modifiers & Qt.ControlModifier) mods.push("Ctrl")
            if (event.modifiers & Qt.AltModifier) mods.push(root.modKey === "Alt" ? "Mod" : "Alt")
            if (event.modifiers & Qt.ShiftModifier) mods.push("Shift")
            const lit = Object.assign({}, root.lit)
            if (code.length > 0) lit[code] = true
            root.lit = lit
            if (event.key === Qt.Key_Escape && mods.length === 0) {
                event.accepted = root.picked.length > 0 || root.moving !== null
                root.picked = ""
                root.moving = null
                return
            }
            if (code.length > 0 && !root.modOfCode[code] && mods.length > 0) {
                root.held = mods
                root.pick(code)
            }
            root.pressedMods = mods.length > 0 && root.modOfCode[code] ? mods : []
            event.accepted = true
        }
        Keys.onReleased: event => {
            const code = root.codeOf[event.nativeScanCode] ?? ""
            const lit = Object.assign({}, root.lit)
            delete lit[code]
            root.lit = lit
            if (root.modOfCode[code]) root.pressedMods = []
        }
        onActiveFocusChanged: if (!activeFocus) { root.lit = {}; root.pressedMods = [] }

        Repeater {
            model: root.caps
            delegate: Rectangle {
                id: cap
                required property var modelData
                readonly property string code: String(cap.modelData.code)
                readonly property var levels: root.keys[cap.code] ?? []
                readonly property var special: root.named[cap.code] ?? null
                readonly property bool fn: /^FK\d\d$/.test(cap.code)
                readonly property bool typed: cap.special === null && cap.code !== "SPCE" && !cap.fn
                // A letter shows once, as its capital; a key with two signs shows the shifted one above.
                readonly property string base: String(cap.levels[0] ?? "")
                readonly property string shifted: String(cap.levels[1] ?? "")
                readonly property bool letter: cap.base.length > 0 && cap.base.toUpperCase() === cap.shifted && cap.base !== cap.shifted
                readonly property string third: { const t = String(cap.levels[2] ?? ""); return t !== cap.base && t !== cap.shifted ? t : "" }
                readonly property string mod: String(root.modOfCode[cap.code] ?? "")
                readonly property bool isMod: cap.mod.length > 0
                readonly property bool holding: cap.isMod && root.layerMods.includes(cap.mod)
                readonly property var bind: root.doing && !cap.isMod ? root.bindAt(cap.code) : null
                readonly property bool bound: cap.bind !== null
                // Left iNiR's under this layer: a dot in its corner, as a changed row has.
                readonly property bool changed: root.doing && !cap.isMod && root.changedCount > 0
                    && root.changes[IrisBinds.heldKey(root.layerMods, root.symAt(cap.code))] !== undefined
                readonly property color tint: cap.bound ? IrisStyle.identityColor(IrisBinds.tintOf(String(cap.bind.category ?? ""))) : IrisStyle.fill
                readonly property bool chosen: root.picked === cap.code
                readonly property bool pressedNow: root.lit[cap.code] === true
                // Faces: what it types, or with a layer what it does.
                readonly property bool showTyping: !root.doing || cap.isMod
                x: Math.round(cap.modelData.at * board.unit)
                y: board.lineY(cap.modelData.line)
                width: Math.round(cap.modelData.span * board.unit - board.gap)
                // ISO Enter is one L over two rows: its top reaches down through the gap, its foot meets it square.
                readonly property bool isoTop: root.iso && cap.code === "RTRN" && cap.modelData.line === 2
                readonly property bool isoFoot: root.iso && cap.code === "RTRN" && cap.modelData.line === 3
                height: Math.round(board.unit - board.gap) + (cap.isoTop ? board.gap : 0)
                // A key wears the Design's row corner, never rounder than a small key holds.
                radius: Math.min(IrisStyle.radiusRow, Math.round(board.unit * 0.18))
                bottomRightRadius: cap.isoTop ? 0 : cap.radius
                topRightRadius: cap.isoFoot ? 0 : cap.radius
                topLeftRadius: cap.isoFoot ? 0 : cap.radius
                // Keys that type something stand out; modifiers sit back at half the fill. With a layer, a bound key
                // wears its category's tint; a free one sits back. Held, picked or pressed: the accent.
                readonly property color fill: IrisStyle.fill
                readonly property color quiet: Qt.rgba(cap.fill.r, cap.fill.g, cap.fill.b, cap.fill.a * 0.5)
                readonly property color rest: cap.holding || cap.chosen || cap.pressedNow ? IrisStyle.accent
                    : root.doing ? (cap.bound ? ColorUtils.applyAlpha(cap.tint, IrisStyle.tintWash) : cap.quiet)
                    : cap.typed || cap.code === "SPCE" ? cap.fill : cap.quiet
                color: keyHover.hovered && !cap.holding && !cap.chosen ? ColorUtils.mix(cap.rest, IrisStyle.text, 0.88) : cap.rest
                readonly property color ink: cap.holding || cap.chosen || cap.pressedNow ? IrisStyle.inkOnAccent : IrisStyle.text
                readonly property bool acts: cap.isMod || root.doing && !cap.isoFoot
                HoverHandler {
                    id: keyHover
                    enabled: cap.acts
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: root.hovered = hovered ? cap.code : root.hovered === cap.code ? "" : root.hovered
                }
                TapHandler {
                    enabled: cap.acts
                    onTapped: {
                        board.forceActiveFocus()
                        if (cap.isMod) root.toggle(cap.mod)
                        else root.pick(cap.code)
                    }
                }
                Behavior on color { ColorAnimation { duration: IrisStyle.motionEnabled ? 140 : 0; easing.type: IrisStyle.feedbackEasing } }

                Rectangle {
                    visible: cap.changed && !cap.isoFoot
                    x: parent.width - width - Math.round(5 * root.d)
                    y: Math.round(5 * root.d)
                    width: Math.round(5 * root.d)
                    height: width
                    radius: width / 2
                    color: cap.holding || cap.chosen || cap.pressedNow ? IrisStyle.inkOnAccent : IrisStyle.accent
                }

                // ── What it types
                IrisText {
                    visible: cap.showTyping && cap.typed && !cap.letter && cap.shifted.length > 0 && cap.shifted !== cap.base
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: cap.third.length > 0 ? -Math.round(6 * root.d) : 0
                    y: Math.round(parent.height * 0.12)
                    text: cap.shifted
                    color: IrisStyle.textSecondary
                    font.pixelSize: Math.round(board.unit * 0.24)
                }
                IrisText {
                    visible: cap.showTyping && cap.typed
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: cap.third.length > 0 ? -Math.round(6 * root.d) : 0
                    // By y alone, as the faces below: another layout turns a letter into a two-sign key and back.
                    y: cap.letter || cap.shifted === cap.base || cap.shifted.length === 0 ? Math.round((parent.height - height) / 2) : Math.round(parent.height * 0.48)
                    text: cap.letter ? cap.shifted : cap.base
                    color: cap.ink
                    font.pixelSize: Math.round(board.unit * (cap.letter ? 0.32 : 0.27))
                    font.weight: Font.DemiBold
                }
                // What AltGr types there, small in the corner.
                IrisText {
                    visible: cap.showTyping && cap.typed && cap.third.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(6 * root.d)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(4 * root.d)
                    text: cap.third
                    color: IrisStyle.textTertiary
                    font.pixelSize: Math.round(board.unit * 0.2)
                }
                MaterialSymbol {
                    visible: cap.showTyping && cap.special !== null && String(cap.special?.glyph ?? "").length > 0 && !cap.isoFoot
                    anchors.centerIn: parent
                    text: String(cap.special?.glyph ?? "")
                    iconSize: Math.round(board.unit * 0.34)
                    color: cap.holding ? cap.ink : IrisStyle.textSecondary
                }
                IrisText {
                    visible: cap.showTyping && ((cap.special !== null && String(cap.special?.text ?? "").length > 0) || cap.code === "SPCE" || cap.fn)
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - Math.round(12 * root.d))
                    text: cap.code === "SPCE" ? root.inUse : cap.fn ? root.sayOf(cap.code) : String(cap.special?.text ?? "")
                    color: cap.holding ? cap.ink : IrisStyle.textSecondary
                    font.pixelSize: Math.round(board.unit * 0.22)
                    font.weight: cap.holding ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                // ── What it does: the key's sign over its category's mark, centred; the bind's name is in the inspector
                // under the board (names cut to "Focus work…" on the keys read as noise, 11-14).
                // A key drawn as a mark (Tab, Enter, the arrows) keeps its mark as its sign.
                readonly property string markSign: String(cap.special?.glyph ?? "")
                MaterialSymbol {
                    visible: !cap.showTyping && !cap.isoFoot && cap.markSign.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Placed by y alone: an anchor let go keeps its last place, and a key bound after the drawing
                    // came up kept its sign centred over the mark.
                    y: cap.bound ? Math.round(3 * root.d) : Math.round((parent.height - height) / 2)
                    text: cap.markSign
                    iconSize: Math.round(board.unit * (cap.bound ? 0.22 : 0.3))
                    color: cap.chosen || cap.pressedNow ? cap.ink : cap.bound ? IrisStyle.textSecondary : IrisStyle.textTertiary
                }
                IrisText {
                    visible: !cap.showTyping && !cap.isoFoot && cap.markSign.length === 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: cap.bound ? Math.round(4 * root.d) : Math.round((parent.height - height) / 2)
                    width: Math.min(implicitWidth, parent.width - Math.round(8 * root.d))
                    elide: Text.ElideRight
                    text: cap.code === "SPCE" ? Translation.tr("Space") : root.sayOf(cap.code) || String(cap.special?.text ?? "")
                    color: cap.chosen || cap.pressedNow ? cap.ink : cap.bound ? IrisStyle.textSecondary : IrisStyle.textTertiary
                    font.pixelSize: Math.max(9, Math.round(board.unit * (cap.bound ? 0.2 : 0.24)))
                    font.weight: cap.bound ? Font.Medium : Font.DemiBold
                }
                MaterialSymbol {
                    visible: cap.bound
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(board.unit * 0.1)
                    text: IrisBinds.glyphOf(String(cap.bind?.category ?? ""))
                    iconSize: Math.round(board.unit * 0.36)
                    fill: 1
                    color: cap.chosen || cap.pressedNow ? cap.ink : cap.tint
                }
            }
        }
    }

    // The key under the pointer or picked: what it does, and on a pick how to change it.
    IrisBindInspector {
        id: inspector
        width: root.width
        visible: root.doing && Object.keys(root.keys).length > 0
        map: root
        code: root.picked.length > 0 ? root.picked : root.hovered
        sticky: root.picked.length > 0
    }

    IrisText {
        visible: root.failed.length > 0
        width: root.width
        text: root.failed
        color: IrisStyle.textSecondary
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.WordWrap
    }

    // A key picked on the drawing: a bind being moved lands there, else the key is shown with its bind or as free.
    function pick(code: string): void {
        if (root.moving !== null) {
            const from = root.moving
            const to = IrisBinds.comboOf(root.layerMods, root.symAt(code))
            root.moving = null
            if (to !== from.key_combo && !root.bindAt(code)) {
                const was = String(from.key_combo)
                root.edit([{ combo: to, action: String(from.action_raw ?? ""), options: String(from.options ?? "") }, { combo: was, action: "" }],
                    [root.stateOf(to, null), root.stateOf(was, from)], "moved")
            }
            root.picked = code
            return
        }
        root.picked = root.picked === code ? "" : code
    }
    // Every key whose action left iNiR's, by its combo as a set: { now, was } (either null). Empty until iNiR's binds
    // and the person's binds are both read, so nothing shows as changed before there is something to compare (a
    // config that failed to read said every key of iNiR's had left it).
    readonly property var changes: {
        const now = {}
        const was = {}
        for (const one of NiriKeybinds.allBinds ?? []) {
            const key = IrisBinds.comboKey(one.key_combo, root.modKey)
            if (!one.commented && !(key in now)) now[key] = one
        }
        for (const one of NiriKeybinds.shippedBinds ?? []) {
            const key = IrisBinds.comboKey(one.key_combo, root.modKey)
            if (!one.commented && !(key in was)) was[key] = one
        }
        const out = {}
        if (Object.keys(was).length === 0 || Object.keys(now).length === 0) return out
        for (const key of Object.keys(now).concat(Object.keys(was))) {
            if (key in out) continue
            if (IrisBinds.actionKey(now[key]?.action_raw) !== IrisBinds.actionKey(was[key]?.action_raw)) out[key] = { now: now[key] ?? null, was: was[key] ?? null }
        }
        return out
    }
    readonly property int changedCount: Object.keys(root.changes).length
    // Every changed key back to iNiR's at once: one change, one Ctrl+Z.
    function restoreKeys(): void {
        const list = Object.keys(root.changes).map(key => root.changes[key])
        if (list.length === 0) return
        const comboOf = one => String((one.was ?? one.now).key_combo)
        root.edit(list.map(one => ({ combo: comboOf(one), shipped: true })), list.map(one => root.stateOf(comboOf(one), one.now)), "restored")
    }
    // An older base has no step queue: there each edit is written alone and has no way back.
    readonly property bool canStep: typeof NiriKeybinds.applyBinds === "function"
    // A key as it is now, as a step that writes it back: Umbriel's untouched key goes back by dropping Settings' line.
    function stateOf(combo: string, bind: var): var {
        const own = CompositorConfig.own?.keybinds ?? {}
        if (NiriKeybinds.umbriel && !(combo in own)) return { combo: combo, shipped: true }
        return bind ? { combo: combo, action: String(bind.action_raw ?? ""), options: String(bind.options ?? "") } : { combo: combo, action: "" }
    }
    // One change to the keys, written at once and kept in Settings' history: Ctrl+Z or Undo writes the keys back.
    function edit(steps: var, back: var, say: string): void {
        if (!root.canStep) {
            // One write at a time there: a move saves its new key, then drops the old one.
            const [first, second] = steps
            if (second) moveSaver.from = second.combo
            if (String(first.action ?? "").length > 0) NiriKeybinds.setBind(first.combo, first.action, first.options ?? "")
            else NiriKeybinds.removeBind(first.combo)
            return
        }
        NiriKeybinds.applyBinds(steps)
        IrisOptions.remember({ kind: "binds", key: "binds:" + steps.map(step => step.combo).join(","), at: Date.now(), steps: [],
            glyph: "keyboard", name: steps[0].combo, say: say, back: () => NiriKeybinds.applyBinds(back), again: () => NiriKeybinds.applyBinds(steps) })
    }
    Connections {
        id: moveSaver
        property string from: ""
        target: NiriKeybinds
        enabled: moveSaver.from.length > 0
        function onBindSaved(keyCombo) { NiriKeybinds.removeBindQuietly(moveSaver.from); moveSaver.from = "" }
        function onBindError(message) { moveSaver.from = "" }
    }

    // One tap: the layout in use first, then the person's country's and the US ones.
    readonly property var choices: {
        const now = root.layouts.find(entry => root.wearing(entry))
        const list = now ? [now] : []
        root.suggested.forEach(entry => { if (!list.some(one => one.layout === entry.layout && one.variant === entry.variant)) list.push(entry) })
        return list
    }
    Flow {
        width: root.width
        spacing: Math.round(8 * root.d)
        visible: root.choosing && root.choices.length > 0
        Repeater {
            model: root.choices
            delegate: IrisButton {
                required property var modelData
                text: modelData.name
                selected: root.wearing(modelData)
                onClicked: root.wear(modelData)
            }
        }
    }

    // Any other, found by its name in the person's language or by its code.
    IrisField {
        id: find
        visible: root.choosing
        width: Math.min(root.width, Math.round(420 * root.d))
        implicitHeight: Math.round(36 * root.d)
        font.pixelSize: IrisStyle.typeLabel
        placeholderText: Translation.tr("Find a layout by its name")
    }
    Flow {
        readonly property string asked: find.text.trim().toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
        // A name with a word that starts as typed comes before one that only holds it ("port": Portuguese, then sUPPORT).
        readonly property var found: {
            if (asked.length < 2) return []
            const plain = text => text.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
            const scored = []
            root.layouts.forEach((entry, index) => {
                const name = plain(entry.name)
                const score = entry.layout === asked || `${entry.layout}(${entry.variant})` === asked ? 0
                    : name.startsWith(asked) ? 1 : name.split(/[\s(),.\/-]+/).some(word => word.startsWith(asked)) ? 2
                    : name.includes(asked) ? 3 : -1
                if (score >= 0) scored.push({ entry: entry, score: score, index: index })
            })
            // Ties: a whole layout before its variants, then xkeyboard-config's own order (V4's sort is not stable).
            const rank = one => one.score * 2 + (one.entry.variant.length > 0 ? 1 : 0)
            return scored.sort((a, b) => rank(a) - rank(b) || a.index - b.index).slice(0, 12).map(one => one.entry)
        }
        visible: root.choosing && found.length > 0
        width: root.width
        spacing: Math.round(8 * root.d)
        Repeater {
            model: parent.found
            delegate: IrisButton {
                required property var modelData
                text: modelData.name
                selected: root.wearing(modelData)
                onClicked: root.wear(modelData)
            }
        }
    }
}
