// Loads a .pragma library file from logic/ for node tests: the pragma line is dropped, the rest written beside it as a module.
const fs = require("fs");
const os = require("os");
const path = require("path");
module.exports = function load(name) {
    const src = fs.readFileSync(path.join(__dirname, "..", "logic", name), "utf8").replace(/^\.pragma.*$/m, "");
    const names = [...src.matchAll(/^(?:function|var) (\w+)/gm)].map(m => m[1]);
    const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), "inknotes-")), name.replace(/\.js$/, ".cjs"));
    fs.writeFileSync(file, src + "\nmodule.exports = {" + names.join(",") + "};\n");
    return require(file);
};
