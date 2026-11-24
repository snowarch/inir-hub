pragma Singleton
pragma ComponentBehavior: Bound

// The look of Presets in each family: one set of names, each read from that family's own tokens, so the controls and
// the views never ask which family is worn.

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.waffle.looks

Singleton {
    readonly property bool iris: Plugins.active === "iris"
    readonly property bool waffle: Plugins.active === "waffle"

    readonly property color page: iris ? IrisStyle.surfaceOpaque : waffle ? Looks.colors.bg0Opaque : Appearance.colors.colLayer2Base
    readonly property color side: iris ? IrisStyle.surfaceHighOpaque : waffle ? Looks.colors.bg1Base : Appearance.colors.colLayer1Base
    readonly property color sheet: iris ? IrisStyle.surfaceHighestOpaque : waffle ? Looks.colors.bg2Base : Appearance.colors.colLayer1Base
    readonly property color plate: iris ? IrisStyle.fill : waffle ? Looks.settings.tile : Appearance.colors.colLayer3Base
    readonly property color hover: iris ? IrisStyle.fillHover : waffle ? Looks.settings.tileHover : Appearance.colors.colLayer3Hover
    readonly property color edge: iris ? IrisStyle.hairline : waffle ? Looks.settings.stroke : Appearance.colors.colLayer0Border
    readonly property color text: iris ? IrisStyle.text : waffle ? Looks.colors.fg : Appearance.colors.colOnSurface
    readonly property color muted: iris ? IrisStyle.subtext : waffle ? Looks.colors.subfg : Appearance.colors.colSubtext
    readonly property color accent: iris ? IrisStyle.accentFill : waffle ? Looks.colors.accent : Appearance.colors.colPrimary
    readonly property color onAccent: iris ? IrisStyle.inkOnAccent : waffle ? Looks.colors.accentFg : Appearance.colors.colOnPrimary
    readonly property color rowOn: iris ? IrisStyle.fillActive : waffle ? Looks.settings.tilePressed : Appearance.colors.colSecondaryContainer
    readonly property color rowOnInk: iris ? IrisStyle.text : waffle ? Looks.colors.fg : Appearance.colors.colOnSecondaryContainer
    readonly property color danger: iris ? IrisStyle.danger : waffle ? Looks.colors.danger : Appearance.colors.colError
    readonly property color scrim: iris ? IrisStyle.veilStrong : waffle ? Looks.colors.shadow : Appearance.colors.colScrim

    readonly property real d: iris ? IrisStyle.density : 1
    readonly property int radius: Math.round(iris ? IrisStyle.radiusTile : waffle ? Looks.radius.large : Appearance.rounding.small)
    readonly property int cardRadius: Math.round(iris ? IrisStyle.radiusCard : waffle ? Looks.radius.xLarge : Appearance.rounding.normal)
    readonly property int smallRadius: Math.round(iris ? IrisStyle.radiusRow : waffle ? Looks.radius.medium : Appearance.rounding.verysmall)
    readonly property real small: iris ? IrisStyle.spaceSmall : waffle ? Looks.settings.cardSpacing : Appearance.sizes.spacingSmall
    readonly property real gap: iris ? IrisStyle.cardPad / 2 : waffle ? Looks.settings.cardPadding / 2 : Appearance.sizes.spacingMedium
    readonly property real pad: iris ? IrisStyle.cardPad : waffle ? Looks.settings.cardPadding : Appearance.sizes.spacingLarge

    readonly property string mainFont: iris ? IrisStyle.fontMain : waffle ? Looks.font.family.ui : Appearance.font.family.main
    readonly property string titleFont: iris ? IrisStyle.fontTitle : waffle ? Looks.font.family.ui : Appearance.font.family.title
    readonly property string monoFont: iris ? IrisStyle.fontNumbers : waffle ? Looks.font.family.monospace : Appearance.font.family.monospace
    readonly property int body: iris ? IrisStyle.typeBody : waffle ? Looks.font.pixelSize.large : Appearance.font.pixelSize.small
    readonly property int meta: iris ? IrisStyle.typeMeta : waffle ? Looks.font.pixelSize.normal : Appearance.font.pixelSize.smaller
    readonly property int title: iris ? IrisStyle.typeTitle : waffle ? Looks.font.pixelSize.xlarger : Appearance.font.pixelSize.larger
    readonly property int labelSize: Math.max(9, meta - 1)
    readonly property int iconSize: Math.round(body * 1.25)
    readonly property int control: Math.round(body * 2.3)
    readonly property int rowHeight: Math.round(body * 3.2)
    readonly property var variableAxes: iris ? ({}) : waffle ? Looks.font.variableAxes.ui : Appearance.font.variableAxes.main

    // Waffle's icon set lacks most editing glyphs: a Material name maps to a Fluent one when there is one.
    readonly property var fluent: ({
        add: "add", search: "search", folder: "folder", folder_open: "folder", "delete": "delete", settings: "settings",
        push_pin: "pin", more_horiz: "more-horizontal", check: "checkmark", close: "dismiss", link: "link",
        chevron_left: "chevron-left", chevron_right: "chevron-right", expand_more: "chevron-down", arrow_back: "arrow-left",
        format_list_bulleted: "list", undo: "arrow-counterclockwise", redo: "arrow-clockwise", restore_from_trash: "arrow-counterclockwise",
        view_sidebar: "panel-left-expand", open_in_new: "open"
    })
    function fluentName(name: string): string { return InkSkin.fluent[name] ?? "" }
}
