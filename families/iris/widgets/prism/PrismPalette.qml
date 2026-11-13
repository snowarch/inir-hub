pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// The palette in Prism: where the colours come from on the flap, the colours themselves across the pane (a tap
// copies one), the chosen one's code on the foot, and on the large face every code under its colour.
PrismFolder {
    id: root

    readonly property var colours: Array.from(root.widget.colours ?? [])
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

    tabGlyph: "palette"
    tabText: Translation.tr("Palette")
    flapText: root.widget.from === "music" ? Translation.tr("Cover") : root.widget.from === "random" ? Translation.tr("Random") : Translation.tr("Wallpaper")

    // ── the pane: the colours ──
    Row {
        id: strip
        readonly property real gap: root.pick(6, 8, 10)
        readonly property real chip: (root.innerWidth - (root.colours.length - 1) * strip.gap) / Math.max(1, root.colours.length)
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        height: root.pick(40, 52, 86)
        spacing: strip.gap
        Repeater {
            model: root.colours
            Rectangle {
                id: chip
                required property string modelData
                required property int index
                width: strip.chip
                height: strip.height
                radius: Math.min(width / 2, root.dp(12))
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
                HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: chipTap; onTapped: root.copyOne(chip.index) }
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
        y: Math.round(root.large ? root.footTop + root.dp(24) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.copiedAll ? Translation.tr("Copied") : root.copied >= 0 ? Translation.tr("Copied") : root.code.toUpperCase()
        size: root.type(16, 20, 28)
        weight: Font.Bold
        font.family: root.fontNumbers
        font.features: ({ "tnum": 1 })
    }
    FaceAction {
        visible: !root.small && root.colours.length > 1
        face: root
        x: root.width - root.inset - width
        y: Math.round(codeText.y + (codeText.height - height) / 2)
        height: root.dp(32)
        width: wordedWidth
        worded: true
        glyph: "content_copy"
        name: Translation.tr("Copy all")
        onActivated: root.copyAll()
    }
    Row {
        visible: root.large && root.colours.length > 0
        x: root.inset
        y: root.height - root.inset - height
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
}
