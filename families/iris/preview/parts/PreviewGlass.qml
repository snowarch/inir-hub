pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.iris.style

// The glass a picture of the screen gives its bodies: its own wallpaper, blurred as the desktop's is. Under
// Settings the compositor blurs nothing, and the window's backdrop is what lies behind Settings, elsewhere and at
// another scale: compositor glass came out a clear tint over a sharp picture (his 10-30).
Item {
    id: glass
    property Item source: null
    // This picture's pixels per screen pixel: the blur reaches as far over the wallpaper as on the desktop.
    property real k: 1
    readonly property bool ready: glass.source !== null && glass.width >= 2 && glass.height >= 2
    readonly property Item texture: blurred
    readonly property Item clearTexture: sharp
    // Hidden by opacity, as IrisGlassSource: the field samples these textures.
    opacity: 0
    ShaderEffectSource {
        id: sharp
        anchors.fill: parent
        sourceItem: glass.source
        hideSource: false
    }
    MultiEffect {
        id: blurred
        anchors.fill: parent
        layer.enabled: glass.ready
        source: sharp
        autoPaddingEnabled: false
        blurEnabled: true
        blur: IrisStyle.glassBlurAmount
        blurMax: Math.max(4, Math.round(IrisStyle.glassBlurMax * Math.min(1, glass.k)))
        saturation: Math.max(-1, Math.min(1, IrisStyle.glassSaturation + Wallpapers.desktopSaturation))
        contrast: Wallpapers.desktopContrast
    }
}
