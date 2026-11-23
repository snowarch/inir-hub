pragma ComponentBehavior: Bound

// The notes folder: what is in it, and every change to it. Each change is one command (mkdir, mv, rm, find, grep) run
// with an argument list; the list is read again afterwards.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "../logic/NotesLogic.js" as Logic

Scope {
    id: root
    required property string folder
    property var notes: []
    property var folders: []
    property var trash: []
    property var hits: []
    property bool loading: true
    property string error: ""
    property string view: Logic.ALL
    property string query: ""
    property string sort: "edited"
    property var pins: []
    readonly property var listed: Logic.listNotes(root.notes, root.view, root.query, root.hits, root.sort, root.pins)
    readonly property int allCount: root.notes.length
    readonly property int rootCount: Logic.countIn(root.notes, Logic.NONE)

    signal created(string rel)
    signal renamed(string from, string to)
    signal removed(string rel)

    function path(rel: string): string { return root.folder + "/" + rel }
    function countOf(folder: string): int { return Logic.countIn(root.notes, folder) }
    function fail(text: string): void { root.error = text }

    function run(argv: var, done: var): void {
        const job = jobs.createObject(root, { command: argv });
        job.finished.connect((code, out) => { if (done) done(code, out); job.destroy(); });
        job.running = true;
    }
    Component {
        id: jobs
        Process {
            id: job
            signal finished(int code, string out)
            property int status: -1
            property bool streamed: false
            stdout: StdioCollector { id: out; onStreamFinished: { job.streamed = true; job.settle() } }
            onExited: code => { job.status = code; job.settle() }
            function settle(): void { if (job.streamed && job.status >= 0) job.finished(job.status, out.text) }
        }
    }

    function refresh(done: var): void {
        root.loading = true;
        root.run(["mkdir", "-p", "--", root.folder], () => root.run([
            "find", root.folder, "-mindepth", "1", "-maxdepth", "2", "-name", Logic.TRASH, "-prune",
            "-o", "-type", "d", "-printf", "d\t%P\t%T@\n",
            "-o", "-type", "f", "-name", "*.md", "-printf", "f\t%P\t%T@\n"
        ], (code, text) => {
            if (code !== 0) root.fail(Translation.tr("Could not read the notes folder."));
            else {
                const listing = Logic.parseListing(text);
                root.notes = listing.notes;
                root.folders = listing.folders;
            }
            root.loading = false;
            if (done) done();
        }));
    }
    function refreshTrash(done: var): void {
        root.run(["find", root.folder + "/" + Logic.TRASH, "-mindepth", "2", "-maxdepth", "3", "-type", "f", "-name", "*.md", "-printf", "%P\n"], (code, text) => {
            root.trash = code === 0 ? Logic.parseTrash(text) : [];
            if (done) done();
        });
    }
    function touch(rel: string): void {
        root.notes = root.notes.map(n => n.rel === rel ? Object.assign({}, n, { mtime: Date.now() }) : n);
    }

    // Search: titles are matched as the list is built; the text of the notes by grep, a moment after typing stops.
    onQueryChanged: find.restart()
    Timer {
        id: find
        interval: 250
        onTriggered: {
            const q = root.query.trim();
            if (q.length < 2) { root.hits = []; return; }
            root.run(["grep", "-rilFZ", "--include=*.md", "--exclude-dir=" + Logic.TRASH, "--", q, root.folder], (code, text) => {
                if (q !== root.query.trim()) return;
                root.hits = text.split("\u0000").filter(p => p.indexOf(root.folder + "/") === 0).map(p => p.slice(root.folder.length + 1));
            });
        }
    }

    function exists(rel: string): bool {
        return root.notes.some(n => n.rel.toLowerCase() === rel.toLowerCase());
    }
    function create(folder: string): void {
        const title = Logic.uniqueTitle(Translation.tr("Untitled"), root.notes.filter(n => n.folder === folder).map(n => n.title));
        const rel = Logic.relOf(folder, title);
        root.run(["touch", "--", root.path(rel)], code => {
            if (code !== 0) { root.fail(Translation.tr("Could not create the note.")); return; }
            root.refresh(() => root.created(rel));
        });
    }
    function move(rel: string, to: string, done: var): void {
        if (rel === to) return;
        if (root.exists(to)) { root.fail(Translation.tr("A note with that name already exists there.")); return; }
        root.run(["mv", "-T", "-n", "--", root.path(rel), root.path(to)], code => {
            if (code !== 0) { root.fail(Translation.tr("Could not move the note.")); return; }
            root.refresh(() => { root.renamed(rel, to); if (done) done(); });
        });
    }
    function rename(rel: string, name: string): bool {
        const title = Logic.cleanName(name);
        if (title === "") { root.fail(Translation.tr("That name cannot be used.")); return false; }
        root.move(rel, Logic.relOf(Logic.folderOf(rel), title));
        return true;
    }

    // The trash is ROOT/.trash/<epochMs>/<path inside the notes folder>.
    function toTrash(rel: string, done: var): void {
        const stamp = String(Date.now());
        const dest = root.folder + "/" + Logic.TRASH + "/" + stamp + "/" + rel;
        const dir = dest.slice(0, dest.lastIndexOf("/"));
        root.run(["mkdir", "-p", "--", dir], () => root.run(["mv", "-T", "-n", "--", root.path(rel), dest], code => {
            if (code !== 0) { root.fail(Translation.tr("Could not move the note to the trash.")); return; }
            root.refresh(() => { root.removed(rel); if (done) done(); });
        }));
    }
    function cleanTrash(stamp: string, done: var): void {
        root.run(["find", root.folder + "/" + Logic.TRASH + "/" + stamp, "-depth", "-type", "d", "-empty", "-delete"], () => root.refreshTrash(done));
    }
    function restore(item: var): void {
        const src = root.folder + "/" + Logic.TRASH + "/" + item.key;
        const dir = item.folder ? root.folder + "/" + item.folder : root.folder;
        const title = Logic.uniqueTitle(item.title, root.notes.filter(n => n.folder === item.folder).map(n => n.title));
        root.run(["mkdir", "-p", "--", dir], () => root.run(["mv", "-T", "-n", "--", src, dir + "/" + title + ".md"], code => {
            if (code !== 0) { root.fail(Translation.tr("Could not restore the note.")); return; }
            root.cleanTrash(String(item.epoch), () => root.refresh());
        }));
    }
    function deleteForever(item: var): void {
        const src = root.folder + "/" + Logic.TRASH + "/" + item.key;
        if (!Logic.insideTrash(root.folder, src)) return;
        root.run(["rm", "--", src], () => root.cleanTrash(String(item.epoch)));
    }
    function emptyTrash(): void {
        root.run(["find", root.folder + "/" + Logic.TRASH, "-mindepth", "1", "-delete"], () => root.refreshTrash());
    }
    // Run when the window opens: what has stayed in the trash longer than the days kept goes.
    function purge(days: int): void {
        root.run(["find", root.folder + "/" + Logic.TRASH, "-mindepth", "1", "-maxdepth", "1", "-type", "d", "-printf", "%f\n"], (code, text) => {
            if (code !== 0) return;
            Logic.expiredEpochs(text.split("\n"), Date.now(), days).forEach(stamp => root.run(["find", root.folder + "/" + Logic.TRASH + "/" + stamp, "-delete"]));
        });
    }

    function createFolder(name: string): bool {
        const clean = Logic.cleanName(name);
        if (clean === "" || root.folders.some(f => f.toLowerCase() === clean.toLowerCase())) { root.fail(Translation.tr("That name cannot be used.")); return false; }
        root.run(["mkdir", "--", root.path(clean)], code => code === 0 ? root.refresh() : root.fail(Translation.tr("Could not create the folder.")));
        return true;
    }
    function renameFolder(from: string, name: string): bool {
        const clean = Logic.cleanName(name);
        if (clean === "" || (clean !== from && root.folders.some(f => f.toLowerCase() === clean.toLowerCase()))) { root.fail(Translation.tr("That name cannot be used.")); return false; }
        root.run(["mv", "-T", "-n", "--", root.path(from), root.path(clean)], code => {
            if (code !== 0) { root.fail(Translation.tr("Could not rename the folder.")); return; }
            root.refresh(() => root.renamed(from, clean));
        });
        return true;
    }
}
