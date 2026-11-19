import QtQuick

// The sheet: one piece of black glass pulled from the screen's edge, and the one light that runs along its contour.
// Everything is measured from the edge the sheet hangs from (`flip` mirrors it for a bar at the bottom): the band, one
// slab and two tags are welded into it with coves. `limb` bends the band into the horizon of a dark disc.
ShaderEffect {
    id: root

    property bool flipped: false
    property real band: NihilStyle.barHeight
    property rect slabRect: Qt.rect(0, 0, 0, 0)
    property rect tagARect: Qt.rect(0, 0, 0, 0)
    property rect tagBRect: Qt.rect(0, 0, 0, 0)
    property point light: Qt.point(0, 0)
    property real lightReach: NihilStyle.s(170)
    property real lightPower: 1
    property rect auroraRect: Qt.rect(0, 0, 0, 0)
    property real auroraPower: 0
    property real limb: 0
    property real limbAt: 0
    property real limbRadius: 2600
    property real veiled: 1
    // How dense the glass is once the band has become the limb.
    property real limbGlass: 0.8

    readonly property size area: Qt.size(root.width, root.height)
    readonly property real flip: root.flipped ? 1 : 0
    readonly property real fuse: NihilStyle.fuse
    readonly property real slabR: NihilStyle.rSheet
    readonly property real tagR: NihilStyle.r(24)
    readonly property vector4d slab: Qt.vector4d(root.slabRect.x, root.slabRect.y, root.slabRect.width, root.slabRect.height)
    readonly property vector4d tagA: Qt.vector4d(root.tagARect.x, root.tagARect.y, root.tagARect.width, root.tagARect.height)
    readonly property vector4d tagB: Qt.vector4d(root.tagBRect.x, root.tagBRect.y, root.tagBRect.width, root.tagBRect.height)
    readonly property point hot: root.light
    readonly property real reach: root.lightReach
    readonly property real power: root.lightPower
    readonly property vector4d aurora: Qt.vector4d(root.auroraRect.x, root.auroraRect.y, root.auroraRect.width, root.auroraRect.height)
    readonly property real auroraP: 0
    readonly property real limbP: root.limb
    readonly property real limbY: root.limbAt
    readonly property real limbR: root.limbRadius
    readonly property real rim: NihilStyle.glassRim
    readonly property real flare: NihilStyle.glassFlare * 0.45
    readonly property real grain: NihilStyle.glassGrain
    readonly property real veil: root.veiled
    readonly property color tint: Qt.alpha(NihilStyle.void_, Math.max(0.86, NihilStyle.glassOpacity))
    readonly property color voidInk: NihilStyle.dark ? "#050403" : "#DDD7CC"
    readonly property color rimInk: NihilStyle.rimInk
    readonly property color specA: NihilStyle.specA
    readonly property color specB: NihilStyle.specB

    fragmentShader: Qt.resolvedUrl("sheet.frag.qsb")
}
