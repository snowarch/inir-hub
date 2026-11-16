pragma ComponentBehavior: Bound

// Storage on the desktop: every drive this computer has mounted, what is left on each and a bar of what it holds; a
// drive past nine tenths turns to the warning colour, so the one about to run out is seen before it does. The
// Material face holds the drive icon in the shape the person picks; Instrument (or the person's Instrument or Readout
// design) gives it the measured grammar. Under iRiS the family's widget designs draw it instead (IrisStorage for iRiS,
// PrismStorage for Prism, named by `iris.desktop` in widget.json). This file owns the reading: every face reads
// `drives`, `lead` and the words from it.

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.instrument
import "storage.js" as Logic

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.storage"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie4Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240 })
    needsColText: true
    resizeMinWidth: 150
    resizeMinHeight: 150
    resizeMaxWidth: 760
    resizeMaxHeight: 760

    // ── What it reads ────────────────────────────────────────
    // A minute at a time, only while the card is on a desktop someone can see: space moves slowly, and a copy that
    // fills a drive shows within the minute.
    readonly property bool sampling: root.visible && root.powerActive
    property bool read: false
    // `df` answered nothing (missing, or refused): said in words, never a blank card.
    property bool failed: false
    property var drives: []
    property string _key: ""
    readonly property bool waiting: !root.read
    // The drive a face leads with: one about to run out, else the system's.
    readonly property int lead: {
        let fullest = -1
        for (let i = 0; i < root.drives.length; i++)
            if (root.drives[i].taken >= 0.9 && (fullest < 0 || root.drives[i].taken > root.drives[fullest].taken)) fullest = i
        return fullest >= 0 ? fullest : 0
    }
    readonly property var leadDrive: root.drives.length > 0 ? root.drives[root.lead] : null
    function drivesFor(most: int): var {
        if (root.drives.length <= most) return root.drives
        // The lead always shows, even when it sits past the cut.
        const shown = root.drives.slice(0, most)
        if (root.lead >= most) shown[most - 1] = root.drives[root.lead]
        return shown
    }
    function leadIn(shown: var): int { return root.leadDrive ? shown.indexOf(root.leadDrive) : -1 }
    readonly property real freeTotal: root.drives.reduce((sum, drive) => sum + drive.free, 0)

    Process {
        id: reader
        command: ["sh", "-c", "LC_ALL=C df -B1 --output=source,fstype,size,used,avail,target 2>/dev/null; echo '@@'; lsblk -rno PATH,LABEL 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = String(this.text).split("@@")
                root.failed = String(parts[0] ?? "").trim().length === 0
                const drives = Logic.drivesOf(parts[0] ?? "", Logic.labelsOf(parts[1] ?? ""))
                const key = Logic.keyOf(drives)
                if (key !== root._key) {
                    root._key = key
                    root.drives = drives
                }
                root.read = true
            }
        }
    }
    Timer {
        interval: 60000
        repeat: true
        triggeredOnStart: true
        running: root.sampling
        onTriggered: if (!reader.running) reader.running = true
    }

    // The words every face shares.
    readonly property string systemName: Translation.tr("System")
    readonly property string homeName: Translation.tr("Home")
    readonly property string freeText: Translation.tr("%1 free")
    readonly property string sizeText: Translation.tr("of %1")
    readonly property string freeWord: Translation.tr("free")
    function nameOf(drive: var): string {
        return !drive ? "" : drive.label.length > 0 ? drive.label : drive.system ? root.systemName : root.homeName
    }
    readonly property string leadFree: root.leadDrive ? Logic.sizeOf(root.leadDrive.free).text : ""
    readonly property string leadFreeValue: root.leadDrive ? Logic.sizeOf(root.leadDrive.free).value : ""
    readonly property string leadFreeUnit: root.leadDrive ? Logic.sizeOf(root.leadDrive.free).unit : ""
    readonly property string leadWhere: root.leadDrive ? Translation.tr("Free on %1").arg(root.nameOf(root.leadDrive)) : ""
    readonly property string totalFree: Logic.sizeOf(root.freeTotal).text
    readonly property string countText: root.drives.length === 1 ? Translation.tr("1 drive") : Translation.tr("%1 drives").arg(root.drives.length)
    readonly property string emptyText: root.waiting ? Translation.tr("Reading the drives…")
        : root.failed ? Translation.tr("Couldn't read the drives: df gave no answer")
        : root.drives.length === 0 ? Translation.tr("No drive to show") : ""

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie4Sided")
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

    component Bars: StorageBars {
        d: root.k
        fontMain: Appearance.font.family.main
        fontNumbers: Appearance.font.family.numbers
        nameSize: Appearance.font.pixelSize.small
        figureSize: Appearance.font.pixelSize.small
        ink: root.widgetInk
        inkMuted: ColorUtils.applyAlpha(root.widgetInk, 0.62)
        track: ColorUtils.applyAlpha(root.widgetInk, root.instrument ? 0.08 : 0.12)
        fill: ColorUtils.applyAlpha(root.widgetInk, 0.5)
        full: root.widgetSemanticColor(root.widgetSignalRole)
        lit: root.widgetSemanticColor(root.widgetPrimaryRole)
        systemName: root.systemName
        homeName: root.homeName
        freeText: root.freeText
        sizeText: root.sizeText
        figure: root.isSmall ? "size" : "free"
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
    // The drive icon in the picked shape.
    component Seal: Item {
        id: seal
        property int size: root.px(64)
        implicitWidth: seal.size
        implicitHeight: seal.size
        MaterialShape {
            anchors.fill: parent
            implicitSize: seal.size
            shape: DesktopWidgetShapes.shapeForName(root.shapeName)
            color: root.widgetSemanticContainer(root.leadDrive && root.leadDrive.taken >= 0.9 ? root.widgetSignalRole : root.widgetPrimaryRole)
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: "hard_drive"
            fill: 1
            iconSize: Math.round(seal.size * 0.42)
            color: root.widgetSemanticOnContainer(root.leadDrive && root.leadDrive.taken >= 0.9 ? root.widgetSignalRole : root.widgetPrimaryRole)
        }
    }

    // ── Shape look ───────────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.pad
        active: !root.instrument && !root.familyFaced
        sourceComponent: Item {
            id: face
            readonly property real head: root.isSmall ? root.px(44) : root.isLarge ? root.px(72) : 0
            Seal {
                id: seal
                size: root.isLarge ? root.px(72) : root.isSmall ? root.px(44) : root.px(88)
                y: root.mediumSize ? Math.round((face.height - height) / 2) : 0
            }
            // Small and large: what is left on the lead drive, big, beside the seal.
            Column {
                visible: !root.mediumSize && root.emptyText.length === 0
                x: seal.width + root.px(12)
                y: Math.round((face.head - height) / 2)
                width: face.width - x
                StyledText {
                    width: parent.width
                    text: root.isLarge ? root.totalFree : root.leadFree
                    elide: Text.ElideRight
                    font.family: Appearance.font.family.numbers
                    font.pixelSize: root.px(root.isLarge ? Appearance.font.pixelSize.huge * 1.3 : Appearance.font.pixelSize.larger)
                    font.weight: Font.Bold
                    color: root.widgetInk
                }
                StyledText {
                    width: parent.width
                    text: root.isLarge ? Translation.tr("Free on %1").arg(root.countText) : root.leadWhere
                    elide: Text.ElideRight
                    font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.62)
                }
            }
            Bars {
                id: bars
                visible: root.emptyText.length === 0
                x: root.mediumSize ? seal.width + root.px(16) : 0
                y: root.mediumSize ? 0 : face.head + root.px(10)
                width: face.width - x
                height: face.height - y
                drives: root.isSmall ? (root.leadDrive ? [root.leadDrive] : []) : root.drivesFor(root.isLarge ? 6 : 3)
                leading: root.isSmall ? 0 : root.leadIn(drives)
            }
            Empty {
                visible: root.emptyText.length > 0
                x: bars.x
                y: bars.y
                width: bars.width
                height: bars.height
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
                text: Translation.tr("Storage")
                color: root.widgetAccentVisible
                scaleFactor: root.k
            }
            Bars {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.emptyText.length === 0
                drives: root.isSmall ? (root.leadDrive ? [root.leadDrive] : []) : root.drivesFor(root.isLarge ? 6 : 3)
                leading: root.isSmall ? 0 : root.leadIn(drives)
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
                    label: Translation.tr("Free")
                    value: root.totalFree
                    ink: root.widgetInk
                    muted: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                    scaleFactor: root.k
                }
                InstrumentField {
                    Layout.fillWidth: true
                    label: Translation.tr("Drives")
                    value: String(root.drives.length)
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
                title: Translation.tr("Shape of the icon")
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
