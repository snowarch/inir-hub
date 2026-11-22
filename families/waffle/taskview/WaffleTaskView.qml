pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.state

Scope {
    id: root

    // Previews are cached and cleaned up automatically when windows close
    // No need to clear on TaskView close - improves performance on re-open

    function openTaskView(): void {
        if (WaffleState.taskViewOpen) return
        // Open INSTANTLY - previews load progressively in background
        WaffleState.taskViewOpen = true
    }

    Loader {
        id: panelLoader
        active: WaffleState.taskViewOpen
        sourceComponent: PanelWindow {
            id: panelWindow
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:wTaskView"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: PolkitService.active ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
            color: "transparent"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // Wallpaper source for blur
            Image {
                id: wallpaperSource
                anchors.fill: parent
                source: {
                    const wBg = Config.options?.waffles?.background ?? {}
                    const path = (wBg.useMainWallpaper ?? true)
                        ? Config.options?.background?.wallpaperPath ?? ""
                        : wBg.wallpaperPath ?? Config.options?.background?.wallpaperPath ?? ""
                    return Wallpapers.stillUrlFor(path)
                }
                fillMode: Image.PreserveAspectCrop
                // Blur source: decode at the screen's pixels, not the file's
                sourceSize: Qt.size(
                    Math.ceil((panelWindow.screen?.width ?? 1920) * Math.max(1, panelWindow.devicePixelRatio ?? 1)),
                    Math.ceil((panelWindow.screen?.height ?? 1080) * Math.max(1, panelWindow.devicePixelRatio ?? 1)))
                visible: false
            }

            // Click outside to close - but not during drag
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                z: -1  // Below everything so workspace clicks work
                onClicked: mouse => {
                    if (content.isDragging) return
                    WaffleState.taskViewOpen = false
                }
            }

            // Waffle Next: the whole desktop sinks behind frosted glass, the desktops float on it
            Item {
                id: blurStrip
                anchors.fill: parent
                clip: true

                // Entry animation - respects GameMode
                opacity: 0

                Component.onCompleted: {
                    if (Looks.transition.enabled) {
                        stripEntryAnim.start()
                    } else {
                        opacity = 1
                        contentScale.xScale = contentScale.yScale = 1
                    }
                }

                ParallelAnimation {
                    id: stripEntryAnim
                    NumberAnimation {
                        target: blurStrip
                        property: "opacity"
                        to: 1
                        duration: Looks.transition.duration.normal
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate
                    }
                    NumberAnimation {
                        target: contentScale
                        properties: "xScale,yScale"
                        to: 1
                        duration: Looks.transition.duration.panel
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Looks.transition.easing.bezierCurve.arrive
                    }
                }

                // Blurred wallpaper background
                ShaderEffectSource {
                    id: blurSource
                    anchors.fill: parent
                    sourceItem: wallpaperSource
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: blurSource
                    blurEnabled: Appearance.effectsEnabled
                    blur: 0.8
                    blurMax: 68
                    saturation: 0.5
                }

                // tint in the scheme's own surface, a touch of accent so it reads as Waffle
                Rectangle {
                    anchors.fill: parent
                    color: Qt.alpha(ColorUtils.mix(Looks.colors.bg0Opaque, Looks.colors.accent, 0.9), Looks.dark ? 0.62 : 0.5)
                }
            }

            WaffleTaskViewContent {
                id: content
                anchors.centerIn: blurStrip
                transform: Scale { id: contentScale; origin.x: content.width / 2; origin.y: content.height / 2; xScale: 0.96; yScale: 0.96 }
                focus: true
                onClosed: WaffleState.taskViewOpen = false
                
                Keys.onEscapePressed: WaffleState.taskViewOpen = false
            }
        }
    }

}
