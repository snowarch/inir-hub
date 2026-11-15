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
// screen opens thirds while a small one opens them whole. A screen's own wins over Layout's (Umbriel: output over
// [layout]), so Layout names each screen that keeps one and lets it follow. Workspaces side by side turn the strip:
// the window takes the screen's width and the share is its height, drawn so.
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
    readonly property bool sideways: { CompositorConfig.revision; return String(root.out?.workspace_axis ?? "vertical") === "horizontal" }
    readonly property var ownWidths: { CompositorConfig.revision; return root.own ? [] : CompositorConfig.outputs.filter(entry => Number(entry.new_width ?? 0) >= 0.1) }
    function shareName(value: real): string {
        return root.steps.find(step => step.value > 0 && Math.abs(step.value - value) < 0.02)?.label ?? `${Math.round(value * 100)} %`
    }
    function followRest(name: string): void {
        const keep = CompositorConfig.selectedOutput
        CompositorConfig.applyDisplay("screen", name)
        CompositorConfig.applyDisplay("new-width", 0)
        CompositorConfig.applyDisplay("screen", keep)
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
                        // The new window, as wide (sideways: as tall) as it opens; the one before it waits at its side.
                        Rectangle {
                            id: pane
                            readonly property real roomX: bezel.width - 2 * Math.round(5 * root.d)
                            readonly property real roomY: bezel.height - 2 * Math.round(5 * root.d)
                            readonly property real cut: step.drawn < 0.99 ? Math.round(1.5 * root.d) : 0
                            x: Math.round(5 * root.d)
                            y: Math.round(5 * root.d)
                            width: root.sideways ? pane.roomX : Math.round(pane.roomX * Math.min(1, step.drawn)) - pane.cut
                            height: root.sideways ? Math.round(pane.roomY * Math.min(1, step.drawn)) - pane.cut : pane.roomY
                            radius: Math.max(2, Math.round(3 * root.d)) // iris-literal: a drawn window's corner
                            color: step.chosen ? IrisStyle.accent : step.share > 0 || !root.own ? IrisStyle.surfaceHighOpaque : IrisStyle.textSecondary
                            Behavior on color { ColorAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
                            opacity: step.chosen || step.share > 0 || !root.own ? 1 : 0.55
                            Behavior on width { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                        }
                        Rectangle {
                            visible: step.drawn < 0.99
                            x: root.sideways ? pane.x : pane.x + pane.width + Math.round(3 * root.d)
                            y: root.sideways ? pane.y + pane.height + Math.round(3 * root.d) : pane.y
                            width: root.sideways ? pane.width : bezel.width
                            height: root.sideways ? bezel.height : pane.height
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

    // Sideways the share is a height: said once, in the person's words.
    IrisText {
        width: root.width
        visible: root.sideways
        wrapMode: Text.WordWrap
        text: Translation.tr("Workspaces sit side by side on %1, so windows there stack top to bottom: this is how tall they open.").arg(CompositorConfig.screenName(root.out))
        color: IrisStyle.subtext
        font.pixelSize: IrisStyle.typeFootnote
    }
    // Each screen that keeps its own width, with the way back to this one.
    Repeater {
        model: ScriptModel { values: root.ownWidths; objectProp: "name" }
        Item {
            id: kept
            required property var modelData
            width: root.width
            implicitHeight: Math.max(note.implicitHeight, follow.implicitHeight)
            IrisText {
                id: note
                anchors.left: parent.left
                anchors.right: follow.left
                anchors.rightMargin: Math.round(10 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.WordWrap
                text: Translation.tr("%1 keeps its own: %2. It opens new windows that way whatever you choose here.").arg(CompositorConfig.screenName(kept.modelData)).arg(root.shareName(Number(kept.modelData.new_width)))
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeFootnote
            }
            IrisButton {
                id: follow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Like the rest")
                colBackground: IrisStyle.tintFill(IrisStyle.accent)
                colBackgroundHover: IrisStyle.tintFillHover(IrisStyle.accent)
                foreground: IrisStyle.accent
                onClicked: root.followRest(String(kept.modelData.name))
            }
        }
    }
}
