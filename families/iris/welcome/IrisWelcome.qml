import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.welcome
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.preview
import qs.modules.iris.components as Iris

// What the welcome wizard shows with iRiS: its look, its three steps and their presets.
Item {
    id: part
    visible: false
    readonly property var wizard: WelcomeHost.wizard

    readonly property color welcomeSurfaceRaised: IrisStyle.surface
    readonly property color welcomeSurfaceHigh: IrisStyle.surfaceHigh
    readonly property color welcomeSurfaceHighest: IrisStyle.surfaceHighest
    readonly property color welcomeSurfaceRaisedHover: IrisStyle.fillHover
    readonly property color welcomeOnSurface: IrisStyle.textStrong
    readonly property color welcomeOnSurfaceVariant: IrisStyle.textSecondary
    readonly property color welcomeOutline: IrisStyle.border
    readonly property color welcomePrimary: IrisStyle.accent
    readonly property color welcomeOnPrimary: IrisStyle.inkOnAccent
    readonly property color welcomePrimaryContainer: IrisStyle.tintFill(IrisStyle.accent)
    readonly property color welcomeOnPrimaryContainer: IrisStyle.textStrong
    readonly property color welcomeSecondary: IrisStyle.secondaryAccent
    readonly property color welcomeSecondaryContainer: IrisStyle.fill
    readonly property color welcomeOnSecondaryContainer: IrisStyle.textStrong
    readonly property color welcomeTertiary: IrisStyle.secondaryAccent
    readonly property color welcomeTertiaryContainer: IrisStyle.tintFill(IrisStyle.secondaryAccent)
    readonly property color welcomeOnTertiaryContainer: IrisStyle.textStrong
    readonly property color welcomeAccentHover: IrisStyle.tintFillHover(IrisStyle.accent)
    readonly property string welcomeFontMain: IrisStyle.fontMain
    readonly property string welcomeFontTitle: IrisStyle.fontTitle
    readonly property string welcomeFontNumbers: IrisStyle.fontNumbers
    readonly property real welcomePanelRadius: IrisStyle.radiusPanel
    readonly property real welcomeControlRadius: IrisStyle.radiusRow
    readonly property real welcomeChoiceRadius: IrisStyle.radiusTile
    readonly property real welcomeCardRadius: IrisStyle.radiusPlate
    readonly property real welcomeFrameInset: IrisStyle.concentricPad(IrisStyle.radiusPanel, 10)
    readonly property real welcomeHeadlineSize: 26 * IrisStyle.typeScale
    readonly property color welcomeSegmentFill: IrisStyle.fill
    readonly property real welcomeKeyRadius: IrisStyle.radiusChip
    readonly property bool welcomeBorderless: true
    readonly property real welcomePlateRadius: IrisStyle.radiusPlate
    readonly property color welcomeQuietFill: IrisStyle.fillQuiet
    readonly property bool welcomeChoiceMark: false
    readonly property real welcomeIntroShare: 0.58

    readonly property var steps: [
        {
            icon: "tune", title: Translation.tr("Starting point"),
            headline: Translation.tr("Choose an iRiS layout"),
            subtitle: Translation.tr("Signature, floating, or a full bar.")
        },
        {
            icon: "palette", title: Translation.tr("Appearance"),
            headline: Translation.tr("Choose an iRiS theme"),
            subtitle: Translation.tr("Themes set material, shape, type and motion together.")
        },
        {
            icon: "dashboard", title: Translation.tr("Layout"),
            headline: Translation.tr("Arrange the desktop"),
            subtitle: Translation.tr("Set the Island edge, Dock and desktop widgets.")
        }
    ]
    readonly property var pages: [startPage, appearancePage, layoutPage]
    readonly property string startSummary: part.effectiveIrisArrangement === "custom"
        ? Translation.tr("Custom") : part.currentIrisArrangement.name
    readonly property string styleSummary: IrisThemes.active?.name ?? Translation.tr("Custom")

    property bool desktopApplied: false
    function entered(step: int): void {
        if (step !== 1 || part.desktopApplied)
            return
        part.desktopApplied = true
        Config.setNestedValues({
            "background.effects.enableBlur": false,
            "background.effects.dim": 0,
            "background.effects.dynamicDim": 0
        })
    }

    readonly property var irisArrangements: [
        {
            id: "signature", name: Translation.tr("Signature"), icon: "crop_free",
            badge: Translation.tr("Recommended"),
            description: Translation.tr("Island attached to its edge, Surround on, Dock opposite."),
            values: {
                "iris.bar.layout": "island",
                "iris.bar.notch": true,
                "iris.surround.enable": true,
                "iris.bar.composition": "cluster",
                "iris.dock.enable": true,
                "iris.dock.position": "auto",
                "iris.dock.notch": true
            }
        },
        {
            id: "floating", name: Translation.tr("Floating"), icon: "layers",
            description: Translation.tr("Island and Dock float above the wallpaper."),
            values: {
                "iris.bar.layout": "island",
                "iris.bar.notch": false,
                "iris.surround.enable": false,
                "iris.bar.composition": "cluster",
                "iris.dock.enable": true,
                "iris.dock.position": "auto",
                "iris.dock.notch": false
            }
        },
        {
            id: "full", name: Translation.tr("Full bar"), icon: "width_full",
            description: Translation.tr("Island spans the edge with start, center and end zones."),
            values: {
                "iris.bar.layout": "full",
                "iris.bar.notch": true,
                "iris.surround.enable": false,
                "iris.bar.composition": "unified",
                "iris.dock.enable": true,
                "iris.dock.position": "auto",
                "iris.dock.notch": false
            }
        }
    ]
    readonly property var irisWelcomeThemeIds: [
        "iris", "liquid-glass", "frost", "aurora", "terminal", "adaptive"
    ]
    readonly property var irisWelcomeThemes: IrisThemes.curated.filter(
        theme => part.irisWelcomeThemeIds.includes(theme.id))

    readonly property string effectiveIrisArrangement: {
        for (const arrangement of part.irisArrangements) {
            if (part.wizard.valuesMatch(arrangement.values))
                return arrangement.id
        }
        return "custom"
    }
    readonly property var currentIrisArrangement: part.wizard.presetById(part.irisArrangements,
        part.effectiveIrisArrangement)


    function applyIrisArrangement(id: string): void {
        Config.setNestedValues(part.wizard.presetById(part.irisArrangements, id).values)
    }

    function applyIrisTheme(id: string): void {
        const theme = IrisThemes.find(id)
        if (theme) IrisThemes.apply(theme)
    }

    // each page brings its own edge fade: the wizard can't anchor one to an item inside a Loader
    Component {
        id: startPage
        Item {
            IrisWelcomeStart { id: page; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.bottom: parent.bottom }
            ScrollEdgeFade { target: page; visible: page.contentHeight > page.height }
        }
    }
    Component {
        id: appearancePage
        Item {
            IrisWelcomeAppearance { id: page; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.bottom: parent.bottom }
            ScrollEdgeFade { target: page; visible: page.contentHeight > page.height }
        }
    }
    Component {
        id: layoutPage
        Item {
            IrisWelcomeLayout { id: page; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.bottom: parent.bottom }
            ScrollEdgeFade { target: page; visible: page.contentHeight > page.height }
        }
    }

    readonly property Component frame: Component {
        Iris.IrisMorphSurface {
            anchors.fill: parent
            open: part.wizard._contentReady
            radius: IrisStyle.radiusPanel
            color: IrisStyle.surfaceHigh
            light: IrisStyle.wallpaperLight
            motionSurface: "settings"
        }
    }
    readonly property Component mark: Component {
        Iris.IrisMark { implicitSize: parent ? parent.width : 30 }
    }
    readonly property Component intro: Component {
        ColumnLayout {
            spacing: 10
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: width / part.wizard.screenAspect
                IrisScreenPreview {
                    anchors.fill: parent
                    screen: part.wizard.focusedScreen
                    maxScale: 1
                }
            }
            WelcomeText {
                text: "iRiS"
                font.family: part.wizard.welcomeFontTitle
                font.pixelSize: 28 * IrisStyle.typeScale
                font.weight: Font.Bold
                color: part.wizard.welcomeOnSurface
            }
            WelcomeText {
                Layout.fillWidth: true
                text: Translation.tr("Your desktop, built around the Island.")
                font.pixelSize: part.wizard.welcomeFontBody
                color: part.wizard.welcomeSecondaryText
                wrapMode: Text.WordWrap
            }
        }
    }
}
