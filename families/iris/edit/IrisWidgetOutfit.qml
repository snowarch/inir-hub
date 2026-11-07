pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// What a desktop widget wears while the desktop is arranged in iRiS (the family's part `widgetOutfit`, loaded by
// AbstractBackgroundWidget): under the pointer a hairline concentric with its card and its name hanging under it;
// chosen, a ring and its keys riding out of the top-right corner the way the Island's bubbles ride out of it (its size,
// its controls, the lock, back on the shelf); carried, it casts the shadow of something lifted. AIRISU marks a chosen
// widget with crop marks instead of a ring; under the Nothing layer the ring is ink and the name a Label.
Item {
    id: root

    property Item widget: null
    // In the card the outfit fills its widget; the edit window (IrisEditDesk) draws one over the card instead, at true
    // size where nothing clips it (`overlay`, placed by its host), and the one in the card keeps only the lifted shadow.
    property bool hostedElsewhere: false
    property bool overlay: false
    // The overlay's room on screen: keys and name stay inside it.
    property rect room: Qt.rect(0, 0, 1920, 1080)
    anchors.fill: root.overlay ? undefined : parent
    readonly property bool dressed: root.overlay || !root.hostedElsewhere

    readonly property bool selected: root.widget?.editSelected ?? false
    readonly property bool hovered: (root.widget?.editHovered ?? false) && !root.selected
    readonly property bool carried: root.widget?.isDragging ?? false
    readonly property bool locked: root.widget?.locked ?? false
    readonly property bool ink: IrisStyle.nothingAt("widgets")
    // The card shrinks the desktop: the outfit's type and keys keep their true size on screen.
    readonly property var card: DesktopEditStage.cardFor(root.widget?.outputName ?? "", root.widget?.scaledScreenWidth ?? 0,
        root.widget?.scaledScreenHeight ?? 0)
    readonly property real hair: root.overlay ? 1 : 1 / Math.max(0.2, root.card.s)
    readonly property real d: IrisStyle.density
    readonly property real cardRadius: Math.round((root.widget?.widgetCardRadius ?? 18) * (root.widget?.scaleFactor ?? 1)) * (root.overlay ? root.card.s : 1)
    readonly property real gap: 4 * root.hair
    readonly property color ringInk: root.ink ? IrisStyle.text : IrisStyle.accent

    readonly property string name: root.widget?.displayName ?? ""
    readonly property var sizes: root.widget?.sizeChoices ?? []
    // Every widget with more than one size steps through them here, an iRiS face or a Material drawing alike.
    readonly property bool sized: root.sizes.length > 1
    readonly property string size: root.widget?.sizeClass ?? ""
    readonly property string sizeName: root.sized ? (root.widget?.sizeLabels?.[root.size] ?? "") : ""
    function nextSize(): void {
        const i = root.sizes.indexOf(root.size)
        root.widget.commitSize(root.sizes[(i + 1) % root.sizes.length])
    }

    // ── The ring ──
    property real lit: root.selected ? 1 : root.hovered ? 0.55 : 0
    Behavior on lit { NumberAnimation { duration: 110; easing.type: IrisStyle.feedbackEasing } }
    Rectangle {
        visible: root.dressed && root.lit > 0.01
        anchors.fill: parent
        anchors.margins: -root.gap
        radius: root.cardRadius + root.gap
        color: "transparent"
        border.width: (root.selected ? 1.5 : 1) * root.hair * IrisStyle.devicePx
        border.color: root.selected ? root.ringInk : IrisStyle.hairlineStrong
        opacity: root.lit
        antialiasing: true
    }

    // ── Lifted while carried ──
    IrisBodyShadow {
        z: -1
        visible: root.carried && !root.overlay && (root.widget?.platedNow ?? false)
        x: 0
        y: 10 * root.hair
        width: root.width
        height: root.height
        radius: root.cardRadius
        blur: 30 * root.hair
        spread: -6 * root.hair
        color: ColorUtils.applyAlpha(IrisStyle.shadow, Math.min(1, IrisStyle.shadow.a * 1.4))
    }

    // ── Room round the widget, for the keys and the name ──
    // In the card: the desktop's safe area in desktop px. Over it: the screen above the shelf, in screen px.
    readonly property real topNow: root.overlay ? (root.parent?.y ?? 0) + root.y : (root.widget?.y ?? 0)
    readonly property real leftNow: root.overlay ? (root.parent?.x ?? 0) + root.x : (root.widget?.x ?? 0)
    readonly property real roomTop: root.overlay ? root.room.y : (root.widget?.placement.safeTop ?? 0)
    readonly property real roomBottom: root.overlay ? root.room.y + root.room.height : (root.widget?.placement.safeBottom ?? 1080)
    readonly property real roomLeft: root.overlay ? root.room.x : 0
    readonly property real roomRight: root.overlay ? root.room.x + root.room.width : (root.widget?.scaledScreenWidth ?? 1920)
    readonly property real keysHeight: keys.height * root.hair
    readonly property real keysWidth: keys.width * root.hair
    readonly property bool tagBelow: root.topNow + root.height + 2 * root.gap + tag.height * root.hair <= root.roomBottom
    // Slid back inside the room at either side.
    function inside(x: real, w: real): real {
        return Math.max(root.roomLeft + 2 * root.gap, Math.min(root.roomRight - 2 * root.gap - w, x))
    }
    // Where the keys stand: right-aligned over the widget on a side chosen when it is chosen or set down, kept while it
    // has room (above, else below, else inside its top), and held still while the pointer is on them, so a size picked
    // there never slides the capsule from under it (his 11-02: they jumped about and overlapped).
    property string keysAt: "above"
    // Chosen on the next turn by a timer the outfit owns: Qt.callLater outlived the outfit when its Loader dropped it
    // and ran in a dead context ("wantedAt is not a function").
    readonly property string wantedAt: root.topNow - root.keysHeight - 2 * root.gap >= root.roomTop ? "above"
        : root.topNow + root.height + 2 * root.gap + root.keysHeight <= root.roomBottom ? "below" : "inside"
    Timer { id: choose; interval: 0; onTriggered: root.keysAt = root.wantedAt }
    readonly property bool sideLost: root.keysAt === "above" ? root.topNow - root.keysHeight - 2 * root.gap < root.roomTop
        : root.keysAt === "below" ? root.topNow + root.height + 2 * root.gap + root.keysHeight > root.roomBottom
        : root.wantedAt !== "inside"
    onSideLostChanged: if (root.sideLost) choose.restart()
    onSelectedChanged: if (root.selected) choose.restart()
    onWidgetChanged: choose.restart()
    onCarriedChanged: if (!root.carried) choose.restart()
    readonly property real liveRight: root.inside(root.leftNow + root.width - root.keysWidth, root.keysWidth) + root.keysWidth
    readonly property real liveTop: root.keysAt === "above" ? root.topNow - 2 * root.gap - root.keysHeight
        : root.keysAt === "below" ? root.topNow + root.height + 2 * root.gap : root.topNow + 2 * root.gap
    readonly property bool holding: keysHover.hovered && root.selected
    property real heldRight: 0
    property real heldTop: 0
    onHoldingChanged: if (root.holding) { root.heldRight = root.liveRight; root.heldTop = root.liveTop }
    // Held, unless the widget grows into them.
    readonly property bool held: root.holding && root.keysAt !== "inside"
        && !(root.heldRight - root.keysWidth < root.leftNow + root.width + root.gap && root.heldRight > root.leftNow - root.gap
            && root.heldTop < root.topNow + root.height + root.gap && root.heldTop + root.keysHeight > root.topNow - root.gap)
    readonly property real keysRight: root.held ? root.heldRight : root.liveRight
    readonly property real keysTop: root.held ? root.heldTop : root.liveTop
    // The sheet holds every key the capsule has: while it is open the capsule steps back, never two sets on screen.
    readonly property bool sheetOpen: root.widget?.quickControlsOpen ?? false

    // ── Its name ──
    Item {
        id: tag
        readonly property real pad: 10 * root.d
        readonly property bool shown: root.dressed && root.hovered && !root.carried
        width: tagRow.implicitWidth + 2 * tag.pad
        height: Math.round(24 * root.d)
        scale: root.hair * (0.92 + 0.08 * tag.show)
        transformOrigin: root.tagBelow ? Item.Top : Item.Bottom
        x: root.inside(root.leftNow + (root.width - tag.width * root.hair) / 2, tag.width * root.hair) - root.leftNow
            + (tag.width * root.hair - tag.width) / 2
        y: root.tagBelow ? root.height + 2 * root.gap : -2 * root.gap - tag.height
        opacity: tag.show
        visible: tag.show > 0.01
        property real show: tag.shown ? 1 : 0
        Behavior on show { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: PrismTheme.canvas
            border.width: IrisStyle.devicePx
            border.color: PrismTheme.line
        }
        // AIRISU: a seal box, its cut parallel to the widget's.
        Row {
            id: tagRow
            anchors.centerIn: parent
            spacing: Math.round(6 * root.d)
            MaterialSymbol {
                visible: root.locked
                anchors.verticalCenter: parent.verticalCenter
                text: "lock"
                iconSize: Math.round(12 * root.d)
                color: IrisStyle.textSecondary
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.name
                color: IrisStyle.text
                font.family: root.ink ? IrisStyle.fontLabel : IrisStyle.fontMain
                font.pixelSize: root.ink ? Math.round(10 * root.d) : IrisStyle.typeFootnote
                font.weight: root.ink ? IrisStyle.weight(Font.Medium) : IrisStyle.weight(Font.DemiBold)
                font.capitalization: root.ink ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: root.ink ? 0.8 * root.d : 0
            }
            // Chosen, the size key says it.
            StyledText {
                visible: root.sizeName.length > 0 && !root.selected
                anchors.verticalCenter: parent.verticalCenter
                text: root.sizeName
                color: IrisStyle.textSecondary
                font.family: root.ink ? IrisStyle.fontLabel : IrisStyle.fontMain
                font.pixelSize: root.ink ? Math.round(10 * root.d) : IrisStyle.typeFootnote
                font.weight: IrisStyle.weight(Font.Medium)
                font.capitalization: root.ink ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: root.ink ? 0.8 * root.d : 0
            }
        }
    }

    // ── Its keys, riding out of the top-right corner ──
    IrisSpring {
        id: emerge
        surface: "panels"
        to: root.dressed && root.selected && !root.carried && !root.sheetOpen ? 1 : 0
        intent: "auto"
        minimum: 0
    }
    readonly property Item keysItem: keys
    // One opaque capsule in Prism Settings' language (his 11-07): its name, the sizes as a segmented pill drawn as the
    // room each takes (one tap to the size wanted, never a cycle), then round keys; the one that opens its controls leads
    // in solid white. Loose glass keys vanished on a dark wallpaper and went grey on a light one (his 10-30 capture).
    Item {
        id: keys
        readonly property real out: Math.max(0, Math.min(1, emerge.value))
        readonly property real pad: PrismTheme.dp(4)
        implicitWidth: keyRow.implicitWidth + 2 * keys.pad
        implicitHeight: keyRow.implicitHeight + 2 * keys.pad
        width: implicitWidth
        height: implicitHeight
        scale: root.hair * (0.6 + 0.4 * keys.out)
        transformOrigin: root.keysAt === "below" ? Item.TopRight : Item.BottomRight
        // The capsule is scaled about its right edge and the edge facing the widget: place those edges.
        x: root.keysRight - root.leftNow - keys.width
        y: root.keysAt === "below" ? root.keysTop - root.topNow : root.keysTop + root.keysHeight - root.topNow - keys.height
        opacity: IrisStyle.contentAt(keys.out)
        visible: keys.out > 0.01
        enabled: root.selected && !root.sheetOpen

        HoverHandler { id: keysHover }
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: PrismTheme.canvas
            border.width: IrisStyle.devicePx
            border.color: PrismTheme.line
        }

        Row {
            id: keyRow
            x: keys.pad
            y: keys.pad
            spacing: PrismTheme.dp(4)

            // Chosen, its name leads the keys: one row, never a tag stacked on them.
            Item {
                implicitHeight: PrismTheme.dp(30)
                implicitWidth: nameRow.implicitWidth + PrismTheme.dp(20)
                Row {
                    id: nameRow
                    anchors.centerIn: parent
                    spacing: PrismTheme.dp(6)
                    PrismGlyph {
                        visible: root.locked
                        anchors.verticalCenter: parent.verticalCenter
                        text: "lock"
                        filled: true
                        iconSize: PrismTheme.dp(14)
                        color: PrismTheme.ink2
                    }
                    PrismText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.name
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                    }
                }
            }
            // The sizes, each drawn as its room on the grid; the one it has is the solid segment.
            Rectangle {
                visible: root.sized && !root.locked
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: sizeRow.implicitWidth + PrismTheme.dp(6)
                implicitHeight: PrismTheme.dp(30)
                radius: height / 2
                color: PrismTheme.fill
                Row {
                    id: sizeRow
                    anchors.centerIn: parent
                    Repeater {
                        model: root.sizes
                        delegate: Item {
                            id: sizeKey
                            required property string modelData
                            readonly property bool chosen: root.size === sizeKey.modelData
                            readonly property real cell: PrismTheme.dp(5)
                            width: PrismTheme.dp(32)
                            height: PrismTheme.dp(24)
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: sizeKey.chosen ? PrismTheme.solid : sizeArea.containsMouse ? PrismTheme.fillHover : "transparent"
                                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                            }
                            Grid {
                                anchors.centerIn: parent
                                columns: 2
                                spacing: PrismTheme.dp(2)
                                Repeater {
                                    model: sizeKey.modelData === "large" ? 4 : 2
                                    delegate: Rectangle {
                                        required property int index
                                        readonly property bool taken: sizeKey.modelData !== "small" || index === 0
                                        width: sizeKey.cell
                                        height: sizeKey.cell
                                        radius: PrismTheme.dp(1)
                                        color: sizeKey.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                                        opacity: taken ? 1 : 0.25
                                    }
                                }
                            }
                            MouseArea {
                                id: sizeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (!sizeKey.chosen) root.widget.commitSize(sizeKey.modelData)
                            }
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: Translation.tr("Size: %1").arg(root.widget?.sizeLabels?.[sizeKey.modelData] ?? sizeKey.modelData)
                            Accessible.checked: sizeKey.chosen
                        }
                    }
                }
            }
            // The plate, one tap from the widget: the same switch as its Look page and the shelf's "every background".
            PrismRound {
                visible: !root.locked && (root.widget?.plateOffered ?? false)
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(30)
                glyphSize: PrismTheme.dp(16)
                glyph: root.widget?.showBackground ? "layers" : "layers_clear"
                Accessible.role: Accessible.Button
                Accessible.name: root.widget?.showBackground ? Translation.tr("Hide background") : Translation.tr("Show background")
                onClicked: root.widget.setPlate(!root.widget.showBackground)
            }
            PrismRound {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(30)
                glyphSize: PrismTheme.dp(16)
                glyph: root.locked ? "lock" : "lock_open"
                lit: root.locked
                Accessible.role: Accessible.Button
                Accessible.name: root.locked ? Translation.tr("Unlock") : Translation.tr("Lock")
                onClicked: root.widget._setOutputValue("locked", !root.locked)
            }
            PrismRound {
                visible: !root.locked
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(30)
                glyphSize: PrismTheme.dp(16)
                glyph: "remove"
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Put back")
                onClicked: {
                    GlobalStates.clearDesktopWidgetSelection()
                    root.widget.takeAway()
                }
            }
            PrismRound {
                visible: !root.locked
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: PrismTheme.dp(30)
                glyphSize: PrismTheme.dp(16)
                glyph: "tune"
                solid: true
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Edit")
                onClicked: root.widget.openQuickControls("widget")
            }
        }
    }
}
