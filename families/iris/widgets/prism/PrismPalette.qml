pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// The palette in Prism: where the colours come from at the head's end, the colours themselves across the pane (a tap
// copies one, a right click keeps it through the next read), the chosen one's code on the foot with what the iRiS face
// does to them (shuffle, wear one as the accent, copy them all), and on the large face every code under its colour.
PrismFolder {
    id: root

    readonly property var colours: Array.from(root.widget.colours ?? [])
    readonly property var kept: root.widget.kept ?? []
    property int chosen: 2
    property int copied: -1
    property bool copiedAll: false
    readonly property string code: root.colours[Math.min(root.chosen, Math.max(0, root.colours.length - 1))] ?? ""
    function copyOne(index: int): void {
        root.chosen = index
        root.widget.copy(root.colours[index])
        root.copiedAll = false
        root.copied = index
        copiedReset.restart()
    }
    function copyAll(): void {
        root.widget.copy(root.colours.join(" "))
        root.copied = -1
        root.copiedAll = true
        copiedReset.restart()
    }
    Timer {
        id: copiedReset
        interval: 1600
        onTriggered: { root.copied = -1; root.copiedAll = false }
    }

    // Small has no foot for the keys: copying them all is the head's key.
    capInteractive: root.small && root.colours.length > 1
    capGlyph: root.copiedAll ? "check" : "content_copy"
    capName: Translation.tr("Copy all")
    onCapClicked: root.copyAll()
    tabGlyph: "palette"
    tabText: Translation.tr("Palette")
    // Small keeps its name whole: where the colours come from shows from medium up.
    flapText: root.small ? "" : root.widget.from === "music" ? Translation.tr("Cover") : root.widget.from === "random" ? Translation.tr("Random") : Translation.tr("Wallpaper")

    // ── the pane: the colours, in a well of the glass's fill so a colour as dark as the glass still shows its edge ──
    Rectangle {
        id: well
        visible: root.colours.length > 0
        readonly property real pad: root.pick(4, 5, 6)
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        width: root.innerWidth
        height: strip.height + 2 * well.pad
        radius: Math.min(strip.height / 2, root.dp(12)) + well.pad
        color: root.fill
    }
    Row {
        id: strip
        readonly property real gap: root.pick(4, 5, 6)
        readonly property real chip: (well.width - 2 * well.pad - (root.colours.length - 1) * strip.gap) / Math.max(1, root.colours.length)
        x: well.x + well.pad
        y: well.y + well.pad
        height: root.pick(34, 44, 78)
        spacing: strip.gap
        Repeater {
            model: root.colours
            Rectangle {
                id: chip
                required property string modelData
                required property int index
                width: strip.chip
                height: strip.height
                radius: well.radius - well.pad
                color: chip.modelData
                scale: chipTap.pressed ? 0.94 : chipHover.hovered ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.copied === chip.index || root.copiedAll
                    text: "check"
                    iconSize: Math.round(Math.min(chip.width, chip.height) * 0.5)
                    color: root.onFill(chip.color)
                }
                Rectangle {
                    visible: root.chosen === chip.index && root.copied !== chip.index && !root.copiedAll
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.dp(6)
                    width: root.dp(6)
                    height: width
                    radius: width / 2
                    color: root.onFill(chip.color)
                }
                // Kept through the next read: a pin of the chip's own ink in its corner.
                MaterialSymbol {
                    visible: String(root.kept[chip.index] ?? "").length > 0
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: root.dp(4)
                    text: "keep"
                    fill: 1
                    iconSize: root.px(root.type(10, 12, 14))
                    color: root.onFill(chip.color)
                }
                HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: chipTap; gesturePolicy: TapHandler.WithinBounds; onTapped: root.copyOne(chip.index) }
                TapHandler { acceptedButtons: Qt.RightButton; onTapped: root.widget.keep(chip.index) }
                Accessible.role: Accessible.Button
                Accessible.name: chip.modelData
            }
        }
    }
    FaceText {
        visible: root.colours.length === 0
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: Translation.tr("No colours yet")
        color: root.inkSecondary
        size: root.type(13, 15, 18)
        weight: Font.DemiBold
    }

    // ── the foot: the chosen code, and copying them all ──
    FaceText {
        id: codeText
        visible: root.colours.length > 0
        face: root
        x: root.inset
        y: Math.round(root.large ? root.footTop + root.dp(16) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.copiedAll ? Translation.tr("Copied") : root.copied >= 0 ? Translation.tr("Copied") : root.code.toUpperCase()
        size: root.type(16, 20, 28)
        weight: Font.Bold
        font.family: root.fontNumbers
        font.features: ({ "tnum": 1 })
    }
    // Shuffle, the chosen colour as the shell's accent (then its undo for a while), and copying them all.
    Row {
        id: keys
        visible: !root.small && root.colours.length > 1
        x: root.width - root.inset - width
        y: Math.round(codeText.y + (codeText.height - height) / 2)
        spacing: root.dp(6)
        FaceAction {
            face: root
            width: root.dp(32)
            height: root.dp(32)
            glyph: "shuffle"
            name: Translation.tr("Shuffle")
            onActivated: root.widget.shuffle()
        }
        FaceAction {
            visible: root.canUseAccent
            face: root
            width: root.dp(32)
            height: root.dp(32)
            glyph: root.accentBefore ? "undo" : "format_paint"
            name: root.accentBefore ? Translation.tr("Undo") : Translation.tr("Use as accent")
            onActivated: root.accentBefore ? root.undoAccent() : root.useAsAccent(root.colours[root.chosen])
        }
        FaceAction {
            face: root
            height: root.dp(32)
            width: wordedWidth
            worded: true
            glyph: root.copiedAll ? "check" : "content_copy"
            name: root.copiedAll ? Translation.tr("Copied") : Translation.tr("Copy all")
            onActivated: root.copyAll()
        }
    }
    Row {
        visible: root.large && root.colours.length > 0
        x: strip.x
        y: root.footBottom - root.dp(10) - height
        spacing: strip.gap
        Repeater {
            model: root.large ? root.colours : []
            FaceText {
                required property string modelData
                required property int index
                face: root
                width: strip.chip
                horizontalAlignment: Text.AlignHCenter
                text: modelData.replace("#", "").toUpperCase()
                color: index === root.chosen ? root.ink : root.inkTertiary
                size: 11
                weight: Font.DemiBold
                font.family: root.fontNumbers
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: root.px(8)
            }
        }
    }

    // The accent it replaced, held only while the undo key shows (the same keys as the iRiS face).
    property var accentBefore: null
    readonly property bool canUseAccent: (Config.options?.panelFamily ?? "ii") === "iris"
        && !(String(ThemeService.currentTheme ?? "auto") !== "auto"
            && Boolean(Config.options?.iris?.appearance?.followTheme ?? true))
    function useAsAccent(value: string): void {
        const c = Qt.color(value)
        const appearance = Config.options?.iris?.appearance
        root.accentBefore = { accent: String(appearance?.accent ?? "blue"), hue: Number(appearance?.theme?.accentHue ?? 212) }
        Config.setNestedValues({ "iris.appearance.accent": "custom",
            "iris.appearance.theme.accentHue": Math.round((c.hslHue < 0 ? 0 : c.hslHue) * 360) })
        accentUndo.restart()
    }
    function undoAccent(): void {
        if (!root.accentBefore) return
        Config.setNestedValues({ "iris.appearance.accent": root.accentBefore.accent,
            "iris.appearance.theme.accentHue": root.accentBefore.hue })
        root.accentBefore = null
        accentUndo.stop()
    }
    Timer { id: accentUndo; interval: 8000; onTriggered: root.accentBefore = null }
}
