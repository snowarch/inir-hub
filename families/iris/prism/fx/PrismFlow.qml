import QtQuick
import qs.modules.iris.prism.core

// Prism's art material: a grainy ribbon of the page's three colours (`.claude/ref/language`: the Design Archive
// posters, the folders' art). Dark it glows over the night, light it is ink on paper. Static: it draws again only when
// a size, a colour or the seed changes. Each corner takes its own radius, so a folder's back sheet can round only
// where it shows.
ShaderEffect {
    id: root
    property string tint: "blue"
    // Which ribbon: a card's number gives each folder of a page its own.
    property real seed: 0
    property point centre: Qt.point(0.62, 0.5)
    property real thickness: 0.42
    property real radius: 0
    property real topLeftRadius: root.radius
    property real topRightRadius: root.radius
    property real bottomRightRadius: root.radius
    property real bottomLeftRadius: root.radius
    property bool dark: !PrismTheme.light
    // From this fraction of the height down the ribbon fades out, so words printed there read on the plain ground.
    property real fade: 1

    readonly property var colours: PrismTheme.palette(root.tint)
    readonly property color ground: root.dark ? PrismTheme.night : PrismTheme.paperLight

    readonly property vector2d size: Qt.vector2d(width, height)
    readonly property vector4d c1: Qt.vector4d(root.colours[0].r, root.colours[0].g, root.colours[0].b, 1)
    readonly property vector4d c2: Qt.vector4d(root.colours[1].r, root.colours[1].g, root.colours[1].b, 1)
    readonly property vector4d c3: Qt.vector4d(root.colours[2].r, root.colours[2].g, root.colours[2].b, 1)
    readonly property vector4d paper: Qt.vector4d(root.ground.r, root.ground.g, root.ground.b, root.dark ? 1 : 0)
    readonly property vector4d shape: Qt.vector4d(root.seed, root.centre.x, root.centre.y, root.thickness)
    readonly property vector4d radii: Qt.vector4d(root.topLeftRadius, root.topRightRadius, root.bottomRightRadius, root.bottomLeftRadius)
    readonly property real grain: root.dark ? 0.05 : 0.07

    fragmentShader: Qt.resolvedUrl("prism_flow.frag.qsb")
    blending: true
}
