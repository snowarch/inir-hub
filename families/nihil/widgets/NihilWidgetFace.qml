pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.nihil.style

// A desktop widget on NiHiL's glass: the plate the widget's material asks for, the content inside it, and the page turn
// of a stack. Faces only lay out what they say.
Item {
    id: root

    required property var widget
    property real padding: root.dp(16)
    default property alias content: body.data

    readonly property string size: root.widget.sizeClass
    readonly property bool small: root.size === "small"
    readonly property bool medium: root.size === "medium"
    readonly property bool large: root.size === "large"
    readonly property real radius: root.widget.cornerRadiusOverride >= 0
        ? root.widget.cornerRadiusOverride : Math.round(root.widget.widgetCardRadius * root.widget.scaleFactor)
    readonly property real contentWidth: root.width - root.padding * 2
    readonly property real contentHeight: root.height - root.padding * 2

    // Seen: the desktop under the face is showing. Anything that ticks follows this.
    readonly property bool moving: root.widget.powerActive && root.widget.visible && root.widget.motionActive

    readonly property string material: root.widget.look.material(root.widget)
    readonly property bool clear: root.material === "clear"

    readonly property bool stacked: root.widget.stacked
    readonly property real slide: root.widget.stackPos
    readonly property bool plated: !root.stacked || root.widget.stackShown

    function dp(value: real): real {
        return Math.round(NihilStyle.s(value) * root.widget.scaleFactor)
    }

    NGlass {
        anchors.fill: parent
        visible: root.plated && !root.clear
        radius: root.radius
        tint: root.material === "glass" ? NihilStyle.glassTint : NihilStyle.base
        ignite: root.widget.stackDropHint ? 1 : 0
    }

    Item {
        id: page
        width: root.width
        height: root.height
        clip: root.stacked && root.slide !== 0
        y: Math.round(root.slide * root.height * 0.5)
        opacity: 1 - Math.pow(Math.min(1, Math.abs(root.slide)), 1.5)

        // With no plate under it, the words carry their own shadow over the wallpaper.
        layer.enabled: root.clear
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 0.7
            shadowOpacity: 0.75
            shadowVerticalOffset: 1
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }

        Item {
            id: body
            anchors.fill: parent
            anchors.margins: root.padding
        }
    }

    // The wheel over a stack turns one page per gesture, and the page that arrives waits for the wheel to go quiet.
    property real wheelTravel: 0
    readonly property bool pageUp: root.stacked && root.widget.stackShown
    onPageUpChanged: {
        root.wheelTravel = 0
        if (root.pageUp)
            wheelHold.restart()
    }

    Timer {
        id: wheelHold
        interval: 360
    }
    Timer {
        id: wheelReset
        interval: 260
        onTriggered: root.wheelTravel = 0
    }

    WheelHandler {
        enabled: root.pageUp
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (wheelHold.running) {
                wheelHold.restart()
                return
            }
            root.wheelTravel += event.angleDelta.y
            wheelReset.restart()
            if (Math.abs(root.wheelTravel) < 120)
                return
            const forward = root.wheelTravel < 0
            root.wheelTravel = 0
            wheelHold.restart()
            DesktopWidgetStacks.step(root.widget.outputName, root.widget.stack.id, forward ? 1 : -1)
        }
    }

    HoverHandler {
        id: stackHover
        enabled: root.stacked
    }
    readonly property bool holding: root.stacked && root.widget.stackShown && (stackHover.hovered || root.widget.containsPress)
    onHoldingChanged: if (root.stacked) DesktopWidgetStacks.setHovered(root.widget.stack.id, root.holding)
}
