pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Display › Screen with two screens or more: the desk as it is. Every screen at its own shape, size and
// place, wearing its wallpaper; one is dragged to where it stands and comes to rest against the nearest edge of
// another (CompositorConfig.settle), which is where the pointer crosses. A press picks the screen the rows below
// change. Screens that are off wait under the desk.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var screens: CompositorConfig.activeOutputs
    readonly property var idle: CompositorConfig.outputs.filter(out => out.enabled === false)
    readonly property var names: root.screens.map(out => out.name)
    readonly property var rects: root.screens.map(out => Object.assign({ name: out.name }, CompositorConfig.logicalRect(out)))
    readonly property var bounds: {
        const all = root.rects.length > 0 ? root.rects : [{ x: 0, y: 0, width: 16, height: 9 }]
        const fromX = Math.min(...all.map(rect => rect.x)), fromY = Math.min(...all.map(rect => rect.y))
        return { x: fromX, y: fromY, width: Math.max(...all.map(rect => rect.x + rect.width)) - fromX, height: Math.max(...all.map(rect => rect.y + rect.height)) - fromY }
    }
    // Screen pixels per logical pixel: the whole desk with room around it to carry a screen to any side.
    readonly property real unit: Math.min(desk.width / (root.bounds.width * 1.5), desk.height / (root.bounds.height * 1.7))
    readonly property real originX: (desk.width - root.bounds.width * root.unit) / 2
    readonly property real originY: (desk.height - root.bounds.height * root.unit) / 2
    // Where the screen in the hand would rest, as CompositorConfig.settle answers.
    property var landing: null
    property string heldName: ""
    readonly property var chosen: CompositorConfig.output
    readonly property string facts: {
        const out = root.chosen
        if (!out) return ""
        if (out.enabled === false) return Translation.tr("Off")
        const inches = CompositorConfig.inchesOf(out)
        return [inches > 0 ? `${Math.round(inches)}″` : "", CompositorConfig.resolutionLabel(out), CompositorConfig.rateLabel(out.current_rate ?? 0), `${Math.round(Number(out.scale ?? 1) * 100)} %`]
            .filter(part => part.length > 0).map(part => part.replace(/ /g, " ")).join(" · ")
    }

    spacing: Math.round(10 * root.d)

    Rectangle {
        id: desk
        width: root.width
        height: Math.round(Math.max(168, Math.min(240, root.width * 0.36)) * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fill
        clip: true

        // The place the held screen will take.
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
            radius: Math.round(5 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
            color: IrisStyle.tintFillHover(IrisStyle.accent)
        }

        Repeater {
            model: ScriptModel { values: root.names }
            Item {
                id: screen
                required property string modelData
                readonly property var out: root.screens.find(entry => entry.name === screen.modelData) ?? null
                readonly property var rect: root.rects.find(entry => entry.name === screen.modelData) ?? ({ x: 0, y: 0, width: 16, height: 9 })
                readonly property bool chosen: root.chosen?.name === screen.modelData
                readonly property bool held: root.heldName === screen.modelData
                property real carryX: 0
                property real carryY: 0

                x: root.originX + (screen.rect.x - root.bounds.x) * root.unit + screen.carryX
                y: root.originY + (screen.rect.y - root.bounds.y) * root.unit + screen.carryY
                width: screen.rect.width * root.unit
                height: screen.rect.height * root.unit
                z: screen.held ? 3 : screen.chosen ? 2 : 1
                scale: screen.held ? 1.03 : 1
                Behavior on x { enabled: !screen.held; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on y { enabled: !screen.held; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 140; easing.type: IrisStyle.feedbackEasing } }

                activeFocusOnTab: true
                Accessible.role: Accessible.RadioButton
                Accessible.name: CompositorConfig.screenName(screen.out)
                Accessible.checkable: true
                Accessible.checked: screen.chosen
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        CompositorConfig.applyDisplay("screen", screen.modelData)
                        event.accepted = true
                    }
                }

                Rectangle {
                    id: bezel
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: Math.round(5 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
                    color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme
                    border.width: 1
                    border.color: IrisStyle.hairline

                    Image {
                        id: picture
                        anchors.fill: parent
                        anchors.margins: Math.max(2, Math.round(2.5 * root.d))
                        source: {
                            const own = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[screen.modelData]?.path : ""
                            return own ? Wallpapers.stillUrlFor(own) : Wallpapers.effectiveWallpaperUrl
                        }
                        sourceSize.width: Math.round(320 * root.d)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                    }
                    // The screens not chosen step back; the chosen one is simply the lit one.
                    Rectangle {
                        anchors.fill: picture
                        color: "#0b0b0c" // iris-literal: a screen turned down, the bezel's own black
                        opacity: screen.chosen || screen.held ? 0 : press.containsMouse || screen.activeFocus ? 0.3 : 0.58
                        Behavior on opacity { NumberAnimation { duration: 140; easing.type: IrisStyle.feedbackEasing } }
                    }
                    IrisText {
                        anchors.centerIn: parent
                        width: parent.width - Math.round(12 * root.d)
                        horizontalAlignment: Text.AlignHCenter
                        text: CompositorConfig.screenName(screen.out)
                        color: "#ffffff" // iris-literal: a name over a wallpaper turned down, never the theme's text
                        opacity: screen.chosen ? 1 : 0.78
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: IrisStyle.weight(screen.chosen ? Font.DemiBold : Font.Medium)
                        style: Text.Raised
                        styleColor: "#99000000" // iris-literal: the name's own shade over any wallpaper
                        elide: Text.ElideRight
                        visible: parent.width > Math.round(64 * root.d)
                    }
                }

                MouseArea {
                    id: press
                    property real fromX: 0
                    property real fromY: 0
                    property bool moved: false
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: mouse => {
                        const at = press.mapToItem(desk, mouse.x, mouse.y)
                        press.fromX = at.x
                        press.fromY = at.y
                        press.moved = false
                        screen.forceActiveFocus()
                        CompositorConfig.applyDisplay("screen", screen.modelData)
                    }
                    onPositionChanged: mouse => {
                        if (!press.pressed) return
                        const at = press.mapToItem(desk, mouse.x, mouse.y)
                        const dx = at.x - press.fromX, dy = at.y - press.fromY
                        if (!press.moved && Math.hypot(dx, dy) < 6) return
                        press.moved = true
                        root.heldName = screen.modelData
                        screen.carryX = dx
                        screen.carryY = dy
                        root.landing = CompositorConfig.settle(root.rects, screen.modelData, screen.rect.x + dx / root.unit, screen.rect.y + dy / root.unit)
                    }
                    onReleased: {
                        const landing = root.landing
                        root.landing = null
                        root.heldName = ""
                        screen.carryX = 0
                        screen.carryY = 0
                        if (press.moved && landing) CompositorConfig.arrange(landing)
                    }
                    onCanceled: { root.landing = null; root.heldName = ""; screen.carryX = 0; screen.carryY = 0 }
                }
            }
        }
    }

    Row {
        width: root.width
        spacing: Math.round(10 * root.d)
        Column {
            width: parent.width - (waiting.visible ? waiting.width + parent.spacing : 0)
            spacing: Math.round(2 * root.d)
            IrisText {
                width: parent.width
                text: CompositorConfig.screenName(root.chosen)
                font.pixelSize: IrisStyle.typeBody
                font.weight: IrisStyle.weight(Font.DemiBold)
                elide: Text.ElideRight
            }
            IrisText {
                width: parent.width
                text: root.facts
                color: IrisStyle.subtext
                font.pixelSize: IrisStyle.typeMeta
                font.features: ({ "tnum": 1 })
                wrapMode: Text.WordWrap
            }
            IrisText {
                width: parent.width
                text: Translation.tr("Drag a screen to where it stands on your desk.")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                wrapMode: Text.WordWrap
            }
        }
        // Screens plugged in and turned off: a press picks one, and its switch below turns it on.
        Row {
            id: waiting
            visible: root.idle.length > 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(6 * root.d)
            Repeater {
                model: ScriptModel { values: root.idle.map(out => out.name) }
                Rectangle {
                    id: chip
                    required property string modelData
                    readonly property var out: root.idle.find(entry => entry.name === chip.modelData) ?? null
                    readonly property bool chosen: root.chosen?.name === chip.modelData
                    width: label.implicitWidth + Math.round(20 * root.d)
                    height: Math.round(28 * root.d)
                    radius: height / 2
                    color: chip.chosen ? IrisStyle.tintFillHover(IrisStyle.accent) : IrisStyle.fill
                    opacity: chip.chosen || tap.containsMouse ? 1 : 0.8
                    IrisText {
                        id: label
                        anchors.centerIn: parent
                        text: CompositorConfig.screenName(chip.out) + " · " + Translation.tr("Off")
                        color: chip.chosen ? IrisStyle.text : IrisStyle.subtext
                        font.pixelSize: IrisStyle.typeFootnote
                        font.weight: IrisStyle.weight(chip.chosen ? Font.DemiBold : Font.Normal)
                    }
                    MouseArea {
                        id: tap
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CompositorConfig.applyDisplay("screen", chip.modelData)
                    }
                }
            }
        }
    }
}
