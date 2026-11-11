pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Display › Screen › Scale: the chosen screen at each scale it takes, side by side, from larger text to
// more space. Each miniature wears the screen's wallpaper and one window whose words grow with the scale, so a person
// picks how big things look instead of a percentage. A press applies it; the figure says the one picked.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var out: CompositorConfig.output
    // Larger text first, the way the eye reads the choice: what grows on the left, what fits more on the right.
    readonly property var steps: CompositorConfig.displayChoices("scale").slice().sort((a, b) => Number(b.value) - Number(a.value))
    readonly property real current: Number(CompositorConfig.displayValue("scale") ?? 1)
    readonly property real aspect: {
        const rect = root.out ? CompositorConfig.logicalRect(root.out) : null
        return rect && rect.height > 0 ? Math.max(0.5, Math.min(3, rect.width / rect.height)) : 16 / 9
    }
    readonly property real gap: Math.round(8 * root.d)
    readonly property real tileWidth: root.steps.length > 0 ? Math.floor((root.width - root.gap * (root.steps.length - 1)) / root.steps.length) : root.width
    readonly property url picture: {
        const own = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[root.out?.name ?? ""]?.path : ""
        return own ? Wallpapers.stillUrlFor(own) : Wallpapers.effectiveWallpaperUrl
    }

    spacing: Math.round(8 * root.d)

    Row {
        spacing: root.gap
        Repeater {
            model: ScriptModel { values: root.steps }
            Rectangle {
                id: step
                required property var modelData
                readonly property real scale_: Number(step.modelData.value)
                readonly property bool chosen: Math.abs(step.scale_ - root.current) < 0.001
                width: root.tileWidth
                height: Math.round((root.tileWidth - Math.round(8 * root.d)) / root.aspect) + Math.round(8 * root.d)
                radius: IrisStyle.radiusTile
                color: step.chosen ? IrisStyle.tintFillHover(IrisStyle.accent) : press.containsMouse || step.activeFocus ? IrisStyle.fillHover : "transparent"
                Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }

                activeFocusOnTab: true
                Accessible.role: Accessible.RadioButton
                Accessible.name: step.modelData.label
                Accessible.checkable: true
                Accessible.checked: step.chosen
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        CompositorConfig.applyDisplay("scale", step.modelData.value)
                        event.accepted = true
                    }
                }

                Rectangle {
                    id: bezel
                    anchors.fill: parent
                    anchors.margins: Math.round(4 * root.d)
                    radius: Math.round(4 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
                    color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: Math.max(1, Math.round(2 * root.d))
                        source: root.picture
                        sourceSize.width: Math.round(200 * root.d)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: step.chosen ? 1 : press.containsMouse || step.activeFocus ? 0.8 : 0.5
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                    }
                    // One window, its words at this scale: the more the scale, the fewer fit.
                    Rectangle {
                        readonly property real ink: Math.max(3, bezel.width * 0.05 * step.scale_)
                        x: Math.round(bezel.width * 0.12)
                        y: Math.round(bezel.height * 0.16)
                        width: Math.round(bezel.width * 0.76)
                        height: Math.round(bezel.height * 0.68)
                        radius: Math.max(2, Math.round(3 * root.d * step.scale_)) // iris-literal: a drawn window's corner
                        color: IrisStyle.surfaceHighOpaque
                        clip: true
                        Column {
                            x: parent.ink * 0.8
                            y: parent.ink * 0.6
                            width: parent.width - parent.ink * 1.6
                            spacing: parent.ink * 0.3
                            IrisText {
                                width: parent.width
                                text: Translation.tr("Morning notes")
                                font.pixelSize: Math.round(parent.parent.ink * 1.15)
                                font.weight: IrisStyle.weight(Font.DemiBold)
                                elide: Text.ElideRight
                                renderType: Text.QtRendering
                            }
                            IrisText {
                                width: parent.width
                                text: Translation.tr("Words, icons and windows take this much room on this screen, and the rest is space.")
                                color: IrisStyle.subtext
                                font.pixelSize: Math.round(parent.parent.ink)
                                wrapMode: Text.WordWrap
                                renderType: Text.QtRendering
                            }
                        }
                    }
                }

                MouseArea {
                    id: press
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: CompositorConfig.applyDisplay("scale", step.modelData.value)
                }
            }
        }
    }

    Item {
        width: root.width
        height: ends.implicitHeight
        IrisText {
            id: ends
            visible: figure.at !== 0
            text: Translation.tr("Larger text")
            color: IrisStyle.subtext
            font.pixelSize: IrisStyle.typeFootnote
        }
        // The figure stands under the miniature it names.
        // At either end it takes that end's word with it: one line, never two words crowding.
        IrisText {
            id: figure
            readonly property int at: root.steps.findIndex(step => Math.abs(Number(step.value) - root.current) < 0.001)
            readonly property string figureText: `${Math.round(root.current * 100)} %`
            visible: at >= 0
            x: at === 0 ? 0 : at === root.steps.length - 1 ? parent.width - width
                : Math.max(ends.implicitWidth + root.gap, Math.min(parent.width - width - more.implicitWidth - root.gap, at * (root.tileWidth + root.gap) + (root.tileWidth - width) / 2))
            text: at === 0 ? figureText + " · " + Translation.tr("Larger text") : at === root.steps.length - 1 ? figureText + " · " + Translation.tr("More space") : figureText
            font.pixelSize: IrisStyle.typeFootnote
            font.weight: IrisStyle.weight(Font.DemiBold)
            font.features: ({ "tnum": 1 })
        }
        IrisText {
            id: more
            visible: figure.at !== root.steps.length - 1
            anchors.right: parent.right
            text: Translation.tr("More space")
            color: IrisStyle.subtext
            font.pixelSize: IrisStyle.typeFootnote
        }
    }
}
