import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.prism.core

// A level as a fader. A drag previews; release commits. The wheel steps once a notch (fine wheels and touchpads add up
// to one), previews each step and commits once when the burst stops, as a release would.
Item {
    id: root
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property string glyph: ""
    property string label: ""
    signal moved(real value)
    signal committed(real value)

    property real live: root.value
    property bool held: false
    // A wheel burst in progress: its steps are previews until it rests.
    property bool wheeling: false
    onValueChanged: if (!root.held && !root.wheeling) root.live = root.value

    function settle(): void {
        if (!root.wheeling) return
        wheelRest.stop()
        root.wheeling = false
        area.wheelAcc = 0
        if (area.wheelMoved) root.committed(root.live)
        area.wheelMoved = false
    }
    Timer { id: wheelRest; interval: 280; onTriggered: root.settle() }

    readonly property real share: root.to > root.from ? Math.max(0, Math.min(1, (root.live - root.from) / (root.to - root.from))) : 0
    implicitWidth: PrismTheme.dp(220)
    implicitHeight: PrismTheme.dp(32)

    function snap(v: real): real {
        const stepped = Math.round((v - root.from) / root.stepSize) * root.stepSize + root.from
        return Math.max(root.from, Math.min(root.to, Number(stepped.toFixed(6))))
    }
    // The factory value: a drag passing it holds there, so it can always be found again; the wheel steps freely.
    property real home: NaN
    function at(x: real): real {
        const raw = root.from + Math.max(0, Math.min(1, (x - root.lead - root.capWidth / 2) / Math.max(1, root.travel))) * (root.to - root.from)
        if (Number.isFinite(root.home) && Math.abs(raw - root.home) < (root.to - root.from) * 0.02) return root.home
        return root.snap(raw)
    }

    // The fader (`.claude/ref/language`: the tactile sliders): a groove cut into the card with its scale printed under
    // it, the person's accent filling it up to a white cap with a grip, the figure printed at the end. The factory value's
    // tick stands taller, so it can be found again by eye as well as by the drag that holds there.
    readonly property real capWidth: PrismTheme.dp(28)
    readonly property real figureRoom: root.label.length > 0 ? Math.max(PrismTheme.dp(46), figure.implicitWidth) + PrismTheme.dp(12) : 0
    // A glyph, when given (the home deck's volume), leads before the groove.
    readonly property real lead: root.glyph.length > 0 ? PrismTheme.dp(26) : 0
    readonly property real grooveWidth: Math.max(root.capWidth * 2, root.width - root.figureRoom - root.lead)
    readonly property real travel: root.grooveWidth - root.capWidth
    readonly property real middle: PrismTheme.dp(12)

    PrismGlyph {
        visible: root.glyph.length > 0
        y: root.middle - height / 2
        text: root.glyph
        filled: true
        iconSize: PrismTheme.dp(16)
        color: PrismTheme.ink2
    }
    PrismWell {
        id: track
        x: root.lead
        y: root.middle - height / 2
        width: root.grooveWidth
        height: PrismTheme.dp(8)
        hovered: area.containsMouse || root.held
    }
    // The groove fills with the person's accent up to the cap: a level is a chosen state, never the art's spectrum.
    Rectangle {
        x: track.x + 1
        y: track.y + 1
        width: Math.max(track.height - 2, cap.x - track.x + cap.width / 2 - 1)
        height: track.height - 2
        radius: height / 2
        color: PrismTheme.accent
    }
    Repeater {
        model: 11
        delegate: Rectangle {
            required property int index
            x: Math.round(root.lead + root.capWidth / 2 + root.travel * index / 10)
            y: track.y + track.height + PrismTheme.dp(5)
            width: 1
            height: index % 5 === 0 ? PrismTheme.dp(5) : PrismTheme.dp(3)
            color: PrismTheme.ink3
            opacity: 0.7
        }
    }
    Rectangle {
        readonly property real share: root.to > root.from ? (root.home - root.from) / (root.to - root.from) : 0
        visible: Number.isFinite(root.home) && share >= 0 && share <= 1
        x: Math.round(root.lead + root.capWidth / 2 + root.travel * share)
        y: track.y + track.height + PrismTheme.dp(4)
        width: 1
        height: PrismTheme.dp(7)
        color: PrismTheme.ink
    }
    PrismKey {
        id: cap
        x: root.lead + root.travel * root.share
        y: root.middle - height / 2 - PrismTheme.dp(1)
        width: root.capWidth
        height: PrismTheme.dp(20)
        radius: PrismTheme.dp(7)
        face: PrismTheme.paper
        hovered: area.containsMouse
        down: root.held
        Behavior on x { enabled: !root.held; NumberAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
        Row {
            anchors.centerIn: parent
            spacing: PrismTheme.dp(3)
            Repeater {
                model: 2
                delegate: Rectangle { width: 1; height: PrismTheme.dp(8); color: PrismTheme.night; opacity: 0.32 }
            }
        }
    }
    PrismText {
        id: figure
        x: root.width - width
        y: root.middle - height / 2
        text: root.label
        figures: true
        font.pixelSize: PrismTheme.small
        font.weight: Font.DemiBold
        color: root.held ? PrismTheme.ink : PrismTheme.ink2
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.settle(); root.held = true; root.live = root.at(mouse.x); root.moved(root.live) }
        onContainsMouseChanged: if (!area.containsMouse) root.settle()
        onPositionChanged: mouse => {
            intent.track(mouse.x, mouse.y)
            if (!pressed) return
            const next = root.at(mouse.x)
            if (next !== root.live) { root.live = next; root.moved(next) }
        }
        onReleased: { root.held = false; root.committed(root.live) }
        onCanceled: { root.held = false; root.live = root.value }
        // A wheel belongs to the page while the page scrolls, and to the level the pointer rests on while the page is
        // still (WheelIntent, the same hand as every slider of the shell). 120 is one notch (Qt's angleDelta, 1/8 degree).
        WheelIntent { id: intent; hovered: area.containsMouse }
        property real wheelAcc: 0
        property bool wheelMoved: false
        onWheel: wheel => {
            if (!root.wheeling && !intent.take(wheel)) return
            const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.pixelDelta.y * 4
            area.wheelAcc += delta
            const steps = Math.trunc(area.wheelAcc / 120)
            root.wheeling = true
            wheelRest.restart()
            if (steps === 0) return
            area.wheelAcc -= steps * 120
            const next = root.snap(root.live + steps * root.stepSize * Math.max(1, Math.round((root.to - root.from) / root.stepSize / 20)))
            if (next !== root.live) { root.live = next; area.wheelMoved = true; root.moved(next) }
        }
    }
}
