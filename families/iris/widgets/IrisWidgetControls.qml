pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.shared.background.widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.widgets.sheet

// A widget's quick controls in Prism Settings' language (his 11-07): its mark and name, the pages as Prism's segmented
// pill, then each page (`sheet/`): choices drawn as cards that stand on the solid when chosen, settings as the numbered
// chart. Hosted by the edit sheet (IrisWidgetSheet) and by the lock's inspector.
ColumnLayout {
    id: root

    required property var widget
    // Hosted by the lock inspector: closing lets go of the selection and removing takes it off the lock only.
    property bool onLock: false
    signal closeRequested()
    function close(): void {
        if (root.onLock) root.closeRequested()
        else root.widget.closeQuickControls()
    }
    readonly property real d: IrisStyle.density
    // The corner of its plates: the sheet that hosts it sets it, so they stay concentric with that sheet (DI29).
    property real plateRadius: IrisStyle.radiusRow
    // Draws a list of rows, given by a host that can (the edit sheet). `IrisSheetRows`-shaped: `specs`, `firstNumber`.
    property Component optionRows: null
    // The keys this sheet draws itself; every other row of the widget comes from the manifest, on its page.
    readonly property var drawn: ["sizeClass", DesktopWidgetDesign.spec.key, "widgetScale", "placementStrategy", "locked"]
        .concat(root.widget.familyFaced ? ["showBackground", "iris.material"] : [])
        .concat(root.widget.ownControlKeys)
    readonly property var widgetRows: root.optionRows ? DesktopWidgetOptions.sheetRows(root.widget.configEntryName, "widget", root.drawn)
        .map(spec => Object.assign({}, spec, { group: "" })) : []
    readonly property var lookRows: root.optionRows ? DesktopWidgetOptions.sheetRows(root.widget.configEntryName, "look", root.drawn)
        .map(spec => Object.assign({}, spec, { group: "" })) : []
    readonly property bool faced: root.widget.familyFaced
    readonly property bool plated: root.widget.showBackground
    readonly property var pages: [
        { value: "widget", label: "Widget" },
        { value: "look", label: "Look" },
        { value: "arrange", label: "Arrange" }
    ].concat(root.widget.stacked ? [{ value: "stack", label: "Stack" }] : [])
    readonly property string page: root.pages.some(entry => entry.value === root.widget._quickTab) ? root.widget._quickTab : "widget"
    readonly property string wallpaperUrl: WallpaperListener.wallpaperUrlForScreen(root.QsWindow?.window?.screen ?? null)
    readonly property string ownMaterial: String(root.widget._readConfigKey("iris.material") ?? "auto")
    readonly property string sharedMaterial: String(Config.options?.iris?.widgets?.material ?? "glass")
    // What stands behind the widget, one row: no plate at all, the one every widget shares (from Settings), or its own.
    readonly property var materials: [
        { value: "none", label: Translation.tr("None") },
        { value: "auto", label: Translation.tr("Shared") },
        { value: "glass", label: Translation.tr("Glass") },
        { value: "solid", label: Translation.tr("Solid") },
        { value: "tinted", label: Translation.tr("Tinted") }
    ].filter(entry => entry.value !== "auto" || root.sharedMaterial !== "clear")
    readonly property string surface: !root.plated ? "none"
        : ["glass", "solid", "tinted"].includes(root.ownMaterial) ? root.ownMaterial
        : root.sharedMaterial === "clear" ? "glass" : "auto"
    function pickSurface(value: string): void {
        root.widget._setOutputValues(value === "none" ? { showBackground: false } : { showBackground: true, "iris.material": value })
    }
    readonly property real cornerMax: 40
    readonly property int cornerValue: Number(root.widget.cornerRadiusOverride)
    readonly property real opacityMin: 20
    readonly property int opacityValue: Math.round(root.widget.look.surfaceOpacity(root.widget) * 100)
    readonly property real scaleMin: 60
    readonly property real scaleMax: 160
    readonly property real scaleValue: Math.round(root.widget.scaleFactor * 100)

    function materialColor(value: string): color {
        const material = value === "none" ? "clear" : value === "auto" ? root.sharedMaterial : value
        if (material === "tinted")
            return root.widget.look.tintedPlate
        if (material === "solid")
            return IrisStyle.surface
        return ColorUtils.applyAlpha(IrisStyle.surface, IrisStyle.materialVeil[material] ?? 1)
    }

    // A popover's measures: one width, as tall as the page in view (`pageHeight`), placed for the tallest (`restingHeight`)
    // so its head never moves under the pointer while the body glides between pages. His 11-02: a sheet that jumped on
    // every tab, then one held at its tallest page that left an empty box under Widget.
    readonly property real resolvedWidth: PrismTheme.dp(344)
    readonly property real restingHeight: Math.ceil(root.implicitHeight)
    readonly property real pageHeight: Math.ceil(root.implicitHeight - pageStack.implicitHeight
        + (pageStack.children[pageStack.currentIndex]?.implicitHeight ?? 0))
    spacing: PrismTheme.dp(16)
    readonly property string designLabel: root.widget.stacked ? ""
        : (root.widget.designChoices.find(entry => entry.value === root.widget.widgetDesign)?.label ?? "")

    // The sheet's head: the widget's mark and name over what it is now (its size and design), and the way out.
    RowLayout {
        Layout.fillWidth: true
        spacing: PrismTheme.dp(12)

        Rectangle {
            Layout.preferredWidth: PrismTheme.dp(38)
            Layout.preferredHeight: Layout.preferredWidth
            radius: Math.round(width * 0.26)
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.lighter(root.widget.identityTint, 1.18) }
                GradientStop { position: 1; color: Qt.darker(root.widget.identityTint, 1.22) }
            }
            PrismGlyph {
                anchors.centerIn: parent
                text: root.widget.identityGlyph
                filled: true
                iconSize: PrismTheme.dp(20)
                color: PrismTheme.paper
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: PrismTheme.dp(1)
            PrismText {
                Layout.fillWidth: true
                text: [root.widget.sizeChoices.length > 1 ? (root.widget.sizeLabels[root.widget.sizeClass] ?? "") : "",
                    root.designLabel].filter(part => part.length > 0).join(" · ")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
            PrismText {
                Layout.fillWidth: true
                text: root.widget.displayName
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
            }
        }
        PrismRound {
            Layout.alignment: Qt.AlignTop
            implicitWidth: PrismTheme.dp(30)
            glyph: "close"
            glyphSize: PrismTheme.dp(16)
            onClicked: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Close")
        }
    }

    PrismChoice {
        Layout.fillWidth: true
        choices: root.pages
        current: root.page
        room: Number.POSITIVE_INFINITY
        onPicked: value => root.widget._quickTab = value
        Accessible.name: Translation.tr("Quick controls")
    }

    StackLayout {
        id: pageStack
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.topMargin: PrismTheme.dp(4)
        currentIndex: Math.max(0, ["widget", "stack", "look", "arrange"].indexOf(root.page))

        SheetWidgetPage { controls: root }

        // Built only for a widget in a stack: the sheet measures every page, and an empty one counts nothing.
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            active: root.widget.stacked
            sourceComponent: IrisStackControls {
                widget: root.widget
                rowRadius: PrismTheme.dp(12)
                part: "manage"
            }
        }

        SheetLookPage { controls: root }

        SheetArrangePage {
            controls: root
            joinControls: Component {
                IrisStackControls {
                    widget: root.widget
                    rowRadius: PrismTheme.dp(12)
                    part: "join"
                }
            }
        }
    }
}
