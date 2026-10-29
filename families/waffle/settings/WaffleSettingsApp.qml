import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions as CF
import qs.modules.waffle.looks
import qs.modules.waffle.settings

ApplicationWindow {
    id: root
    
    property bool uiReady: Config.ready
    property string pendingStartSection: ""
    
    property var pages: [
        {
            name: Translation.tr("Home"),
            desc: Translation.tr("What you change most"),
            icon: "flash-on",
            component: Qt.resolvedUrl("pages/WQuickPage.qml")
        },
        {
            name: Translation.tr("General"),
            desc: Translation.tr("Sound, power, time, input, idle"),
            icon: "settings",
            component: Qt.resolvedUrl("pages/WGeneralPage.qml")
        },
        {
            name: Translation.tr("Taskbar"),
            desc: Translation.tr("Alignment, icons, clock, tray"),
            icon: "pin",
            component: Qt.resolvedUrl("pages/WBarPage.qml")
        },
        {
            name: Translation.tr("Background"),
            desc: Translation.tr("Wallpaper, slideshow, effects"),
            icon: "image",
            component: Qt.resolvedUrl("pages/WBackgroundPage.qml")
        },
        {
            name: Translation.tr("Themes"),
            desc: Translation.tr("Colors, light and dark, fonts"),
            icon: "dark-theme",
            component: Qt.resolvedUrl("pages/WThemesPage.qml")
        },
        {
            name: Translation.tr("Gowall"),
            desc: Translation.tr("Recolor wallpapers to your theme"),
            icon: "wand",
            component: Qt.resolvedUrl("pages/WGowallPage.qml")
        },
        {
            name: Translation.tr("Interface"),
            desc: Translation.tr("Start, Action Center, notifications"),
            icon: "widgets",
            component: Qt.resolvedUrl("pages/WInterfacePage.qml")
        },
        {
            name: Translation.tr("Modules"),
            desc: Translation.tr("Which parts of the shell run"),
            icon: "settings-cog-multiple",
            component: Qt.resolvedUrl("pages/WModulesPage.qml")
        },
        {
            name: Translation.tr("Waffle Style"),
            desc: Translation.tr("The Windows 11 look and its details"),
            icon: "start-here",
            component: Qt.resolvedUrl("pages/WWaffleStylePage.qml")
        },
        {
            name: Translation.tr("Shortcuts"),
            desc: Translation.tr("Every key combination"),
            icon: "keyboard",
            component: Qt.resolvedUrl("pages/WShortcutsPage.qml")
        },
        {
            name: Translation.tr("About"),
            desc: Translation.tr("Version, system, credits"),
            icon: "info",
            component: Qt.resolvedUrl("pages/WAboutPage.qml")
        },
        {
            name: Translation.tr("Monitors"),
            desc: Translation.tr("What shows on each display"),
            icon: "desktop",
            component: Qt.resolvedUrl("pages/WMonitorVisibilityPage.qml")
        },
        {
            name: Translation.tr("Autostart"),
            desc: Translation.tr("Apps that start with iNiR"),
            icon: "power",
            component: Qt.resolvedUrl("pages/WAutostartPage.qml")
        },
        {
            name: Translation.tr("Workspace Strip"),
            desc: Translation.tr("The workspace switcher at the screen edge"),
            icon: "panel-left-expand",
            component: Qt.resolvedUrl("pages/WWorkspaceStripPage.qml")
        },
        {
            name: Translation.tr("Mascot"),
            desc: Translation.tr("Kira on your desktop"),
            icon: "people",
            component: Qt.resolvedUrl("pages/WMascotPage.qml")
        },
        {
            name: Translation.tr("AI"),
            desc: Translation.tr("Models, providers, privacy"),
            icon: "wand",
            component: Qt.resolvedUrl("pages/WAiPage.qml")
        },
        {
            name: Translation.tr("Effects"),
            desc: Translation.tr("Blur, glass, motion"),
            icon: "eye",
            component: Qt.resolvedUrl("pages/WEffectsPage.qml")
        },
        {
            name: Translation.tr("Shell Layout"),
            desc: Translation.tr("Move and size the panels"),
            icon: "panel-left-contract",
            component: Qt.resolvedUrl("pages/WShellLayoutPage.qml")
        },
        {
            key: "hub",
            name: Translation.tr("Hub"),
            desc: Translation.tr("Widgets, themes and web apps"),
            icon: "store-microsoft",
            component: Qt.resolvedUrl("pages/WHubPage.qml")
        }
    ]
    
    // the pane shows these; a category with one page opens it, more show their link cards (Windows' Settings IA)
    readonly property var categories: [
        { name: Translation.tr("Home"), icon: "widgets", tint: "#0067C0", tintDark: "#60CDFF", pages: [0] },
        { name: Translation.tr("System"), icon: "desktop", tint: "#0067C0", tintDark: "#4CC2FF", pages: [1, 11, 12], hero: "system" },
        { name: Translation.tr("Personalization"), icon: "paint-bucket", tint: "#C239B3", tintDark: "#F08CE4", pages: [3, 4, 2, 8, 5, 14], hero: "desktop" },
        { name: Translation.tr("Windows & layout"), icon: "apps", tint: "#8764B8", tintDark: "#C6A8F5", pages: [6, 7, 17, 13, 16] },
        { name: Translation.tr("Keyboard & shortcuts"), icon: "keyboard", tint: "#038387", tintDark: "#4FD8D8", pages: [9] },
        { name: Translation.tr("AI"), icon: "wand", tint: "#CA5010", tintDark: "#FFA266", pages: [15] },
        { name: Translation.tr("Hub"), icon: "store-microsoft", tint: "#107C10", tintDark: "#6CCB5F", pages: [18] },
        { name: Translation.tr("About"), icon: "info", tint: "#5D5A58", tintDark: "#C8C6C4", pages: [10], apart: true }
    ]

    property int currentPage: 0
    property int _requestedStartPage: -1
    property bool _navigationInitialized: false

    function _persistCurrentPage(): void {
        if (root._navigationInitialized && Persistent.ready && Persistent.states?.settings)
            Persistent.states.settings.wafflePage = Math.max(0, Math.min(root.currentPage, root.pages.length - 1))
    }

    function initializeNavigation(): void {
        if (root._navigationInitialized || !Persistent.ready)
            return
        const persisted = Persistent.states?.settings?.wafflePage ?? 0
        const requested = root._requestedStartPage >= 0 ? root._requestedStartPage : persisted
        root.currentPage = Math.max(0, Math.min(requested, root.pages.length - 1))
        root._navigationInitialized = true
        root._persistCurrentPage()
        root.tryOpenPendingSection()
    }

    onCurrentPageChanged: root._persistCurrentPage()
    
    visible: true
    onClosing: Qt.quit()
    title: "Settings — iNiR"

    function tryOpenPendingSection(): void {
        if (!root.pendingStartSection || !root.uiReady)
            return

        const targetLabel = root.pendingStartSection
        root.pendingStartSection = ""
        Qt.callLater(() => {
            settingsContent.openSearchResult({
                pageIndex: root.currentPage,
                targetLabel: targetLabel
            })
        })
    }
    
    Component.onCompleted: {
        Quickshell.watchFiles = false
        Config.readWriteDelay = 0
        // A number, or a page's key (`inir settingsNav open hub`).
        const startEnv = Quickshell.env("QS_SETTINGS_PAGE") ?? "";
        const startPage = parseInt(startEnv);
        if (!isNaN(startPage)) root._requestedStartPage = startPage;
        else if (startEnv.length > 0) root._requestedStartPage = root.pages.findIndex(page => page.key === startEnv);

        const startSection = Quickshell.env("QS_SETTINGS_SECTION");
        if (startSection)
            root.pendingStartSection = startSection;

        root.initializeNavigation()
    }

    Connections {
        target: Persistent
        function onReadyChanged() { root.initializeNavigation() }
    }
    
    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) ThemeService.applyCurrentTheme()
            root.tryOpenPendingSection()
        }
    }
    
    minimumWidth: 700
    minimumHeight: 450
    width: 1280
    height: 820
    color: root.uiReady ? Looks.colors.bg0Opaque : "transparent"
    
    // Loading state
    Item {
        anchors.fill: parent
        visible: !root.uiReady
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            
            FluentIcon {
                Layout.alignment: Qt.AlignHCenter
                icon: "settings"
                implicitSize: 32
                color: Looks.colors.accent
                opacity: loadingPulse.running ? 1 : 0.6
                
                SequentialAnimation on opacity {
                    id: loadingPulse
                    running: !root.uiReady
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.9; duration: 800; easing.type: Easing.InOutQuad }
                }
                
                RotationAnimation on rotation {
                    running: !root.uiReady
                    from: 0; to: 360
                    duration: 3000
                    loops: Animation.Infinite
                }
            }
            
            WText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Loading...")
                font.pixelSize: Looks.font.pixelSize.normal
                color: Looks.colors.subfg
            }
        }
    }
    
    // Main content
    WSettingsContent {
        id: settingsContent
        anchors.fill: parent
        visible: root.uiReady
        opacity: visible ? 1 : 0
        
        pages: root.pages
        categories: root.categories
        currentPage: root.currentPage
        loadEnabled: root.uiReady && root._navigationInitialized
        onCurrentPageChanged: {
            if (navigationReady && root.currentPage !== currentPage)
                root.currentPage = currentPage
        }
        onCloseRequested: root.close()
        Component.onCompleted: root.tryOpenPendingSection()
        
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }
    }
    
    // Keyboard shortcuts
    Shortcut {
        sequence: "Ctrl+PageDown"
        onActivated: root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
    }
    
    Shortcut {
        sequence: "Ctrl+PageUp"
        onActivated: root.currentPage = Math.max(root.currentPage - 1, 0)
    }
    
    Shortcut {
        sequence: "Ctrl+Tab"
        onActivated: root.currentPage = (root.currentPage + 1) % root.pages.length
    }
    
    Shortcut {
        sequence: "Ctrl+Shift+Tab"
        onActivated: root.currentPage = (root.currentPage - 1 + root.pages.length) % root.pages.length
    }
}
