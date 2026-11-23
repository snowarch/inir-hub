pragma ComponentBehavior: Bound

// The note editor: a rich text view of a Markdown document, like a word processor, with the Markdown mode beside it.
// Qt keeps the document and writes it back as Markdown; inline styles go through the selection, and block kinds
// (headings, lists, code) are edited as Markdown around a marker and loaded again. It imports nothing from the shell,
// so the tests drive the real thing with a bare window.

import QtQuick
import QtQuick.Controls
import "../logic/MdOps.js" as Md

Item {
    id: root

    property color ink: palette.windowText
    property color muted: palette.mid
    property color selection: palette.highlight
    property color selectionInk: palette.highlightedText
    property color linkInk: palette.link
    // Qt writes text set in a fixed-pitch font as inline code, so a family that is one falls back to the system sans.
    property string fontFamily: "sans-serif"
    property string monoFamily: "monospace"
    property int pixelSize: 16
    property int margin: 24
    property bool rawMode: false
    property bool readOnly: false

    readonly property alias edit: rich
    readonly property alias raw: plain
    readonly property alias flick: flick
    // Styles of the text at the caret, or the ones the next typed text will get.
    property var fmt: ({ bold: false, italic: false, strikeout: false })
    property var pending: ({})
    property var snaps: []
    property int at: -1
    property bool busy: false
    property int lastLength: 0
    property string safeFamily: "sans-serif"

    function fitFamily(): void {
        probe.font.family = root.fontFamily;
        root.safeFamily = probe.text.charAt(0) === "`" ? "sans-serif" : root.fontFamily;
    }
    onFontFamilyChanged: root.fitFamily()
    Component.onCompleted: root.fitFamily()
    TextEdit { id: probe; visible: false; textFormat: TextEdit.MarkdownText; text: "x" }

    signal edited()
    signal linkRequested()
    signal zoomStep(int direction)

    function load(md: string): void {
        root.busy = true;
        rich.text = md;
        plain.text = md;
        root.busy = false;
        root.pending = ({});
        root.lastLength = rich.length;
        root.snaps = [];
        root.at = -1;
        root.snap();
        root.syncFormat();
    }
    function markdown(): string { return root.rawMode ? plain.text : rich.text }
    function focusEditor(): void { (root.rawMode ? plain : rich).forceActiveFocus() }
    function setRaw(on: bool): void {
        if (on === root.rawMode) return;
        root.flushHistory();
        root.busy = true;
        if (on) plain.text = rich.text;
        else rich.text = plain.text;
        root.busy = false;
        root.rawMode = on;
        root.pending = ({});
        root.lastLength = rich.length;
        if (!on) root.snap();
        root.focusEditor();
    }

    // History: snapshots of the Markdown, taken a moment after typing stops and before every structural change.
    function snap(): void {
        const md = rich.text;
        if (root.at >= 0 && root.snaps[root.at].md === md) return;
        const kept = root.snaps.slice(Math.max(0, root.at - 98), root.at + 1);
        kept.push({ md: md, cursor: rich.cursorPosition });
        root.snaps = kept;
        root.at = kept.length - 1;
    }
    function flushHistory(): void {
        if (!history.running) return;
        history.stop();
        root.snap();
    }
    function restore(): void {
        root.busy = true;
        rich.text = root.snaps[root.at].md;
        rich.cursorPosition = Math.min(root.snaps[root.at].cursor, rich.length);
        root.busy = false;
        root.lastLength = rich.length;
        root.syncFormat();
        root.edited();
    }
    function undo(): void {
        if (root.rawMode) { plain.undo(); return; }
        root.flushHistory();
        if (root.at <= 0) return;
        root.at--;
        root.restore();
    }
    function redo(): void {
        if (root.rawMode) { plain.redo(); return; }
        if (root.at >= root.snaps.length - 1) return;
        root.at++;
        root.restore();
    }
    Timer { id: history; interval: 600; onTriggered: root.snap() }

    // TextEdit.insert() drops the block's list or heading when it lands at the start of the document: insert as the selection.
    function put(pos: int, text: string): void {
        rich.select(pos, pos);
        rich.cursorSelection.text = text;
    }
    // The caret (and the selection) as markers in the Markdown, changed by fn, and put back where they landed.
    function withMarks(both: bool, fn: var): void {
        root.busy = true;
        const s = rich.selectionStart;
        const e = rich.selectionEnd;
        if (s !== e) { root.put(e, Md.B); root.put(s, Md.A); }
        else root.put(s, both ? Md.A + Md.B : Md.A);
        root.loadMarked(fn(rich.text));
    }
    // Load Markdown that holds the markers, take them out and put the caret (or the selection) where they were.
    function loadMarked(md: string): void {
        rich.text = md;
        const text = rich.getText(0, rich.length);
        const ia = text.indexOf(Md.A);
        const ib = text.indexOf(Md.B);
        if (ib >= 0) rich.remove(ib, ib + 1);
        if (ia >= 0) rich.remove(ia, ia + 1);
        if (ia >= 0 && ib >= 0 && ib - 1 > ia) rich.select(ia, ib - 1);
        else if (ia >= 0) rich.cursorPosition = ia;
        root.busy = false;
        root.lastLength = rich.length;
        root.pending = ({});
        root.syncFormat();
        root.edited();
    }
    function block(kind: string): void {
        if (root.rawMode) return;
        root.flushHistory();
        root.withMarks(false, md => Md.setBlock(md, kind));
        root.snap();
    }
    function inlineCode(): void {
        root.flushHistory();
        root.withMarks(true, md => Md.wrapInline(md, "code", ""));
        root.snap();
    }
    function link(url: string): void {
        root.flushHistory();
        root.withMarks(true, md => Md.wrapInline(md, "link", url));
        root.snap();
    }

    // Bold, italic or strikeout over the selection, one character at a time so mixed text keeps what else it has.
    function toggleInline(prop: string): void {
        if (root.rawMode) return;
        const s = rich.selectionStart;
        const e = rich.selectionEnd;
        if (s === e) {
            const next = Object.assign({}, root.pending);
            next[prop] = !root.fmt[prop];
            root.pending = next;
            root.syncFormat();
            return;
        }
        root.flushHistory();
        rich.select(s, s + 1);
        const on = !rich.cursorSelection.font[prop];
        root.styleRange(s, e, prop, on);
        rich.select(s, e);
        root.syncFormat();
        root.snap();
        root.edited();
    }
    function styleRange(from: int, to: int, prop: string, on: bool): void {
        root.busy = true;
        const cs = rich.cursorSelection;
        for (let i = from; i < to; i++) {
            rich.select(i, i + 1);
            const f = cs.font;
            if (f[prop] === on) continue;
            f[prop] = on;
            cs.font = f;
        }
        root.busy = false;
    }
    function syncFormat(): void {
        const f = rich.cursorSelection.font;
        const p = root.pending;
        root.fmt = {
            bold: p.bold !== undefined ? p.bold : f.bold,
            italic: p.italic !== undefined ? p.italic : f.italic,
            strikeout: p.strikeout !== undefined ? p.strikeout : f.strikeout
        };
    }

    // Typed text takes the styles chosen at the caret; a block shortcut ("# ", "- ", "1. ", "[] ") turns the block.
    function typed(): void {
        const grew = rich.length - root.lastLength;
        root.lastLength = rich.length;
        const p = rich.cursorPosition;
        if (grew > 0 && Object.keys(root.pending).length > 0 && p >= grew) {
            const keep = root.pending;
            root.pending = ({});
            for (const k in keep) root.styleRange(p - grew, p, k, keep[k]);
            rich.cursorPosition = p;
            root.syncFormat();
        }
        if (grew > 0) shortcut.restart();
        history.restart();
        root.edited();
    }
    Timer {
        id: shortcut
        interval: 0
        onTriggered: {
            const p = rich.cursorPosition;
            if (rich.selectionStart !== rich.selectionEnd || p < 2 || rich.getText(p - 1, p) !== " ") return;
            const hit = Md.shortcutOf(rich.getText(Math.max(0, p - 5), p), p <= 5);
            if (!hit) return;
            root.busy = true;
            rich.remove(p - hit.length, p);
            root.busy = false;
            root.block(hit.kind);
        }
    }

    function enter(): bool {
        const p = rich.cursorPosition;
        if (rich.selectionStart !== rich.selectionEnd) return false;
        const before = rich.getText(0, p);
        const lead = before.slice(before.lastIndexOf("\u2029") + 1);
        if (Md.fenceTyped(lead) && (p === rich.length || rich.getText(p, p + 1) === "\u2029")) {
            root.busy = true;
            rich.remove(p - 3, p);
            root.busy = false;
            root.block("code");
            return true;
        }
        root.flushHistory();
        root.busy = true;
        root.put(p, Md.A);
        const out = Md.enterEdit(rich.text);
        if (out === null) {
            rich.remove(p, p + 1);
            rich.cursorPosition = p;
            root.busy = false;
            return false;
        }
        root.loadMarked(out);
        root.snap();
        return true;
    }

    function handleKey(event: var): bool {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        const k = event.key;
        if (!ctrl) return (k === Qt.Key_Return || k === Qt.Key_Enter) && !shift && root.enter();
        if (k === Qt.Key_B) root.toggleInline("bold");
        else if (k === Qt.Key_I) root.toggleInline("italic");
        else if (k === Qt.Key_X && shift) root.toggleInline("strikeout");
        else if (k === Qt.Key_E) root.inlineCode();
        else if (k === Qt.Key_K) root.linkRequested();
        else if (k === Qt.Key_Z && !shift) root.undo();
        else if ((k === Qt.Key_Z && shift) || k === Qt.Key_Y) root.redo();
        else if (!shift && k >= Qt.Key_0 && k <= Qt.Key_3) root.block(k === Qt.Key_0 ? "p" : "h" + (k - Qt.Key_0));
        else if (shift && (k === Qt.Key_7 || k === Qt.Key_Ampersand)) root.block("ol");
        else if (shift && (k === Qt.Key_8 || k === Qt.Key_Asterisk)) root.block("ul");
        else if (shift && (k === Qt.Key_9 || k === Qt.Key_ParenLeft)) root.block("task");
        else return false;
        return true;
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: Math.max(height, (root.rawMode ? plain.implicitHeight : rich.implicitHeight))
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: 6
                radius: width / 2
                color: root.muted
                opacity: 0.6
            }
        }
        function ensure(rect: rect): void {
            const pad = rect.height;
            if (rect.y - pad < flick.contentY) flick.contentY = Math.max(0, rect.y - pad);
            else if (rect.y + rect.height + pad > flick.contentY + flick.height) flick.contentY = rect.y + rect.height + pad - flick.height;
        }

        TextEdit {
            id: rich
            width: flick.width
            height: Math.max(implicitHeight, flick.height)
            visible: !root.rawMode
            textFormat: TextEdit.MarkdownText
            wrapMode: TextEdit.Wrap
            readOnly: root.readOnly
            selectByMouse: true
            persistentSelection: true
            color: root.ink
            selectionColor: root.selection
            selectedTextColor: root.selectionInk
            font.family: root.safeFamily
            font.pixelSize: root.pixelSize
            leftPadding: root.margin
            rightPadding: root.margin
            topPadding: root.margin / 2
            bottomPadding: root.margin
            onTextChanged: if (!root.busy) root.typed()
            onCursorPositionChanged: if (!root.busy) { root.syncFormat(); flick.ensure(rich.cursorRectangle); }
            Keys.onPressed: event => { event.accepted = root.handleKey(event) }
        }
        TextEdit {
            id: plain
            width: flick.width
            height: Math.max(implicitHeight, flick.height)
            visible: root.rawMode
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            readOnly: root.readOnly
            selectByMouse: true
            persistentSelection: true
            color: root.ink
            selectionColor: root.selection
            selectedTextColor: root.selectionInk
            font.family: root.monoFamily
            font.pixelSize: root.pixelSize
            leftPadding: root.margin
            rightPadding: root.margin
            topPadding: root.margin / 2
            bottomPadding: root.margin
            onTextChanged: if (root.rawMode) root.edited()
            onCursorRectangleChanged: if (root.rawMode) flick.ensure(plain.cursorRectangle)
        }
    }
    WheelHandler {
        acceptedModifiers: Qt.ControlModifier
        onWheel: event => root.zoomStep(event.angleDelta.y > 0 ? 1 : -1)
    }
}
