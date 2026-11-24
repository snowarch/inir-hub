const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const logicPath = path.join(__dirname, "../logic/StoreLogic.js");
const source = fs.readFileSync(logicPath, "utf8");
const logicModule = { exports: {} };
vm.compileFunction(source.replace(/^\.pragma library\r?\n/, ""), ["module"], { filename: logicPath })(logicModule);
const L = logicModule.exports;

const tests = {
    "cleanFolder removes separators, leading dots and extra spaces"() {
        assert.equal(L.cleanFolder("  ../a/b\\c  "), "a b c");
        assert.equal(L.cleanFolder(".hidden"), "hidden");
        assert.equal(L.cleanFolder("x".repeat(80)).length, 60);
        assert.equal(L.cleanFolder("  /  "), "");
    },
    "validRoot wants an absolute path without .. or a trash folder"() {
        assert.equal(L.validRoot("/home/a/presets"), true);
        assert.equal(L.validRoot("presets"), false);
        assert.equal(L.validRoot("/a/../b"), false);
        assert.equal(L.validRoot("/a/.trash/b"), false);
        assert.equal(L.validRoot("/"), false);
    },
    "path helpers"() {
        assert.equal(L.stem("Work/dark-blue.look.json"), "dark-blue");
        assert.equal(L.folderOf("Work/x.look.json"), "Work");
        assert.equal(L.folderOf("x.look.json"), "");
        assert.equal(L.relOf("/r", "/r/Work/x.look.json"), "Work/x.look.json");
        assert.equal(L.relOf("/r", "/other/x.look.json"), null);
        assert.equal(L.fileFor("/r", "", "a"), "/r/a.look.json");
        assert.equal(L.fileFor("/r", "W", "a"), "/r/W/a.look.json");
        assert.equal(L.trashDest("/r", "5", "W/a.look.json"), "/r/.trash/5/W/a.look.json");
    },
    "parseListing keeps one-level folders and preset files"() {
        const out = L.parseListing("d\tWork\nd\tWork/deep\nd\tarch\nf\ta.look.json\nf\tWork/b.look.json\nf\tWork/deep/c.look.json\nf\tnotes.txt\n");
        assert.deepEqual(out.folders, ["arch", "Work"]);
        assert.deepEqual(out.files, ["a.look.json", "Work/b.look.json"]);
    },
    "familyLabel names the families and keeps unknown ones"() {
        assert.equal(L.familyLabel("ii"), "Material");
        assert.equal(L.familyLabel("iris"), "iRiS");
        assert.equal(L.familyLabel("waffle"), "Waffle");
        assert.equal(L.familyLabel("other"), "other");
        assert.equal(L.familyLabel("toString"), "toString");
    },
    "madeMs reads ISO stamps"() {
        assert.equal(L.madeMs("2099-01-01T00:00:00Z"), Date.UTC(2099, 0, 1));
        assert.ok(Number.isNaN(L.madeMs("nope")));
        assert.ok(Number.isNaN(L.madeMs(undefined)));
    },
    "firstLine skips blank lines"() {
        assert.equal(L.firstLine("\n  \nboom\nmore"), "boom");
        assert.equal(L.firstLine(""), "");
    }
};

let failed = 0;
for (const [name, fn] of Object.entries(tests)) {
    try { fn(); console.log("ok - " + name); } catch (error) { failed += 1; console.error("not ok - " + name + "\n" + error.message); }
}
process.exit(failed ? 1 : 0);
