pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.settings
import qs.modules.iris.components
import qs.modules.iris.style

PanelWindow {
    id: root
    property string section: "bar"
    property int advancedPage: -1
    property string query: ""
    property string requestedSection: ""
    readonly property real d: IrisStyle.density
    // Section badges follow the grouped-settings convention: one quiet tint per
    // category so the sidebar scans by colour as well as by label.
    readonly property var sections: [
        { id: "bar", title: "Island", subtitle: "Composition, size and how the Island responds", icon: "pill", tint: "#0a84ff" },
        { id: "player", title: "Now Playing", subtitle: "Music in the Island and on the lock screen", icon: "music_note", tint: "#ff375f" },
        { id: "dock", title: "Dock", subtitle: "Visibility, material and app icons", icon: "dock_to_bottom", tint: "#5e5ce6" },
        { id: "appearance", title: "Appearance", subtitle: "Shape and motion of every iRiS surface", icon: "palette", tint: "#bf5af2" },
        { id: "desktop", title: "Desktop", subtitle: "Widgets on the wallpaper and the overview backdrop", icon: "widgets", tint: "#30b0c7" },
        { id: "surfaces", title: "Spotlight & Panels", subtitle: "Search, Control Center and system feedback", icon: "space_dashboard", tint: "#ff9f0a" },
        { id: "system", title: "All Settings", subtitle: "Every iNiR page", icon: "settings", tint: "#8e8e93" }
    ]
    readonly property var specifications: [
        { section: "bar", group: "Layout", label: "Design", path: "iris.appearance.design", kind: "choice", fallback: "island", choices: [{label:"Island",value:"island"},{label:"Classic",value:"classic"}] },
        { section: "bar", group: "Layout", label: "Composition", description: "Cluster splits media and controls into bubbles beside the clock.", path: "iris.bar.composition", kind: "choice", fallback: "unified", choices: [{label:"Unified",value:"unified"},{label:"Cluster",value:"cluster"}] },
        { section: "bar", group: "Layout", label: "Screen edge", path: "iris.bar.position", kind: "choice", fallback: "top", choices: [{label:"Top",value:"top"},{label:"Bottom",value:"bottom"}] },
        { section: "bar", group: "Layout", label: "Attach as a notch", description: "Melts the Island into the screen edge.", path: "iris.bar.notch", kind: "switch", fallback: false },
        { section: "bar", group: "Size", label: "Height", path: "iris.bar.height", kind: "range", fallback:42,min:32,max:64,unit:" px" },
        { section: "bar", group: "Size", label: "Gap from the edge", path: "iris.bar.margin", kind: "range", fallback:8,min:0,max:24,unit:" px" },
        { section: "bar", group: "Size", label: "Reserve space for windows", path: "iris.bar.reserveSpace", kind: "switch", fallback:true },
        { section: "bar", group: "Interaction", label: "Expand on hover", description: "The pointer has to rest on the Island; passing over it does nothing.", path: "iris.bar.hoverExpand", kind: "switch", fallback:true },
        { section: "bar", group: "Interaction", label: "Hover delay", path: "iris.bar.hoverDelay", kind: "range", fallback:160,min:60,max:400,step:10,unit:" ms" },
        { section: "bar", group: "Interaction", label: "Scroll on the Island", description: "Hold Shift to adjust the other one.", path: "iris.bar.scrollAction", kind: "choice", fallback: "volume", choices: [{label:"Volume",value:"volume"},{label:"Brightness",value:"brightness"},{label:"Off",value:"none"}] },
        { section: "player", group: "Artwork", label: "Round album cover", path: "iris.player.roundCover", kind: "switch", fallback:true },
        { section: "player", group: "Artwork", label: "Blurred album background", description: "Tints the expanded Island and media cards with the cover.", path: "iris.player.artworkBackground", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Show dock", path: "iris.dock.enable", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Automatically hide", description: "Rest the pointer at the screen edge to reveal it.", path: "iris.dock.autoHide", kind: "switch", fallback:true },
        { section: "dock", group: "Visibility", label: "Stay visible on empty workspaces", path: "iris.dock.revealOnEmpty", kind: "switch", fallback:true },
        { section: "dock", group: "Look", label: "Attach as a notch", path: "iris.dock.notch", kind: "switch", fallback:false },
        { section: "dock", group: "Look", label: "Compositor blur", description: "Translucent material when the compositor provides blur.", path: "iris.dock.blur", kind: "switch", fallback:false },
        { section: "dock", group: "Icons", label: "Icon size", path: "iris.dock.iconSize", kind: "range", fallback:40,min:28,max:64,unit:" px" },
        { section: "dock", group: "Icons", label: "Magnify on hover", path: "iris.dock.magnification", kind: "switch", fallback:true },
        { section: "dock", group: "Icons", label: "Notification badges", path: "iris.dock.badges", kind: "switch", fallback:true },
        { section: "appearance", group: "Shape", label: "Expanded corners", path: "iris.appearance.expandedRadius", kind: "range", fallback:28,min:16,max:40,unit:" px" },
        { section: "appearance", group: "Motion", label: "Animations", path: "iris.appearance.motion", kind: "switch", fallback:true },
        { section: "appearance", group: "Motion", label: "Morph duration", description: "How long surfaces take to grow out of the Island.", path: "iris.appearance.motionDuration", kind: "range", fallback:220,min:100,max:400,step:10,unit:" ms" },
        { section: "desktop", group: "Widgets", label: "Desktop widgets", description: "Turning this off also unloads their data providers.", path: "iris.modules.desktopWidgets", kind: "switch", fallback:true },
        { section: "desktop", group: "Overview backdrop", label: "Wallpaper behind the overview", description: "Shown around workspaces when Niri's overview is open.", path: "background.backdrop.enable", kind: "switch", fallback:false },
        { section: "desktop", group: "Overview backdrop", label: "Blur", path: "background.backdrop.blurRadius", kind: "range", fallback:32,min:0,max:100,unit:" px" },
        { section: "desktop", group: "Overview backdrop", label: "Dim", path: "background.backdrop.dim", kind: "range", fallback:35,min:0,max:100,unit:" %" },
        { section: "desktop", group: "Overview backdrop", label: "Vignette", path: "background.backdrop.vignetteEnabled", kind: "switch", fallback:false },
        { section: "surfaces", group: "Spotlight", label: "Spotlight", path: "iris.modules.palette", kind: "switch", fallback:true },
        { section: "surfaces", group: "Spotlight", label: "Width", path: "iris.palette.width", kind: "range", fallback:640,min:420,max:900,step:10,unit:" px" },
        { section: "surfaces", group: "Spotlight", label: "Maximum results", path: "iris.palette.maxResults", kind: "range", fallback:8,min:3,max:14 },
        { section: "surfaces", group: "Spotlight", label: "Search mode shortcuts", description: "Clipboard, calculator, actions and more under the suggestions.", path: "iris.palette.showHints", kind: "switch", fallback:true },
        { section: "surfaces", group: "Control Center", label: "Control Center", path: "iris.modules.controlCenter", kind: "switch", fallback:true },
        { section: "surfaces", group: "Control Center", label: "Width", path: "iris.controlCenter.width", kind: "range", fallback:360,min:320,max:540,step:10,unit:" px" },
        { section: "surfaces", group: "Feedback", label: "Notifications", path: "iris.modules.notificationPopup", kind: "switch", fallback:true },
        { section: "surfaces", group: "Feedback", label: "Volume and brightness feedback", path: "iris.modules.osd", kind: "switch", fallback:true },
        { section: "surfaces", group: "Windows", label: "Confirm before closing windows", description: "Asks before the close-window shortcut closes an app.", path: "closeConfirm.enabled", kind: "switch", fallback:false }
    ]
    readonly property var currentSection: root.sections.find(s => s.id === root.section) ?? root.sections[0]
    readonly property var entries: specifications.filter(spec => query.length > 0
        ? (Translation.tr(spec.label) + " " + Translation.tr(spec.group)).toLowerCase().includes(query.toLowerCase())
        : spec.section === section)
    // Consecutive rows of one group share a card; search groups by section.
    readonly property var groups: {
        const out = []
        for (const spec of root.entries) {
            const title = root.query.length > 0
                ? Translation.tr(root.sections.find(s => s.id === spec.section)?.title ?? "")
                : Translation.tr(spec.group ?? "")
            if (out.length === 0 || out[out.length - 1].title !== title) out.push({ title: title, rows: [] })
            out[out.length - 1].rows.push(spec)
        }
        return out
    }
    readonly property var pages: SettingsPageRegistry.pages.map(page => Object.assign({}, page, { component: Quickshell.shellPath(page.component) }))

    function applyRequest(): void {
        root.requestedSection = GlobalStates.settingsOverlayRequestedSection
        GlobalStates.settingsOverlayRequestedSection = ""
        const page = GlobalStates.settingsOverlayRequestedPage
        if (page >= 0) {
            root.advancedPage = page === 28 ? -1 : page
            root.section = page === 28 ? "bar" : "system"
            GlobalStates.settingsOverlayCurrentPage = page
            GlobalStates.settingsOverlayRequestedPage = -1
        }
    }
    function selectSection(id: string): void {
        root.section = id
        root.advancedPage = -1
        searchField.text = ""
    }
    Component.onCompleted: if (GlobalStates.settingsOverlayOpen) root.applyRequest()
    Connections {
        target: GlobalStates
        function onSettingsOverlayRequestedPageChanged(): void { root.applyRequest() }
        function onSettingsOverlayOpenChanged(): void { if (GlobalStates.settingsOverlayOpen) root.applyRequest() }
    }
    // Content slides in a few pixels whenever the page changes.
    onSectionChanged: pageEnter.restart()
    onAdvancedPageChanged: pageEnter.restart()

    // May be preloaded hidden while the Island is expanded; the layer surface
    // only exists while open or while the morph is still collapsing.
    visible: GlobalStates.settingsOverlayOpen || frame.progress > 0
    screen: GlobalStates.focusedScreen
    color: "transparent"
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:iris-settings"
    WlrLayershell.layer: GlobalStates.settingsNativeDialogOpen ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.settingsNativeDialogOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    // Escape steps back: search, then an advanced page, then closes.
    Shortcut {
        sequence: "Escape"
        enabled: GlobalStates.settingsOverlayOpen
        onActivated: {
            if (root.query.length > 0) searchField.text = ""
            else if (root.advancedPage >= 0) root.advancedPage = -1
            else GlobalStates.settingsOverlayOpen = false
        }
    }
    Shortcut { sequence: "Ctrl+F"; enabled: GlobalStates.settingsOverlayOpen; onActivated: searchField.forceActiveFocus() }
    MouseArea { anchors.fill: parent; onClicked: GlobalStates.settingsOverlayOpen = false }

    IrisMorphSurface {
        id: frame
        open: GlobalStates.settingsOverlayOpen
        radius: Math.round(30 * root.d)
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width - 32, 980 * root.d)
        height: Math.min(parent.height - 48, 700 * root.d)
        MouseArea { anchors.fill: parent }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Sidebar ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.min(236 * root.d, frame.width * 0.3)
                color: IrisStyle.surfaceHigh
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12 * root.d
                    anchors.topMargin: 16 * root.d
                    spacing: 2 * root.d

                    // Search capsule.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10 * root.d
                        implicitHeight: Math.round(32 * root.d)
                        radius: height / 2
                        color: ColorUtils.applyAlpha(IrisStyle.text, searchField.activeFocus ? 0.12 : 0.08)
                        border.width: searchField.activeFocus ? 1 : 0
                        border.color: ColorUtils.applyAlpha(IrisStyle.accent, 0.6)
                        MaterialSymbol {
                            id: searchGlyph
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * root.d
                            anchors.verticalCenter: parent.verticalCenter
                            text: "search"
                            iconSize: Math.round(16 * root.d)
                            color: IrisStyle.muted
                        }
                        TextInput {
                            id: searchField
                            anchors.left: searchGlyph.right
                            anchors.leftMargin: 6 * root.d
                            anchors.right: parent.right
                            anchors.rightMargin: 12 * root.d
                            anchors.verticalCenter: parent.verticalCenter
                            color: IrisStyle.text
                            selectionColor: IrisStyle.accentContainer
                            font.family: IrisStyle.fontMain
                            font.pixelSize: 13 * IrisStyle.typeScale
                            clip: true
                            onTextChanged: { root.query = text; if (text.length > 0) root.advancedPage = -1 }
                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchField.text.length === 0
                                text: Translation.tr("Search")
                                color: IrisStyle.muted
                                font.pixelSize: searchField.font.pixelSize
                            }
                        }
                    }

                    Repeater {
                        model: root.sections
                        MouseArea {
                            id: sectionRow
                            required property var modelData
                            readonly property bool selected: root.query.length === 0 && root.section === sectionRow.modelData.id
                            Layout.fillWidth: true
                            implicitHeight: Math.round(36 * root.d)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            Accessible.role: Accessible.Button
                            Accessible.name: Translation.tr(sectionRow.modelData.title)
                            onClicked: root.selectSection(sectionRow.modelData.id)
                            Rectangle {
                                anchors.fill: parent
                                radius: Math.round(10 * root.d)
                                color: sectionRow.selected ? ColorUtils.applyAlpha(IrisStyle.accent, 0.22)
                                    : sectionRow.containsMouse ? ColorUtils.applyAlpha(IrisStyle.text, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: IrisStyle.duration(110) } }
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8 * root.d
                                anchors.rightMargin: 8 * root.d
                                spacing: 10 * root.d
                                Rectangle {
                                    implicitWidth: Math.round(24 * root.d)
                                    implicitHeight: implicitWidth
                                    radius: Math.round(7 * root.d)
                                    color: sectionRow.modelData.tint
                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        text: sectionRow.modelData.icon
                                        iconSize: Math.round(15 * root.d)
                                        fill: 1
                                        color: "#ffffff"
                                    }
                                }
                                IrisText {
                                    Layout.fillWidth: true
                                    text: Translation.tr(sectionRow.modelData.title)
                                    font.pixelSize: 13 * IrisStyle.typeScale
                                    font.weight: sectionRow.selected ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8 * root.d
                        Layout.bottomMargin: 4 * root.d
                        spacing: 8 * root.d
                        IrisMark { implicitSize: Math.round(22 * root.d) }
                        ColumnLayout {
                            spacing: 0
                            IrisText { text: "iRiS"; font.pixelSize: 13 * IrisStyle.typeScale; font.weight: Font.DemiBold }
                            IrisText {
                                text: IrisStyle.island ? Translation.tr("Island design") : Translation.tr("Classic design")
                                color: IrisStyle.muted
                                font.pixelSize: 11 * IrisStyle.typeScale
                            }
                        }
                    }
                }
            }

            // ── Content ────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 28 * root.d
                    Layout.rightMargin: 14 * root.d
                    Layout.topMargin: 14 * root.d
                    Layout.preferredHeight: Math.round(56 * root.d)
                    spacing: 8 * root.d
                    IrisIconButton {
                        visible: root.advancedPage >= 0
                        materialIcon: "chevron_left"
                        onClicked: root.advancedPage = -1
                        Accessible.name: Translation.tr("Back")
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        IrisText {
                            Layout.fillWidth: true
                            text: root.query.length > 0 ? Translation.tr("Results for “%1”").arg(root.query)
                                : root.advancedPage >= 0 ? String(root.pages[root.advancedPage]?.name ?? root.pages[root.advancedPage]?.title ?? "")
                                : Translation.tr(root.currentSection.title)
                            font.family: IrisStyle.fontTitle
                            font.pixelSize: 21 * IrisStyle.typeScale
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: root.query.length === 0 && root.advancedPage < 0
                            text: Translation.tr(root.currentSection.subtitle)
                            color: IrisStyle.muted
                            font.pixelSize: 12 * IrisStyle.typeScale
                            elide: Text.ElideRight
                        }
                    }
                    IrisIconButton {
                        materialIcon: "close"
                        onClicked: GlobalStates.settingsOverlayOpen = false
                        Accessible.name: Translation.tr("Close settings")
                    }
                }

                Item {
                    id: pageArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ParallelAnimation {
                        id: pageEnter
                        NumberAnimation { target: pageArea; property: "opacity"; from: 0.35; to: 1; duration: IrisStyle.duration(160); easing.type: Easing.OutCubic }
                        NumberAnimation { target: pageShift; property: "y"; from: 10 * root.d; to: 0; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
                    }
                    transform: Translate { id: pageShift }

                    Flickable {
                        id: settingsFlick
                        anchors.fill: parent
                        visible: root.advancedPage < 0
                        contentHeight: settingsRows.implicitHeight + 28 * root.d
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: settingsRows
                            x: 28 * root.d
                            y: 8 * root.d
                            width: settingsFlick.width - 56 * root.d
                            spacing: 20 * root.d

                            Loader {
                                Layout.fillWidth: true
                                active: root.section === "bar" && root.query.length === 0
                                visible: active
                                sourceComponent: IslandPreview {}
                            }

                            IrisText {
                                visible: root.query.length > 0 && root.entries.length === 0
                                Layout.topMargin: 24 * root.d
                                Layout.alignment: Qt.AlignHCenter
                                text: Translation.tr("No matching settings")
                                color: IrisStyle.muted
                            }

                            Repeater {
                                model: root.groups
                                ColumnLayout {
                                    id: group
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 6 * root.d
                                    IrisText {
                                        Layout.leftMargin: 16 * root.d
                                        text: group.modelData.title
                                        color: IrisStyle.muted
                                        font.pixelSize: 12 * IrisStyle.typeScale
                                        font.weight: Font.DemiBold
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: groupRows.implicitHeight
                                        radius: Math.round(14 * root.d)
                                        color: IrisStyle.surfaceHigh
                                        ColumnLayout {
                                            id: groupRows
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            spacing: 0
                                            Repeater {
                                                model: group.modelData.rows
                                                IrisSetting {
                                                    required property var modelData
                                                    required property int index
                                                    Layout.fillWidth: true
                                                    spec: modelData
                                                    last: index === group.modelData.rows.length - 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            LinkCard {
                                visible: root.section === "desktop" && root.query.length === 0
                                links: [{ label: Translation.tr("Edit desktop widgets"), icon: "edit", action: () => { GlobalStates.settingsOverlayOpen = false; GlobalStates.setWidgetEditMode(true) } }]
                            }

                            LinkCard {
                                visible: root.section === "system" && root.query.length === 0
                                links: root.pages.filter(page => !page.panelFamily || page.panelFamily === "iris").map(page => ({
                                    label: String(page.name ?? page.title ?? page.key),
                                    icon: page.icon ?? "chevron_right",
                                    action: () => root.advancedPage = root.pages.findIndex(candidate => candidate.key === page.key)
                                }))
                            }
                        }
                    }

                    SettingsPageHost {
                        id: pageHost
                        anchors.fill: parent
                        anchors.leftMargin: 12 * root.d
                        anchors.rightMargin: 12 * root.d
                        onCurrentItemChanged: {
                            if (currentItem && root.requestedSection.length > 0
                                && SettingsSearchRegistry.activatePageSection(currentItem, root.requestedSection))
                                root.requestedSection = ""
                        }
                        onCurrentIndexChanged: {
                            if (currentIndex >= 0) GlobalStates.settingsOverlayCurrentPage = currentIndex
                        }
                        visible: root.advancedPage >= 0
                        pages: root.pages
                        requestedIndex: root.advancedPage
                        loadEnabled: visible
                        directNavigation: true
                    }
                }
            }
        }
    }

    component Morph: NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }

    // A grouped card of navigation rows with chevrons.
    component LinkCard: Rectangle {
        id: card
        property var links: []
        Layout.fillWidth: true
        implicitHeight: linkColumn.implicitHeight
        radius: Math.round(14 * root.d)
        color: IrisStyle.surfaceHigh
        ColumnLayout {
            id: linkColumn
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
            Repeater {
                model: card.links
                MouseArea {
                    id: link
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(44 * root.d)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: link.modelData.label
                    onClicked: link.modelData.action()
                    Rectangle {
                        anchors.fill: parent
                        radius: card.radius
                        color: ColorUtils.applyAlpha(IrisStyle.text, link.containsMouse ? 0.05 : 0)
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16 * root.d
                        anchors.rightMargin: 12 * root.d
                        spacing: 12 * root.d
                        MaterialSymbol {
                            text: link.modelData.icon
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.subtext
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: link.modelData.label
                            font.pixelSize: 13.5 * IrisStyle.typeScale
                            font.weight: Font.Normal
                            elide: Text.ElideRight
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: Math.round(18 * root.d)
                            color: IrisStyle.muted
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 46 * root.d
                        height: 1
                        visible: link.index < card.links.length - 1
                        color: IrisStyle.hairline
                    }
                }
            }
        }
    }

    // Live miniature of the Island on a wallpaper strip; follows the options
    // above it with the same morph curve.
    component IslandPreview: Rectangle {
        id: preview
        readonly property var bar: Config.options?.iris?.bar ?? ({})
        readonly property bool island: IrisStyle.island
        readonly property bool cluster: String(preview.bar?.composition ?? "unified") === "cluster"
        readonly property bool atBottom: String(preview.bar?.position ?? "top") === "bottom"
        readonly property bool notch: preview.bar?.notch ?? false
        readonly property real unit: 0.42
        readonly property real pillHeight: Math.max(14, Number(preview.bar?.height ?? 42) * preview.unit)
        readonly property real gap: preview.notch ? 0 : Number(preview.bar?.margin ?? 8) * preview.unit
        implicitHeight: Math.round(132 * root.d)
        radius: Math.round(14 * root.d)
        clip: true
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#2b2f4a" }
            GradientStop { position: 0.55; color: "#5a3f5c" }
            GradientStop { position: 1; color: "#b0655a" }
        }

        // Classic: a full-width bar.
        Rectangle {
            visible: !preview.island
            x: preview.gap + 10; width: preview.width - 2 * (preview.gap + 10)
            y: preview.atBottom ? preview.height - height - preview.gap - 6 : preview.gap + 6
            height: preview.pillHeight
            radius: 6
            color: "#000000"
        }
        // Island chassis.
        Rectangle {
            id: chassis
            visible: preview.island
            width: preview.cluster ? 54 : 118
            height: preview.pillHeight + (preview.notch ? radius : 0)
            radius: preview.pillHeight / 2
            x: (preview.width - width) / 2
            y: preview.atBottom ? preview.height - preview.pillHeight - preview.gap - (preview.notch ? 0 : 6) : (preview.notch ? -radius : preview.gap + 6)
            color: "#000000"
            Behavior on width { Morph {} }
            Behavior on y { Morph {} }
            IrisText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: (preview.notch && !preview.atBottom ? chassis.radius : 0) + (preview.pillHeight - height) / 2
                text: DateTime.timeDisplay
                color: "#ffffff"
                font.pixelSize: Math.max(8, preview.pillHeight * 0.36)
                font.weight: Font.DemiBold
            }
        }
        Repeater {
            model: 2
            Rectangle {
                required property int index
                visible: preview.island
                width: preview.pillHeight - (preview.notch ? 3 : 0)
                height: width
                radius: width / 2
                color: "#000000"
                y: preview.atBottom ? preview.height - preview.pillHeight - preview.gap - (preview.notch ? 0 : 6) + (preview.pillHeight - height) / 2
                    : (preview.notch ? 0 : preview.gap + 6) + (preview.pillHeight - height) / 2
                x: preview.cluster
                    ? (index === 0 ? chassis.x - width - 3 : chassis.x + chassis.width + 3)
                    : chassis.x + (chassis.width - width) / 2
                opacity: preview.cluster ? 1 : 0
                Behavior on x { Morph {} }
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(120) } }
            }
        }
        // Dock, opposite the Island.
        Rectangle {
            readonly property bool dockNotch: Config.options?.iris?.dock?.notch ?? false
            visible: Config.options?.iris?.dock?.enable ?? true
            width: 150
            height: 20
            radius: dockNotch ? 6 : 8
            x: (preview.width - width) / 2
            y: preview.atBottom ? (dockNotch ? -6 : 8) : preview.height - height - (dockNotch ? -6 : 8)
            color: "#000000"
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: parent.dockNotch ? (preview.atBottom ? 3 : -3) : 0
                spacing: 5
                Repeater {
                    model: 7
                    Rectangle { width: 11; height: 11; radius: 3; color: Qt.rgba(1, 1, 1, 0.22 + (index % 3) * 0.12); required property int index }
                }
            }
        }
    }
}
