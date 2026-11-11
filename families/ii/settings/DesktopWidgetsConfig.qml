import qs
import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit
import qs.modules.common.functions
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.japaneseTypography
import "root:modules/shared/background/widgets/japaneseTypography/JapaneseTypographyPresets.js" as JapanesePresets

ContentPage {
    id: root
    settingsPageIndex: 14
    settingsPageName: Translation.tr("Widgets")

    property bool isIiActive: ["ii", "iris"].includes(Config.options?.panelFamily ?? "ii")
    readonly property bool irisActive: (Config.options?.panelFamily ?? "ii") === "iris"
    function openIrisWidgets(): void {
        GlobalStates.openSettingsAt("iris", "desktop/widgets")
    }
    property int _customMediaFolderCount: 0
    property int _customMediaFolderImageCount: 0
    property int _customMediaFolderGifCount: 0
    property int _customMediaFolderVideoCount: 0
    property int _taskLoadingCount: 0

    function activateSettingsSearchSection(section: string): bool {
        const parts = String(section || "").toLowerCase().split(/[·›]/)
        const label = parts[parts.length - 1].trim()
        const card = root._cards.find(entry => entry.group.toLowerCase() === label)
        const target = card?.tab ?? ({ "custom widgets": "personal", "organic edge": "edges", "screen edges": "edges" })[label] ?? ""
        if (target.length === 0)
            return false
        root.activeSection = target
        return true
    }

    component LazySection: Loader {
        id: sectionLoader
        property bool requested: false
        property bool resident: false
        property bool _countedLoading: false

        Layout.fillWidth: true
        asynchronous: true
        active: resident
        visible: requested && status !== Loader.Null
        enabled: requested && status === Loader.Ready && opacity > 0.99
        opacity: requested && status === Loader.Ready ? 1 : 0
        Layout.preferredHeight: requested && status === Loader.Ready && item ? item.implicitHeight : 0

        transform: Translate {
            y: sectionLoader.requested && sectionLoader.status === Loader.Ready ? 0 : 4
            Behavior on y {
                enabled: Appearance.animationsEnabled
                NumberAnimation {
                    duration: Appearance.animation.elementMoveEnter.duration
                    easing.type: Appearance.animation.elementMoveEnter.type
                    easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                }
            }
        }

        Behavior on opacity {
            enabled: Appearance.animationsEnabled
            NumberAnimation {
                duration: Appearance.animation.elementMoveEnter.duration
                easing.type: Appearance.animation.elementMoveEnter.type
                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
            }
        }

        function syncLoadingState(): void {
            const shouldCount = requested && status === Loader.Loading
            if (shouldCount === _countedLoading)
                return
            root._taskLoadingCount = Math.max(0, root._taskLoadingCount + (shouldCount ? 1 : -1))
            _countedLoading = shouldCount
        }

        onRequestedChanged: {
            if (requested) {
                unloadDelay.stop()
                resident = true
            } else if (status === Loader.Ready) {
                unloadDelay.restart()
            } else {
                unloadDelay.stop()
                resident = false
            }
            syncLoadingState()
        }
        onStatusChanged: syncLoadingState()
        Component.onCompleted: {
            if (requested)
                resident = true
            syncLoadingState()
        }
        Component.onDestruction: {
            if (_countedLoading)
                root._taskLoadingCount = Math.max(0, root._taskLoadingCount - 1)
        }
        Timer {
            id: unloadDelay
            interval: 600
            repeat: false
            onTriggered: parent.resident = false
        }
    }

    readonly property var _customImageShapes: [
        { value: "Circle", shape: MaterialShape.Shape.Circle },
        { value: "Square", shape: MaterialShape.Shape.Square },
        { value: "Slanted", shape: MaterialShape.Shape.Slanted },
        { value: "Arch", shape: MaterialShape.Shape.Arch },
        { value: "Fan", shape: MaterialShape.Shape.Fan },
        { value: "Arrow", shape: MaterialShape.Shape.Arrow },
        { value: "SemiCircle", shape: MaterialShape.Shape.SemiCircle },
        { value: "Oval", shape: MaterialShape.Shape.Oval },
        { value: "Pill", shape: MaterialShape.Shape.Pill },
        { value: "Triangle", shape: MaterialShape.Shape.Triangle },
        { value: "Diamond", shape: MaterialShape.Shape.Diamond },
        { value: "ClamShell", shape: MaterialShape.Shape.ClamShell },
        { value: "Pentagon", shape: MaterialShape.Shape.Pentagon },
        { value: "Gem", shape: MaterialShape.Shape.Gem },
        { value: "Sunny", shape: MaterialShape.Shape.Sunny },
        { value: "VerySunny", shape: MaterialShape.Shape.VerySunny },
        { value: "Cookie4Sided", shape: MaterialShape.Shape.Cookie4Sided },
        { value: "Cookie6Sided", shape: MaterialShape.Shape.Cookie6Sided },
        { value: "Cookie7Sided", shape: MaterialShape.Shape.Cookie7Sided },
        { value: "Cookie9Sided", shape: MaterialShape.Shape.Cookie9Sided },
        { value: "Cookie12Sided", shape: MaterialShape.Shape.Cookie12Sided },
        { value: "Ghostish", shape: MaterialShape.Shape.Ghostish },
        { value: "Clover4Leaf", shape: MaterialShape.Shape.Clover4Leaf },
        { value: "Clover8Leaf", shape: MaterialShape.Shape.Clover8Leaf },
        { value: "Burst", shape: MaterialShape.Shape.Burst },
        { value: "SoftBurst", shape: MaterialShape.Shape.SoftBurst },
        { value: "Boom", shape: MaterialShape.Shape.Boom },
        { value: "SoftBoom", shape: MaterialShape.Shape.SoftBoom },
        { value: "Flower", shape: MaterialShape.Shape.Flower },
        { value: "Puffy", shape: MaterialShape.Shape.Puffy },
        { value: "PuffyDiamond", shape: MaterialShape.Shape.PuffyDiamond },
        { value: "PixelCircle", shape: MaterialShape.Shape.PixelCircle },
        { value: "PixelTriangle", shape: MaterialShape.Shape.PixelTriangle },
        { value: "Bun", shape: MaterialShape.Shape.Bun },
        { value: "Heart", shape: MaterialShape.Shape.Heart }
    ]

    // A widget's option reads what the screen in front shows and writes every screen: a plain base write lost to the
    // screen's own copy of the key (set once from edit mode) and the row did nothing.
    function _widgetPath(path: string): var {
        const match = /^background\.widgets\.([A-Za-z]+)\.(.+)$/.exec(String(path ?? ""))
        return match && DesktopWidgetRegistry.entry(match[1]) ? { widget: match[1], key: match[2] } : null
    }
    function readPath(path: string, fallback: var): var {
        const at = root._widgetPath(path)
        return at ? DesktopWidgetOptions.value(at.widget, at.key, fallback) : Config.getNestedValue(path, fallback)
    }
    function writePath(path: string, value: var): void {
        root.writePaths({ [path]: value })
    }
    function writePaths(updates: var): void {
        const plain = ({})
        const byWidget = ({})
        for (const path of Object.keys(updates ?? {})) {
            const at = root._widgetPath(path)
            if (!at) {
                plain[path] = updates[path]
                continue
            }
            byWidget[at.widget] = Object.assign(byWidget[at.widget] ?? {}, { [at.key]: updates[path] })
        }
        if (Object.keys(plain).length > 0)
            Config.setNestedValues(plain)
        for (const widget of Object.keys(byWidget))
            DesktopWidgetLayout.setEverywhere(widget, byWidget[widget])
    }

    readonly property string _japanesePath: "background.widgets.japaneseTypography"
        && (Appearance.angelEverywhere
            || (Appearance.auroraEverywhere && !Appearance.inirEverywhere)
            || (!Appearance.zzzEverywhere && !Appearance.cookieEverywhere
                && !Appearance.angelEverywhere && !Appearance.auroraEverywhere
                && !Appearance.inirEverywhere
                && (Config.options?.background?.widgets?.style ?? "panel") === "island"
                && (Config.options?.material?.style?.island?.glass ?? true)
                && (Config.options?.material?.style?.island?.opacity ?? 1) < 0.999))

    function _setJapaneseValue(key: string, value: var, group: string): void {
        root.writePaths(JapanesePresets.setValue(root._japanesePath, key, value, group));
    }

    function _applyJapaneseCompositionPreset(preset: string): void {
        root.writePaths(JapanesePresets.composition(root._japanesePath, preset));
    }

    function _customMediaChoiceActive(choice: string): bool {
        const base = "background.widgets.customImage"
        const mode = root.readPath(base + ".sourceMode", "file")
        const filter = root.readPath(base + ".mediaFilter", "all")
        return mode === "file" ? choice === "file" : choice === filter
    }

    function _customMediaFolderUrl(path: string): string {
        const value = String(path ?? "")
        if (!value) return ""
        return value.startsWith("file:") ? value : "file://" + value
    }

    function _refreshCustomMediaFolderInventory(): void {
        let mediaCount = 0
        let imageCount = 0
        let gifCount = 0
        let videoCount = 0
        if (customMediaFolderInventory.status === FolderListModel.Ready) {
            for (let i = 0; i < customMediaFolderInventory.count; ++i) {
                const path = String(customMediaFolderInventory.get(i, "filePath")
                    || FileUtils.trimFileProtocol(customMediaFolderInventory.get(i, "fileURL")) || "")
                if (!Images.isValidMediaByName(path)) continue
                mediaCount++
                if (Images.isValidVideoByName(path)) videoCount++
                else if (path.toLowerCase().endsWith(".gif")) gifCount++
                else if (Images.isValidImageByName(path)) imageCount++
            }
        }
        root._customMediaFolderCount = mediaCount
        root._customMediaFolderImageCount = imageCount
        root._customMediaFolderGifCount = gifCount
        root._customMediaFolderVideoCount = videoCount

        const base = "background.widgets.customImage"
        const mode = root.readPath(base + ".sourceMode", "file")
        const filter = root.readPath(base + ".mediaFilter", "all")
        const selectedCount = filter === "images" ? imageCount
            : filter === "gifs" ? gifCount
            : filter === "videos" ? videoCount
            : mediaCount
        if (mode === "folder" && mediaCount > 0 && selectedCount === 0
                && filter !== "all")
            Qt.callLater(() => root.writePath(base + ".mediaFilter", "all"))
    }

    function _activateCustomMediaChoice(choice: string): void {
        const base = "background.widgets.customImage"
        const path = root.readPath(base + ".path", "")
        const updates = {}
        if (choice === "file") {
            if (!Images.isValidMediaByName(path)) return
            updates[base + ".sourceMode"] = "file"
        } else {
            const count = choice === "images" ? root._customMediaFolderImageCount
                : choice === "gifs" ? root._customMediaFolderGifCount
                : choice === "videos" ? root._customMediaFolderVideoCount
                : root._customMediaFolderCount
            if (count === 0) return
            updates[base + ".sourceMode"] = "folder"
            updates[base + ".mediaFilter"] = choice
        }
        root.writePaths(updates)
    }

    FolderListModel {
        id: customMediaFolderInventory
        folder: root._customMediaFolderUrl(
            root.readPath("background.widgets.customImage.folder", ""))
        nameFilters: Images.validImageExtensions.concat(Images.validVideoExtensions)
            .map(ext => "*." + ext)
        caseSensitive: false
        showDirs: false
        showDotAndDotDot: false
        showHidden: false
        showOnlyReadable: true
        sortField: FolderListModel.Name
        onCountChanged: root._refreshCustomMediaFolderInventory()
        onStatusChanged: if (status === FolderListModel.Ready)
            root._refreshCustomMediaFolderInventory()
        onFolderChanged: Qt.callLater(root._refreshCustomMediaFolderInventory)
    }

    FileDialog {
        id: customImageFileDialog
        title: Translation.tr("Choose media file")
        fileMode: FileDialog.OpenFile
        nameFilters: [
            Translation.tr("Media") + " (*.jpg *.jpeg *.png *.webp *.tif *.tiff *.svg *.gif *.mp4 *.webm *.mkv *.avi *.mov)",
            Translation.tr("Images") + " (*.jpg *.jpeg *.png *.webp *.tif *.tiff *.svg *.gif)",
            Translation.tr("Videos") + " (*.mp4 *.webm *.mkv *.avi *.mov)",
            Translation.tr("All files") + " (*)"
        ]
        onAccepted: {
            const path = FileUtils.trimFileProtocol(String(selectedFile));
            if (Images.isValidMediaByName(path)) {
                root.writePaths({
                    "background.widgets.customImage.path": path,
                    "background.widgets.customImage.sourceMode": "file"
                });
            }
        }
    }

    FolderDialog {
        id: customImageFolderDialog
        title: Translation.tr("Choose media folder")
        onAccepted: {
            const path = FileUtils.trimFileProtocol(String(selectedFolder));
            if (path.length > 0) {
                root.writePaths({
                    "background.widgets.customImage.folder": path,
                    "background.widgets.customImage.sourceMode": "folder"
                });
            }
        }
    }

    SettingsNativeDialogGuard {
        dialog: customImageFileDialog
        dialogKey: "desktop-widgets-custom-media-file"
    }

    SettingsNativeDialogGuard {
        dialog: customImageFolderDialog
        dialogKey: "desktop-widgets-custom-media-folder"
    }

    function _applyJapanesePalettePreset(preset: string): void {
        root.writePaths(JapanesePresets.palette(root._japanesePath, preset));
    }


    // Zone names for placement strategy resolution
    readonly property var _zoneNames: ["topLeft", "topCenter", "topRight", "centerLeft", "center", "centerRight", "bottomLeft", "bottomCenter", "bottomRight"]

    // Resolve any zone name to the display mode "zone"
    function _resolvedMode(strategy: string): string {
        if (root._zoneNames.indexOf(strategy) >= 0) return "zone";
        return strategy;
    }

    // Handle mode selection — when "zone" selected, default to center
    function _applyMode(configPath: string, mode: string, currentStrategy: string): void {
        if (mode === "zone") {
            // If already on a zone, keep it; otherwise default to center
            if (root._zoneNames.indexOf(currentStrategy) < 0)
                root.writePath(configPath + ".placementStrategy", "center");
        } else {
            root.writePath(configPath + ".placementStrategy", mode);
        }
    }

    function _placementOptions(): var {
        return [
            { displayName: Translation.tr("Draggable"), icon: "drag_pan", value: "free" },
            { displayName: Translation.tr("Least busy"), icon: "category", value: "leastBusy" },
            { displayName: Translation.tr("Most busy"), icon: "shapes", value: "mostBusy" },
            { displayName: Translation.tr("Zone"), icon: "grid_view", value: "zone" },
        ]
    }


    readonly property var _paletteWidgetKeys: DesktopWidgetRegistry.paletteKeys

    function _semanticRoleOptions(): var {
        return [
            { displayName: Translation.tr("Primary"), icon: "palette", value: "primary" },
            { displayName: Translation.tr("Secondary"), icon: "filter_2", value: "secondary" },
            { displayName: Translation.tr("Tertiary"), icon: "filter_3", value: "tertiary" },
            { displayName: Translation.tr("Warning"), icon: "warning", value: "warning" },
            { displayName: Translation.tr("Signal"), icon: "error", value: "signal" },
            { displayName: Translation.tr("Surface"), icon: "layers", value: "surface" }
        ]
    }

    function _palettePresetOptions(): var {
        return [
            { value: "balanced", label: Translation.tr("Default"), roles: ["primary", "secondary", "tertiary"] },
            { value: "primary", label: Translation.tr("Primary"), roles: ["primary", "primary", "primary"] },
            { value: "secondary", label: Translation.tr("Secondary"), roles: ["secondary", "secondary", "secondary"] },
            { value: "tertiary", label: Translation.tr("Tertiary"), roles: ["tertiary", "tertiary", "tertiary"] }
        ]
    }

    function _palettePresetSpec(preset: string): var {
        switch (preset) {
        case "primary":
            return { primary: "primary", secondary: "primary", tertiary: "primary", signal: "signal", surface: "surface" };
        case "secondary":
            return { primary: "secondary", secondary: "secondary", tertiary: "secondary", signal: "signal", surface: "surface" };
        case "tertiary":
            return { primary: "tertiary", secondary: "tertiary", tertiary: "tertiary", signal: "signal", surface: "surface" };
        default:
            return { primary: "primary", secondary: "secondary", tertiary: "tertiary", signal: "signal", surface: "surface" };
        }
    }

    function _palettePresetForPath(configPath: string): string {
        const roles = {
            primary: String(root.readPath(configPath + ".palette.primary", "primary")),
            secondary: String(root.readPath(configPath + ".palette.secondary", "secondary")),
            tertiary: String(root.readPath(configPath + ".palette.tertiary", "tertiary")),
            signal: String(root.readPath(configPath + ".palette.signal", "signal")),
            surface: String(root.readPath(configPath + ".palette.surface", "surface"))
        }
        for (const preset of root._palettePresetOptions()) {
            const spec = root._palettePresetSpec(preset.value)
            if (roles.primary === spec.primary && roles.secondary === spec.secondary
                    && roles.tertiary === spec.tertiary && roles.signal === spec.signal
                    && roles.surface === spec.surface)
                return preset.value
        }
        return "custom"
    }

    function _applyPalettePreset(configPath: string, preset: string): void {
        const spec = root._palettePresetSpec(preset)
        const prefix = configPath + ".palette."
        const updates = {}
        updates[prefix + "primary"] = spec.primary
        updates[prefix + "secondary"] = spec.secondary
        updates[prefix + "tertiary"] = spec.tertiary
        updates[prefix + "signal"] = spec.signal
        updates[prefix + "surface"] = spec.surface
        root.writePaths(updates)
    }

    function _commonPalettePreset(): string {
        let common = ""
        for (const widgetKey of root._paletteWidgetKeys) {
            const preset = root._palettePresetForPath("background.widgets." + widgetKey)
            if (preset === "custom") return "mixed"
            if (common.length === 0) common = preset
            else if (common !== preset) return "mixed"
        }
        return common.length > 0 ? common : "balanced"
    }

    function _applyPalettePresetAll(preset: string): void {
        const spec = root._palettePresetSpec(preset)
        const updates = {}
        for (const widgetKey of root._paletteWidgetKeys) {
            const prefix = "background.widgets." + widgetKey + ".palette."
            updates[prefix + "primary"] = spec.primary
            updates[prefix + "secondary"] = spec.secondary
            updates[prefix + "tertiary"] = spec.tertiary
            updates[prefix + "signal"] = spec.signal
            updates[prefix + "surface"] = spec.surface
        }
        root.writePaths(updates)
    }

    function _semanticPreviewColor(role: string): color {
        switch (role) {
        case "secondary": return Appearance.colors.colSecondary
        case "tertiary": return Appearance.colors.colTertiary
        default: return Appearance.colors.colPrimary
        }
    }


    function _customWidgetInstalled(widgetId: string): bool {
        if (!CustomWidgets.ready) return false;
        for (let i = 0; i < CustomWidgets.widgets.length; i++) {
            if (CustomWidgets.widgets[i].id === widgetId)
                return true;
        }
        return false;
    }

    function _zoneDisplayName(zone: string): string {
        const labels = {
            topLeft: Translation.tr("Top left"),
            topCenter: Translation.tr("Top center"),
            topRight: Translation.tr("Top right"),
            centerLeft: Translation.tr("Center left"),
            center: Translation.tr("Center"),
            centerRight: Translation.tr("Center right"),
            bottomLeft: Translation.tr("Bottom left"),
            bottomCenter: Translation.tr("Bottom center"),
            bottomRight: Translation.tr("Bottom right")
        };
        return labels[zone] ?? Translation.tr("Zone");
    }

    // ── Reusable zone picker (3x3 grid) ────────────────────────
    component WidgetZonePicker: ColumnLayout {
        id: wzp
        required property string configPath
        Layout.fillWidth: true

        readonly property string currentStrategy: root.readPath(wzp.configPath + ".placementStrategy", "free")
        readonly property bool isZone: root._zoneNames.indexOf(currentStrategy) >= 0
        visible: isZone

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8

            MaterialSymbol {
                text: "grid_view"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Selected zone: %1").arg(root._zoneDisplayName(wzp.currentStrategy))
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
            }
        }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Choose the screen region this widget should occupy. The widget stays attached to that zone when its size or the screen geometry changes.")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            implicitHeight: zonePlate.implicitHeight

            Rectangle {
                id: zonePlate
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: zoneGrid.implicitWidth + 16
                implicitHeight: zoneGrid.implicitHeight + 16
                radius: Appearance.rounding.small
                color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.05)
                border.width: 1
                border.color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)

                Grid {
                    id: zoneGrid
                    anchors.centerIn: parent
                    columns: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { zone: "topLeft", icon: "north_west" },
                            { zone: "topCenter", icon: "north" },
                            { zone: "topRight", icon: "north_east" },
                            { zone: "centerLeft", icon: "west" },
                            { zone: "center", icon: "filter_center_focus" },
                            { zone: "centerRight", icon: "east" },
                            { zone: "bottomLeft", icon: "south_west" },
                            { zone: "bottomCenter", icon: "south" },
                            { zone: "bottomRight", icon: "south_east" }
                        ]
                        delegate: RippleButton {
                            required property var modelData
                            width: 36; height: 36
                            buttonRadius: Appearance.rounding.small
                            toggled: wzp.currentStrategy === modelData.zone
                            colBackground: "transparent"
                            colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.06)
                            colBackgroundToggled: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.16)
                            colBackgroundToggledHover: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.24)
                            colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
                            downAction: () => root.writePath(wzp.configPath + ".placementStrategy", modelData.zone)
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: modelData.icon
                                iconSize: 18
                                color: parent.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }
                            StyledToolTip { text: root._zoneDisplayName(modelData.zone) }
                        }
                    }
                }
            }
        }
    }

    // ── Reusable placement selector (resolves zone names) ──────
    component WidgetPlacementSelector: ConfigSelectionArray {
        id: wps
        required property string configPath
        required property string defaultStrategy
        Layout.fillWidth: true
        Layout.preferredWidth: 360
        Layout.minimumWidth: 180

        readonly property string currentStrategy: root.readPath(wps.configPath + ".placementStrategy", wps.defaultStrategy)

        currentValue: root._resolvedMode(wps.currentStrategy)
        onSelected: newValue => root._applyMode(wps.configPath, newValue, wps.currentStrategy)
        options: root._placementOptions()
    }

    component WidgetSettingRow: RowLayout {
        id: wsr
        property string label: ""
        property string icon: ""
        property bool trailing: true
        default property alias controlData: controlRow.data

        Layout.fillWidth: true
        spacing: 10

        MaterialSymbol {
            visible: wsr.icon.length > 0
            text: wsr.icon
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            Layout.alignment: Qt.AlignVCenter
        }

        // Label fills the row so a right-aligned control hugs the edge with no
        // dead gap (mascot-page density). When the control itself should stretch
        // (trailing:false, e.g. a selection array), the label hugs instead.
        StyledText {
            text: wsr.label
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
            Layout.fillWidth: wsr.trailing
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            id: controlRow
            Layout.fillWidth: !wsr.trailing
            Layout.alignment: Qt.AlignVCenter
            spacing: 8
        }
    }

    component WidgetToggleChip: SelectionGroupButton {
        id: wtc
        required property string configPath
        property bool defaultValue: false

        Layout.fillWidth: false
        leftmost: true; rightmost: true
        toggled: Boolean(root.readPath(wtc.configPath, wtc.defaultValue))
        onClicked: root.writePath(wtc.configPath, !wtc.toggled)
    }

    // Widget enable toggles must agree with the desktop editor, which stores
    // per-output overrides. Show the effective state and clear overrides on change
    // so the base enable value is the single source of truth for settings.
    // A choice for every widget at once: none lit while they disagree, and it says so.
    component EveryWidgetRow: WidgetSettingRow {
        id: everyRow
        property string optionKey: ""
        property var options: []
        readonly property string shared: DesktopWidgetOptions.everyState(everyRow.optionKey)
        trailing: false
        visible: everyRow.shared !== ""

        ConfigSelectionArray {
            Layout.fillWidth: false
            enableSettingsSearch: false
            currentValue: everyRow.shared
            options: everyRow.options
            onSelected: newValue => DesktopWidgetOptions.setEvery(everyRow.optionKey,
                newValue === "true" ? true : newValue === "false" ? false : newValue)
        }
        StyledText {
            visible: everyRow.shared === "mixed"
            text: Translation.tr("Mixed")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }

    // The plates' strength, written once on release (each step rewrote every widget).
    component EveryWidgetStrength: WidgetSettingRow {
        id: everyStrength
        readonly property string shared: DesktopWidgetOptions.everyState("backgroundOpacity")
        readonly property string plates: DesktopWidgetOptions.everyState("showBackground")
        label: Translation.tr("Background strength")
        icon: "opacity"
        trailing: false
        visible: everyStrength.shared !== "" && everyStrength.plates !== "false"

        StyledSlider {
            id: everySlider
            Layout.fillWidth: true
            configuration: StyledSlider.Configuration.S
            stopIndicatorValues: []
            from: 0; to: 100; stepSize: 2
            value: everyStrength.shared === "mixed" ? 16 : Math.round(Number(everyStrength.shared) * 100)
            onPressedChanged: if (!pressed) DesktopWidgetOptions.setEvery("backgroundOpacity", Math.round(everySlider.value) / 100)
            onMoved: if (!pressed) DesktopWidgetOptions.setEvery("backgroundOpacity", Math.round(everySlider.value) / 100)
        }
        StyledText {
            Layout.preferredWidth: 52
            horizontalAlignment: Text.AlignRight
            text: everyStrength.shared === "mixed" && !everySlider.pressed ? Translation.tr("Mixed") : Math.round(everySlider.value) + "%"
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            font.family: Appearance.font.family.numbers
        }
    }

    component WidgetStateChip: SelectionGroupButton {
        id: wsc
        property bool active: false
        property var toggleAction

        Layout.fillWidth: false
        leftmost: true; rightmost: true
        toggled: wsc.active
        onClicked: if (wsc.toggleAction) wsc.toggleAction(!wsc.active)
    }

    component WidgetEnableChip: SelectionGroupButton {
        id: wec
        required property string widgetKey
        property bool defaultValue: false

        Layout.fillWidth: false
        leftmost: true; rightmost: true
        toggled: DesktopWidgetLayout.effectiveEnabled(wec.widgetKey, wec.defaultValue)
        onClicked: DesktopWidgetLayout.setGloballyEnabled(wec.widgetKey, !wec.toggled)
    }



    component WidgetResetButton: RippleButton {
        id: wrb
        required property string configPath
        required property var defaults
        property bool resetSemanticPalette: wrb.configPath.startsWith("background.widgets.")
            && !wrb.configPath.startsWith("background.widgets.custom.")
        property bool armed: false
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignRight
        implicitHeight: 32
        implicitWidth: wrbRow.implicitWidth + 24
        buttonRadius: Appearance.rounding.full
        toggled: wrb.armed
        colBackground: "transparent"
        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)
        colBackgroundToggled: ColorUtils.applyAlpha(Appearance.colors.colError, 0.14)
        colBackgroundToggledHover: ColorUtils.applyAlpha(Appearance.colors.colError, 0.22)
        onClicked: {
            if (!wrb.armed) {
                wrb.armed = true
                wrbResetTimer.restart()
                return
            }
            wrb.armed = false
            wrbResetTimer.stop()
            const updates = {}
            for (const key in wrb.defaults) {
                // A reset keeps the widget on the desktop and where it stands.
                if (key === "enable" || key === "x" || key === "y")
                    continue
                updates[wrb.configPath + "." + key] = wrb.defaults[key]
            }
            if (wrb.resetSemanticPalette) {
                const spec = root._palettePresetSpec("balanced")
                const prefix = wrb.configPath + ".palette."
                updates[prefix + "primary"] = spec.primary
                updates[prefix + "secondary"] = spec.secondary
                updates[prefix + "tertiary"] = spec.tertiary
                updates[prefix + "signal"] = spec.signal
                updates[prefix + "surface"] = spec.surface
            }
            root.writePaths(updates)
        }
        Timer {
            id: wrbResetTimer
            interval: 3000
            onTriggered: wrb.armed = false
        }
        contentItem: Item {
            implicitWidth: wrbRow.implicitWidth
            implicitHeight: wrbRow.implicitHeight
            RowLayout {
                id: wrbRow
                width: Math.min(implicitWidth, parent.width)
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol {
                    text: wrb.armed ? "warning" : "restart_alt"
                    iconSize: 18
                    color: wrb.armed ? Appearance.colors.colError : Appearance.colors.colSubtext
                }
                StyledText {
                    text: wrb.armed ? Translation.tr("Confirm reset") : Translation.tr("Reset to defaults")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: wrb.armed ? Appearance.colors.colError : Appearance.colors.colSubtext
                }
            }
        }
        StyledToolTip {
            text: wrb.armed
                ? Translation.tr("Click again to restore this widget's defaults")
                : Translation.tr("Restore this widget's default settings")
        }
    }

    component PowerSavingSwitchRow: WidgetSettingRow {
        id: psRow
        required property string psKey
        property bool psDefault: true
        readonly property string _psPath: "background.widgets.powerSaving." + psKey
        StyledSwitch {
            checked: Boolean(root.readPath(psRow._psPath, psRow.psDefault))
            onCheckedChanged: {
                if (checked !== Boolean(root.readPath(psRow._psPath, psRow.psDefault)))
                    root.writePath(psRow._psPath, checked)
            }
        }
    }

    // ── Reusable percentage row ──────────────────────────────
    component SliderRow: WidgetSettingRow {
        id: sliderRow
        property string configPath: ""
        property string tooltipText: ""
        property real sliderFrom: 0
        property real sliderTo: 100
        property real sliderStep: 5
        property real sliderValue: 0
        // Normalized config values are stored as 0..1. Older or malformed
        // 0..100 values are accepted and clamped instead of displaying 10000%.
        property bool isNormalized: false

        trailing: false

        function _clamp(value: real): real {
            return Math.max(sliderRow.sliderFrom, Math.min(sliderRow.sliderTo, value));
        }

        function _displayValue(value: var): real {
            const numeric = Number(value);
            if (!Number.isFinite(numeric))
                return sliderRow.sliderFrom;
            if (!sliderRow.isNormalized)
                return sliderRow._clamp(numeric);
            return sliderRow._clamp(numeric <= 1 ? numeric * 100 : numeric);
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledSlider {
                id: _slider
                Layout.fillWidth: true
                configuration: StyledSlider.Configuration.S
                stopIndicatorValues: []
                from: sliderRow.sliderFrom
                to: sliderRow.sliderTo
                stepSize: sliderRow.sliderStep
                value: sliderRow._displayValue(sliderRow.sliderValue)
                onMoved: {
                    const displayValue = sliderRow._clamp(_slider.value);
                    root.writePath(sliderRow.configPath,
                        sliderRow.isNormalized ? Math.round(displayValue) / 100 : Math.round(displayValue));
                }
                StyledToolTip {
                    visible: sliderRow.tooltipText.length > 0
                    text: sliderRow.tooltipText
                }
            }

            StyledText {
                Layout.preferredWidth: 44
                horizontalAlignment: Text.AlignRight
                text: Math.round(sliderRow._clamp(_slider.value)) + "%"
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.numbers
            }
        }
    }

    component WidgetPalettePresetPicker: ColumnLayout {
        id: palettePicker
        required property string configPath
        property bool applyGlobally: false

        Layout.fillWidth: true
        spacing: 7

        readonly property string currentPreset: {
            void Config.revision
            return palettePicker.applyGlobally
                ? root._commonPalettePreset()
                : root._palettePresetForPath(palettePicker.configPath)
        }

        GridLayout {
            id: palettePresetGrid
            Layout.fillWidth: true
            columns: palettePicker.width >= 520 ? 4 : 2
            columnSpacing: 6
            rowSpacing: 6

            Repeater {
                model: root._palettePresetOptions()

                delegate: RippleButton {
                    id: presetButton
                    required property var modelData
                    readonly property color presetAccent: root._semanticPreviewColor(modelData.roles[0])
                    Layout.fillWidth: true
                    Layout.minimumWidth: 112
                    Layout.preferredHeight: 38
                    buttonRadius: Appearance.rounding.small
                    toggled: palettePicker.currentPreset === modelData.value
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundToggled: ColorUtils.mix(
                        Appearance.colors.colLayer2, presetButton.presetAccent, 0.93)
                    colBackgroundToggledHover: ColorUtils.mix(
                        Appearance.colors.colLayer2Hover, presetButton.presetAccent, 0.90)
                    colRipple: ColorUtils.applyAlpha(presetButton.presetAccent, 0.10)
                    colRippleToggled: ColorUtils.applyAlpha(presetButton.presetAccent, 0.14)
                    downAction: () => {
                        if (palettePicker.applyGlobally)
                            root._applyPalettePresetAll(modelData.value)
                        else
                            root._applyPalettePreset(palettePicker.configPath, modelData.value)
                    }

                    contentItem: Item {
                        Rectangle {
                            anchors.fill: parent
                            radius: presetButton.buttonRadius
                            color: "transparent"
                            border.width: presetButton.toggled ? 1.5 : 0
                            border.color: presetButton.presetAccent
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Row {
                                spacing: -4
                                Repeater {
                                    model: presetButton.modelData.roles
                                    Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: root._semanticPreviewColor(modelData)
                                        border.width: 1
                                        border.color: Qt.rgba(0, 0, 0, 0.25)
                                        z: 3 - index
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: presetButton.modelData.label
                                color: presetButton.toggled
                                    ? presetButton.presetAccent : Appearance.colors.colOnLayer2
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: presetButton.toggled ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            visible: palettePicker.currentPreset === "custom"
                || palettePicker.currentPreset === "mixed"
            text: palettePicker.currentPreset === "mixed"
                ? Translation.tr("Widgets currently use different palettes")
                : Translation.tr("Custom role mapping")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
        }
    }


    component JapaneseCompositionPicker: ColumnLayout {
        id: compositionPicker
        Layout.fillWidth: true
        spacing: 8

        readonly property string currentPreset: root.readPath(root._japanesePath + ".preset", "exhibition")

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { value: "exhibition", label: Translation.tr("Exhibition"), mirror: false, secondary: true, seal: true, footer: true },
                    { value: "magazine", label: Translation.tr("Magazine"), mirror: true, secondary: true, seal: true, footer: true },
                    { value: "minimal", label: Translation.tr("Minimal"), mirror: false, secondary: false, seal: false, footer: false },
                    { value: "traditional", label: Translation.tr("Traditional"), mirror: true, secondary: true, seal: true, footer: false }
                ]

                delegate: RippleButton {
                    id: compositionCard
                    required property var modelData
                    width: 136
                    height: 112
                    buttonRadius: Appearance.rounding.small
                    toggled: compositionPicker.currentPreset === modelData.value
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.035)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.075)
                    colBackgroundToggled: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.14)
                    colBackgroundToggledHover: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.20)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10)
                    downAction: () => root._applyJapaneseCompositionPreset(modelData.value)

                    contentItem: ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            VerticalJapaneseText {
                                x: compositionCard.modelData.mirror ? parent.width - width - 2 : 2
                                y: 2
                                width: 48
                                height: parent.height - 8
                                text: "夏の記憶"
                                fontFamily: "serif"
                                fontPixelSize: compositionCard.modelData.value === "minimal" ? 20 : 16
                                fontWeight: Font.DemiBold
                                letterSpacing: 0
                                columnGap: 3
                                maxColumns: compositionCard.modelData.value === "minimal" ? 1 : 2
                                color: compositionCard.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            }

                            VerticalJapaneseText {
                                visible: compositionCard.modelData.secondary
                                x: compositionCard.modelData.mirror ? 38 : 54
                                y: 6
                                width: 30
                                height: parent.height - 16
                                text: "潮風と夏"
                                fontFamily: "serif"
                                fontPixelSize: 9
                                letterSpacing: 0
                                columnGap: 2
                                maxColumns: 2
                                color: Appearance.colors.colSubtext
                            }

                            Rectangle {
                                visible: compositionCard.modelData.seal
                                x: compositionCard.modelData.mirror ? 2 : parent.width - width - 2
                                y: 2
                                width: 17
                                height: 34
                                color: "transparent"
                                border.width: 1
                                border.color: Appearance.colors.colTertiary
                                StyledText {
                                    anchors.centerIn: parent
                                    text: "展"
                                    color: Appearance.colors.colTertiary
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            Rectangle {
                                visible: compositionCard.modelData.footer
                                x: compositionCard.modelData.mirror ? parent.width - width - 2 : 2
                                anchors.bottom: parent.bottom
                                width: parent.width * 0.68
                                height: 1
                                color: Appearance.colors.colPrimary
                                opacity: 0.65
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: compositionCard.modelData.label
                            horizontalAlignment: Text.AlignHCenter
                            color: compositionCard.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: compositionCard.toggled ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component JapanesePalettePicker: ColumnLayout {
        id: palettePicker
        Layout.fillWidth: true
        spacing: 8

        readonly property string currentPreset: root.readPath(root._japanesePath + ".palettePreset", "adaptive")

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { value: "adaptive", label: Translation.tr("Adaptive"), colors: [] },
                    { value: "sumi", label: Translation.tr("Sumi ink"), colors: ["#17130F", "#493D31", "#9D382B"] },
                    { value: "ivory", label: Translation.tr("Ivory"), colors: ["#F3E8D3", "#D8C3A2", "#C76049"] },
                    { value: "sunset", label: Translation.tr("Sunset"), colors: ["#E6C49A", "#C39D73", "#A94B37"] },
                    { value: "cinema", label: Translation.tr("Cinema"), colors: ["#F1EEE7", "#AAA299", "#D9684B"] }
                ]

                delegate: RippleButton {
                    id: paletteCard
                    required property var modelData
                    readonly property var swatches: modelData.value === "adaptive"
                        ? [Appearance.colors.colOnLayer0, Appearance.colors.colPrimary, Appearance.colors.colTertiary]
                        : modelData.colors
                    width: 136
                    height: 54
                    buttonRadius: Appearance.rounding.small
                    toggled: palettePicker.currentPreset === modelData.value
                    colBackground: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.035)
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.075)
                    colBackgroundToggled: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.14)
                    colBackgroundToggledHover: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.20)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10)
                    downAction: () => root._applyJapanesePalettePreset(modelData.value)

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Row {
                            spacing: -4
                            Repeater {
                                model: paletteCard.swatches
                                Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: modelData
                                    border.width: 1
                                    border.color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.22)
                                    z: 3 - index
                                }
                            }
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: paletteCard.modelData.label
                            color: paletteCard.toggled ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: paletteCard.toggled ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    component JapaneseColorPickerRow: Item {
        id: colorRow
        required property string label
        required property string configKey
        required property string fallbackColor

        Layout.fillWidth: true
        implicitHeight: 40
        readonly property color currentColor: {
            const parsed = Qt.color(String(root.readPath(root._japanesePath + "." + colorRow.configKey, colorRow.fallbackColor)));
            return parsed.valid ? parsed : Qt.color(colorRow.fallbackColor);
        }

        RowLayout {
            anchors.fill: parent
            spacing: 10

            StyledText {
                Layout.fillWidth: true
                text: colorRow.label
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                elide: Text.ElideRight
            }

            RippleButton {
                implicitWidth: 132
                implicitHeight: 34
                buttonRadius: Appearance.rounding.full
                colBackground: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.055)
                colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.10)
                colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10)
                downAction: () => colorDialog.open()

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 7

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: colorRow.currentColor
                        border.width: 1
                        border.color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.25)
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: colorRow.currentColor.toString().toUpperCase().substring(0, 7)
                        color: Appearance.colors.colSubtext
                        font.family: Appearance.font.family.monospace
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        elide: Text.ElideRight
                    }

                    MaterialSymbol {
                        text: "edit"
                        iconSize: 16
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        ColorDialog {
            id: colorDialog
            selectedColor: colorRow.currentColor
            onAccepted: root._setJapaneseValue(colorRow.configKey, selectedColor.toString(), "palette")
        }

        SettingsNativeDialogGuard {
            dialog: colorDialog
            dialogKey: "desktop-widgets-japanese-color"
        }
    }

    // ── A widget's card: every row comes from its manifest (DesktopWidgetOptions) ──
    component WidgetCard: SettingsCardSection {
        id: card
        required property var entry
        readonly property string widget: card.entry.key
        readonly property var hand: root._cardExtras[card.widget] ?? ({})
        readonly property bool hasColours: DesktopWidgetRegistry.paletteKeys.includes(card.widget)
        readonly property var rows: DesktopWidgetOptions.widgetRows.filter(spec => spec.widget === card.widget && !(card.hand.drawn ?? []).includes(spec.key))
        readonly property var shown: {
            void Config.revision
            return card.rows.filter(spec => spec.widgetEnable || spec.showIf())
        }
        readonly property bool isOn: card.shown.length > 1
        // The head says what it is, then its rows by part, then how it looks and where it sits.
        readonly property var layout: {
            const names = []
            const rowsIn = ({})
            const put = (name, spec) => {
                if (!rowsIn[name]) {
                    rowsIn[name] = []
                    names.push(name)
                }
                rowsIn[name].push(spec)
            }
            const heads = ["sizeClass", DesktopWidgetDesign.spec.key]
            for (const spec of card.shown.filter(spec => spec.widgetEnable || heads.includes(spec.key)))
                put("", spec)
            for (const spec of card.shown.filter(spec => (spec.page ?? "widget") === "widget" && !spec.widgetEnable && !heads.includes(spec.key)))
                put(String(spec.part ?? "Options"), spec)
            for (const spec of card.shown.filter(spec => spec.page === "look" && !heads.includes(spec.key)))
                put("Look", spec)
            for (const spec of card.shown.filter(spec => spec.page === "arrange"))
                put("Arrange", spec)
            return { names: names, rowsIn: rowsIn }
        }
        readonly property var blocks: {
            const list = []
            for (const name of card.layout.names) {
                list.push({ id: "rows:" + name, name: name })
                if (name === "" && card.isOn && card.hand.extra)
                    list.push({ id: "extra", name: "" })
                if (name === "Look" && card.isOn && card.hasColours)
                    list.push({ id: "colours", name: "" })
            }
            if (card.isOn)
                list.push({ id: "reset", name: "" })
            return list
        }
        onBlocksChanged: Qt.callLater(card.relayoutTiles)

        settingsTaskSection: card.entry.tab
        icon: DesktopWidgetRegistry.entries.find(entry => entry.key === card.widget)?.glyph ?? "widgets"
        title: Translation.tr(card.entry.group)

        Repeater {
            model: ScriptModel { objectProp: "id"; values: card.blocks }
            delegate: Loader {
                id: cardBlock
                required property var modelData
                Layout.fillWidth: true
                sourceComponent: cardBlock.modelData.id === "extra" ? (card.hand.extra ?? null)
                    : cardBlock.modelData.id === "colours" ? coloursBlock
                    : cardBlock.modelData.id === "reset" ? resetBlock : rowsBlock
                onLoaded: Qt.callLater(card.relayoutTiles)
                Component {
                    id: rowsBlock
                    ContentSubsection {
                        id: rowsHere
                        title: cardBlock.modelData.name.length > 0 ? Translation.tr(cardBlock.modelData.name) : ""
                        Repeater {
                            model: ScriptModel {
                                objectProp: "path"
                                values: card.layout.rowsIn[cardBlock.modelData.name] ?? []
                            }
                            delegate: WidgetOptionRow {}
                        }
                    }
                }
                Component {
                    id: coloursBlock
                    WidgetColours { configPath: "background.widgets." + card.widget }
                }
                Component {
                    id: resetBlock
                    SettingsGroup {
                        WidgetResetButton {
                            configPath: "background.widgets." + card.widget
                            defaults: DesktopWidgetRegistry.defaultsOf(card.widget)
                        }
                    }
                }
            }
        }
    }

    // One row, drawn by its kind.
    component WidgetOptionRow: Loader {
        id: optionRow
        required property var modelData
        readonly property var spec: optionRow.modelData
        readonly property int picks: (optionRow.spec.choicesFrom ? DesktopWidgetOptions.choicesFor(String(optionRow.spec.choicesFrom)) : (optionRow.spec.choices ?? [])).length
        Layout.fillWidth: true
        sourceComponent: optionRow.spec.key === "placementStrategy" ? placementRow
            : optionRow.spec.kind === "switch" ? switchRow
            : optionRow.spec.kind === "range" ? rangeRow
            : optionRow.spec.kind === "choice" ? (optionRow.picks > 12 ? comboRow : choiceRow)
            : optionRow.spec.kind === "action" ? actionRow
            : /[Ff]ontFamily$/.test(optionRow.spec.key) ? fontRow : textRow
        onLoaded: item.spec = optionRow.spec
    }
    function _rowLabel(spec: var): string {
        return Translation.tr(String(spec?.label ?? ""))
    }
    function _rowPicks(spec: var): var {
        return spec?.choicesFrom ? DesktopWidgetOptions.choicesFor(String(spec.choicesFrom)) : (spec?.choices ?? [])
    }
    function _rowValue(spec: var): var {
        void Config.revision
        return spec?.path ? DesktopWidgetOptions.read(spec) : undefined
    }
    Component {
        id: switchRow
        SettingsSwitch {
            property var spec: ({})
            text: root._rowLabel(spec)
            description: spec.description ? Translation.tr(spec.description) : ""
            autoToggle: false
            checked: Boolean(root._rowValue(spec))
            onToggledByUser: next => DesktopWidgetOptions.write(spec, next)
        }
    }
    Component {
        id: rangeRow
        ConfigSpinBox {
            id: range
            property var spec: ({})
            readonly property real factor: Number(range.spec.scale ?? 1)
            text: root._rowLabel(range.spec)
            description: range.spec.description ? Translation.tr(range.spec.description) : ""
            unit: String(range.spec.unit ?? "").trim()
            from: Math.round(Number(range.spec.min ?? 0) * range.factor)
            to: Math.round(Number(range.spec.max ?? 100) * range.factor)
            stepSize: Math.max(1, Math.round(Number(range.spec.step ?? 1) * range.factor))
            specialValueText: range.spec.lowLabel ? Translation.tr(range.spec.lowLabel)
                : range.spec.zeroLabel && Number(range.spec.min ?? 0) === 0 ? Translation.tr(range.spec.zeroLabel) : ""
            value: Math.round(Number(root._rowValue(range.spec) ?? 0) * range.factor)
            onValueModified: DesktopWidgetOptions.write(range.spec, range.value / range.factor)
        }
    }
    Component {
        id: choiceRow
        WidgetSettingRow {
            id: choice
            property var spec: ({})
            label: root._rowLabel(choice.spec)
            trailing: false
            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: root._rowValue(choice.spec)
                options: root._rowPicks(choice.spec).map(pick => ({ displayName: Translation.tr(String(pick.label)), icon: pick.glyph ?? "", value: pick.value }))
                onSelected: next => DesktopWidgetOptions.write(choice.spec, next)
            }
        }
    }
    Component {
        id: comboRow
        WidgetSettingRow {
            id: combo
            property var spec: ({})
            readonly property var picks: root._rowPicks(combo.spec)
            label: root._rowLabel(combo.spec)
            trailing: false
            StyledComboBox {
                Layout.fillWidth: true
                model: combo.picks
                textRole: "label"
                currentIndex: Math.max(0, combo.picks.findIndex(pick => String(pick.value) === String(root._rowValue(combo.spec))))
                onActivated: index => DesktopWidgetOptions.write(combo.spec, combo.picks[index].value)
            }
        }
    }
    Component {
        id: textRow
        WidgetSettingRow {
            id: words
            property var spec: ({})
            label: root._rowLabel(words.spec)
            trailing: false
            MaterialTextField {
                Layout.fillWidth: true
                text: String(root._rowValue(words.spec) ?? "")
                // Material floats a placeholder over a filled field, where it only repeats the row's label.
                placeholderText: length === 0 && words.spec.placeholder ? Translation.tr(words.spec.placeholder) : ""
                onEditingFinished: if (text !== String(root._rowValue(words.spec) ?? "")) DesktopWidgetOptions.write(words.spec, text)
            }
        }
    }
    Component {
        id: actionRow
        WidgetSettingRow {
            id: action
            property var spec: ({})
            label: root._rowLabel(action.spec)
            trailing: false
            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignRight
                color: Appearance.colors.colSubtext
                text: {
                    void Config.revision
                    return DesktopWidgetOptions.captionOf(action.spec)
                }
            }
            SelectionGroupButton {
                Layout.fillWidth: false
                leftmost: true; rightmost: true
                buttonText: Translation.tr(String(action.spec.button ?? action.spec.label))
                onClicked: action.spec.run?.()
            }
        }
    }
    Component {
        id: fontRow
        FontSelector {
            id: face
            property var spec: ({})
            label: root._rowLabel(face.spec)
            icon: "font_download"
            selectedFont: String(root._rowValue(face.spec) ?? "")
            onSelectedFontChanged: if (face.spec.key && selectedFont !== String(root._rowValue(face.spec) ?? "")) DesktopWidgetOptions.write(face.spec, selectedFont)
        }
    }
    Component {
        id: placementRow
        ColumnLayout {
            id: placement
            property var spec: ({})
            readonly property string path: "background.widgets." + String(placement.spec.widget ?? "")
            spacing: 4
            WidgetSettingRow {
                label: Translation.tr("Position")
                trailing: false
                WidgetPlacementSelector {
                    configPath: placement.path
                    defaultStrategy: "free"
                }
            }
            WidgetZonePicker {
                configPath: placement.path
            }
        }
    }

    // A widget's accent roles: the palette people pick, and each role for those who want to.
    component WidgetColours: ContentSubsection {
        id: colours
        required property string configPath
        property bool detailsOpen: false
        title: Translation.tr("Colors")

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Choose a palette preset. Fine tuning is optional and stays out of the way until you open it.")
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            wrapMode: Text.WordWrap
        }

        WidgetPalettePresetPicker {
            configPath: colours.configPath
        }

        RippleButton {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignLeft
            implicitWidth: paletteDetailsRow.implicitWidth + 20
            implicitHeight: 30
            buttonRadius: Appearance.rounding.full
            toggled: colours.detailsOpen
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.07)
            colBackgroundToggled: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.12)
            colBackgroundToggledHover: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.18)
            colRipple: ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.10)
            downAction: () => colours.detailsOpen = !colours.detailsOpen

            contentItem: Item {
                implicitWidth: paletteDetailsRow.implicitWidth
                implicitHeight: paletteDetailsRow.implicitHeight
                RowLayout {
                    id: paletteDetailsRow
                    width: Math.min(implicitWidth, parent.width)
                    anchors.centerIn: parent
                    spacing: 5
                    MaterialSymbol {
                        text: colours.detailsOpen ? "expand_less" : "tune"
                        iconSize: 16
                        color: colours.detailsOpen
                            ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: Translation.tr("Customize roles")
                        color: colours.detailsOpen
                            ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }
            }
        }

        ColumnLayout {
            visible: colours.detailsOpen
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: [
                    { key: "primary", label: Translation.tr("Main accent"), icon: "palette", fallback: "primary" },
                    { key: "secondary", label: Translation.tr("Secondary accent"), icon: "filter_2", fallback: "secondary" },
                    { key: "tertiary", label: Translation.tr("Tertiary accent"), icon: "filter_3", fallback: "tertiary" },
                    { key: "signal", label: Translation.tr("Alerts"), icon: "error", fallback: "signal" },
                    { key: "surface", label: Translation.tr("Surface"), icon: "layers", fallback: "surface" }
                ]

                delegate: WidgetSettingRow {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon
                    trailing: false

                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: String(root.readPath(
                            colours.configPath + ".palette." + modelData.key, modelData.fallback))
                        onSelected: newValue => root.writePath(
                            colours.configPath + ".palette." + modelData.key, newValue)
                        options: root._semanticRoleOptions()
                    }
                }
            }
        }
    }


    // ── Overview: every widget toggleable at a glance ─────────
    property string activeSection: "manage"

    SettingsTaskNavigator {
        icon: "dashboard_customize"
        title: Translation.tr("Desktop Widgets")
        description: Translation.tr("Configure your desktop widgets in focused views: layout management, clocks, weather, media, screen edges and personal widgets.")
        summary: options.map(option => option.displayName).join(" \u00b7 ")
        currentValue: root.activeSection
        onSelected: value => root.activeSection = value
        // the clusters iRiS Settings › Widgets uses, so a widget sits in the same place in every family
        options: [
            { displayName: Translation.tr("Manage"), icon: "dashboard_customize", value: "manage" },
            { displayName: Translation.tr("Time"), icon: "schedule", value: "time" },
            { displayName: Translation.tr("Music"), icon: "album", value: "media" },
            { displayName: Translation.tr("System"), icon: "monitor_heart", value: "system" },
            { displayName: Translation.tr("Yours"), icon: "person", value: "personal" },
            { displayName: Translation.tr("Art"), icon: "brush", value: "art" },
            { displayName: Translation.tr("Screen edges"), icon: "border_outer", value: "edges" }
        ]
    }

    SettingsTaskLoadingState {
        loading: root._taskLoadingCount > 0
        text: Translation.tr("Loading section…")
    }

    // ── Widgets at a glance ─────────────────────────────────
    SettingsTaskLoader {
        requested: root.isIiActive && root.activeSection === "manage"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "manage"
        expanded: true
        icon: "dashboard_customize"
        title: Translation.tr("Widgets at a glance")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Toggle any widget here; fine-tune it in its section below")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    // every widget the registry knows that this family draws
                    model: DesktopWidgetRegistry.entriesFor(Config.options?.panelFamily ?? "ii")
                    delegate: WidgetEnableChip {
                        required property var modelData
                        widgetKey: modelData.key
                        defaultValue: Boolean(modelData.defaultOn)
                        buttonIcon: String(modelData.glyph ?? "")
                        buttonText: Translation.tr(modelData.name)
                    }
                }
            }
        }
    }
        }
    }

    // ── Every widget at once ────────────────────────────────
    SettingsTaskLoader {
        requested: root.isIiActive && root.activeSection === "manage"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "manage"
        expanded: true
        icon: "select_all"
        title: Translation.tr("Every widget")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("One change for every widget on the desktop. Each widget's own section still changes just that one.")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
                wrapMode: Text.Wrap
            }
            EveryWidgetRow {
                label: Translation.tr("Background")
                icon: "format_color_fill"
                optionKey: "showBackground"
                options: [
                    { displayName: Translation.tr("Show"), icon: "visibility", value: "true" },
                    { displayName: Translation.tr("Hide"), icon: "visibility_off", value: "false" }
                ]
            }
            EveryWidgetStrength {}
            EveryWidgetRow {
                label: Translation.tr("Outline")
                icon: "border_outer"
                optionKey: "showBorder"
                options: [
                    { displayName: Translation.tr("Show"), icon: "visibility", value: "true" },
                    { displayName: Translation.tr("Hide"), icon: "visibility_off", value: "false" }
                ]
            }
            EveryWidgetRow {
                label: Translation.tr("Ink")
                icon: "format_color_text"
                optionKey: "colorMode"
                options: [
                    { displayName: Translation.tr("Auto"), icon: "contrast", value: "auto" },
                    { displayName: Translation.tr("Light ink"), icon: "light_mode", value: "light" },
                    { displayName: Translation.tr("Dark ink"), icon: "dark_mode", value: "dark" }
                ]
            }
            EveryWidgetRow {
                label: Translation.tr("Position")
                icon: "lock"
                optionKey: "locked"
                options: [
                    { displayName: Translation.tr("Free"), icon: "lock_open", value: "false" },
                    { displayName: Translation.tr("Locked"), icon: "lock", value: "true" }
                ]
            }
        }
    }
        }
    }

    // ── Edit Mode ───────────────────────────────────────────
    SettingsTaskLoader {
        requested: root.isIiActive && root.activeSection === "manage"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "manage"
        expanded: false
        icon: "grid_on"
        title: Translation.tr("Edit Mode")

        SettingsGroup {
            WidgetSettingRow {
                label: Translation.tr("Desktop editing")
                icon: "edit"
                trailing: false
                WidgetStateChip {
                    buttonIcon: "edit"
                    buttonText: Translation.tr("Edit mode")
                    active: GlobalStates.widgetEditMode
                    toggleAction: checked => GlobalStates.setWidgetEditMode(checked)
                    StyledToolTip { text: Translation.tr("Show widget handles and desktop placement controls") }
                }
            }
            WidgetSettingRow {
                label: Translation.tr("Grid")
                icon: "grid_3x3"
                WidgetToggleChip {
                    configPath: "background.widgets.editGrid.snap"
                    defaultValue: true
                    buttonIcon: "grid_3x3"
                    buttonText: Translation.tr("Snap")
                }
                StyledSpinBox {
                    from: 8; to: 128; stepSize: 8
                    value: root.readPath("background.widgets.editGrid.size", 32)
                    onValueModified: root.writePath("background.widgets.editGrid.size", value)
                    StyledToolTip {
                        text: Translation.tr("Grid cell size in pixels")
                    }
                }
            }
            WidgetSettingRow {
                label: Translation.tr("Shrink the desktop while editing")
                icon: "zoom_in_map"
                WidgetToggleChip {
                    configPath: "background.widgets.editCard"
                    defaultValue: true
                    buttonIcon: "zoom_in_map"
                    buttonText: Translation.tr("Card")
                    StyledToolTip { text: Translation.tr("Off: widgets are arranged in place, at full size") }
                }
            }
            SliderRow {
                label: Translation.tr("Fade with windows")
                icon: "visibility_off"
                configPath: "background.widgets.dynamicOpacity"
                sliderValue: root.readPath("background.widgets.dynamicOpacity", 0)
                sliderStep: 10
                tooltipText: Translation.tr("Reduce widget opacity when windows are on the current workspace (0 = off)")
            }
        }
    }
        }
    }

    // ── Widget Colors ───────────────────────────────────────
    SettingsTaskLoader {
        requested: root.isIiActive && root.activeSection === "manage"
        sourceComponent: Component {
    SettingsCardSection {
        settingsTaskSection: "manage"
        expanded: false
        icon: "palette"
        title: Translation.tr("Widget Colors")

        SettingsGroup {
            StyledText {
                visible: root.irisActive
                Layout.fillWidth: true
                text: Translation.tr("iRiS sets the design, material and colours of every widget in its own Settings. The options on each widget below apply while it wears the Material, iNstrument or Readout design.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }
            SelectionGroupButton {
                visible: root.irisActive
                Layout.fillWidth: false
                leftmost: true; rightmost: true
                buttonIcon: "widgets"
                buttonText: Translation.tr("Open iRiS widget settings")
                onClicked: root.openIrisWidgets()
            }
            WidgetSettingRow {
                visible: !root.irisActive
                label: Translation.tr("Global widget design")
                icon: "widgets"
                trailing: false
                ConfigSelectionArray {
                    currentValue: DesktopWidgetDesign.shared
                    options: DesktopWidgetDesign.choices.map(choice => ({
                        displayName: Translation.tr(choice.label), icon: choice.icon, value: choice.value
                    }))
                    onSelected: newValue => DesktopWidgetDesign.apply(newValue)
                }
            }
            StyledText {
                visible: !root.irisActive
                Layout.fillWidth: true
                text: Translation.tr("One look on every widget. Individual keeps each widget's own style.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }
            RowLayout {
                visible: !root.irisActive && (DesktopWidgetDesign.exceptionCount > 0 || DesktopWidgetDesign.canUndo)
                spacing: 6
                SelectionGroupButton {
                    visible: DesktopWidgetDesign.exceptionCount > 0
                    Layout.fillWidth: false
                    leftmost: true; rightmost: true
                    buttonIcon: "select_all"
                    buttonText: Translation.tr("Match every widget")
                    onClicked: DesktopWidgetDesign.apply(DesktopWidgetDesign.shared)
                }
                SelectionGroupButton {
                    visible: DesktopWidgetDesign.canUndo
                    Layout.fillWidth: false
                    leftmost: true; rightmost: true
                    buttonIcon: "undo"
                    buttonText: Translation.tr("Undo design change")
                    onClicked: DesktopWidgetDesign.undo()
                }
            }
            StyledText {
                visible: !root.irisActive
                Layout.fillWidth: true
                text: Translation.tr("Apply one wallpaper-generated color preset to every built-in desktop widget. You can still tune any widget individually below.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.WordWrap
            }


            WidgetPalettePresetPicker {
                visible: !root.irisActive
                configPath: ""
                applyGlobally: true
            }
        }
    }
        }
    }

    // ── Power Saving ────────────────────────────────────────
    SettingsTaskLoader {
        requested: root.isIiActive && root.activeSection === "manage"
        sourceComponent: Component {
    SettingsCardSection {
        id: powerSavingSection
        settingsTaskSection: "manage"
        expanded: false
        icon: "battery_saver"
        title: Translation.tr("Power Saving")

        // Helper to read powerSaving config with defaults
        function _ps(key: string, defaultVal: bool): bool {
            return Boolean(root.readPath("background.widgets.powerSaving." + key, defaultVal))
        }
        function _setPs(key: string, val: bool): void {
            root.writePath("background.widgets.powerSaving." + key, val)
        }

        SettingsGroup {
            PowerSavingSwitchRow {
                label: Translation.tr("Enable power saving")
                icon: "power_settings_new"
                psKey: "enable"
            }
            PowerSavingSwitchRow {
                label: Translation.tr("Pause on GameMode")
                icon: "sports_esports"
                psKey: "pauseOnGameMode"
            }
            PowerSavingSwitchRow {
                label: Translation.tr("Pause on fullscreen")
                icon: "fullscreen"
                psKey: "pauseOnFullscreen"
            }
            PowerSavingSwitchRow {
                label: Translation.tr("Pause when windows present")
                icon: "web_asset"
                psKey: "pauseWhenWindowsPresent"
                psDefault: false
            }
            PowerSavingSwitchRow {
                label: Translation.tr("Show paused effect")
                icon: "filter_b_and_w"
                psKey: "showPausedEffect"
                psDefault: false
            }

            // Status indicator
            WidgetSettingRow {
                label: Translation.tr("Current status")
                icon: "info"
                trailing: false
                Rectangle {
                    width: powerStatusRow.implicitWidth + 16
                    height: 28
                    radius: Appearance.rounding.small
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)
                    
                    Row {
                        id: powerStatusRow
                        anchors.centerIn: parent
                        spacing: 6
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: WidgetPowerManager.widgetsActive ? "play_circle" : "pause_circle"
                            iconSize: 16
                            color: WidgetPowerManager.widgetsActive 
                                ? Appearance.colors.colPrimary 
                                : Appearance.colors.colSubtext
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (WidgetPowerManager.widgetsActive)
                                    return Translation.tr("Active")
                                switch (WidgetPowerManager.pauseReason) {
                                case "gameMode": return Translation.tr("Paused - GameMode")
                                case "fullscreen": return Translation.tr("Paused - fullscreen")
                                case "windowsPresent": return Translation.tr("Paused - windows present")
                                case "outputDisabled": return Translation.tr("Paused - output disabled")
                                default: return Translation.tr("Paused")
                                }
                            }
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: WidgetPowerManager.widgetsActive 
                                ? Appearance.colors.colPrimary 
                                : Appearance.colors.colSubtext
                        }
                    }
                }
            }
        }
    }
        }
    }

    // ── Clock ───────────────────────────────────────────────
    // ── One card per widget, in the clusters every family shares ──
    readonly property var _tabOfCluster: ({ "Time": "time", "Music": "media", "System": "system", "Yours": "personal", "Art": "art" })
    readonly property var _cards: DesktopWidgetOptions.clusters.reduce((all, cluster) => all.concat(cluster.groups
        .map(group => ({ group: group, tab: root._tabOfCluster[cluster.caption] ?? "", key: DesktopWidgetRegistry.entries.find(entry => entry.group === group)?.key ?? "" }))
        .filter(card => card.key.length > 0 && card.tab.length > 0 && DesktopWidgetRegistry.entriesFor(Config.options?.panelFamily ?? "ii").some(entry => entry.key === card.key))), [])
    // What a card draws by hand, above its rows, and the rows that leaves out.
    readonly property var _cardExtras: ({
        worldClock: { extra: worldClockExtra, drawn: ["timezones"] },
        customImage: { extra: customImageExtra, drawn: ["sourceMode", "path", "folder", "mediaFilter", "shape"] },
        shape: { extra: shapeExtra, drawn: ["shape"] },
        japaneseTypography: { extra: japaneseExtra, drawn: ["preset", "palettePreset", "primaryColor", "secondaryColor", "sealColor", "detailColor", "ruleColor", "outlineColor"] },
        mascot: { extra: mascotExtra, drawn: ["poseFilter", "pose", "customPath"] }
    })

    Repeater {
        model: root._cards
        delegate: LazySection {
            id: cardSection
            required property var modelData
            requested: root.isIiActive && root.activeSection === cardSection.modelData.tab
            sourceComponent: Component {
                WidgetCard { entry: cardSection.modelData }
            }
        }
    }

    Component {
        id: worldClockExtra
        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            ContentSubsection {
                id: worldClockZones
                property var availableTimezones: WorldClock.comboModel.filter(
                    entry => !WorldClock.timezones.includes(entry.tz))
                title: Translation.tr("Time zones")

                Repeater {
                    model: WorldClock.timezones.length
                    delegate: WidgetSettingRow {
                        id: tzRow
                        required property int index
                        label: Translation.tr("City %1").arg(tzRow.index + 1)
                        icon: "schedule"
                        trailing: false

                        StyledComboBox {
                            Layout.fillWidth: true
                            model: WorldClock.comboModel
                            textRole: "label"
                            currentIndex: Math.max(0, WorldClock.comboModel.findIndex(o => o.tz === WorldClock.timezones[tzRow.index]))
                            onActivated: idx => WorldClock.setTimezone(tzRow.index, WorldClock.comboModel[idx].tz)
                        }

                        RippleButton {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            enabled: WorldClock.timezones.length > 1
                            opacity: enabled ? 1 : 0.32
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2Hover
                            colRipple: Appearance.colors.colLayer2Active
                            releaseAction: () => WorldClock.removeTimezone(tzRow.index)
                            contentItem: MaterialSymbol {
                                anchors.centerIn: parent
                                text: "delete"
                                color: Appearance.colors.colOnLayer1
                                iconSize: 17
                            }
                            StyledToolTip { text: Translation.tr("Remove city") }
                        }
                    }
                }

                WidgetSettingRow {
                    visible: WorldClock.timezones.length < WorldClock.maxTimezones
                        && worldClockZones.availableTimezones.length > 0
                    label: Translation.tr("Add city")
                    icon: "add_location_alt"
                    trailing: false

                    StyledComboBox {
                        id: worldClockAddZone
                        Layout.fillWidth: true
                        model: worldClockZones.availableTimezones
                        textRole: "label"
                    }
                    RippleButton {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 34
                        buttonRadius: Appearance.rounding.small
                        colBackground: Appearance.colors.colPrimaryContainer
                        colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                        colRipple: Appearance.colors.colPrimaryContainerActive
                        releaseAction: () => {
                            const entry = worldClockZones.availableTimezones[worldClockAddZone.currentIndex]
                            if (entry)
                                WorldClock.addTimezone(entry.tz)
                        }
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "add"
                            color: Appearance.colors.colOnPrimaryContainer
                            iconSize: 18
                        }
                        StyledToolTip { text: Translation.tr("Add city") }
                    }
                }
            }
        }
    }

    Component {
        id: customImageExtra
        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            ContentSubsection {
                title: Translation.tr("Source")

                WidgetSettingRow {
                    label: Translation.tr("Show")
                    icon: "filter_alt"
                    trailing: false

                    GridLayout {
                        id: customMediaQuickChoices
                        Layout.fillWidth: true
                        readonly property var choices: [
                            { label: Translation.tr("File"), icon: "draft", value: "file",
                                available: Images.isValidMediaByName(root.readPath("background.widgets.customImage.path", "")) },
                            { label: Translation.tr("All") + " " + root._customMediaFolderCount,
                                icon: "perm_media", value: "all", available: root._customMediaFolderCount > 0 },
                            { label: Translation.tr("Images") + " " + root._customMediaFolderImageCount,
                                icon: "image", value: "images", available: root._customMediaFolderImageCount > 0 },
                            { label: "GIF " + root._customMediaFolderGifCount,
                                icon: "motion_photos_on", value: "gifs", available: root._customMediaFolderGifCount > 0 },
                            { label: Translation.tr("Videos") + " " + root._customMediaFolderVideoCount,
                                icon: "movie", value: "videos", available: root._customMediaFolderVideoCount > 0 }
                        ].filter(choice => choice.available)
                        columns: Math.max(1, choices.length)
                        columnSpacing: 4
                        rowSpacing: 4

                        Repeater {
                            model: customMediaQuickChoices.choices

                            SelectionGroupButton {
                                required property var modelData
                                Layout.fillWidth: true
                                leftmost: true; rightmost: true
                                toggled: root._customMediaChoiceActive(modelData.value)
                                buttonIcon: modelData.icon
                                buttonText: modelData.label
                                onClicked: root._activateCustomMediaChoice(modelData.value)
                            }
                        }
                    }
                }

                WidgetSettingRow {
                    label: Translation.tr("Source type")
                    icon: "perm_media"
                    trailing: false

                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: root.readPath("background.widgets.customImage.sourceMode", "file")
                        onSelected: newValue => {
                            const path = root.readPath("background.widgets.customImage.path", "")
                            const folder = root.readPath("background.widgets.customImage.folder", "")
                            if (newValue === "folder" && folder.length === 0) {
                                customImageFolderDialog.open()
                                return
                            }
                            if (newValue === "file" && path.length === 0) {
                                customImageFileDialog.open()
                                return
                            }
                            root.writePath("background.widgets.customImage.sourceMode", newValue)
                        }
                        options: [
                            { displayName: Translation.tr("Single file"), icon: "draft", value: "file" },
                            { displayName: Translation.tr("Folder gallery"), icon: "folder_open", value: "folder" }
                        ]
                    }
                }

                WidgetSettingRow {
                    visible: root.readPath("background.widgets.customImage.sourceMode", "file") === "file"
                    label: Translation.tr("Media file")
                    icon: "perm_media"
                    trailing: false

                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Image, GIF, or video")
                        text: root.readPath("background.widgets.customImage.path", "")
                        onAccepted: {
                            const path = text.trim();
                            if (path.length === 0 || Images.isValidMediaByName(path))
                                root.writePath("background.widgets.customImage.path", path);
                        }
                        onEditingFinished: {
                            const path = text.trim();
                            if (path.length === 0 || Images.isValidMediaByName(path))
                                root.writePath("background.widgets.customImage.path", path);
                        }
                    }

                    SelectionGroupButton {
                        Layout.fillWidth: false
                        leftmost: true; rightmost: true
                        buttonIcon: "folder_open"
                        buttonText: Translation.tr("Browse")
                        onClicked: customImageFileDialog.open()
                    }

                    SelectionGroupButton {
                        visible: root.readPath("background.widgets.customImage.path", "").length > 0
                        Layout.fillWidth: false
                        leftmost: true; rightmost: true
                        buttonIcon: "close"
                        buttonText: Translation.tr("Clear")
                        onClicked: {
                            const folder = root.readPath("background.widgets.customImage.folder", "")
                            const updates = ({ "background.widgets.customImage.path": "" })
                            if (folder.length > 0)
                                updates["background.widgets.customImage.sourceMode"] = "folder"
                            root.writePaths(updates)
                        }
                    }
                }

                WidgetSettingRow {
                    visible: root.readPath("background.widgets.customImage.sourceMode", "file") === "folder"
                    label: Translation.tr("Media folder")
                    icon: "folder_open"
                    trailing: false

                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Folder containing images or videos")
                        text: root.readPath("background.widgets.customImage.folder", "")
                        onAccepted: root.writePath("background.widgets.customImage.folder", text.trim())
                        onEditingFinished: root.writePath("background.widgets.customImage.folder", text.trim())
                    }

                    SelectionGroupButton {
                        Layout.fillWidth: false
                        leftmost: true; rightmost: true
                        buttonIcon: "folder_open"
                        buttonText: Translation.tr("Browse")
                        onClicked: customImageFolderDialog.open()
                    }

                    SelectionGroupButton {
                        visible: root.readPath("background.widgets.customImage.folder", "").length > 0
                        Layout.fillWidth: false
                        leftmost: true; rightmost: true
                        buttonIcon: "close"
                        buttonText: Translation.tr("Clear")
                        onClicked: {
                            const path = root.readPath("background.widgets.customImage.path", "")
                            const updates = ({ "background.widgets.customImage.folder": "" })
                            if (path.length > 0)
                                updates["background.widgets.customImage.sourceMode"] = "file"
                            root.writePaths(updates)
                        }
                    }
                }

                WidgetSettingRow {
                    visible: root.readPath("background.widgets.customImage.sourceMode", "file") === "folder"
                    label: Translation.tr("Media type")
                    icon: "filter_alt"
                    trailing: false

                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: root.readPath("background.widgets.customImage.mediaFilter", "all")
                        onSelected: newValue => root.writePath("background.widgets.customImage.mediaFilter", newValue)
                        options: [
                            { displayName: Translation.tr("All media") + " (" + root._customMediaFolderCount + ")", icon: "perm_media", value: "all", available: true },
                            { displayName: Translation.tr("Images only") + " (" + root._customMediaFolderImageCount + ")", icon: "image", value: "images", available: root._customMediaFolderImageCount > 0 },
                            { displayName: "GIF (" + root._customMediaFolderGifCount + ")", icon: "motion_photos_on", value: "gifs", available: root._customMediaFolderGifCount > 0 },
                            { displayName: Translation.tr("Videos only") + " (" + root._customMediaFolderVideoCount + ")", icon: "movie", value: "videos", available: root._customMediaFolderVideoCount > 0 }
                        ].filter(option => option.available)
                    }
                }

                SettingsNote {
                    icon: "volume_off"
                    text: Translation.tr("Videos play silently. Images, animated GIFs, and videos can share the same folder.")
                }
            }
            ContentSubsection {
                title: Translation.tr("Shape")

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: root._customImageShapes

                        Rectangle {
                            id: shapeCell
                            required property var modelData
                            width: 52
                            height: 52
                            radius: Appearance.rounding.small
                            readonly property bool selected: root.readPath("background.widgets.customImage.shape", "Cookie4Sided") === modelData.value
                            color: selected
                                ? ColorUtils.applyAlpha(Appearance.colors.colPrimary, 0.14)
                                : ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, shapeMouse.containsMouse ? 0.07 : 0.03)
                            border.width: selected ? 1.5 : 0
                            border.color: Appearance.colors.colPrimary

                            MaterialShape {
                                anchors.centerIn: parent
                                implicitSize: 28
                                shape: shapeCell.modelData.shape
                                color: shapeCell.selected
                                    ? Appearance.colors.colPrimary
                                    : Appearance.colors.colOnLayer1
                            }

                            MouseArea {
                                id: shapeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.writePath("background.widgets.customImage.shape", shapeCell.modelData.value)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: shapeExtra
        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            WidgetShapePicker {
                Layout.fillWidth: true
                selectedShape: root.readPath("background.widgets.shape.shape", "Flower")
                onShapeSelected: name => root.writePath("background.widgets.shape.shape", name)
            }
        }
    }

    Component {
        id: japaneseExtra
        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            ContentSubsection {
                title: Translation.tr("Layout presets")
                JapaneseCompositionPicker {}
            }
            ContentSubsection {
                title: Translation.tr("Editorial palette")

                JapanesePalettePicker {}

                WidgetSettingRow {
                    label: Translation.tr("Color source")
                    icon: "palette"
                    trailing: false
                    ConfigSelectionArray {
                        currentValue: root.readPath(root._japanesePath + ".paletteMode", "adaptive")
                        onSelected: newValue => {
                            if (newValue === "adaptive") root._applyJapanesePalettePreset("adaptive")
                            else root._setJapaneseValue("paletteMode", "manual", "palette")
                        }
                        options: [
                            { displayName: Translation.tr("Wallpaper adaptive"), icon: "auto_awesome", value: "adaptive" },
                            { displayName: Translation.tr("Manual roles"), icon: "palette", value: "manual" }
                        ]
                    }
                }

                ColumnLayout {
                    visible: root.readPath(root._japanesePath + ".paletteMode", "adaptive") === "manual"
                    Layout.fillWidth: true
                    spacing: 2

                    JapaneseColorPickerRow { label: Translation.tr("Lead title"); configKey: "primaryColor"; fallbackColor: "#E7D4B2" }
                    JapaneseColorPickerRow { label: Translation.tr("Secondary copy"); configKey: "secondaryColor"; fallbackColor: "#CDB48D" }
                    JapaneseColorPickerRow { label: Translation.tr("Seal"); configKey: "sealColor"; fallbackColor: "#A64B39" }
                    JapaneseColorPickerRow { label: Translation.tr("Footer and date"); configKey: "detailColor"; fallbackColor: "#D0B996" }
                    JapaneseColorPickerRow { label: Translation.tr("Editorial rule"); configKey: "ruleColor"; fallbackColor: "#C18A53" }
                }

            }
            JapaneseColorPickerRow {
                visible: root.readPath(root._japanesePath + ".outlineOpacity", 0) > 0
                label: Translation.tr("Outline color")
                configKey: "outlineColor"
                fallbackColor: "#000000"
            }
        }
    }

    Component {
        id: mascotExtra
        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap
            SettingsGroup {
                id: mascotWidgetGroup

                // Pose thumbnails come from the shared mascot catalog.
                readonly property var poseGroups: [
                    { f: "all", label: Translation.tr("All") },
                    { f: "featured", label: Translation.tr("Featured") },
                    { f: "pixel", label: Translation.tr("Pixel") },
                    { f: "street", label: Translation.tr("Street") },
                    { f: "chibi", label: Translation.tr("Chibi") },
                    { f: "loops", label: Translation.tr("Loops") },
                    { f: "manual", label: Translation.tr("Manual") }
                ]
                function _optionsFor(poses: var): var {
                    const result = []
                    for (let i = 0; i < poses.length; ++i) {
                        const pose = poses[i]
                        result.push({
                            displayName: MascotCatalog.displayName(pose),
                            value: pose,
                            image: MascotCatalog.sourceFor(pose)
                        })
                    }
                    return result
                }
                readonly property var poseOptions: {
                    MascotCatalog.revision
                    return mascotWidgetGroup._optionsFor(
                        MascotCatalog.desktopWidgetSelectablePoses)
                }
                // Same persisted key as the widget popover chips, so both stay in sync
                readonly property string poseFilter: {
                    Config.revision
                    return root.readPath("background.widgets.mascot.poseFilter", "all")
                }
                readonly property var filteredPoseOptions: {
                    MascotCatalog.revision
                    return mascotWidgetGroup._optionsFor(
                        MascotCatalog.desktopWidgetPosesForGroup(
                            mascotWidgetGroup.poseFilter))
                }
                ContentSubsection {
                    title: Translation.tr("Image")

                    StyledText {
                        Layout.fillWidth: true
                        visible: !(Config.options?.mascot?.enable ?? false)
                    text: Translation.tr("Needs the global mascot switch (Settings › Mascot)")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
                Flow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: childrenRect.height
                    spacing: 2
                    Repeater {
                        model: mascotWidgetGroup.poseGroups
                        SelectionGroupButton {
                            required property var modelData
                            required property int index
                            leftmost: index === 0
                            rightmost: index === mascotWidgetGroup.poseGroups.length - 1
                            toggled: mascotWidgetGroup.poseFilter === modelData.f
                            buttonText: modelData.label
                            onClicked: root.writePath(
                                "background.widgets.mascot.poseFilter", modelData.f)
                        }
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    visible: mascotWidgetGroup.poseFilter === "manual"
                    text: Translation.tr("Manual-only poses never rotate automatically")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.Wrap
                }
                MascotPoseGallery {
                    Layout.fillWidth: true
                    label: Translation.tr("Pose on the desktop")
                    options: mascotWidgetGroup.filteredPoseOptions
                    currentValue: {
                        const configured = root.readPath("background.widgets.mascot.pose", "reading")
                        return mascotWidgetGroup.poseOptions.some(o => o.value === configured)
                            ? configured
                            : (mascotWidgetGroup.poseOptions[0]?.value ?? "presence-idle-loop")
                    }
                    onSelected: value => root.writePath("background.widgets.mascot.pose", value)
                }
                WidgetSettingRow {
                    label: Translation.tr("Custom image")
                    icon: "image"
                    trailing: false
                    MaterialTextField {
                        Layout.fillWidth: true
                        placeholderText: Translation.tr("Path to any image or GIF (empty = pose above)")
                        text: root.readPath("background.widgets.mascot.customPath", "")
                        onEditingFinished: root.writePath("background.widgets.mascot.customPath", text.trim())
                    }
                }
                }
            }
        }
    }

    LazySection {
        requested: root.isIiActive && root.activeSection === "personal"
        sourceComponent: Component {
            SettingsCardSection {
                settingsTaskSection: "personal"
                expanded: false
        icon: "widgets"
        title: Translation.tr("Custom Widgets")

        SettingsGroup {
            // Description
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("QML widgets you create or install. Place widget folders in ~/.config/inir/widgets/ — each needs a widget.json manifest and a .qml file.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.WordWrap
            }

            // Action bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Create new
                SelectionGroupButton {
                    Layout.fillWidth: false
                    leftmost: true; rightmost: true
                    buttonIcon: "add"
                    buttonText: Translation.tr("New")
                    onClicked: _cwCreateRow.visible = !_cwCreateRow.visible
                }

                // Install example
                SelectionGroupButton {
                    visible: !root._customWidgetInstalled("example-widget")
                    Layout.fillWidth: false
                    leftmost: true; rightmost: true
                    buttonIcon: "download"
                    buttonText: Translation.tr("Example")
                    onClicked: CustomWidgets.installExample()
                    StyledToolTip { text: Translation.tr("Install the built-in example widget to learn from") }
                }

                Item { Layout.fillWidth: true }

                // Open folder
                RippleButton {
                    width: 36; height: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.12)
                    downAction: () => CustomWidgets.openWidgetDir("")
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "folder_open"; iconSize: 20; color: Appearance.colors.colOnLayer1 }
                    StyledToolTip { text: Translation.tr("Open widgets folder") }
                }

                // Reload
                RippleButton {
                    width: 36; height: 36
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)
                    colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.12)
                    downAction: () => CustomWidgets.reload()
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "refresh"; iconSize: 20; color: Appearance.colors.colOnLayer1 }
                    StyledToolTip { text: Translation.tr("Scan for new or changed widgets") }
                }
            }

            // Create widget inline form (hidden by default)
            ColumnLayout {
                id: _cwCreateRow
                visible: false
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    MaterialTextField {
                        id: _newWidgetNameField
                        Layout.fillWidth: true
                        height: 40
                        placeholderText: Translation.tr("widget-name (lowercase, dashes)")
                        font.pixelSize: Appearance.font.pixelSize.small
                        validator: RegularExpressionValidator { regularExpression: /[a-z0-9][a-z0-9\-]*/ }
                        onAccepted: {
                            if (text.length > 0) {
                                CustomWidgets.create(text);
                                text = "";
                                _cwCreateRow.visible = false;
                            }
                        }
                    }
                    SelectionGroupButton {
                        id: _cwCreateBtn
                        Layout.fillWidth: false
                        leftmost: true; rightmost: true
                        buttonIcon: "add"
                        buttonText: Translation.tr("Create")
                        enabled: _newWidgetNameField.text.length > 0
                        opacity: enabled ? 1 : 0.4
                        onClicked: {
                            if (_newWidgetNameField.text.length > 0) {
                                CustomWidgets.create(_newWidgetNameField.text);
                                _newWidgetNameField.text = "";
                                _cwCreateRow.visible = false;
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Creates a template with all imports, services, and an example layout. Edit the .qml file to customize.")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.WordWrap
                }
            }

            // Empty state
            ColumnLayout {
                visible: CustomWidgets.ready && CustomWidgets.widgets.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 12
                Layout.bottomMargin: 8
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "widgets"
                    iconSize: 40
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.2)
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No custom widgets installed")
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.5)
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Click 'New' to create one, or 'Example' to install a demo widget")
                    color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.35)
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        // Per-widget cards
        Repeater {
            model: CustomWidgets.ready ? CustomWidgets.widgets : []

            SettingsGroup {
                id: cwDelegate
                required property var modelData
                required property int index

                ContentSubsection {
                    title: cwDelegate.modelData.name
                    SettingsSwitch {
                        buttonIcon: "visibility"
                        text: Translation.tr("On the desktop")
                        autoToggle: false
                        checked: DesktopWidgetOptions.on("custom." + cwDelegate.modelData.id)
                        onToggledByUser: next => DesktopWidgetLayout.setGloballyEnabled("custom." + cwDelegate.modelData.id, next)
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Position")

                    ConfigRow {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("Coordinates")
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillWidth: true }
                        Row {
                            spacing: 8
                            StyledSpinBox {
                                from: 0; to: 10000; stepSize: root.readPath("background.widgets.editGrid.size", 32)
                                value: root.readPath("background.widgets.custom." + cwDelegate.modelData.id + ".x", 240 + cwDelegate.index * 36)
                                onValueModified: root.writePath("background.widgets.custom." + cwDelegate.modelData.id + ".x", value)
                                StyledToolTip { text: Translation.tr("X position") }
                            }
                            StyledSpinBox {
                                from: 0; to: 10000; stepSize: root.readPath("background.widgets.editGrid.size", 32)
                                value: root.readPath("background.widgets.custom." + cwDelegate.modelData.id + ".y", 240 + cwDelegate.index * 28)
                                onValueModified: root.writePath("background.widgets.custom." + cwDelegate.modelData.id + ".y", value)
                                StyledToolTip { text: Translation.tr("Y position") }
                            }
                        }
                    }

                    ConfigRow {
                        Layout.fillWidth: true
                        StyledText {
                            text: Translation.tr("Desktop editing")
                            color: Appearance.colors.colOnLayer1
                        }
                        Item { Layout.fillWidth: true }
                        SelectionGroupButton {
                            Layout.fillWidth: false
                            leftmost: true; rightmost: true
                            buttonIcon: "drag_pan"
                            buttonText: Translation.tr("Edit on desktop")
                            onClicked: {
                                DesktopWidgetLayout.setGloballyEnabled("custom." + cwDelegate.modelData.id, true);
                                GlobalStates.setWidgetEditMode(true);
                            }
                        }
                    }
                }


                // Meta row: version, author, actions
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: (cwDelegate.modelData.author ? (cwDelegate.modelData.author + " · ") : "") + "v" + cwDelegate.modelData.version
                        color: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.5)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                    Item { Layout.fillWidth: true }

                    // Edit (open folder)
                    RippleButton {
                        width: 28; height: 28
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.08)
                        colRipple: ColorUtils.applyAlpha(Appearance.colors.colOnLayer1, 0.12)
                        downAction: () => CustomWidgets.openWidgetDir(cwDelegate.modelData.id)
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "edit"; iconSize: 16; color: Appearance.colors.colOnLayer1 }
                        StyledToolTip { text: Translation.tr("Open widget folder") }
                    }

                    // Delete
                    RippleButton {
                        width: 28; height: 28
                        buttonRadius: Appearance.rounding.full
                        colBackground: "transparent"
                        colBackgroundHover: ColorUtils.applyAlpha(Appearance.colors.colError, 0.08)
                        colRipple: ColorUtils.applyAlpha(Appearance.colors.colError, 0.12)
                        downAction: () => { _cwDeleteConfirm.widgetId = cwDelegate.modelData.id; _cwDeleteConfirm.widgetName = cwDelegate.modelData.name; _cwDeleteConfirm.visible = true }
                        contentItem: MaterialSymbol { anchors.centerIn: parent; text: "delete"; iconSize: 16; color: Appearance.colors.colError }
                        StyledToolTip { text: Translation.tr("Remove widget") }
                    }
                }

                // Validation warnings
                NoticeBox {
                    visible: !cwDelegate.modelData.valid
                    Layout.fillWidth: true
                    materialIcon: "warning"
                    text: (cwDelegate.modelData.warnings || []).join("\n")
                }

                // The widget's own options, as its manifest lists them (DesktopWidgetOptions).
                ContentSubsection {
                    id: ownOptions
                    readonly property var rows: {
                        void Config.revision
                        return DesktopWidgetOptions.sheetRows("custom." + cwDelegate.modelData.id, "widget").filter(spec => spec.showIf())
                    }
                    visible: ownOptions.rows.length > 0
                    title: Translation.tr("Settings")
                    Repeater {
                        model: ScriptModel { objectProp: "path"; values: ownOptions.rows }
                        delegate: WidgetOptionRow {}
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Look")
                    Repeater {
                        model: ScriptModel {
                            objectProp: "path"
                            values: {
                                void Config.revision
                                const widget = "custom." + cwDelegate.modelData.id
                                const rows = DesktopWidgetOptions.sheetRows(widget, "look").concat(DesktopWidgetOptions.sheetRows(widget, "arrange"))
                                return rows.filter(spec => spec.showIf())
                            }
                        }
                        delegate: WidgetOptionRow {}
                    }
                }
            }
        }
            }
        }
    }

    LazySection {
        requested: root.isIiActive && root.activeSection === "edges"
        sourceComponent: OrganicEdgeSettings {}
    }

    // Delete confirmation overlay (shared for all custom widgets)
    NoticeBox {
        id: _cwDeleteConfirm
        property string widgetId: ""
        property string widgetName: ""
        visible: false
        Layout.fillWidth: true
        materialIcon: "delete"
        text: Translation.tr("Remove '%1'? This deletes the widget folder permanently.").arg(_cwDeleteConfirm.widgetName)

        DialogButton {
            buttonText: Translation.tr("Cancel")
            onClicked: _cwDeleteConfirm.visible = false
        }
        DialogButton {
            buttonText: Translation.tr("Delete")
            colEnabled: Appearance.colors.colError
            onClicked: {
                CustomWidgets.remove(_cwDeleteConfirm.widgetId);
                _cwDeleteConfirm.visible = false;
            }
        }
    }
}
