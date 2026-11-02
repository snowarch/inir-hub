import QtQuick
import qs.modules.iris.style
import qs.modules.iris.frame

// Light streak over a surface IrisField does not draw (desktop widgets, IrisSurface): the field's aurora and the streak
// on the edges that face the light under the Island, laid over the plate's own fill. Static: it redraws only with its
// window.
ShaderEffect {
    id: root

    // Where the plate's top-left sits on its output, and the output's size, in pixels.
    property point at: Qt.point(0, 0)
    property size output: Qt.size(1920, 1080)
    property real radius: 0
    // Top-left, top-right, bottom-right, bottom-left: a notched side has square corners.
    property vector4d corners: Qt.vector4d(root.radius, root.radius, root.radius, root.radius)
    // The plate's own colour: what the aurora is held against.
    property color base: IrisStyle.surface
    // How much of the light this plate catches.
    property real strength: 1

    fragmentShader: Qt.resolvedUrl("IrisStreakPlate.frag.qsb")
    readonly property vector4d plate: Qt.vector4d(root.at.x, root.at.y, root.output.width, root.output.height)
    readonly property vector4d body: Qt.vector4d(root.width, root.height, 0, 0)
    readonly property vector4d tone: Qt.vector4d(root.base.r, root.base.g, root.base.b, root.base.a)
    readonly property vector4d streakMix: Qt.vector4d(IrisStyle.streakMix.x, IrisStyle.streakMix.y * root.strength,
        IrisStyle.streakMix.z * root.strength, 0)
    readonly property vector4d streakHue0: IrisStyle.streakHue0
    readonly property vector4d streakHue1: IrisStyle.streakHue1
    readonly property vector4d streakHue2: IrisStyle.streakHue2
    // The same light as the field's (IrisField.streakSource).
    readonly property vector4d streakSource: IrisStyle.streakLightOn(root.output, IrisFrame.islandEdge)
}
