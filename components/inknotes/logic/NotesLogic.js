.pragma library

// Paths, names, listings, sorting and trash planning for the notes folder. Pure functions: nothing here reads a file.

var ALL = "*all*";
var NONE = "";
var TRASH = ".trash";

// A note or folder name that is safe as one path part: no slash, no control character, not hidden, not too long.
function cleanName(raw) {
    var s = String(raw || "").replace(/[\u0000-\u001f\/\\]/g, " ").replace(/\s+/g, " ").trim();
    s = s.replace(/\.md$/i, "").trim();
    if (s === "" || s[0] === "." || s.length > 120) return "";
    return s;
}

// A custom folder must be absolute, free of "..", and not inside the trash.
function validRoot(path) {
    var p = String(path || "").trim();
    if (p.length < 2 || p[0] !== "/") return false;
    var parts = p.split("/");
    for (var i = 0; i < parts.length; i++) if (parts[i] === ".." || parts[i] === TRASH) return false;
    return p.indexOf("//") < 0 && p.indexOf("\n") < 0;
}

function rootFor(location, custom, documents, state) {
    if (location === "hidden") return state + "/inknotes";
    if (location === "custom" && validRoot(custom)) return custom.replace(/\/+$/, "");
    return documents + "/inknotes";
}

function titleOf(rel) {
    var base = rel.slice(rel.lastIndexOf("/") + 1);
    return base.replace(/\.md$/i, "");
}
function folderOf(rel) { var i = rel.indexOf("/"); return i < 0 ? "" : rel.slice(0, i); }
function relOf(folder, title) { return (folder ? folder + "/" : "") + title + ".md"; }

// Output of: find ROOT -mindepth 1 -maxdepth 2 -name .trash -prune -o -type d -printf "d\t%P\t%T@\n" -o -type f -name "*.md" -printf "f\t%P\t%T@\n"
function parseListing(text) {
    var notes = [];
    var dirs = [];
    String(text || "").split("\n").forEach(function (line) {
        var p = line.split("\t");
        if (p.length < 3 || p[1] === "" || p[1][0] === ".") return;
        var parts = p[1].split("/");
        if (parts.some(function (s) { return s[0] === "."; })) return;
        if (p[0] === "d" && parts.length === 1) dirs.push(p[1]);
        else if (p[0] === "f") notes.push({ rel: p[1], title: titleOf(p[1]), folder: folderOf(p[1]), mtime: Math.round(parseFloat(p[2]) * 1000) || 0 });
    });
    dirs.sort(function (a, b) { return a.toLowerCase() < b.toLowerCase() ? -1 : 1; });
    return { notes: notes, folders: dirs };
}

function countIn(notes, folder) {
    return notes.filter(function (n) { return folder === ALL || n.folder === folder; }).length;
}

// Notes of a folder view (ALL, NONE or a folder name), filtered by a query (titles, plus the rels in hits), pinned first.
function listNotes(notes, view, query, hits, sort, pins) {
    var q = String(query || "").trim().toLowerCase();
    var out = notes.filter(function (n) {
        if (view !== ALL && n.folder !== view) return false;
        if (q === "") return true;
        return n.title.toLowerCase().indexOf(q) >= 0 || (hits && hits.indexOf(n.rel) >= 0);
    });
    out.sort(function (a, b) {
        var pa = pins.indexOf(a.rel) >= 0 ? 0 : 1;
        var pb = pins.indexOf(b.rel) >= 0 ? 0 : 1;
        if (pa !== pb) return pa - pb;
        if (sort === "title") return a.title.toLowerCase() < b.title.toLowerCase() ? -1 : a.title.toLowerCase() > b.title.toLowerCase() ? 1 : 0;
        return b.mtime - a.mtime;
    });
    return out;
}

// "Untitled", then "Untitled 2", "Untitled 3": the first title no existing name (case-insensitive) uses.
function uniqueTitle(base, taken) {
    var low = taken.map(function (t) { return t.toLowerCase(); });
    if (low.indexOf(base.toLowerCase()) < 0) return base;
    for (var n = 2; ; n++) if (low.indexOf((base + " " + n).toLowerCase()) < 0) return base + " " + n;
}

// How long ago, as parts the view turns into words: k is now, min, hour, yesterday, days or date.
function ago(ms, now) {
    var s = Math.max(0, Math.round((now - ms) / 1000));
    if (s < 60) return { k: "now", n: 0 };
    if (s < 3600) return { k: "min", n: Math.floor(s / 60) };
    var start = new Date(now);
    start.setHours(0, 0, 0, 0);
    if (ms >= start.getTime()) return { k: "hour", n: Math.floor(s / 3600) };
    if (ms >= start.getTime() - 86400000) return { k: "yesterday", n: 1 };
    if (ms >= start.getTime() - 6 * 86400000) return { k: "days", n: Math.ceil((start.getTime() - ms) / 86400000) };
    return { k: "date", n: 0 };
}

// A key of a map (pins, fonts) that moves with a note or folder: from "A.md" to "B.md", or folder "F" to "G".
function movedKey(key, from, to) {
    if (key === from) return to;
    if (key.indexOf(from + "/") === 0) return to + key.slice(from.length);
    return key;
}

// Output of: find ROOT/.trash -mindepth 2 -maxdepth 3 -type f -name "*.md" -printf "%P\n"  ("<epochMs>/<rel>")
function parseTrash(text) {
    var out = [];
    String(text || "").split("\n").forEach(function (line) {
        var i = line.indexOf("/");
        var epoch = parseInt(line.slice(0, i), 10);
        if (i < 1 || !(epoch > 0)) return;
        var rel = line.slice(i + 1);
        out.push({ epoch: epoch, rel: rel, title: titleOf(rel), folder: folderOf(rel), key: line });
    });
    out.sort(function (a, b) { return b.epoch - a.epoch; });
    return out;
}

// Trash folder names (epoch milliseconds) older than the days kept; days <= 0 keeps everything.
function expiredEpochs(names, now, days) {
    if (!(days > 0)) return [];
    return names.filter(function (n) { var e = parseInt(n, 10); return /^\d+$/.test(n) && e > 0 && now - e > days * 86400000; });
}

// A path that is a note or folder under ROOT/.trash/<epoch>/, with no way out of it.
function insideTrash(root, path) {
    var pre = root + "/" + TRASH + "/";
    return path.indexOf(pre) === 0 && path.length > pre.length && path.split("/").indexOf("..") < 0;
}
