pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.nihil.style

// The wallpaper printed in one bit: whatever the desktop draws (a picture, a transition, a video), screened to black and
// white through an ordered dither. It redraws only when what is under it changes.
Item {
    id: root

    // Background's wallpaper container: hidden from the scene and drawn here.
    property Item source: null
    property bool live: false
    readonly property Item texture: capture
    signal shown()

    ShaderEffectSource {
        id: capture
        anchors.fill: parent
        sourceItem: root.source
        hideSource: true
        live: true
        mipmap: true
        smooth: true
        visible: false
    }
    ShaderEffect {
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("IrisPrintWallpaper.frag.qsb")
        readonly property var source: capture
        readonly property vector4d frame: Qt.vector4d(width, height, Math.max(2, Math.round(3 * IrisStyle.density)), 0)
    }
    Component.onCompleted: root.shown()
}
