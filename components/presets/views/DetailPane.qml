import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import "../skin"
import "../logic/PresetLogic.js" as Logic
import "../logic/StoreLogic.js" as Files

// The chosen preset and everything done with it.
Rectangle {
    id: root
    required property var store
    property var preset: null
    property bool withWallpaper: true
    property bool narrow: false
    readonly property bool idle: root.preset !== null && !root.store.busy
    signal applyRequested()
    signal previewRequested()
    signal undoRequested()
    signal updateRequested()
    signal groupsRequested()
    signal quickEditRequested()
    signal renameRequested()
    signal moveTo(string folder)
    signal deleteRequested()
    signal wallpaperToggled(bool enabled)
    signal backRequested()
    color: PrSkin.side
    radius: PrSkin.cardRadius

    function groupLabel(id: string): string {
        const group = Logic.GROUPS.find(g => g.id === id);
        return group ? Translation.tr(group.label) : id;
    }
    function when(made: string): string {
        const ms = Files.madeMs(made);
        return isNaN(ms) ? Translation.tr("Unknown date") : Qt.formatDateTime(new Date(ms), Locale.ShortFormat);
    }

    PrButton {
        visible: root.narrow
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: PrSkin.gap
        symbol: "arrow_back"; quiet: true; hint: Translation.tr("Presets")
        onClicked: root.backRequested()
    }
    PrText {
        visible: root.preset === null
        anchors.centerIn: parent
        width: parent.width - PrSkin.pad * 2
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: PrSkin.muted
        text: Translation.tr("Choose a preset to apply or change it.")
    }
    Flickable {
        visible: root.preset !== null
        anchors.fill: parent
        anchors.margins: PrSkin.pad
        anchors.topMargin: root.narrow ? PrSkin.pad + PrSkin.control : PrSkin.pad
        clip: true
        contentWidth: width
        contentHeight: column.implicitHeight
        ScrollBar.vertical: PrScrollBar {}
        ColumnLayout {
            id: column
            width: parent.width
            spacing: PrSkin.gap
            PrText { Layout.fillWidth: true; text: root.preset ? root.preset.name : ""; role: "title"; wrapMode: Text.WrapAnywhere; elide: Text.ElideNone }
            PrText {
                Layout.fillWidth: true
                role: "meta"; color: PrSkin.muted; wrapMode: Text.Wrap
                text: root.preset ? (root.preset.family !== "" ? Files.familyLabel(root.preset.family) + "  ·  " : "") + Translation.tr("%1 settings").arg(root.preset.settings) + "  ·  " + root.when(root.preset.made) : ""
            }
            Flow {
                Layout.fillWidth: true
                spacing: PrSkin.small / 2
                Repeater {
                    model: root.preset ? root.preset.groups : []
                    Chip { required property string modelData; text: root.groupLabel(modelData) }
                }
            }
            GroupCheck {
                visible: root.preset !== null && root.preset.hasWallpaper
                Layout.fillWidth: true
                label: Translation.tr("Also apply the wallpaper")
                checked: root.withWallpaper
                onToggled: value => root.wallpaperToggled(value)
            }
            PrText {
                visible: root.store.busy
                Layout.fillWidth: true
                role: "meta"; color: PrSkin.muted; wrapMode: Text.Wrap
                text: Translation.tr("Working on it…")
            }
            Flow {
                Layout.fillWidth: true
                spacing: PrSkin.small
                PrButton { label: Translation.tr("Apply"); symbol: "check"; primary: true; enabled: root.idle; onClicked: root.applyRequested() }
                PrButton { label: Translation.tr("Preview changes"); symbol: "visibility"; enabled: root.idle; onClicked: root.previewRequested() }
                PrButton { visible: root.store.canUndo; label: Translation.tr("Undo last apply"); symbol: "undo"; enabled: !root.store.busy; onClicked: root.undoRequested() }
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: PrSkin.edge }
            Flow {
                Layout.fillWidth: true
                spacing: PrSkin.small
                PrButton { label: Translation.tr("Update from current look"); symbol: "sync"; enabled: root.idle; onClicked: root.updateRequested() }
                PrButton { label: Translation.tr("Quick edit"); symbol: "edit_note"; enabled: root.idle; onClicked: root.quickEditRequested() }
                PrButton { label: Translation.tr("Edit saved groups"); symbol: "tune"; enabled: root.idle; onClicked: root.groupsRequested() }
                PrButton { label: Translation.tr("Rename"); symbol: "edit"; enabled: root.idle; onClicked: root.renameRequested() }
                PrButton { id: moveButton; label: Translation.tr("Move"); symbol: "folder"; enabled: root.idle; onClicked: root.openMove(moveButton) }
                PrButton { label: Translation.tr("Delete"); symbol: "delete"; danger: true; enabled: root.idle; onClicked: root.deleteRequested() }
            }
        }
    }

    function openMove(anchor: Item): void {
        const here = root.preset ? root.preset.folder : "";
        const targets = [""].concat(root.store.folders).filter(f => f !== here);
        if (targets.length === 0) return;
        moveMenu.model = targets.map(f => ({
            text: f === "" ? Translation.tr("No folder") : f,
            iconName: f === "" ? "folder_off" : "folder",
            action: () => root.moveTo(f)
        }));
        moveMenu.open(anchor, Qt.point(anchor.width / 2, anchor.height));
    }
    PrMenu { id: moveMenu }
}
