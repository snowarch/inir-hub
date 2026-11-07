import QtQuick
import qs.modules.iris.prism.core

// A level as the reference's white-fill pill, lying down: the fill is the value, the glyph rides at its start and the
// figure at the end. A drag previews; release commits. The wheel steps once a notch (fine wheels and touchpads add up
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
    function at(x: real): real { return root.snap(root.from + (x / root.width) * (root.to - root.from)) }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: area.containsMouse || root.held ? PrismTheme.fillHover : PrismTheme.fill
        clip: true
        Rectangle {
            width: Math.max(track.height, track.width * root.share)
            height: track.height
            radius: track.radius
            color: PrismTheme.solid
            opacity: root.share > 0 ? 1 : 0.0
            Behavior on width { enabled: !root.held; NumberAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
        }
    }
    // Ink that crosses the fill flips with it: one copy clipped to the fill, one to the rest.
    Item {
        id: inkOn
        width: Math.max(track.height, track.width * root.share)
        height: root.height
        clip: true
        PrismGlyph { x: PrismTheme.dp(10); anchors.verticalCenter: parent.verticalCenter; text: root.glyph; iconSize: PrismTheme.dp(16); filled: true; color: PrismTheme.inkSolid; visible: root.glyph.length > 0 }
        PrismText { x: root.width - width - PrismTheme.dp(12); anchors.verticalCenter: parent.verticalCenter; text: root.label; figures: true; font.weight: Font.DemiBold; color: PrismTheme.inkSolid; font.pixelSize: PrismTheme.small }
    }
    Item {
        x: inkOn.width
        width: root.width - x
        height: root.height
        clip: true
        PrismGlyph { x: PrismTheme.dp(10) - parent.x; anchors.verticalCenter: parent.verticalCenter; text: root.glyph; iconSize: PrismTheme.dp(16); filled: true; color: PrismTheme.ink2; visible: root.glyph.length > 0 }
        PrismText { x: root.width - width - PrismTheme.dp(12) - parent.x; anchors.verticalCenter: parent.verticalCenter; text: root.label; figures: true; font.weight: Font.DemiBold; color: PrismTheme.ink; font.pixelSize: PrismTheme.small }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => { root.settle(); root.held = true; root.live = root.at(mouse.x); root.moved(root.live) }
        onContainsMouseChanged: { area.lastScene = Qt.point(-1, -1); if (!area.containsMouse) root.settle() }
        onPositionChanged: mouse => {
            // Rows scrolled under a still pointer leave its place on screen unchanged; only a hand moves it.
            const scene = area.mapToItem(null, mouse.x, mouse.y)
            if (area.lastScene.x >= 0 && Math.abs(scene.x - area.lastScene.x) + Math.abs(scene.y - area.lastScene.y) > 4) area.aimedAt = Date.now()
            area.lastScene = scene
            if (!pressed) return
            const next = root.at(mouse.x)
            if (next !== root.live) { root.live = next; root.moved(next) }
        }
        onReleased: { root.held = false; root.committed(root.live) }
        onCanceled: { root.held = false; root.live = root.value }
        // A wheel belongs to the page while the page scrolls: the level takes it only once the pointer was moved onto
        // it after the last scroll (intent from the hand, not from where the rows landed), and never while the page is
        // still moving (a hand's tremor mid-scroll is not aim). 120 is one notch (Qt's angleDelta, 1/8 degree).
        property real aimedAt: 0
        property point lastScene: Qt.point(-1, -1)
        property real wheelAcc: 0
        property bool wheelMoved: false
        onWheel: wheel => {
            if (!root.wheeling && (area.aimedAt <= PrismState.scrolledAt || Date.now() - PrismState.scrolledAt < 400)) { wheel.accepted = false; return }
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
