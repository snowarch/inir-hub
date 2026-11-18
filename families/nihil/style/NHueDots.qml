import QtQuick

// A hue picked off a line of dots, each in its own colour, the chosen one larger. Drag, wheel or arrow keys.
Canvas {
    id: root

    property real hue: 0
    property string name: ""
    signal moved(real degrees)
    signal released(real degrees)

    readonly property int count: Math.max(12, Math.floor(width / NihilStyle.s(13)))
    readonly property real pitch: (width - height) / (root.count - 1)
    readonly property int at: Math.round(NihilStyle.clamp(root.hue, 0, 360) / 360 * (root.count - 1))
    readonly property real strength: NihilStyle.vividness
    readonly property bool darkScheme: NihilStyle.dark
    readonly property bool squareDots: NihilStyle.squareDots

    implicitWidth: NihilStyle.s(300)
    implicitHeight: NihilStyle.s(26)
    renderStrategy: Canvas.Cooperative
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: root.name

    onAtChanged: requestPaint()
    onCountChanged: requestPaint()
    onStrengthChanged: requestPaint()
    onDarkSchemeChanged: requestPaint()
    onSquareDotsChanged: requestPaint()
    onWidthChanged: requestPaint()

    function degreesAt(index: int): real { return Math.round(NihilStyle.clamp(index, 0, root.count - 1) / (root.count - 1) * 360) }
    function step(by: int): void { const next = root.degreesAt(root.at + by); root.moved(next); root.released(next) }
    Keys.onLeftPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        for (let i = 0; i < root.count; ++i) {
            const big = i === root.at
            const r = big ? height / 2 : height * 0.2
            const cx = height / 2 + i * root.pitch
            ctx.fillStyle = NihilStyle.hueColor(i / (root.count - 1) * 360)
            ctx.beginPath()
            if (root.squareDots) ctx.rect(cx - r, height / 2 - r, r * 2, r * 2)
            else ctx.arc(cx, height / 2, r, 0, Math.PI * 2)
            ctx.fill()
        }
    }

    NFocus { shown: root.activeFocus; radius: NihilStyle.s(8) }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        property real last: root.hue
        function pick(px: real): void {
            last = root.degreesAt(Math.round((px - root.height / 2) / root.pitch))
            root.moved(last)
        }
        onPressed: event => pick(event.x)
        onPositionChanged: event => { if (pressed) pick(event.x) }
        onReleased: root.released(last)
        onWheel: event => root.step(event.angleDelta.y > 0 ? 1 : -1)
    }
}
