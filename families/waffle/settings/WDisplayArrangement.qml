pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Settings › Display's top, as Windows draws it: every screen that is on as a numbered tile at its own shape, size and
// place; the one whose settings the rows below change is the accent one. A press picks a screen; one dragged comes to
// rest against the nearest edge of another (CompositorConfig.settle), where it is let go. "Identify" puts each
// screen's number on the screen itself, the same number its tile wears. Screens that are off wait beside the button.
ColumnLayout {
    id: root

    readonly property var screens: CompositorConfig.activeOutputs
    readonly property var idle: CompositorConfig.outputs.filter(out => out.enabled === false)
    readonly property var names: root.screens.map(out => out.name)
    readonly property var rects: root.screens.map(out => Object.assign({ name: out.name }, CompositorConfig.logicalRect(out)))
    readonly property var bounds: {
        const all = root.rects.length > 0 ? root.rects : [{ x: 0, y: 0, width: 16, height: 9 }]
        const fromX = Math.min(...all.map(rect => rect.x)), fromY = Math.min(...all.map(rect => rect.y))
        return { x: fromX, y: fromY, width: Math.max(...all.map(rect => rect.x + rect.width)) - fromX, height: Math.max(...all.map(rect => rect.y + rect.height)) - fromY }
    }
    // Room around the desk to carry a screen to any side of another.
    readonly property real unit: Math.min(desk.width / (root.bounds.width * 1.5), desk.height / (root.bounds.height * 1.6))
    readonly property real originX: (desk.width - root.bounds.width * root.unit) / 2
    readonly property real originY: (desk.height - root.bounds.height * root.unit) / 2
    readonly property var chosen: CompositorConfig.output
    property var landing: null
    property string heldName: ""
    readonly property string facts: {
        const out = root.chosen
        if (!out) return ""
        if (out.enabled === false) return Translation.tr("Off")
        const inches = CompositorConfig.inchesOf(out)
        return [inches > 0 ? `${Math.round(inches)}″` : "", CompositorConfig.resolutionLabel(out), CompositorConfig.rateLabel(out.current_rate ?? 0), `${Math.round(Number(out.scale ?? 1) * 100)} %`]
            .filter(part => part.length > 0).join(" · ")
    }
    function numberOf(name: string): int { return CompositorConfig.outputs.findIndex(out => out.name === name) + 1 }
    function pick(name: string): void { CompositorConfig.applyDisplay("screen", name) }

    spacing: Looks.dp(12)

    WScreenIdentify { id: identify }

    Item {
        id: desk
        Layout.fillWidth: true
        Layout.preferredHeight: Math.round(Math.max(Looks.dp(150), Math.min(Looks.dp(220), desk.width * 0.34)))

        // The place the screen in the hand will take.
        Rectangle {
            id: ghost
            readonly property var rect: root.rects.find(entry => entry.name === root.heldName) ?? null
            readonly property var other: root.rects.find(entry => entry.name !== root.heldName) ?? null
            readonly property bool shown: root.landing !== null && ghost.rect !== null && ghost.other !== null
            readonly property real atX: ghost.shown ? ghost.other.x + root.landing[root.heldName].x - root.landing[ghost.other.name].x : 0
            readonly property real atY: ghost.shown ? ghost.other.y + root.landing[root.heldName].y - root.landing[ghost.other.name].y : 0
            visible: ghost.shown
            x: root.originX + (ghost.atX - root.bounds.x) * root.unit
            y: root.originY + (ghost.atY - root.bounds.y) * root.unit
            width: (ghost.rect?.width ?? 0) * root.unit
            height: (ghost.rect?.height ?? 0) * root.unit
            radius: Looks.settings.radiusSmall
            color: ColorUtils.transparentize(Looks.colors.accent, 0.7)
            border.width: 1
            border.color: Looks.colors.accent
        }

        Repeater {
            model: ScriptModel { values: root.names }
            Rectangle {
                id: tile
                required property string modelData
                readonly property var out: root.screens.find(entry => entry.name === tile.modelData) ?? null
                readonly property var rect: root.rects.find(entry => entry.name === tile.modelData) ?? ({ x: 0, y: 0, width: 16, height: 9 })
                readonly property bool chosen: root.chosen?.name === tile.modelData
                readonly property bool held: root.heldName === tile.modelData
                property real carryX: 0
                property real carryY: 0

                // A hairline apart from its neighbours, as Windows' tiles sit.
                x: root.originX + (tile.rect.x - root.bounds.x) * root.unit + tile.carryX + 1
                y: root.originY + (tile.rect.y - root.bounds.y) * root.unit + tile.carryY + 1
                width: tile.rect.width * root.unit - 2
                height: tile.rect.height * root.unit - 2
                z: tile.held ? 3 : tile.chosen ? 2 : 1
                radius: Looks.settings.radiusSmall
                color: tile.chosen ? (press.pressed ? Looks.colors.accentActive : press.containsMouse ? Looks.colors.accentHover : Looks.colors.accent)
                    : press.pressed ? Looks.settings.tilePressed : press.containsMouse ? Looks.settings.tileHover : Looks.settings.tile
                border.width: tile.chosen ? 0 : 1
                border.color: Looks.settings.strokeStrong
                Behavior on x { enabled: !tile.held && Looks.transition.enabled; NumberAnimation { duration: Looks.transition.duration.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate } }
                Behavior on y { enabled: !tile.held && Looks.transition.enabled; NumberAnimation { duration: Looks.transition.duration.slow; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.decelerate } }
                Behavior on color { ColorAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard } }

                activeFocusOnTab: true
                Accessible.role: Accessible.RadioButton
                Accessible.name: CompositorConfig.screenName(tile.out)
                Accessible.checkable: true
                Accessible.checked: tile.chosen
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.pick(tile.modelData)
                        event.accepted = true
                    }
                }
                WFocusVisual { shown: tile.activeFocus; radius: tile.radius }

                WText {
                    anchors.centerIn: parent
                    text: String(root.numberOf(tile.modelData))
                    color: tile.chosen ? Looks.colors.accentFg : Looks.colors.fg
                    font.pixelSize: Math.round(Math.max(Looks.settings.body, Math.min(Looks.settings.title, tile.height * 0.4)))
                    font.weight: Looks.font.weight.strong
                }

                MouseArea {
                    id: press
                    property real fromX: 0
                    property real fromY: 0
                    property bool moved: false
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: press.moved ? Qt.ClosedHandCursor : root.screens.length > 1 ? Qt.OpenHandCursor : Qt.PointingHandCursor
                    onPressed: mouse => {
                        const at = press.mapToItem(desk, mouse.x, mouse.y)
                        press.fromX = at.x
                        press.fromY = at.y
                        press.moved = false
                        root.pick(tile.modelData)
                    }
                    onPositionChanged: mouse => {
                        if (!press.pressed || root.screens.length < 2) return
                        const at = press.mapToItem(desk, mouse.x, mouse.y)
                        const dx = at.x - press.fromX, dy = at.y - press.fromY
                        if (!press.moved && Math.hypot(dx, dy) < 6) return
                        press.moved = true
                        root.heldName = tile.modelData
                        tile.carryX = dx
                        tile.carryY = dy
                        root.landing = CompositorConfig.settle(root.rects, tile.modelData, tile.rect.x + dx / root.unit, tile.rect.y + dy / root.unit)
                    }
                    onReleased: {
                        const landing = root.landing
                        root.landing = null
                        root.heldName = ""
                        tile.carryX = 0
                        tile.carryY = 0
                        if (press.moved && landing) CompositorConfig.arrange(landing)
                        press.moved = false
                    }
                    onCanceled: { root.landing = null; root.heldName = ""; tile.carryX = 0; tile.carryY = 0; press.moved = false }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Looks.dp(12)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            WText {
                Layout.fillWidth: true
                text: root.chosen ? `${root.numberOf(root.chosen.name)}  ${CompositorConfig.screenName(root.chosen)}` : ""
                font.pixelSize: Looks.settings.body
                font.weight: Looks.font.weight.strong
                elide: Text.ElideRight
            }
            WText {
                Layout.fillWidth: true
                text: root.facts
                font.pixelSize: Looks.settings.caption
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
            }
            WText {
                Layout.fillWidth: true
                text: root.chosen?.enabled === false ? Translation.tr("Its switch below turns it back on, where it stood.")
                    : root.screens.length > 1 ? Translation.tr("Drag a screen to where it stands on your desk.") : ""
                visible: text.length > 0
                font.pixelSize: Looks.settings.caption
                color: Looks.colors.subfg
                wrapMode: Text.WordWrap
            }
        }

        // Screens plugged in and turned off: a press picks one, and its switch below turns it on.
        Repeater {
            model: ScriptModel { values: root.idle.map(out => out.name) }
            WButton {
                id: chip
                required property string modelData
                readonly property bool chosen: root.chosen?.name === chip.modelData
                text: `${root.numberOf(chip.modelData)}  ${CompositorConfig.screenName(root.idle.find(entry => entry.name === chip.modelData) ?? null)} · ${Translation.tr("Off")}`
                checked: chip.chosen
                colBackground: Looks.colors.interactiveSurface
                colBackgroundHover: Looks.colors.interactiveSurfaceHover
                colBackgroundActive: Looks.colors.interactiveSurfaceActive
                onClicked: root.pick(chip.modelData)
            }
        }

        WButton {
            visible: CompositorConfig.outputs.length > 1
            text: Translation.tr("Identify")
            colBackground: Looks.colors.interactiveSurface
            colBackgroundHover: Looks.colors.interactiveSurfaceHover
            colBackgroundActive: Looks.colors.interactiveSurfaceActive
            onClicked: identify.show()
        }
    }
}
