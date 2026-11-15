pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Keyboard: the keyboard drawn with what each key types in the layout in use (read from libxkbcommon by
// keymap.py, the same keymap the compositor builds), the space bar saying the layout's name; under it the layouts for
// the person's country as one tap each, and every other layout found by its name in their language. Raell Tech's page
// (his 11-14) is where it comes from; the raw XKB fields stay below it for what a tap cannot say.
Column {
    id: root

    property var spec: ({})
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

    // Rows in key units (an ANSI board is 15 wide). ISO: the key beside left Shift, Enter two rows tall.
    readonly property var rows: [
        ["TLDE", "AE01", "AE02", "AE03", "AE04", "AE05", "AE06", "AE07", "AE08", "AE09", "AE10", "AE11", "AE12", ["BKSP", 2]],
        [["TAB", 1.5], "AD01", "AD02", "AD03", "AD04", "AD05", "AD06", "AD07", "AD08", "AD09", "AD10", "AD11", "AD12", root.iso ? ["RTRN", 1.5] : ["BKSL", 1.5]],
        [["CAPS", 1.75], "AC01", "AC02", "AC03", "AC04", "AC05", "AC06", "AC07", "AC08", "AC09", "AC10", "AC11"].concat(root.iso ? ["BKSL", ["RTRN", 1.25]] : [["RTRN", 2.25]]),
        [["LFSH", root.iso ? 1.25 : 2.25]].concat(root.iso ? ["LSGT"] : [], ["AB01", "AB02", "AB03", "AB04", "AB05", "AB06", "AB07", "AB08", "AB09", "AB10"],
            root.keys.AB11 ? ["AB11", ["RTSH", 1.75]] : [["RTSH", 2.75]]),
        [["LCTL", 1.25], ["LWIN", 1.25], ["LALT", 1.25], ["SPCE", 6.25], ["RALT", 1.25], ["RWIN", 1.25], ["MENU", 1.25], ["RCTL", 1.25]]
    ]
    // Every key once, placed: a model of plain objects (nested arrays reach a delegate as lists, not JS arrays).
    readonly property var caps: {
        const out = []
        root.rows.forEach((row, line) => {
            let at = 0
            row.forEach(cap => {
                const code = Array.isArray(cap) ? cap[0] : cap
                const span = Array.isArray(cap) ? cap[1] : 1
                out.push({ code: code, span: span, line: line, at: at })
                at += span
            })
        })
        return out
    }
    readonly property var named: ({
        BKSP: { glyph: "backspace" }, TAB: { glyph: "keyboard_tab" }, CAPS: { glyph: "keyboard_capslock" },
        RTRN: { glyph: "keyboard_return" }, LFSH: { glyph: "shift" }, RTSH: { glyph: "shift" }, MENU: { glyph: "menu" },
        LCTL: { text: Translation.tr("Ctrl") }, RCTL: { text: Translation.tr("Ctrl") }, LALT: { text: Translation.tr("Alt") },
        RALT: { text: Translation.tr("AltGr") }, LWIN: { text: Translation.tr("Super") }, RWIN: { text: Translation.tr("Super") }
    })

    width: parent ? parent.width : 0
    spacing: Math.round(16 * root.d)

    Item {
        id: board
        readonly property real gap: Math.round(5 * root.d)
        width: Math.min(root.width, Math.round(900 * root.d))
        readonly property real unit: (board.width + board.gap) / 15
        height: Math.round(board.unit * 5 - board.gap)
        visible: Object.keys(root.keys).length > 0
        Repeater {
            model: root.caps
            delegate: Rectangle {
                id: cap
                required property var modelData
                readonly property string code: String(cap.modelData.code)
                readonly property var levels: root.keys[cap.code] ?? []
                readonly property var special: root.named[cap.code] ?? null
                readonly property bool typed: cap.special === null && cap.code !== "SPCE"
                // A letter shows once, as its capital; a key with two signs shows the shifted one above.
                readonly property string base: String(cap.levels[0] ?? "")
                readonly property string shifted: String(cap.levels[1] ?? "")
                readonly property bool letter: cap.base.length > 0 && cap.base.toUpperCase() === cap.shifted && cap.base !== cap.shifted
                readonly property string third: { const t = String(cap.levels[2] ?? ""); return t !== cap.base && t !== cap.shifted ? t : "" }
                x: Math.round(cap.modelData.at * board.unit)
                y: Math.round(cap.modelData.line * board.unit)
                width: Math.round(cap.modelData.span * board.unit - board.gap)
                // ISO Enter is one L over two rows: its top reaches down through the gap, its foot meets it square.
                readonly property bool isoTop: root.iso && cap.code === "RTRN" && cap.modelData.line === 1
                readonly property bool isoFoot: root.iso && cap.code === "RTRN" && cap.modelData.line === 2
                height: Math.round(board.unit - board.gap) + (cap.isoTop ? board.gap : 0)
                // A key wears the Design's row corner, never rounder than a small key holds.
                radius: Math.min(IrisStyle.radiusRow, Math.round(board.unit * 0.18))
                bottomRightRadius: cap.isoTop ? 0 : cap.radius
                topRightRadius: cap.isoFoot ? 0 : cap.radius
                topLeftRadius: cap.isoFoot ? 0 : cap.radius
                // Keys that type something stand out; modifiers sit back at half the fill.
                readonly property color fill: IrisStyle.fill
                color: cap.typed || cap.code === "SPCE" ? cap.fill : Qt.rgba(cap.fill.r, cap.fill.g, cap.fill.b, cap.fill.a * 0.5)
                IrisText {
                    visible: cap.typed && !cap.letter && cap.shifted.length > 0 && cap.shifted !== cap.base
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: cap.third.length > 0 ? -Math.round(6 * root.d) : 0
                    y: Math.round(parent.height * 0.12)
                    text: cap.shifted
                    color: IrisStyle.textSecondary
                    font.pixelSize: Math.round(board.unit * 0.24)
                }
                IrisText {
                    visible: cap.typed
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.horizontalCenterOffset: cap.third.length > 0 ? -Math.round(6 * root.d) : 0
                    anchors.verticalCenter: cap.letter || cap.shifted === cap.base || cap.shifted.length === 0 ? parent.verticalCenter : undefined
                    y: Math.round(parent.height * 0.48)
                    text: cap.letter ? cap.shifted : cap.base
                    color: IrisStyle.text
                    font.pixelSize: Math.round(board.unit * (cap.letter ? 0.32 : 0.27))
                    font.weight: Font.DemiBold
                }
                // What AltGr types there, small in the corner.
                IrisText {
                    visible: cap.typed && cap.third.length > 0
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(6 * root.d)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Math.round(4 * root.d)
                    text: cap.third
                    color: IrisStyle.textTertiary
                    font.pixelSize: Math.round(board.unit * 0.2)
                }
                MaterialSymbol {
                    visible: cap.special !== null && String(cap.special?.glyph ?? "").length > 0 && !cap.isoFoot
                    anchors.centerIn: parent
                    text: String(cap.special?.glyph ?? "")
                    iconSize: Math.round(board.unit * 0.34)
                    color: IrisStyle.textSecondary
                }
                IrisText {
                    visible: (cap.special !== null && String(cap.special?.text ?? "").length > 0) || cap.code === "SPCE"
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - Math.round(12 * root.d))
                    text: cap.code === "SPCE" ? root.inUse : String(cap.special?.text ?? "")
                    color: IrisStyle.textSecondary
                    font.pixelSize: Math.round(board.unit * 0.22)
                    elide: Text.ElideRight
                }
            }
        }
    }

    IrisText {
        visible: root.failed.length > 0
        width: root.width
        text: root.failed
        color: IrisStyle.textSecondary
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.WordWrap
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
        visible: root.choices.length > 0
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
        visible: found.length > 0
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
