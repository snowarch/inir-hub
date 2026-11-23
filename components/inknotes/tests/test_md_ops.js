const assert = require("assert");
const M = require("./load")("MdOps.js");
const { A, B } = M;
let n = 0;
const t = (name, fn) => { fn(); n++; };

t("setBlock heading on caret line", () => {
    assert.equal(M.setBlock("one\n\ntw" + A + "o\n\nthree", "h2"), "one\n\n## tw" + A + "o\n\nthree");
});
t("setBlock list joins neighbours and toggles off", () => {
    const md = "- a\n- b" + A;
    assert.equal(M.setBlock("para\n\n" + A + "x", "ul"), "para\n\n- " + A + "x");
    assert.equal(M.setBlock(md, "ul"), "- a\n\nb" + A);
    assert.equal(M.setBlock("a" + A + "\nb" + B, "ol"), "1. a" + A + "\n1. b" + B);
});
t("setBlock task keeps checked and converts back", () => {
    assert.equal(M.setBlock("- [x] a" + A, "task"), "a" + A);
    assert.equal(M.setBlock("- [x] a" + A, "ul"), "- a" + A);
    assert.equal(M.setBlock("- a" + A, "task"), "- [ ] a" + A);
});
t("setBlock code wraps and unwraps", () => {
    assert.equal(M.setBlock("x" + A, "code"), "```\nx" + A + "\n```");
    assert.equal(M.setBlock("```\nx" + A + "\ny\n```", "code"), "x" + A + "\n\ny");
    assert.equal(M.setBlock("```\nx" + A + "\n```", "h1"), "# x" + A);
});
t("setBlock without a mark changes nothing", () => assert.equal(M.setBlock("a", "h1"), "a"));
t("enter after a heading starts a paragraph", () => {
    assert.equal(M.enterEdit("# Ti" + A + "tle"), "# Ti\n\n" + A + "tle");
    assert.equal(M.enterEdit("# Title" + A), "# Title\n\n" + A);
});
t("enter in lists continues and leaves on an empty item", () => {
    assert.equal(M.enterEdit("- a" + A), "- a\n- " + A);
    assert.equal(M.enterEdit("- [x] a" + A), "- [x] a\n- [ ] " + A);
    assert.equal(M.enterEdit("1. a" + A + "b"), "1. a\n1. " + A + "b");
    assert.equal(M.enterEdit("- a\n- " + A), "- a\n\n" + A);
    assert.equal(M.enterEdit("plain" + A), null);
});
t("enter on an empty code line leaves the block", () => {
    assert.equal(M.enterEdit("```\nx\n" + A + "\n```"), "```\nx\n```\n\n" + A);
    assert.equal(M.enterEdit("```\nx" + A + "\n```"), null);
});
t("wrapInline code and link", () => {
    assert.equal(M.wrapInline("a " + A + "b" + B + " c", "code"), "a `" + A + "b" + B + "` c");
    assert.equal(M.wrapInline("a `" + A + "b" + B + "` c", "code"), "a " + A + "b" + B + " c");
    assert.equal(M.wrapInline("a " + A + "**b**" + B, "code"), "a `" + A + "b" + B + "`");
    assert.equal(M.wrapInline("a " + A + "`b" + B + "` c", "code"), "a " + A + "b" + B + " c");
    assert.equal(M.wrapInline("a " + A + "b" + B, "link", "https://example.com"), "a [" + A + "b" + B + "](https://example.com)");
    assert.equal(M.wrapInline("[" + A + "b" + B + "](https://example.com)", "link", ""), A + "b" + B);
    assert.equal(M.wrapInline("[" + A + "b" + B + "](https://example.com)", "link", "https://example.com/z"), "[" + A + "b" + B + "](https://example.com/z)");
    assert.equal(M.wrapInline("a " + A + B, "link", "https://example.com"), "a [" + A + "https://example.com" + B + "](https://example.com)");
});
t("shortcutOf", () => {
    assert.deepEqual(M.shortcutOf("# ", true), { kind: "h1", length: 2 });
    assert.deepEqual(M.shortcutOf("x\u2029### ", false), { kind: "h3", length: 4 });
    assert.deepEqual(M.shortcutOf("x\u20291. ", false), { kind: "ol", length: 3 });
    assert.deepEqual(M.shortcutOf("\u2029[] ", false), { kind: "task", length: 3 });
    assert.deepEqual(M.shortcutOf("- ", true), { kind: "ul", length: 2 });
    assert.equal(M.shortcutOf("ab- ", false), null);
    assert.equal(M.shortcutOf("ab# ", true), null);
    assert.equal(M.shortcutOf("#### ", true), null);
});
console.log("md ops: " + n + " groups ok");
