import QtQuick
import QtTest
import "../editor"

TestCase {
    id: tc
    name: "RichEditor"
    width: 520
    height: 400
    visible: true
    when: windowShown

    RichEditor {
        id: ed
        width: 500
        height: 380
        pixelSize: 16
    }

    function fresh(md) {
        ed.rawMode = false;
        ed.load(md || "");
        ed.edit.forceActiveFocus();
        ed.edit.cursorPosition = ed.edit.length;
        wait(20);
    }
    function type(s) {
        for (let i = 0; i < s.length; i++) { keyClick(s[i]); wait(3); }
        wait(30);
    }
    function md() { return ed.markdown().replace(/\n+$/, "") }

    function test_heading_shortcut_from_keys() {
        fresh("");
        type("# Title");
        compare(md(), "# Title");
        keyClick(Qt.Key_Return);
        type("body");
        compare(md(), "# Title\n\nbody");
        verify(md().indexOf("**") < 0);
    }
    function test_list_shortcuts_and_enter() {
        fresh("");
        type("- one");
        keyClick(Qt.Key_Return);
        type("two");
        compare(md(), "- one\n- two");
        keyClick(Qt.Key_Return);
        keyClick(Qt.Key_Return);
        type("after");
        compare(md(), "- one\n- two\n\nafter");
        fresh("");
        type("1. a");
        keyClick(Qt.Key_Return);
        type("b");
        verify(/^1\.\s+a\n\d\.\s+b$/.test(md()));
        fresh("");
        type("[] t");
        compare(md(), "- [ ] t");
        keyClick(Qt.Key_Return);
        type("u");
        compare(md(), "- [ ] t\n- [ ] u");
    }
    function test_shortcut_when_the_text_arrives_together() {
        fresh("");
        keyClick("#"); keyClick("#"); keyClick("#"); keyClick(" ");
        wait(50);
        compare(md(), "");
        type("t");
        compare(md(), "### t");
        fresh("x");
        keyClick(Qt.Key_Return);
        keyClick("-"); keyClick(" ");
        wait(50);
        type("t");
        compare(md(), "x\n\n- t");
    }
    function test_inline_styles_on_selection_keep_other_styles() {
        fresh("abc def ghi");
        ed.edit.select(0, 3);
        ed.toggleInline("bold");
        compare(md(), "**abc** def ghi");
        ed.edit.select(0, 7);
        ed.toggleInline("italic");
        verify(md().indexOf("**") >= 0 && md().indexOf("def") > 0);
        ed.edit.select(0, 7);
        ed.toggleInline("italic");
        compare(md(), "**abc** def ghi");
        ed.edit.select(0, 3);
        ed.toggleInline("bold");
        compare(md(), "abc def ghi");
    }
    function test_pending_style_applies_to_typed_text() {
        fresh("");
        ed.toggleInline("bold");
        verify(ed.fmt.bold);
        type("ab");
        compare(md(), "**ab**");
        ed.toggleInline("bold");
        type("cd");
        compare(md(), "**ab**cd");
    }
    function test_undo_redo() {
        fresh("one");
        type(" two");
        ed.flushHistory();
        ed.block("h1");
        compare(md(), "# one two");
        ed.undo();
        compare(md(), "one two");
        ed.undo();
        compare(md(), "one");
        ed.redo();
        compare(md(), "one two");
        ed.redo();
        compare(md(), "# one two");
    }
    function test_task_box_click_toggles_and_counts_as_an_edit() {
        fresh("- [ ] a");
        const edits = [];
        ed.edited.connect(() => edits.push(1));
        const r = ed.edit.positionToRectangle(0);
        mouseClick(ed.edit, r.x - 8, r.y + r.height / 2);
        wait(50);
        compare(md(), "- [x] a");
        verify(edits.length > 0);
    }
    function test_keys() {
        fresh("abc");
        ed.edit.select(0, 3);
        keyClick(Qt.Key_B, Qt.ControlModifier);
        compare(md(), "**abc**");
        keyClick(Qt.Key_2, Qt.ControlModifier);
        compare(md(), "## abc");
        keyClick(Qt.Key_0, Qt.ControlModifier);
        compare(md(), "abc");
        keyClick(Qt.Key_8, Qt.ControlModifier | Qt.ShiftModifier);
        compare(md(), "- abc");
        keyClick(Qt.Key_Z, Qt.ControlModifier);
        compare(md(), "abc");
    }
}
