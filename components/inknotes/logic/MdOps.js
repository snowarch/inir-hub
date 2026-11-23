.pragma library

// Markdown edits for the rich editor. The editor marks the caret with A and the end of a selection with B (private-use
// characters it inserts into the document), reads the Markdown Qt writes, hands it to one of these functions and loads
// the result again. Nothing here touches Qt: every function takes and returns strings.

var A = "\uE000";
var B = "\uE001";
var TOGGLES = { ul: true, ol: true, task: true, code: true };

function strip(s) { return s.split(A).join("").split(B).join(""); }

function kindOf(line) {
    var s = strip(line);
    var m = /^(#{1,6}) /.exec(s);
    if (m) return "h" + Math.min(3, m[1].length);
    if (/^[-*+] \[[ xX]\] ?/.test(s)) return "task";
    if (/^[-*+] /.test(s)) return "ul";
    if (/^\d+[.)] /.test(s)) return "ol";
    return "p";
}

function bodyOf(line) {
    return line.replace(/^(#{1,6} |[-*+] \[[ xX]\] |[-*+] |\d+[.)] +)/, "");
}

// Lines to units: a fenced block is one unit, a blank line separates and is dropped, an indented line continues.
function parseUnits(lines) {
    var units = [];
    for (var i = 0; i < lines.length; i++) {
        var l = lines[i];
        if (/^\s*(```|~~~)/.test(l)) {
            var inner = [];
            i++;
            while (i < lines.length && !/^\s*(```|~~~)\s*$/.test(lines[i])) inner.push(lines[i++]);
            units.push({ t: "fence", inner: inner });
        } else if (l.trim() === "") {
            continue;
        } else {
            units.push({ t: "line", line: l, cont: /^\s+\S/.test(l) && units.length > 0 });
        }
    }
    return units;
}

function unitText(u) { return u.t === "fence" ? u.inner.join("\n") : u.line; }
function unitKind(u) { return u.t === "fence" ? "code" : kindOf(u.line); }
function sameList(a, b) {
    return (a === "ol" && b === "ol") || ((a === "ul" || a === "task") && (b === "ul" || b === "task"));
}

function join(units) {
    var out = [];
    var prev = "";
    units.forEach(function (u) {
        var k = unitKind(u);
        if (out.length > 0 && !u.cont && !sameList(prev, k)) out.push("");
        if (u.t === "fence") out.push.apply(out, ["```"].concat(u.inner, ["```"]));
        else out.push(u.line);
        prev = k;
    });
    return out.join("\n");
}

function indexOfMark(units, ch) {
    for (var i = 0; i < units.length; i++) if (unitText(units[i]).indexOf(ch) >= 0) return i;
    return -1;
}

function convert(line, target) {
    var body = bodyOf(line);
    var checked = /^[-*+] \[[xX]\]/.test(strip(line));
    switch (target) {
    case "h1": return "# " + body;
    case "h2": return "## " + body;
    case "h3": return "### " + body;
    case "ul": return "- " + body;
    case "ol": return "1. " + body;
    case "task": return "- [" + (checked ? "x" : " ") + "] " + body;
    default: return body;
    }
}

// Give the blocks from the caret (A) to the end of the selection (B) a kind: p, h1-h3, ul, ol, task or code.
// Asking for a list or code kind the whole selection already has turns it back into paragraphs.
function setBlock(md, kind) {
    var units = parseUnits(md.split("\n"));
    var a = indexOfMark(units, A);
    if (a < 0) return md;
    var b = Math.max(a, indexOfMark(units, B));
    var sel = units.slice(a, b + 1);
    var target = TOGGLES[kind] && sel.every(function (u) { return unitKind(u) === kind; }) ? "p" : kind;
    var lines = [];
    sel.forEach(function (u) { if (u.t === "fence") lines.push.apply(lines, u.inner); else lines.push(u.line); });
    var made = target === "code"
        ? [{ t: "fence", inner: lines }]
        : lines.map(function (l) { return { t: "line", line: convert(l, target), cont: false }; });
    return join(units.slice(0, a).concat(made, units.slice(b + 1)));
}

// What Enter does when the plain editor would do the wrong thing, or null to leave it to the editor.
function enterEdit(md) {
    var units = parseUnits(md.split("\n"));
    var i = indexOfMark(units, A);
    if (i < 0) return null;
    var u = units[i];
    var made;
    if (u.t === "fence") {
        var j = u.inner.indexOf(A);
        if (j < 0) return null;
        made = [];
        if (j > 0) made.push({ t: "fence", inner: u.inner.slice(0, j) });
        made.push({ t: "line", line: A, cont: false });
        if (j < u.inner.length - 1) made.push({ t: "fence", inner: u.inner.slice(j + 1) });
    } else {
        var k = kindOf(u.line);
        if (k === "p") return null;
        var body = bodyOf(u.line);
        var prefix = u.line.slice(0, u.line.length - body.length);
        var at = body.indexOf(A);
        var before = body.slice(0, at);
        var after = body.slice(at + 1);
        if (k !== "ul" && k !== "ol" && k !== "task") {
            made = [{ t: "line", line: prefix + before, cont: false }, { t: "line", line: A + after, cont: false }];
        } else if (strip(body) === "") {
            made = [{ t: "line", line: A, cont: false }];
        } else {
            var next = k === "task" ? "- [ ] " : k === "ol" ? "1. " : prefix;
            made = [{ t: "line", line: prefix + before, cont: false }, { t: "line", line: next + A + after, cont: false }];
        }
    }
    return join(units.slice(0, i).concat(made, units.slice(i + 1)));
}

// Inline code or a link around what lies between A and B (one line). A link with an empty url removes the link.
function wrapInline(md, kind, url) {
    var ia = md.indexOf(A);
    var ib = md.indexOf(B);
    if (ia < 0 || ib < ia) return md;
    var pre = md.slice(0, ia);
    var mid = md.slice(ia + 1, ib);
    var post = md.slice(ib + 1);
    if (mid.indexOf("\n") >= 0) return md;
    // The span of a pattern (a code span, a link) the markers touch, replaced by what make says; null when there is none.
    var span = function (re, make) {
        var hit;
        while ((hit = re.exec(md))) {
            if (hit.index > ib || hit.index + hit[0].length < ia) continue;
            return md.slice(0, hit.index) + make(hit) + md.slice(hit.index + hit[0].length);
        }
        return null;
    };
    if (kind === "code") {
        var off = span(/`([^`]*)`/g, function (h) { return h[1]; });
        return off !== null ? off : pre + "`" + A + mid.replace(/\*\*|~~|\*/g, "") + B + "`" + post;
    }
    var moved = span(/\[([^\]]*)\]\(([^)]*)\)/g, function (h) { return url ? "[" + h[1] + "](" + url + ")" : h[1]; });
    if (moved !== null) return moved;
    if (!url) return md;
    return pre + "[" + A + (mid || url) + B + "](" + url + ")" + post;
}

// What was typed before the caret (up to five characters, "\u2029" between blocks) as a Markdown shortcut: a block kind
// and how many characters to delete, or null. atStart says the window begins at the start of the document.
function shortcutOf(window, atStart) {
    var m = /\u2029(#{1,3}|[-*]|1\.|\[ ?\]) $/.exec((atStart ? "\u2029" : "") + window);
    if (!m) return null;
    var t = m[1];
    var kind = t[0] === "#" ? "h" + t.length : t === "1." ? "ol" : t[0] === "[" ? "task" : "ul";
    return { kind: kind, length: t.length + 1 };
}

// Text from the start of the block to the caret is exactly a code fence typed by hand.
function fenceTyped(blockBefore) { return blockBefore === "```"; }
