pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// A display change waiting for Keep, at the Settings sheet's foot: one black card that grows from a point, its
// countdown drawn as a ring, Revert and Keep. A change made in Settings says nothing here (his 11-07: the capsule
// with Undo on every change was in the way; a row's arrow puts its default back, Ctrl+Z still takes a change back).
Item {
    id: root

    property real d: IrisStyle.settingsDensity
    // The width it may take (the sheet's).
    property real room: 600
    // Kept off while another sheet covers the body (Home's editor).
    property bool allowed: true
    function u(n: real): int { return Math.round(n * root.d) }

    readonly property var pending: CompositorConfig.pending
    readonly property string mode: root.allowed && root.pending ? "display" : ""
    readonly property bool shown: root.mode.length > 0

    // ── What the expanded island says: a display change and the way back.
    readonly property string displayWhat: {
        const key = String(root.pending?.key ?? "")
        return key === "mode" ? Translation.tr("Resolution") : key === "scale" ? Translation.tr("Scale")
            : key === "transform" ? Translation.tr("Rotation") : key === "vrr" ? Translation.tr("Variable refresh rate") : ""
    }
    function displayWord(value: string): string {
        const key = String(root.pending?.key ?? "")
        if (key === "mode") {
            const parts = value.split("@")
            const rate = parseFloat(parts[1] ?? "")
            return parts[0].replace("x", "×") + (Number.isFinite(rate) ? " · " + Math.round(rate) + " Hz" : "")
        }
        if (key === "scale") return Number(value).toFixed(2).replace(/0$/, "").replace(/\.0$/, "") + "×"
        if (key === "transform") return /^\d+$/.test(value) ? value + "°" : value === "normal" ? "0°" : value
        if (key === "vrr") return value === "off" ? Translation.tr("Off") : Translation.tr("On")
        return value
    }

    // ── The shape. Growing takes the emerge spring (it overshoots a little, as the Island does opening); shrinking the
    // recede one (critically damped: it settles without a bounce). Set together so the curve is picked before it moves.
    readonly property int compactHeight: root.u(44)
    readonly property int expandedHeight: root.u(118)
    // The question is never cut: a long language widens the island up to the room it has.
    readonly property real wantedW: root.mode === "display" ? Math.min(root.room - root.u(32), Math.max(root.u(452), displayFace.needs))
        : root.compactHeight
    readonly property real wantedH: root.mode === "display" ? root.expandedHeight : root.compactHeight
    property real goalW: root.compactHeight
    property real goalH: root.compactHeight
    property bool growing: true
    function reshape(): void {
        const w = Math.ceil(root.wantedW), h = Math.ceil(root.wantedH)
        root.growing = w * h >= root.goalW * root.goalH
        root.goalW = w
        root.goalH = h
    }
    onWantedWChanged: root.reshape()
    onWantedHChanged: root.reshape()
    onModeChanged: root.reshape()
    readonly property int springTime: root.growing ? IrisStyle.emergeDuration : IrisStyle.recedeDuration
    readonly property var springCurve: root.growing ? IrisStyle.emergeCurve : IrisStyle.recedeCurve

    width: plate.width
    height: plate.height
    visible: plate.opacity > 0.01

    IrisBodyShadow {
        anchors.fill: plate
        radius: plate.radius
        offset.y: root.u(8)
        blur: root.u(26)
        spread: 0
        color: IrisStyle.liveIslandShadow
        opacity: plate.opacity
        scale: plate.scale
    }
    Rectangle {
        id: plate
        width: root.goalW
        height: root.goalH
        radius: root.mode === "display" ? root.u(30) : height / 2
        color: IrisStyle.liveIsland
        antialiasing: true
        // From a point and back into one: the plate is a dot when it has nothing to say.
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.4
        Behavior on width { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on height { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on radius { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(root.shown ? 120 : 200); easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: root.shown ? IrisStyle.emergeDuration : IrisStyle.recedeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.shown ? IrisStyle.emergeCurve : IrisStyle.recedeCurve } }
        clip: true

        // ── A display change waiting: its mark and words at the top, the answers under them.
        Item {
            id: displayFace
            readonly property int pad: root.u(14)
            // Mark, the question, the ring: what the face needs to say it whole.
            readonly property real needs: 2 * displayFace.pad + root.u(36 + 12 + 12 + 36) + Math.ceil(question.implicitWidth)
            width: Math.min(root.room - root.u(32), Math.max(root.u(452), displayFace.needs))
            height: root.expandedHeight
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.mode === "display" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: root.mode === "display" ? Math.round(root.springTime * 0.26) : 0 }
                    NumberAnimation { duration: IrisStyle.duration(root.mode === "display" ? 190 : 90); easing.type: IrisStyle.feedbackEasing }
                }
            }
            IrisSquircle {
                id: displayMark
                x: displayFace.pad
                y: displayFace.pad + root.u(2)
                width: root.u(36)
                height: width
                plain: false
                tint: IrisStyle.identity.blue
                glyph: "monitor"
            }
            Column {
                anchors.left: displayMark.right
                anchors.leftMargin: root.u(12)
                anchors.right: ring.left
                anchors.rightMargin: root.u(12)
                anchors.verticalCenter: displayMark.verticalCenter
                spacing: root.u(1)
                IrisText {
                    id: question
                    width: parent.width
                    text: Translation.tr("Keep this display setting?")
                    color: IrisStyle.liveIslandInk
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                Row {
                    width: parent.width
                    spacing: root.u(6)
                    IrisText {
                        text: root.displayWhat
                        color: IrisStyle.liveIslandQuiet
                        font.pixelSize: IrisStyle.typeLabel
                    }
                    IrisText {
                        text: root.pending ? root.displayWord(String(root.pending.previous)) : ""
                        color: IrisStyle.liveIslandQuiet
                        font.pixelSize: IrisStyle.typeLabel
                        font.strikeout: true
                        font.features: { "tnum": 1 }
                    }
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "arrow_forward"
                        iconSize: root.u(14)
                        color: IrisStyle.liveIslandQuiet
                    }
                    IrisText {
                        text: root.pending ? root.displayWord(String(root.pending.value)) : ""
                        color: IrisStyle.liveIslandHue(IrisStyle.identity.blue)
                        font.pixelSize: IrisStyle.typeLabel
                        font.weight: IrisStyle.weight(Font.Bold)
                        font.features: { "tnum": 1 }
                    }
                }
            }
            // The seconds left, drawn: a ring that empties as they go, the figure rolling inside it.
            Item {
                id: ring
                anchors.right: parent.right
                anchors.rightMargin: displayFace.pad
                anchors.verticalCenter: displayMark.verticalCenter
                width: root.u(36)
                height: width
                readonly property real stroke: Math.max(2, root.u(3))
                property real level: root.pending ? CompositorConfig.secondsLeft / Math.max(1, CompositorConfig.revertAfter) : 1
                // The ring steps with the figure it rings, each second a short settle, as a watch's seconds hand.
                Behavior on level { NumberAnimation { duration: IrisStyle.duration(360); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve } }
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: IrisStyle.liveIslandKey
                        strokeWidth: ring.stroke
                        fillColor: "transparent"
                        PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: ring.width / 2 - ring.stroke / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 }
                    }
                    ShapePath {
                        strokeColor: IrisStyle.liveIslandHue(IrisStyle.identity.blue)
                        strokeWidth: ring.stroke
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: ring.width / 2; centerY: ring.height / 2; radiusX: ring.width / 2 - ring.stroke / 2; radiusY: radiusX; startAngle: -90; sweepAngle: 360 * Math.max(0, Math.min(1, ring.level)) }
                    }
                }
                IrisNumber {
                    anchors.centerIn: parent
                    text: String(CompositorConfig.secondsLeft)
                    pixelSize: IrisStyle.typeLabel
                    weight: IrisStyle.weight(Font.Bold)
                    color: IrisStyle.liveIslandInk
                    countDown: true
                }
                Accessible.role: Accessible.StaticText
                Accessible.name: Translation.tr("Keep this display setting? It goes back in %1 s.").arg(CompositorConfig.secondsLeft)
            }
            Row {
                id: answers
                x: displayFace.pad
                anchors.bottom: parent.bottom
                anchors.bottomMargin: displayFace.pad
                spacing: root.u(8)
                readonly property real each: Math.floor((displayFace.width - 2 * displayFace.pad - answers.spacing) / 2)
                Repeater {
                    model: [{ name: Translation.tr("Revert"), keep: false }, { name: Translation.tr("Keep"), keep: true }]
                    delegate: Rectangle {
                        id: answer
                        required property var modelData
                        width: answers.each
                        height: root.u(36)
                        // Concentric with the card: its radius less the air round it.
                        radius: height / 2
                        color: answer.modelData.keep ? (answerArea.containsMouse ? Qt.rgba(1, 1, 1, 0.86) : IrisStyle.liveIslandInk) // iris-literal: Keep on the black, hovered
                            : answerArea.containsMouse ? IrisStyle.liveIslandKeyHover : IrisStyle.liveIslandKey
                        scale: answerArea.pressed ? IrisStyle.pressScale(0.96) : 1
                        Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                        IrisText {
                            anchors.centerIn: parent
                            text: answer.modelData.name
                            color: answer.modelData.keep ? IrisStyle.liveIsland : IrisStyle.liveIslandInk
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(Font.DemiBold)
                        }
                        MouseArea {
                            id: answerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: answer.modelData.keep ? CompositorConfig.keepDisplay() : CompositorConfig.revertDisplay()
                        }
                        Accessible.role: Accessible.Button
                        Accessible.name: answer.modelData.name
                    }
                }
            }
        }
    }

    Accessible.role: Accessible.AlertMessage
    Accessible.name: Translation.tr("Keep this display setting?")
}
