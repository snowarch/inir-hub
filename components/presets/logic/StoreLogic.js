.pragma library

// File-level helpers of the presets folder: names, paths, the listing read from `find`.

var EXT = ".look.json";
var TRASH = ".trash";
var WORK = ".work";

function cleanFolder(name) {
    return String(name).replace(/[\/\\\u0000-\u001f]/g, " ").replace(/^[.\s]+/, "").replace(/\s+/g, " ").trim().slice(0, 60);
}

function validRoot(path) {
    return typeof path === "string" && path.charAt(0) === "/" && path.length > 1
        && path.split("/").indexOf("..") < 0 && path.split("/").indexOf(TRASH) < 0;
}

function baseName(rel) {
    return rel.slice(rel.lastIndexOf("/") + 1);
}

function stem(rel) {
    const base = baseName(rel);
    return base.slice(-EXT.length) === EXT ? base.slice(0, base.length - EXT.length) : base;
}

function folderOf(rel) {
    const i = rel.lastIndexOf("/");
    return i < 0 ? "" : rel.slice(0, i);
}

function relOf(root, file) {
    return file.indexOf(root + "/") === 0 ? file.slice(root.length + 1) : null;
}

function fileFor(root, folder, slug) {
    return root + "/" + (folder === "" ? "" : folder + "/") + slug + EXT;
}

function trashDest(root, stamp, rel) {
    return root + "/" + TRASH + "/" + stamp + "/" + rel;
}

// Lines of `find -printf "d\t%P\n" / "f\t%P\n"`: folders one level deep and presets one or two levels deep.
function parseListing(text) {
    const folders = [];
    const files = [];
    text.split("\n").forEach(function (line) {
        const tab = line.indexOf("\t");
        if (tab < 0)
            return;
        const kind = line.slice(0, tab);
        const rel = line.slice(tab + 1);
        if (rel === "")
            return;
        if (kind === "d" && rel.indexOf("/") < 0)
            folders.push(rel);
        else if (kind === "f" && rel.slice(-EXT.length) === EXT && rel.split("/").length <= 2)
            files.push(rel);
    });
    folders.sort(function (a, b) { return a.toLowerCase().localeCompare(b.toLowerCase()); });
    return { folders: folders, files: files };
}

function byName(a, b) {
    return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
}

// The family name in a look file as people know it.
function familyLabel(family) {
    const known = { ii: "Material", material: "Material", iris: "iRiS", waffle: "Waffle", waffles: "Waffle" };
    return Object.prototype.hasOwnProperty.call(known, family) ? known[family] : family;
}

// The "made" stamp of a look as milliseconds, or NaN.
function madeMs(made) {
    return typeof made === "string" ? Date.parse(made) : NaN;
}

function firstLine(text) {
    const lines = String(text).split("\n").map(function (l) { return l.trim(); }).filter(function (l) { return l !== ""; });
    return lines.length > 0 ? lines[0] : "";
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { EXT, TRASH, WORK, cleanFolder, validRoot, baseName, stem, folderOf, relOf, fileFor, trashDest, parseListing, byName, familyLabel, madeMs, firstLine };
