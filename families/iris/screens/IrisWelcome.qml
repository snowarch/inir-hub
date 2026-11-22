pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

// iRiS's welcome at startup: on the dark, the ring of its mark draws itself round a glow of the accent and says good
// morning; then its pupil opens like a camera's iris, seven blades turning back off the desktop, the ring riding the
// opening out. A key or a click opens it at once.
Scope {
    id: root

    property real veil: 0   // the dark coming in over the desktop
    property real ring: 0   // how much of the ring is drawn
    property real words: 0  // the greeting
    property real open: 0   // 0 shut, 1 the desktop whole
    property bool leaving: false
    readonly property int blades: 7

    readonly property string greeting: {
        const hour = new Date().getHours()
        if (hour < 6) return Translation.tr("Good night")
        if (hour < 12) return Translation.tr("Good morning")
        if (hour < 18) return Translation.tr("Good afternoon")
        return Translation.tr("Good evening")
    }
    readonly property string name: SystemInfo.displayName || SystemInfo.username

    function openUp(): void {
        if (root.leaving)
            return
        root.leaving = true
        timeline.stop()
        opening.start()
    }

    SequentialAnimation {
        id: timeline
        running: true
        NumberAnimation { target: root; property: "veil"; to: 1; duration: IrisStyle.duration(220); easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "ring"; to: 1; duration: IrisStyle.duration(820); easing.type: Easing.InOutCubic }
            SequentialAnimation {
                PauseAnimation { duration: IrisStyle.duration(380) }
                NumberAnimation { target: root; property: "words"; to: 1; duration: IrisStyle.duration(560); easing.type: Easing.OutCubic }
            }
        }
        PauseAnimation { duration: 900 }
        ScriptAction { script: root.openUp() }
    }

    SequentialAnimation {
        id: opening
        ParallelAnimation {
            NumberAnimation { target: root; property: "veil"; to: 1; duration: IrisStyle.duration(120) }
            NumberAnimation { target: root; property: "ring"; to: 1; duration: IrisStyle.duration(160) }
            NumberAnimation { target: root; property: "words"; to: 0; duration: IrisStyle.duration(180); easing.type: Easing.InCubic }
            NumberAnimation {
                target: root
                property: "open"
                to: 1
                // Slow to give, quick through the middle, settling as the last blade leaves the screen.
                duration: IrisStyle.duration(1000)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: [0.6, 0, 0.2, 1, 1, 1]
            }
        }
        ScriptAction {
            script: {
                GlobalStates.bootGreetingOpen = false
                GlobalStates.bootGreetingDone = true
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool primary: (win.modelData?.name ?? "") === (GlobalStates.primaryScreen?.name ?? "")

            screen: win.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; bottom: true; left: true; right: true }
            WlrLayershell.namespace: "quickshell:boot-greeting"
            WlrLayershell.layer: WlrLayer.Overlay
            // iris-menus: none. A greeting and its keys, no menu.
            WlrLayershell.keyboardFocus: win.primary && !root.leaving && !PolkitService.active
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            // Opening, the desktop under it takes clicks already.
            mask: Region { item: root.leaving ? null : shade }

            Item {
                id: shade
                anchors.fill: parent
                opacity: root.veil

                readonly property real diag: Math.hypot(shade.width, shade.height)
                readonly property real mark: Math.round(Math.min(shade.width, shade.height) * 0.075)
                readonly property real cx: shade.width / 2
                readonly property real cy: shade.height / 2 - (win.primary ? shade.mark * 0.6 : 0)
                readonly property real stroke: Math.max(2, Math.round(shade.mark * 0.09))
                readonly property real pupil: shade.mark * 0.21
                // The aperture: from the pupil out past every corner, its blades turning as they open.
                readonly property real reach: root.open <= 0 ? 0 : shade.pupil + (shade.diag / 2 + shade.mark - shade.pupil) * root.open
                readonly property real rim: shade.reach / Math.cos(Math.PI / root.blades)
                readonly property real turn: (root.open * 64 - 90) * Math.PI / 180
                readonly property var corners: {
                    if (shade.reach <= 0)
                        return []
                    const out = []
                    for (let k = 0; k <= root.blades; k++) {
                        const a = shade.turn + k * 2 * Math.PI / root.blades
                        out.push(Qt.point(shade.cx + shade.rim * Math.cos(a), shade.cy + shade.rim * Math.sin(a)))
                    }
                    return out
                }
                // Each blade's straight edge runs on past the corner it makes, to the rim of the lens.
                readonly property var seams: {
                    const out = []
                    for (let k = 0; k + 1 < shade.corners.length; k++) {
                        const from = shade.corners[k], to = shade.corners[k + 1]
                        const len = Math.hypot(to.x - from.x, to.y - from.y) || 1
                        out.push([to, Qt.point(to.x + (to.x - from.x) / len * shade.diag, to.y + (to.y - from.y) / len * shade.diag)])
                    }
                    return out
                }

                // The dark, with the iris cut out of it once it opens.
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: -1
                        fillColor: IrisStyle.surfaceOpaque
                        fillRule: ShapePath.OddEvenFill
                        PathPolyline {
                            path: [Qt.point(-2, -2), Qt.point(shade.width + 2, -2), Qt.point(shade.width + 2, shade.height + 2),
                                Qt.point(-2, shade.height + 2), Qt.point(-2, -2)]
                        }
                        PathPolyline { path: shade.corners }
                    }
                    // The blades' seams, faint, there only while they move.
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Qt.alpha(IrisStyle.text, 0.12 * Math.min(1, root.open * 8) * (1 - root.open))
                        strokeWidth: 1
                        PathMultiline { paths: shade.seams }
                    }
                    // Light catching the blades' edges round the opening.
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: Qt.alpha(IrisStyle.accent, 0.55 * (1 - root.open))
                        strokeWidth: 1.5
                        joinStyle: ShapePath.MiterJoin
                        PathPolyline { path: shade.corners }
                    }
                }

                // The glow the mark rises in; it widens and goes as the iris opens.
                Shape {
                    readonly property real size: shade.mark * 7 * (1 + root.open * 2)
                    x: shade.cx - size / 2
                    y: shade.cy - size / 2
                    width: size
                    height: size
                    opacity: root.ring * Math.pow(1 - root.open, 2)
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: -1
                        fillGradient: RadialGradient {
                            centerX: shade.mark * 3.5 * (1 + root.open * 2); centerY: centerX
                            focalX: centerX; focalY: centerY
                            centerRadius: centerX
                            GradientStop { position: 0; color: Qt.alpha(IrisStyle.accent, 0.26) }
                            GradientStop { position: 0.4; color: Qt.alpha(IrisStyle.accent, 0.09) }
                            GradientStop { position: 1; color: Qt.alpha(IrisStyle.accent, 0) }
                        }
                        PathRectangle { width: shade.mark * 7 * (1 + root.open * 2); height: width }
                    }
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: Math.max(0, 1 - root.open * 1.6)
                    // The ring's track, faint, so the light has a path to draw.
                    ShapePath {
                        strokeColor: Qt.alpha(IrisStyle.accent, 0.16 * Math.min(1, root.ring * 4))
                        strokeWidth: shade.stroke
                        fillColor: "transparent"
                        PathAngleArc {
                            centerX: shade.cx
                            centerY: shade.cy
                            radiusX: Math.max(shade.mark, shade.rim)
                            radiusY: radiusX
                            startAngle: -90
                            sweepAngle: 360
                        }
                    }
                    ShapePath {
                        strokeColor: IrisStyle.accent
                        strokeWidth: shade.stroke
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathAngleArc {
                            centerX: shade.cx
                            centerY: shade.cy
                            radiusX: Math.max(shade.mark, shade.rim)
                            radiusY: radiusX
                            startAngle: -90
                            sweepAngle: 360 * root.ring
                        }
                    }
                }

                // The head of the light as it draws: a brighter bead that settles into the ring once it closes.
                Rectangle {
                    readonly property real angle: (-90 + 360 * root.ring) * Math.PI / 180
                    width: shade.stroke * 2.2
                    height: width
                    radius: width / 2
                    x: shade.cx + shade.mark * Math.cos(angle) - width / 2
                    y: shade.cy + shade.mark * Math.sin(angle) - height / 2
                    color: Qt.lighter(IrisStyle.accent, 1.35)
                    opacity: root.ring > 0 && root.ring < 1 ? Math.min(1, root.ring * 6) * Math.min(1, (1 - root.ring) * 6) : 0
                }

                // The pupil, there once the ring closes; the iris opens from it.
                Rectangle {
                    width: shade.pupil * 2
                    height: width
                    radius: width / 2
                    x: shade.cx - width / 2
                    y: shade.cy - height / 2
                    color: IrisStyle.accent
                    scale: Math.max(0, (root.ring - 0.6) / 0.4)
                    opacity: Math.max(0, 1 - root.open * 14)
                }

                Column {
                    visible: win.primary
                    x: Math.round(shade.cx - width / 2)
                    y: Math.round(shade.cy + shade.mark + 40)
                    spacing: 6
                    opacity: root.words
                    transform: Translate { y: Math.round((1 - root.words) * 14) }

                    IrisText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        role: IrisText.Title
                        font.pixelSize: IrisStyle.typeDotM
                        // The words close up as they arrive.
                        font.letterSpacing: (1 - root.words) * 6
                        tone: IrisStyle.text
                        text: root.greeting
                    }
                    IrisText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.name.length > 0
                        role: IrisText.Body
                        opacity: Math.max(0, root.words * 1.6 - 0.6)
                        tone: IrisStyle.textSecondary
                        text: root.name
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.openUp()
                }
                Item {
                    anchors.fill: parent
                    focus: win.primary && !root.leaving
                    Keys.onPressed: event => {
                        event.accepted = true
                        root.openUp()
                    }
                }
            }
        }
    }
}
