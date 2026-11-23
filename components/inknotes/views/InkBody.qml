pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import "../skin"
import "../state"
import "../logic/NotesLogic.js" as Logic

// The whole window: three panes, the open note and its saving, the questions and the shortcuts.
Item {
    id: root
    property bool startWithNew: false
    signal closeRequested()

    readonly property bool narrow: width < InkSkin.body * 52
    property string page: "list"
    property string view: Logic.ALL
    property bool trashOpen: false
    property string current: ""
    property bool dirty: false
    property string saveState: "saved"
    property string asking: ""
    property string target: ""
    readonly property bool sheetOpen: ask.open || settings.open
    readonly property bool typing: notes.typing || ask.typing || settings.typing || editor.editor.edit.activeFocus || editor.editor.raw.activeFocus
    readonly property bool showFolders: root.narrow ? root.page === "folders" : InkOptions.showFolders
    readonly property bool showList: root.narrow ? root.page === "list" : InkOptions.showList
    readonly property bool showEditor: root.narrow ? root.page === "editor" : true
    readonly property string heading: root.view === Logic.ALL ? Translation.tr("All notes") : root.view === Logic.NONE ? Translation.tr("No folder") : root.view
    focus: true

    NotesStore {
        id: store
        folder: InkOptions.rootPath
        sort: InkOptions.sort
        pins: InkOptions.pins
        onCreated: rel => { root.select(rel); editor.editor.focusEditor(); }
        onRenamed: (from, to) => root.followMove(from, to)
        onRemoved: rel => { if (root.current === rel || root.current.indexOf(rel + "/") === 0) root.clear(); }
    }
    FileView {
        id: noteFile
        property bool failed: false
        blockLoading: true
        blockWrites: true
        printErrors: false
        onSaveFailed: failed = true
        onLoadFailed: failed = true
    }
    onTrashOpenChanged: if (root.trashOpen) store.refreshTrash()

    // Saving: a moment after typing stops, and before the note changes or the window closes.
    Timer { id: saveLater; interval: 700; onTriggered: root.flush() }
    function flush(): void {
        saveLater.stop();
        if (!root.dirty || root.current === "") return;
        noteFile.failed = false;
        noteFile.setText(editor.editor.markdown());
        const ok = !noteFile.failed;
        root.dirty = !ok;
        root.saveState = ok ? "saved" : "failed";
        if (ok) store.touch(root.current);
    }
    function select(rel: string): void {
        root.flush();
        root.current = rel;
        noteFile.failed = false;
        noteFile.path = store.path(rel);
        editor.editor.load(noteFile.failed ? "" : noteFile.text());
        root.dirty = false;
        root.saveState = noteFile.failed ? "failed" : "saved";
        InkOptions.set("lastNote", rel);
        root.trashOpen = false;
        if (root.narrow) root.page = "editor";
    }
    function clear(): void {
        root.current = "";
        root.dirty = false;
        noteFile.path = "";
        editor.editor.load("");
        InkOptions.set("lastNote", "");
    }
    function followMove(from: string, to: string): void {
        InkOptions.moved(from, to);
        if (root.view === from) root.view = to;
        if (root.current === from || root.current.indexOf(from + "/") === 0) {
            root.current = Logic.movedKey(root.current, from, to);
            noteFile.path = store.path(root.current);
        }
    }
    function newNote(): void {
        root.trashOpen = false;
        store.query = "";
        store.create(root.view === Logic.ALL ? "" : root.view);
    }
    function pick(view: string): void {
        root.view = view;
        root.trashOpen = false;
        if (root.narrow) root.page = "list";
    }
    function toggleFolders(): void { InkOptions.set("showFolders", !InkOptions.showFolders) }
    function toggleList(): void { InkOptions.set("showList", !InkOptions.showList) }
    function leave(): void {
        if (root.sheetOpen) { ask.open = false; settings.open = false; }
        else if (root.typing) root.forceActiveFocus();
        else { root.flush(); root.closeRequested(); }
    }

    // Questions
    function question(kind: string, target: string): void {
        root.asking = kind;
        root.target = target;
        const q = {
            newFolder: [Translation.tr("New folder"), "", true, "", Translation.tr("Create"), false],
            renameFolder: [Translation.tr("Rename folder"), "", true, target, Translation.tr("Rename"), false],
            deleteFolder: [Translation.tr("Move folder to trash"), Translation.tr("The folder and its notes go to the trash."), false, "", Translation.tr("Move to trash"), true],
            renameNote: [Translation.tr("Rename note"), "", true, Logic.titleOf(target), Translation.tr("Rename"), false],
            emptyTrash: [Translation.tr("Empty trash"), Translation.tr("Everything in the trash is deleted for good."), false, "", Translation.tr("Empty trash"), true],
            link: [Translation.tr("Link"), "", true, "https://", Translation.tr("Add link"), false]
        }[kind];
        ask.title = q[0]; ask.message = q[1]; ask.field = q[2]; ask.value = q[3]; ask.action = q[4]; ask.danger = q[5];
        ask.open = true;
    }
    function answered(value: string): void {
        const kind = root.asking;
        const text = value.trim();
        ask.open = false;
        if (kind === "newFolder") store.createFolder(text);
        else if (kind === "renameFolder") store.renameFolder(root.target, text);
        else if (kind === "deleteFolder") store.toTrash(root.target);
        else if (kind === "renameNote") { root.flush(); store.rename(root.target, text); }
        else if (kind === "emptyTrash") store.emptyTrash();
        else if (kind === "link") { if (text !== "") editor.editor.link(text); editor.editor.focusEditor(); }
    }

    Component.onCompleted: {
        store.refresh(() => {
            const last = InkOptions.lastNote;
            if (root.startWithNew) root.newNote();
            else if (last !== "" && store.notes.some(n => n.rel === last)) root.select(last);
        });
        store.purge(InkOptions.trashDays);
    }
    Component.onDestruction: root.flush()
    Connections {
        target: InkOptions
        function onRootPathChanged(): void {
            root.flush();
            root.clear();
            root.view = Logic.ALL;
            store.refresh();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.small
        spacing: InkSkin.small
        FoldersPane {
            Layout.fillHeight: true
            Layout.fillWidth: root.narrow
            Layout.preferredWidth: InkSkin.body * 14
            visible: root.showFolders
            store: store
            view: root.view
            trashOpen: root.trashOpen
            onPicked: view => root.pick(view)
            onNewFolder: root.question("newFolder", "")
            onRenameFolder: name => root.question("renameFolder", name)
            onDeleteFolder: name => root.question("deleteFolder", name)
            onTrashRequested: { root.trashOpen = true; if (root.narrow) root.page = "list"; }
            onSettingsRequested: settings.open = true
        }
        NotesPane {
            id: notes
            Layout.fillHeight: true
            Layout.fillWidth: root.narrow
            Layout.preferredWidth: InkSkin.body * 19
            visible: root.showList && !root.trashOpen
            store: store
            current: root.current
            heading: root.heading
            onPicked: rel => root.select(rel)
            onNewNote: root.newNote()
            onRenameNote: rel => root.question("renameNote", rel)
            onTrashNote: rel => { if (rel === root.current) root.flush(); store.toTrash(rel); }
        }
        TrashView {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: root.trashOpen && (!root.narrow || root.page !== "folders")
            store: store
            days: InkOptions.trashDays
            narrow: root.narrow
            onEmptyRequested: root.question("emptyTrash", "")
            onBackRequested: root.page = "folders"
        }
        EditorPane {
            id: editor
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: root.showEditor && !root.trashOpen
            rel: root.current
            folderName: Logic.folderOf(root.current)
            saveState: root.saveState
            narrow: root.narrow
            onRenameRequested: root.question("renameNote", root.current)
            onBackRequested: root.page = "list"
            onFoldersToggled: root.toggleFolders()
            onListToggled: root.toggleList()
            onNewNote: root.newNote()
            onLinkRequested: root.question("link", "")
            Connections {
                target: editor.editor
                function onEdited(): void {
                    root.dirty = true;
                    root.saveState = "saving";
                    saveLater.restart();
                }
            }
        }
    }

    Rectangle {
        visible: store.error !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: InkSkin.pad
        width: Math.min(root.width - InkSkin.pad * 2, errorText.implicitWidth + InkSkin.pad * 2)
        height: errorText.implicitHeight + InkSkin.gap * 2
        radius: InkSkin.smallRadius
        color: InkSkin.sheet
        border.color: InkSkin.danger
        InkText { id: errorText; anchors.centerIn: parent; width: parent.width - InkSkin.pad; text: store.error; color: InkSkin.danger; wrapMode: Text.Wrap }
        MouseArea { anchors.fill: parent; onClicked: store.error = "" }
        Timer { running: store.error !== ""; interval: 6000; onTriggered: store.error = "" }
    }

    AskSheet { id: ask; anchors.fill: parent; onAccepted: value => root.answered(value); onClosed: ask.open = false }
    SettingsSheet { id: settings; anchors.fill: parent; rootPath: InkOptions.rootPath; onClosed: settings.open = false }

    Shortcut { sequence: "Escape"; onActivated: root.leave() }
    Shortcut { sequence: "Ctrl+N"; enabled: !root.sheetOpen; onActivated: root.newNote() }
    Shortcut {
        sequence: "Ctrl+F"; enabled: !root.sheetOpen
        onActivated: { if (root.narrow) root.page = "list"; else if (!InkOptions.showList) root.toggleList(); root.trashOpen = false; notes.focusSearch(); }
    }
    Shortcut { sequence: "Delete"; enabled: !root.typing && !root.sheetOpen && root.current !== ""; onActivated: { root.flush(); store.toTrash(root.current); } }
    Shortcut { sequence: "Ctrl+\\"; onActivated: root.toggleFolders() }
    Shortcut { sequences: ["Ctrl+Shift+\\", "Ctrl+|"]; onActivated: root.toggleList() }
    Shortcut { sequences: ["Ctrl+=", "Ctrl++"]; enabled: root.current !== ""; onActivated: editor.zoomBy(1) }
    Shortcut { sequence: "Ctrl+-"; enabled: root.current !== ""; onActivated: editor.zoomBy(-1) }
    Shortcut { sequence: "Ctrl+Shift+M"; enabled: root.current !== ""; onActivated: editor.toggleRaw() }
    Shortcut { sequence: "Ctrl+Shift+T"; onActivated: InkOptions.set("showToolbar", !InkOptions.showToolbar) }
}
