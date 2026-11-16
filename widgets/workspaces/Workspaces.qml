pragma ComponentBehavior: Bound

// Your workspaces on the desktop as Niri lays them: one lane per workspace of this screen, its columns as wide as they
// are, the window each one comes back to marked; press a window to go to it, a lane to go to that workspace.
// The Material face holds the number of the workspace in use in the shape the person picks; iNstrument (or the
// person's iNstrument or Readout design) gives it the measured grammar. Under iRiS the family's widget designs draw
// it instead (IrisWorkspaces for iRiS, PrismWorkspaces for Prism, named by `iris.desktop` in widget.json).
// This file owns the reading: every face reads `lanes`, `open`, `here` from it.

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.instrument
import "workspaces.js" as Logic

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.workspaces"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie7Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240, icons: true })
    needsColText: true
    resizeMinWidth: 150
    resizeMinHeight: 150
    resizeMaxWidth: 760
    resizeMaxHeight: 760

    // ── What it reads ────────────────────────────────────────
    readonly property bool supported: CompositorService.isNiri || CompositorService.isUmbriel
    readonly property bool waiting: root.supported && root.spaces.length === 0
    readonly property bool steerable: !GlobalStates.widgetEditMode
    readonly property bool icons: Boolean(root._readConfigKey("icons") ?? true)
    readonly property real outputWidth: Number(NiriService.outputs?.[root.outputName]?.logical?.width ?? root.screenWidth)
    readonly property var hidden: Array.prototype.slice.call(MinimizedWindows.minimizedIds ?? [])
    // The workspace map, not `allWorkspaces`: only the map follows which window each workspace comes back to.
    readonly property var spaces: Object.values(NiriService.workspaces ?? {})
    // Rebuilt only when the layout moves (never on a title) and only while the card is on a desktop.
    readonly property string layoutKey: root.visible && root.supported
        ? Logic.keyOf(NiriService.windows, root.spaces, root.outputName, root.hidden) : ""
    property var lanes: []
    onLayoutKeyChanged: {
        if (root.layoutKey.length > 0)
            root.lanes = Logic.lanes(NiriService.windows, root.spaces, root.outputName, root.outputWidth, root.hidden)
    }
    readonly property int open: Logic.count(root.lanes)
    readonly property var current: Logic.active(root.lanes)
    readonly property var here: Logic.here(root.lanes)
        function lanesFor(most: int): var { return Logic.around(root.lanes, most) }

    // The words every face shares: the workspace in use, and what the foot says.
    readonly property string currentName: root.current
        ? (root.current.name.length > 0 ? root.current.name : Translation.tr("Workspace %1").arg(root.current.idx)) : ""
    readonly property string openText: root.open === 1 ? Translation.tr("1 window") : Translation.tr("%1 windows").arg(root.open)
    // A state with no lanes to draw says why, and what will show.
    readonly property string emptyText: !root.supported ? Translation.tr("Workspaces show on Niri and Umbriel")
        : root.waiting ? Translation.tr("Reading the workspaces…")
        : root.lanes.length === 0 ? Translation.tr("No workspace on this screen")
        : root.open === 0 ? Translation.tr("Nothing open. Your windows show here as Niri lays them out") : ""

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie7Sided")
    readonly property real k: Math.max(0.4, Math.min(root.width / (root.isSmall ? 176 : 368), root.height / (root.isLarge ? 368 : 176)))
    function px(v: real): int { return Math.round(v * root.k) }
    readonly property int pad: root.px(root.isSmall ? 14 : 16)
    readonly property bool mediumSize: !root.isSmall && !root.isLarge

    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && !root.familyFaced && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    // The lanes in the widget's ink: tiles over a quiet track, the window you come back to in the primary container.
    component Lanes: WorkspaceLanes {
        d: root.k
        steerable: root.steerable
        icons: root.icons
        fontNumbers: Appearance.font.family.numbers
        fontMain: Appearance.font.family.main
        feedback: Appearance.animation.elementMoveFast.duration
        wordSize: Appearance.font.pixelSize.smaller
        ink: root.widgetInk
        inkMuted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
        number: ColorUtils.applyAlpha(root.widgetInk, 0.5)
        numberActive: root.widgetAccentVisible
        well: ColorUtils.applyAlpha(root.widgetInk, root.instrument ? 0.05 : 0.07)
        wellHover: ColorUtils.applyAlpha(root.widgetInk, 0.11)
        wellActive: ColorUtils.applyAlpha(root.widgetInk, root.instrument ? 0.09 : 0.12)
        tile: ColorUtils.applyAlpha(root.widgetInk, 0.24)
        tileHover: ColorUtils.applyAlpha(root.widgetInk, 0.34)
        tileHere: ColorUtils.applyAlpha(root.widgetInk, 0.34)
        lit: root.widgetSemanticColor(root.widgetPrimaryRole)
        onLit: root.widgetSemanticOnColor(root.widgetPrimaryRole)
        radius: root.instrument ? 4 : 12
    }
    component Empty: StyledText {
        text: root.emptyText
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: root.px(Appearance.font.pixelSize.small)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
    }
    // The number of the workspace in use, in the picked shape (a quiet circle while there is none).
    component Seal: Item {
        id: seal
        property int size: root.px(64)
        implicitWidth: seal.size
        implicitHeight: seal.size
        MaterialShape {
            anchors.fill: parent
            implicitSize: seal.size
            shape: DesktopWidgetShapes.shapeForName(root.current ? root.shapeName : "Circle")
            color: root.current ? root.widgetSemanticContainer(root.widgetPrimaryRole) : ColorUtils.applyAlpha(root.widgetInk, 0.14)
        }
        StyledText {
            anchors.centerIn: parent
            visible: root.current !== null
            text: root.current?.idx ?? ""
            font.family: Appearance.font.family.numbers
            font.pixelSize: Math.round(seal.size * 0.44)
            font.weight: Font.Bold
            font.features: ({ "tnum": 1 })
            color: root.widgetSemanticOnContainer(root.widgetPrimaryRole)
        }
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.current === null
            text: "view_week"
            fill: 1
            iconSize: Math.round(seal.size * 0.42)
            color: root.widgetInk
        }
    }
    component Eyebrow: StyledText {
        text: Translation.tr("Workspaces")
        elide: Text.ElideRight
        // A long word ("Arbeitsbereiche" in caps) shrinks a little before it would be cut.
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(Appearance.font.pixelSize.smaller * 0.72)
        font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
        font.weight: Font.DemiBold
        font.capitalization: root.widgetCapitalization
        font.letterSpacing: root.isSmall ? 0 : root.px(1)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
    }
    component Detail: StyledText {
        elide: Text.ElideRight
        font.pixelSize: root.px(Appearance.font.pixelSize.small)
        color: ColorUtils.applyAlpha(root.widgetInk, 0.58)
    }

    // ── Shape look ───────────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.pad
        active: !root.instrument && !root.familyFaced
        sourceComponent: Item {
            id: face
            readonly property real head: root.isLarge ? root.px(72) : root.isSmall ? root.px(44) : 0
            // Small and large: the seal heads the card; medium: it stands at the left of the lanes.
            Seal {
                id: seal
                size: root.isLarge ? root.px(72) : root.isSmall ? root.px(44) : root.px(88)
                y: root.isSmall || root.isLarge ? 0 : Math.round((face.height - height) / 2)
            }
            // Medium: the name and the count share one line over the lanes.
            Eyebrow {
                visible: root.mediumSize
                x: lanes.x
                width: face.width - x - (mediumCount.visible ? mediumCount.implicitWidth + root.px(8) : 0)
            }
            Detail {
                id: mediumCount
                visible: root.mediumSize && root.emptyText.length === 0
                x: face.width - implicitWidth
                text: root.openText
            }
            Column {
                visible: !root.mediumSize
                x: seal.width + root.px(12)
                y: Math.round((face.head - height) / 2)
                width: face.width - x
                spacing: root.px(1)
                Eyebrow { width: parent.width }
                StyledText {
                    width: parent.width
                    visible: root.isLarge && root.current !== null
                    text: root.currentName
                    // A long name the person gave the workspace shrinks before it would be cut.
                    elide: Text.ElideRight
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: Math.round(font.pixelSize * 0.7)
                    font.family: root.widgetTitleFamily
                    font.weight: root.widgetTitleWeight
                    font.letterSpacing: root.widgetTitleTracking
                    font.pixelSize: root.px(Appearance.font.pixelSize.huge * root.widgetTitleScale)
                    color: root.widgetInk
                }
                Detail {
                    width: parent.width
                    visible: root.emptyText.length === 0
                    text: root.openText
                }
            }
            Lanes {
                id: lanes
                visible: root.emptyText.length === 0
                x: root.isSmall || root.isLarge ? 0 : seal.width + root.px(16)
                y: root.isSmall || root.isLarge ? face.head + root.px(12) : root.px(24)
                width: face.width - x
                height: face.height - y
                lanes: root.lanesFor(root.isLarge ? 6 : 3)
                numberWidth: root.isSmall ? 0 : 18
                numberSize: Appearance.font.pixelSize.small
                maxLane: root.isLarge ? 72 : root.isSmall ? 30 : 36
                icons: root.icons
                names: !root.isSmall
            }
            Empty {
                visible: root.emptyText.length > 0
                x: lanes.x
                y: lanes.y
                width: lanes.width
                height: lanes.height
            }
        }
    }

    // ── Instrument look ──────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.px(14)
        active: root.instrument && !root.familyFaced
        sourceComponent: ColumnLayout {
            spacing: root.px(8)
            InstrumentLabel {
                Layout.fillWidth: true
                text: Translation.tr("Workspaces") + (root.current ? " / " + root.current.idx : "")
                color: root.widgetAccentVisible
                scaleFactor: root.k
            }
            Lanes {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.emptyText.length === 0
                lanes: root.lanesFor(root.isLarge ? 6 : 3)
                numberWidth: 16
                numberSize: Appearance.font.pixelSize.smaller
                maxLane: root.isLarge ? 64 : 30
                icons: root.icons
                names: !root.isSmall
            }
            Empty {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.emptyText.length > 0
            }
            RowLayout {
                Layout.fillWidth: true
                visible: !root.isSmall && root.emptyText.length === 0
                spacing: root.px(12)
                InstrumentField {
                    Layout.fillWidth: true
                    label: Translation.tr("Windows")
                    value: String(root.open)
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
                InstrumentField {
                    Layout.fillWidth: true
                    label: Translation.tr("Here")
                    value: String(root.current?.count ?? 0)
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
            }
        }
    }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                visible: !root.familyFaced
                title: Translation.tr("Style")
                WidgetQuickChoices {
                    current: root.instrument ? "instrument" : "shape"
                    model: [
                        { label: Translation.tr("Shape"), icon: "interests", value: "shape" },
                        { label: Translation.tr("Instrument"), icon: "avg_pace", value: "instrument" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                visible: !root.instrument && !root.familyFaced
                title: Translation.tr("Shape of the number")
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
