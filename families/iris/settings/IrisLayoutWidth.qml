pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// How wide a new window opens: the screen with a window of each width, side by side. Under Layout it is every
// screen's; under Displays (`spec.screen`) it is the chosen screen's own, with "Like the rest" first, so a wide
// screen opens thirds while a small one opens them whole.
Column {
    id: root

    property var spec: ({})
    readonly property bool own: root.spec?.screen === true
    readonly property real d: IrisStyle.settingsDensity
    readonly property var out: CompositorConfig.output
    readonly property real shared: { CompositorConfig.revision; return Number(CompositorConfig.value({ comp: "layout", key: "new-width", fallback: 0.5 })) || 0.5 }
    readonly property real current: { CompositorConfig.revision; return root.own ? Number(CompositorConfig.displayValue("new-width")) || 0 : root.shared }
    readonly property var steps: (root.own ? [{ value: 0, label: Translation.tr("Like the rest") }] : []).concat([
        { value: 1 / 3, label: Translation.tr("A third") }, { value: 0.5, label: Translation.tr("Half") },
        { value: 2 / 3, label: Translation.tr("Two thirds") }, { value: 1, label: Translation.tr("Whole") }])
    readonly property real aspect: {
        const rect = root.out ? CompositorConfig.logicalRect(root.out) : null
        return rect && rect.height > 0 ? Math.max(0.5, Math.min(3, rect.width / rect.height)) : 16 / 9
    }
    readonly property real gap: Math.round(8 * root.d)
    readonly property real tileWidth: Math.floor((root.width - root.gap * (root.steps.length - 1)) / root.steps.length)
    readonly property url picture: {
        const mine = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[root.out?.name ?? ""]?.path : ""
        return mine ? Wallpapers.stillUrlFor(mine) : Wallpapers.effectiveWallpaperUrl
    }
    function pick(value: real): void {
        if (root.own) CompositorConfig.applyDisplay("new-width", value)
        else CompositorConfig.set({ comp: "layout", key: "new-width" }, Math.round(value * 1000) / 1000)
    }

    spacing: Math.round(6 * root.d)

    Row {
        spacing: root.gap
        Repeater {
            model: ScriptModel { values: root.steps }
            Column {
                id: step
                required property var modelData
                readonly property real share: Number(step.modelData.value)
                // What it draws: its own width, or the shared one when it follows the rest.
                readonly property real drawn: step.share > 0 ? step.share : root.shared
                readonly property bool chosen: Math.abs(step.share - root.current) < 0.02
                width: root.tileWidth
                spacing: Math.round(6 * root.d)

                Rectangle {
                    id: tile
                    width: parent.width
                    height: Math.round((root.tileWidth - Math.round(8 * root.d)) / root.aspect) + Math.round(8 * root.d)
                    radius: IrisStyle.radiusTile
                    // The pick is the window itself lit, never a plate around the screen.
                    color: !step.chosen && (press.containsMouse || tile.activeFocus) ? IrisStyle.fillHover : "transparent"
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }

                    activeFocusOnTab: true
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: step.modelData.label
                    Accessible.checkable: true
                    Accessible.checked: step.chosen
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            root.pick(step.share)
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
                            opacity: step.chosen ? 1 : press.containsMouse || tile.activeFocus ? 0.8 : 0.5
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        }
                        // The new window, as wide as it opens; the one before it waits at its side.
                        Rectangle {
                            id: pane
                            readonly property real room: bezel.width - 2 * Math.round(5 * root.d)
                            x: Math.round(5 * root.d)
                            y: Math.round(5 * root.d)
                            width: Math.round(pane.room * Math.min(1, step.drawn)) - (step.drawn < 0.99 ? Math.round(1.5 * root.d) : 0)
                            height: bezel.height - 2 * Math.round(5 * root.d)
                            radius: Math.max(2, Math.round(3 * root.d)) // iris-literal: a drawn window's corner
                            color: step.chosen ? IrisStyle.accent : step.share > 0 || !root.own ? IrisStyle.surfaceHighOpaque : IrisStyle.textSecondary
                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                            opacity: step.chosen || step.share > 0 || !root.own ? 1 : 0.55
                            Behavior on width { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                        }
                        Rectangle {
                            visible: step.drawn < 0.99
                            x: pane.x + pane.width + Math.round(3 * root.d)
                            y: pane.y
                            width: bezel.width
                            height: pane.height
                            radius: pane.radius
                            color: IrisStyle.surfaceHighOpaque
                            opacity: 0.4
                        }
                    }
                    MouseArea {
                        id: press
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pick(step.share)
                    }
                }
                IrisText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: step.modelData.label
                    color: step.chosen ? IrisStyle.text : IrisStyle.subtext
                    font.pixelSize: IrisStyle.typeFootnote
                    font.weight: IrisStyle.weight(step.chosen ? Font.DemiBold : Font.Normal)
                    elide: Text.ElideRight
                }
            }
        }
    }
}
