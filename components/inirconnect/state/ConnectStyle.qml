pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.style

Singleton {
    id: root

    readonly property bool isIris: Plugins.active === "iris"
    readonly property var _c: Appearance.colors
    readonly property real _scale: FamilyStyle.typeScale

    readonly property real density: root.isIris ? IrisStyle.density : 1.0
    readonly property bool motionEnabled: FamilyStyle.motionEnabled

    // Surfaces & plates
    readonly property color surface: root.isIris ? IrisStyle.surface : root._c.colLayer2Base
    readonly property bool dark: root.isIris ? !IrisStyle.light : Qt.color(root.surface).hslLightness < 0.5
    readonly property color fill: root.isIris ? IrisStyle.fill : root._c.colLayer1Base
    readonly property color formPlate: root.isIris ? IrisStyle.formPlate : root._c.colLayer3Base
    readonly property color fillHover: root.isIris ? IrisStyle.fillHover : root._c.colLayer3Hover
    readonly property color fillActive: root.isIris ? IrisStyle.fillActive : root._c.colLayer3Active
    readonly property color fillQuiet: FamilyStyle.fillQuiet
    readonly property color plateEdge: root.isIris ? IrisStyle.plateEdge : root._c.colLayer0Border
    readonly property color hairline: root.isIris ? IrisStyle.hairline : root._c.colOutlineVariant
    readonly property color border: root.isIris ? IrisStyle.border : root._c.colOutlineVariant

    // Ink / text
    readonly property color text: root.isIris ? IrisStyle.text : root._c.colOnLayer2
    readonly property color subtext: root.isIris ? IrisStyle.subtext : root._c.colSubtext
    readonly property color muted: root.isIris ? IrisStyle.muted : FamilyStyle.textTertiary

    // Accents & semantic
    readonly property color accent: root.isIris ? IrisStyle.accent : root._c.colPrimary
    readonly property color accentFill: root.isIris ? IrisStyle.accentFill : root._c.colPrimary
    readonly property color accentHover: root.isIris ? IrisStyle.accentHover : root._c.colPrimaryHover
    readonly property color secondaryAccent: root.isIris ? IrisStyle.secondaryAccent : root._c.colSecondary
    readonly property color inkOnAccentFill: root.isIris ? IrisStyle.inkOnAccentFill : root._c.colOnPrimary
    readonly property color success: root.isIris ? IrisStyle.success : root._c.colSuccess
    readonly property color danger: root.isIris ? IrisStyle.danger : root._c.colError
    readonly property color gray: root.isIris ? IrisStyle.identity.gray : root._c.colOutline
    readonly property color green: root.isIris ? IrisStyle.identity.green : root._c.colSuccess
    readonly property color red: root.isIris ? IrisStyle.identity.red : root._c.colError

    // Typography
    readonly property string fontMain: root.isIris ? IrisStyle.fontRead : Appearance.font.family.main
    readonly property string fontTitle: root.isIris ? IrisStyle.fontTitle : Appearance.font.family.title
    readonly property string fontNumbers: root.isIris ? IrisStyle.fontNumbers : Appearance.font.family.numbers
    readonly property string fontMono: root.isIris ? IrisStyle.fontMono : Appearance.font.family.monospace
    readonly property string fontLabel: root.isIris ? IrisStyle.fontLabel : Appearance.font.family.main
    readonly property int typeHeadline: root.isIris ? IrisStyle.typeHeadline : Math.round(15 * root._scale)
    readonly property int typeBody: root.isIris ? IrisStyle.typeBody : Math.round(14 * root._scale)
    readonly property int typeLabel: root.isIris ? IrisStyle.typeLabel : Math.round(14 * root._scale)
    readonly property int typeMeta: root.isIris ? IrisStyle.typeMeta : Math.round(12 * root._scale)
    readonly property int typeCaption: root.isIris ? IrisStyle.typeCaption : Math.round(11 * root._scale)

    // Radii
    readonly property int radiusCard: root.isIris ? IrisStyle.radiusCard : Appearance.rounding.normal
    readonly property int radiusTile: root.isIris ? IrisStyle.radiusTile : Appearance.rounding.small
    readonly property int radiusRow: root.isIris ? IrisStyle.radiusRow : Appearance.rounding.verysmall
    readonly property int radiusButton: root.isIris ? IrisStyle.radiusSmall : Appearance.rounding.small

    // Motion
    readonly property int revealDuration: FamilyStyle.revealDuration
    readonly property int feedbackDuration: FamilyStyle.feedbackDuration
    readonly property int morphDuration: FamilyStyle.morphDuration
    readonly property var morphCurve: FamilyStyle.morphCurve
    readonly property int feedbackEasing: FamilyStyle.feedbackEasing

    function weight(base: int): int {
        return FamilyStyle.weight(base)
    }

    function tintFill(tint: color): color {
        return FamilyStyle.tintFill(tint)
    }

    function tintFillHover(tint: color): color {
        return FamilyStyle.tintFillHover(tint)
    }

    function pressScale(base: real): real {
        return FamilyStyle.pressScale(base)
    }
}
