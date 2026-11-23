const assert = require("assert");
const L = require("./load")("NotesLogic.js");
let n = 0;
const t = (name, fn) => { fn(); n++; };

t("cleanName", () => {
    [["  My / note.md ", "My note"], [".hidden", ""], ["..", ""], ["   ", ""], ["a".repeat(121), ""], ["Notas del día", "Notas del día"]]
        .forEach(([raw, clean]) => assert.equal(L.cleanName(raw), clean));
});
t("validRoot and rootFor", () => {
    assert.ok(L.validRoot("/home/a/notes"));
    ["notes", "/home/../etc", "/home/a/.trash/x", "/"].forEach(p => assert.ok(!L.validRoot(p), p));
    assert.equal(L.rootFor("documents", "", "/d", "/s"), "/d/inknotes");
    assert.equal(L.rootFor("hidden", "", "/d", "/s"), "/s/inknotes");
    assert.equal(L.rootFor("custom", "/x/y/", "/d", "/s"), "/x/y");
    assert.equal(L.rootFor("custom", "../x", "/d", "/s"), "/d/inknotes");
});
t("parseListing", () => {
    const r = L.parseListing("d\tWork\t1.5\nd\tWork/Deep\t1\nf\tA.md\t100.25\nf\tWork/B.md\t200\nf\t.hid.md\t1\nf\t.x/C.md\t1\nbad\n");
    assert.deepEqual(r.folders, ["Work"]);
    assert.deepEqual(r.notes.map(x => x.rel), ["A.md", "Work/B.md"]);
    assert.equal(r.notes[1].folder, "Work");
    assert.equal(r.notes[0].mtime, 100250);
    assert.equal(r.notes[0].title, "A");
});
t("listNotes filters, searches, sorts, pins first", () => {
    const notes = [{ rel: "a.md", title: "a", folder: "", mtime: 1 }, { rel: "F/b.md", title: "B", folder: "F", mtime: 3 }, { rel: "c.md", title: "c", folder: "", mtime: 2 }];
    const rels = l => l.map(x => x.rel);
    assert.deepEqual(rels(L.listNotes(notes, L.ALL, "", null, "edited", [])), ["F/b.md", "c.md", "a.md"]);
    assert.deepEqual(rels(L.listNotes(notes, L.NONE, "", null, "edited", [])), ["c.md", "a.md"]);
    assert.deepEqual(rels(L.listNotes(notes, L.ALL, "", null, "title", [])), ["a.md", "F/b.md", "c.md"]);
    assert.deepEqual(rels(L.listNotes(notes, L.ALL, "", null, "edited", ["a.md"])), ["a.md", "F/b.md", "c.md"]);
    assert.deepEqual(rels(L.listNotes(notes, L.ALL, "B", null, "edited", [])), ["F/b.md"]);
    assert.deepEqual(rels(L.listNotes(notes, L.ALL, "zzz", ["c.md"], "edited", [])), ["c.md"]);
    assert.equal(L.countIn(notes, L.ALL), 3);
    assert.equal(L.countIn(notes, "F"), 1);
});
t("uniqueTitle", () => {
    assert.equal(L.uniqueTitle("Untitled", []), "Untitled");
    assert.equal(L.uniqueTitle("Untitled", ["untitled"]), "Untitled 2");
    assert.equal(L.uniqueTitle("Untitled", ["Untitled", "Untitled 2"]), "Untitled 3");
});
t("ago", () => {
    const now = new Date(2026, 5, 15, 14, 0, 0).getTime();
    assert.equal(L.ago(now - 5000, now).k, "now");
    assert.deepEqual(L.ago(now - 5 * 60000, now), { k: "min", n: 5 });
    assert.equal(L.ago(new Date(2026, 5, 15, 9, 0).getTime(), now).k, "hour");
    assert.equal(L.ago(new Date(2026, 5, 14, 23, 0).getTime(), now).k, "yesterday");
    assert.equal(L.ago(new Date(2026, 5, 12, 10, 0).getTime(), now).k, "days");
    assert.equal(L.ago(new Date(2026, 4, 1).getTime(), now).k, "date");
});
t("movedKey", () => {
    assert.equal(L.movedKey("A.md", "A.md", "B.md"), "B.md");
    assert.equal(L.movedKey("F/x.md", "F", "G"), "G/x.md");
    assert.equal(L.movedKey("Fx/x.md", "F", "G"), "Fx/x.md");
});
t("trash", () => {
    const r = L.parseTrash("100/A.md\n300/F/B.md\nnonsense\n/x.md");
    assert.deepEqual(r.map(x => x.key), ["300/F/B.md", "100/A.md"]);
    assert.equal(r[0].folder, "F");
    assert.deepEqual(L.expiredEpochs(["1000", "x", "99999999999999"], 100000000, 1), ["1000"]);
    assert.deepEqual(L.expiredEpochs(["1000"], 1e12, 0), []);
    assert.ok(L.insideTrash("/r", "/r/.trash/1/a.md"));
    assert.ok(!L.insideTrash("/r", "/r/.trash/"));
    assert.ok(!L.insideTrash("/r", "/r/.trash/1/../../x"));
    assert.ok(!L.insideTrash("/r", "/r/a.md"));
});
console.log("notes logic: " + n + " groups ok");
