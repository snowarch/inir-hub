import QtQuick
import qs.modules.iris.prism.core

// The panel's air: the page's three colours as soft blooms along the window's top, over the canvas (the posters'
// colour field, his 11-15). A copy over a scrolled column's edge (`fadeDown`/`fadeUp`) draws the same air at the same
// place and fades along its height: the rows melt into the air. Over iRiS's glass the canvas is a veil over the
// compositor's blur or over the blurred wallpaper (`backdrop`). Static: it draws again only on a size, page or colour
// change (or a live wallpaper's frame under Glass).
ShaderEffect {
    id: root
    property string tint: "grey"
    // What the air belongs to (the page): each gets its own blooms.
    property string key: ""
    readonly property real seed: Array.from(root.key).reduce((n, letter) => (n * 31 + letter.charCodeAt(0)) % 9973, 3) * 0.017
    // The window this air fills, and where this copy's top-left sits in it.
    property size frameSize: Qt.size(width, height)
    property point origin: Qt.point(0, 0)
    property real radius: 0
    // 0: the whole air. 1: this copy fades out downward (the column's head). -1: fades in downward (its foot).
    property int fadeDir: 0

    // Under Glass: the blurred wallpaper (IrisGlassSource.texture) and where the window's top-left lies on the screen.
    property Item backdrop: null
    property point screenAt: Qt.point(0, 0)
    property size screenSize: Qt.size(1, 1)
    // 0 the solid canvas, 1 a veil over the compositor's blur, 2 the wallpaper's glass (solid until it is ready).
    readonly property int material: PrismTheme.glassBlur ? 1 : PrismTheme.glassWallpaper && root.backdrop ? 2 : 0
    readonly property vector4d glass: Qt.vector4d(root.material, PrismTheme.veil, 0, 0)
    readonly property vector4d screen: Qt.vector4d(root.screenAt.x, root.screenAt.y, root.screenSize.width, root.screenSize.height)

    readonly property var colours: PrismTheme.palette(root.tint)
    readonly property color canvas: PrismTheme.canvas

    readonly property vector2d size: Qt.vector2d(width, height)
    readonly property vector4d frame: Qt.vector4d(root.origin.x, root.origin.y, root.frameSize.width, root.frameSize.height)
    readonly property vector4d c1: Qt.vector4d(root.colours[0].r, root.colours[0].g, root.colours[0].b, 1)
    readonly property vector4d c2: Qt.vector4d(root.colours[1].r, root.colours[1].g, root.colours[1].b, 1)
    readonly property vector4d c3: Qt.vector4d(root.colours[2].r, root.colours[2].g, root.colours[2].b, 1)
    readonly property vector4d ground: Qt.vector4d(root.canvas.r, root.canvas.g, root.canvas.b, PrismTheme.light ? 0 : 1)
    readonly property vector4d band: Qt.vector4d(0, 0, 0, root.fadeDir)
    // Enough to colour the air, never enough to lift the ink off it: the page's name and credits stand on it.
    readonly property real strength: PrismTheme.light ? 0.24 : 0.32

    fragmentShader: Qt.resolvedUrl("prism_aura.frag.qsb")
    blending: root.fadeDir !== 0 || root.radius > 0 || root.material === 1
}
