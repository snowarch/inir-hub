pragma ComponentBehavior: Bound

// The presets folder: what is in it and every change to it. Each change is one command run with an argument list
// (mkdir, mv, rm, find, inir look ...) or one small file written; the list is read again afterwards.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "../logic/PresetLogic.js" as Logic
import "../logic/StoreLogic.js" as Files

Item {
    id: root
    required property string rootDir
    property var folders: []
    property var presets: []
    property string selectedFolder: ""
    property bool busy: false
    property bool loaded: false
    property bool scanning: false
    property int skipped: 0
    property string message: ""
    property bool ok: true
    property string previewText: ""
    property bool canUndo: false
    property bool withWallpaper: true

    signal done(bool ok, string message)
    signal groupsReady(var ids)

    function presetAt(file: string): var {
        return root.presets.find(p => p.file === file) ?? null;
    }
    function byName(name: string): var {
        const key = name.trim().toLowerCase();
        return root.presets.find(p => p.name.toLowerCase() === key) ?? null;
    }

    // One command, its exit code and its output (standard output, then errors) handed to done.
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
            property int streams: 0
            stdout: StdioCollector { id: out; onStreamFinished: { job.streams += 1; job.settle() } }
            stderr: StdioCollector { id: err; onStreamFinished: { job.streams += 1; job.settle() } }
            onExited: code => { job.status = code; job.settle() }
            function settle(): void { if (job.streams >= 2 && job.status >= 0) job.finished(job.status, out.text + (err.text !== "" ? "\n" + err.text : "")) }
        }
    }

    // One file at a time, read or written synchronously.
    FileView {
        id: io
        property bool failed: false
        blockLoading: true
        blockWrites: true
        printErrors: false
        onLoadFailed: failed = true
        onSaveFailed: failed = true
    }
    function readText(path: string): var {
        io.failed = false;
        io.path = "";
        io.path = path;
        if (io.failed) return null;
        try { return io.text(); } catch (e) { return null; }
    }
    function writeText(path: string, text: string): bool {
        io.path = path;
        io.failed = false;
        io.setText(text);
        return !io.failed;
    }

    function finish(ok: bool, message: string): void {
        root.busy = false;
        root.ok = ok;
        root.message = message;
        root.done(ok, message);
    }
    function begin(): bool {
        if (root.busy) return false;
        root.busy = true;
        root.message = "";
        return true;
    }

    function entryOf(rel: string, text: var): var {
        const look = Logic.parsePreset(text);
        if (look === null) return null;
        const info = Logic.summarize(look);
        const known = Logic.GROUPS.map(g => g.id);
        return {
            folder: Files.folderOf(rel),
            name: typeof look.presetName === "string" && look.presetName !== "" ? look.presetName : Files.stem(rel),
            file: root.rootDir + "/" + rel,
            family: info.family ?? "",
            groups: Array.isArray(look.presetGroups) ? look.presetGroups.filter(id => known.indexOf(id) >= 0) : info.groups,
            settings: info.settings,
            hasWallpaper: info.hasWallpaper,
            made: typeof look.made === "string" ? look.made : ""
        };
    }

    // Reads the folder again. Not tied to busy: the caller decides.
    function reload(done: var): void {
        root.run(["mkdir", "-p", "--", root.rootDir], () => root.run([
            "find", root.rootDir, "-mindepth", "1", "-maxdepth", "2", "-name", ".*", "-prune",
            "-o", "-type", "d", "-printf", "d\t%P\n",
            "-o", "-type", "f", "-name", "*" + Files.EXT, "-printf", "f\t%P\n"
        ], (code, text) => {
            if (code !== 0) {
                root.finish(false, Translation.tr("Could not read the presets folder."));
                return;
            }
            const listing = Files.parseListing(text);
            const entries = [];
            let bad = 0;
            listing.files.forEach(rel => {
                const body = root.readText(root.rootDir + "/" + rel);
                const entry = body === null ? null : root.entryOf(rel, body);
                if (entry === null) bad += 1; else entries.push(entry);
            });
            entries.sort(Files.byName);
            root.folders = listing.folders;
            root.presets = entries;
            root.skipped = bad;
            if (root.selectedFolder !== "" && listing.folders.indexOf(root.selectedFolder) < 0) root.selectedFolder = "";
            root.loaded = true;
            if (done) done();
        }));
    }
    function refresh(): void {
        if (!root.begin()) return;
        root.reload(() => root.finish(true, ""));
    }
    // The change is made: read the folder again, then report.
    function settled(message: string): void {
        root.reload(() => root.finish(true, message));
    }

    // The current look, exported to a temporary file and read: done(look or null, reason).
    function exportCurrent(done: var): void {
        const tmp = root.rootDir + "/" + Files.WORK + "/export-" + Date.now() + Files.EXT;
        root.run(["mkdir", "-p", "--", root.rootDir + "/" + Files.WORK], code => {
            if (code !== 0) { done(null, Translation.tr("Could not create the presets folder.")); return; }
            root.run(["inir", "look", "export", tmp], (status, out) => {
                const text = status === 0 ? root.readText(tmp) : null;
                root.run(["rm", "-f", "--", tmp]);
                const look = text === null ? null : Logic.parsePreset(text);
                done(look, look !== null ? "" : (Files.firstLine(out) || Translation.tr("Could not read the current look.")));
            });
        });
    }
    function availableGroups(): void {
        if (root.scanning) return;
        root.scanning = true;
        root.exportCurrent(look => {
            root.scanning = false;
            root.groupsReady(look === null ? [] : Logic.groupsPresent(look));
        });
    }

    // The trash is ROOT/.trash/<epochMs>/<path inside the presets folder>.
    function toTrash(rel: string, failure: string, success: string): void {
        const dest = Files.trashDest(root.rootDir, String(Date.now()), rel);
        root.run(["mkdir", "-p", "--", dest.slice(0, dest.lastIndexOf("/"))], () => root.run(
            ["mv", "-T", "-n", "--", root.rootDir + "/" + rel, dest], code => {
                if (code !== 0) root.finish(false, failure); else root.settled(success);
            }));
    }

    function folderExists(name: string): bool {
        return root.folders.some(f => f.toLowerCase() === name.toLowerCase());
    }
    function createFolder(name: string): void {
        const clean = Files.cleanFolder(name);
        if (!root.begin()) return;
        if (clean === "" || root.folderExists(clean)) { root.finish(false, Translation.tr("That name cannot be used.")); return; }
        root.run(["mkdir", "--", root.rootDir + "/" + clean], code => {
            if (code !== 0) { root.finish(false, Translation.tr("Could not create the folder.")); return; }
            root.selectedFolder = clean;
            root.settled(Translation.tr("Folder %1 created.").arg(clean));
        });
    }
    function renameFolder(from: string, to: string): void {
        const clean = Files.cleanFolder(to);
        if (!root.begin()) return;
        if (clean === "" || (clean.toLowerCase() !== from.toLowerCase() && root.folderExists(clean))) { root.finish(false, Translation.tr("That name cannot be used.")); return; }
        root.run(["mv", "-T", "-n", "--", root.rootDir + "/" + from, root.rootDir + "/" + clean], code => {
            if (code !== 0) { root.finish(false, Translation.tr("Could not rename the folder.")); return; }
            if (root.selectedFolder === from) root.selectedFolder = clean;
            root.settled(Translation.tr("Folder renamed to %1.").arg(clean));
        });
    }
    function deleteFolder(name: string): void {
        if (!root.begin()) return;
        if (root.selectedFolder === name) root.selectedFolder = "";
        root.toTrash(name, Translation.tr("Could not move the folder to the trash."), Translation.tr("Folder %1 moved to the trash.").arg(name));
    }

    function takenNames(folder: string, except: string): var {
        const names = [];
        root.presets.forEach(p => {
            if (p.folder !== folder || p.file === except) return;
            names.push(p.name);
            names.push(Files.stem(p.file));
        });
        return names;
    }

    function savePreset(name: string, folder: string, groupIds: var): void {
        if (!root.begin()) return;
        const clean = name.trim();
        if (clean === "" || groupIds.length === 0 || (folder !== "" && !root.folderExists(folder))) { root.finish(false, Translation.tr("That name cannot be used.")); return; }
        root.exportCurrent((look, reason) => {
            if (look === null) { root.finish(false, reason); return; }
            const unique = Logic.uniqueName(clean, root.takenNames(folder, ""));
            const out = Logic.filterLook(look, groupIds);
            out.presetName = unique;
            const file = Files.fileFor(root.rootDir, folder, Logic.slug(unique));
            root.run(["mkdir", "-p", "--", file.slice(0, file.lastIndexOf("/"))], () => {
                if (!root.writeText(file, JSON.stringify(out, null, 2))) { root.finish(false, Translation.tr("Could not save the preset.")); return; }
                root.settled(Translation.tr("Saved %1.").arg(unique));
            });
        });
    }

    // recapture: groupIds are the groups read again from the current look, the rest stay as saved. Otherwise groupIds
    // are the groups the preset keeps, and it only drops the ones left out.
    function updatePreset(file: string, groupIds: var, recapture: bool): void {
        if (!root.begin()) return;
        const info = root.presetAt(file);
        const text = info === null ? null : root.readText(file);
        const old = text === null ? null : Logic.parsePreset(text);
        if (old === null || groupIds.length === 0) { root.finish(false, Translation.tr("Could not read the preset.")); return; }
        const write = merged => {
            merged.presetName = info.name;
            if (!root.writeText(file, JSON.stringify(merged, null, 2))) { root.finish(false, Translation.tr("Could not save the preset.")); return; }
            root.settled(Translation.tr("Updated %1.").arg(info.name));
        };
        if (!recapture) { write(Logic.filterLook(old, groupIds)); return; }
        root.exportCurrent((look, reason) => {
            if (look === null) root.finish(false, reason); else write(Logic.mergeUpdate(old, look, groupIds));
        });
    }

    function renamePreset(file: string, newName: string): void {
        if (!root.begin()) return;
        const info = root.presetAt(file);
        const clean = newName.trim();
        const text = info === null || clean === "" ? null : root.readText(file);
        const look = text === null ? null : Logic.parsePreset(text);
        if (look === null) { root.finish(false, Translation.tr("That name cannot be used.")); return; }
        const slugs = root.takenNames(info.folder, file).map(Logic.slug);
        if (slugs.indexOf(Logic.slug(clean)) >= 0) { root.finish(false, Translation.tr("A preset with that name already exists there.")); return; }
        look.presetName = clean;
        const target = Files.fileFor(root.rootDir, info.folder, Logic.slug(clean));
        const write = () => {
            if (!root.writeText(target, JSON.stringify(look, null, 2))) { root.finish(false, Translation.tr("Could not save the preset.")); return; }
            root.settled(Translation.tr("Renamed to %1.").arg(clean));
        };
        if (target === file) { write(); return; }
        root.run(["mv", "-T", "-n", "--", file, target], code => {
            if (code !== 0) root.finish(false, Translation.tr("Could not rename the preset.")); else write();
        });
    }

    function movePreset(file: string, folder: string): void {
        if (!root.begin()) return;
        const info = root.presetAt(file);
        if (info === null || (folder !== "" && !root.folderExists(folder))) { root.finish(false, Translation.tr("Could not move the preset.")); return; }
        if (info.folder === folder) { root.finish(true, ""); return; }
        const slugs = root.takenNames(folder, "").map(Logic.slug);
        if (slugs.indexOf(Logic.slug(info.name)) >= 0 || slugs.indexOf(Files.stem(file)) >= 0) { root.finish(false, Translation.tr("A preset with that name already exists there.")); return; }
        const target = Files.fileFor(root.rootDir, folder, Files.stem(file));
        root.run(["mv", "-T", "-n", "--", file, target], code => {
            if (code !== 0) root.finish(false, Translation.tr("Could not move the preset."));
            else root.settled(Translation.tr("Moved %1.").arg(info.name));
        });
    }

    function deletePreset(file: string): void {
        if (!root.begin()) return;
        const info = root.presetAt(file);
        const rel = Files.relOf(root.rootDir, file);
        if (info === null || rel === null) { root.finish(false, Translation.tr("Could not move the preset to the trash.")); return; }
        root.toTrash(rel, Translation.tr("Could not move the preset to the trash."), Translation.tr("%1 moved to the trash.").arg(info.name));
    }

    // These two are the only ones that change the desktop: the look is imported, or the last snapshot is restored.
    function applyPreset(file: string, withWallpaper: bool): void {
        if (!root.begin()) return;
        const info = root.presetAt(file);
        if (info === null) { root.finish(false, Translation.tr("Could not read the preset.")); return; }
        root.run(["inir", "look", "import", file].concat(withWallpaper ? [] : ["--no-wallpaper"]), (code, out) => {
            if (code !== 0) { root.finish(false, Files.firstLine(out) || Translation.tr("Could not apply the preset.")); return; }
            root.canUndo = true;
            root.finish(true, Translation.tr("Applied %1.").arg(info.name));
        });
    }
    function previewApply(file: string): void {
        if (!root.begin()) return;
        root.previewText = "";
        root.run(["inir", "look", "import", file, "--dry-run"].concat(root.withWallpaper ? [] : ["--no-wallpaper"]), (code, out) => {
            if (code !== 0) { root.finish(false, Files.firstLine(out) || Translation.tr("Could not read the changes.")); return; }
            root.previewText = out.trim() !== "" ? out.trim() : Translation.tr("Nothing would change.");
            root.finish(true, "");
        });
    }
    function undo(): void {
        if (!root.begin()) return;
        root.run(["inir", "look", "restore", "1"], (code, out) => {
            if (code !== 0) { root.finish(false, Files.firstLine(out) || Translation.tr("Could not undo.")); return; }
            root.canUndo = false;
            root.finish(true, Translation.tr("The look before the last apply is back."));
        });
    }
}
