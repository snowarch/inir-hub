pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import "../skin"
import "../state"
import "../logic/PresetLogic.js" as Logic

// The whole window: three panes, the questions, the sheets and Escape.
Item {
    id: root
    property string requestedName: ""
    signal requestHandled()
    signal closeRequested()

    readonly property bool narrow: width < InkSkin.body * 52
    property string page: "list"
    property string current: ""
    property string asking: ""
    property string target: ""
    property string followName: ""
    readonly property var preset: store.presetAt(root.current)
    readonly property bool sheetOpen: ask.open || save.open || preview.open
    readonly property bool typing: ask.typing || save.typing
    readonly property string heading: store.selectedFolder === "" ? Translation.tr("All presets") : store.selectedFolder
    focus: true

    PresetStore {
        id: store
        rootDir: PresetOptions.rootDir
        withWallpaper: PresetOptions.applyWallpaper
        onSelectedFolderChanged: PresetOptions.set("lastFolder", store.selectedFolder)
        onGroupsReady: ids => root.groupsRead(ids)
        onDone: root.settled()
    }
    Connections {
        target: PresetOptions
        function onRootDirChanged(): void { root.current = ""; store.refresh(); }
    }
    Component.onCompleted: {
        store.selectedFolder = PresetOptions.lastFolder;
        store.refresh();
    }
    onRequestedNameChanged: root.tryRequest()

    // After every change: follow a renamed, moved or new preset, and answer an apply asked for by name.
    function settled(): void {
        if (root.followName !== "") {
            const found = store.byName(root.followName);
            root.followName = "";
            if (found !== null) root.current = found.file;
        }
        root.tryRequest();
    }
    function tryRequest(): void {
        const name = root.requestedName;
        if (name === "" || !store.loaded || store.busy) return;
        root.requestHandled();
        const found = store.byName(name);
        if (found === null) { store.ok = false; store.message = Translation.tr("No preset is named %1.").arg(name); return; }
        root.select(found.file);
        store.applyPreset(found.file, PresetOptions.applyWallpaper);
    }
    function select(file: string): void {
        root.current = file;
        if (root.narrow) root.page = "detail";
    }
    function pickFolder(folder: string): void {
        store.selectedFolder = folder;
        if (root.narrow) root.page = "list";
    }
    function leave(): void {
        if (root.sheetOpen) { ask.open = false; save.open = false; preview.open = false; }
        else if (root.typing) root.forceActiveFocus();
        else root.closeRequested();
    }

    // Questions
    function question(kind: string, target: string): void {
        root.asking = kind;
        root.target = target;
        const name = root.preset ? root.preset.name : "";
        const q = {
            newFolder: [Translation.tr("New folder"), "", true, "", Translation.tr("Create"), false],
            renameFolder: [Translation.tr("Rename folder"), "", true, target, Translation.tr("Rename"), false],
            deleteFolder: [Translation.tr("Move folder to trash"), Translation.tr("The folder and its presets go to the trash."), false, "", Translation.tr("Move to trash"), true],
            renamePreset: [Translation.tr("Rename preset"), "", true, name, Translation.tr("Rename"), false],
            deletePreset: [Translation.tr("Delete preset"), Translation.tr("%1 goes to the trash. Your desktop does not change.").arg(name), false, "", Translation.tr("Move to trash"), true]
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
        else if (kind === "deleteFolder") store.deleteFolder(root.target);
        else if (kind === "renamePreset" && root.preset) { root.followName = text; store.renamePreset(root.preset.file, text); }
        else if (kind === "deletePreset" && root.preset) {
            const file = root.preset.file;
            root.current = "";
            if (root.narrow) root.page = "list";
            store.deletePreset(file);
        }
    }

    // Group sheet
    function openSave(): void {
        save.mode = "save";
        save.presetName = "";
        save.folder = store.selectedFolder;
        save.folders = store.folders;
        save.available = [];
        save.selected = [];
        save.reading = true;
        save.open = true;
        store.availableGroups();
    }
    function openUpdate(): void {
        if (!root.preset) return;
        save.mode = "update";
        save.available = [];
        save.selected = [];
        save.reading = true;
        save.open = true;
        store.availableGroups();
    }
    function openEdit(): void {
        if (!root.preset) return;
        save.mode = "edit";
        save.available = root.preset.groups;
        save.selected = root.preset.groups;
        save.reading = false;
        save.open = true;
    }
    function groupsRead(ids: var): void {
        if (!save.open || !save.reading) return;
        save.available = ids;
        save.selected = save.mode === "update" && root.preset ? root.preset.groups.filter(g => ids.indexOf(g) >= 0) : ids;
        save.reading = false;
    }
    function submitted(name: string, folder: string, groups: var): void {
        save.open = false;
        if (save.mode === "save") { root.followName = name; store.savePreset(name, folder, groups); }
        else if (root.preset) store.updatePreset(root.preset.file, groups, save.mode === "update");
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: InkSkin.small
        spacing: InkSkin.small
        FoldersPane {
            Layout.fillHeight: true
            Layout.fillWidth: root.narrow
            Layout.preferredWidth: InkSkin.body * 14
            visible: !root.narrow || root.page === "folders"
            store: store
            onPicked: folder => root.pickFolder(folder)
            onNewFolder: root.question("newFolder", "")
            onRenameFolder: name => root.question("renameFolder", name)
            onDeleteFolder: name => root.question("deleteFolder", name)
        }
        PresetsPane {
            Layout.fillHeight: true
            Layout.fillWidth: root.narrow
            Layout.preferredWidth: InkSkin.body * 22
            visible: !root.narrow || root.page === "list"
            store: store
            current: root.current
            heading: root.heading
            narrow: root.narrow
            onPicked: file => root.select(file)
            onSaveRequested: root.openSave()
            onFoldersRequested: root.page = "folders"
        }
        DetailPane {
            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !root.narrow || root.page === "detail"
            store: store
            preset: root.preset
            withWallpaper: PresetOptions.applyWallpaper
            narrow: root.narrow
            onApplyRequested: store.applyPreset(root.preset.file, PresetOptions.applyWallpaper)
            onPreviewRequested: { preview.open = true; store.previewApply(root.preset.file); }
            onUndoRequested: store.undo()
            onUpdateRequested: root.openUpdate()
            onGroupsRequested: root.openEdit()
            onRenameRequested: root.question("renamePreset", "")
            onMoveTo: folder => { root.followName = root.preset.name; store.movePreset(root.preset.file, folder); }
            onDeleteRequested: root.question("deletePreset", "")
            onWallpaperToggled: enabled => PresetOptions.set("applyWallpaper", enabled)
            onBackRequested: root.page = "list"
        }
    }

    Rectangle {
        visible: store.message !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: InkSkin.pad
        width: Math.min(root.width - InkSkin.pad * 2, toastRow.implicitWidth + InkSkin.pad * 2)
        height: toastRow.implicitHeight + InkSkin.gap * 2
        radius: InkSkin.smallRadius
        color: InkSkin.sheet
        border.color: store.ok ? InkSkin.edge : InkSkin.danger
        RowLayout {
            id: toastRow
            anchors.centerIn: parent
            width: parent.width - InkSkin.pad
            spacing: InkSkin.gap
            InkText { Layout.fillWidth: true; text: store.message; color: store.ok ? InkSkin.text : InkSkin.danger; wrapMode: Text.Wrap; elide: Text.ElideNone }
            InkButton { visible: store.ok && store.canUndo; label: Translation.tr("Undo"); symbol: "undo"; enabled: !store.busy; onClicked: store.undo() }
        }
        MouseArea { anchors.fill: parent; z: -1; onClicked: store.message = "" }
        Timer { running: store.message !== ""; interval: 8000; onTriggered: store.message = "" }
    }

    AskSheet { id: ask; anchors.fill: parent; onAccepted: value => root.answered(value); onClosed: ask.open = false }
    SaveSheet { id: save; anchors.fill: parent; onSubmitted: (name, folder, groups) => root.submitted(name, folder, groups); onClosed: save.open = false }
    PreviewSheet { id: preview; anchors.fill: parent; store: store; onClosed: preview.open = false }

    Shortcut { sequence: "Escape"; onActivated: root.leave() }
}
