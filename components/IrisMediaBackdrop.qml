pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common.functions
import qs.modules.iris.style

// Blurred album-art vibrancy with a legibility scrim. A small source texture
// keeps the blur cheap; `radius` masks it when the host does not clip.
Item {
    id: root
    property string source: ""
    property real radius: 0
    property real strength: 0.62

    // Blur fades towards transparent at its edges; drawing it past the host's
    // bounds keeps those dark rims outside the (clipped) surface.
    readonly property real overscan: 48

    Image {
        id: cover
        anchors.fill: parent
        anchors.margins: -root.overscan
        source: root.source
        sourceSize: Qt.size(160, 160)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }
    Item {
        id: composed
        anchors.fill: parent
        visible: root.radius <= 0
        FastBlur {
            anchors.fill: parent
            anchors.margins: -root.overscan
            source: cover
            radius: 64
            opacity: root.strength
            visible: cover.status === Image.Ready
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.42) }
                GradientStop { position: 1; color: ColorUtils.applyAlpha(IrisStyle.surface, 0.72) }
            }
        }
    }
    Loader {
        anchors.fill: parent
        active: root.radius > 0
        sourceComponent: OpacityMask {
            source: ShaderEffectSource { sourceItem: composed; hideSource: true; live: true }
            maskSource: Rectangle { width: root.width; height: root.height; radius: root.radius }
        }
    }
}
