pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Windows › Effects, where the compositor draws effects of its own: the screen with its wallpaper, a
// window, that window's border and the pointer, each wearing what it has on. A press opens that part's choices under
// the screen; the pick lands at once on the real screen and the drawing wears it too.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property var parts: [
        { key: "screen", name: Translation.tr("Screen") },
        { key: "window", name: Translation.tr("Windows") },
        { key: "border", name: Translation.tr("Border") },
        { key: "cursor", name: Translation.tr("Pointer") }
    ].filter(part => CompositorConfig.has("effects", part.key))
    // The part whose choices are open, and the one under the pointer; "" is none.
    property string open: ""
    property string hovered: ""
    readonly property var openPart: root.parts.find(part => part.key === root.open) ?? null
    onOpenChanged: if (root.open.length > 0) followSoon.restart()
    // The choices open under the screen; on a short window that is under the fold, so the page follows them down.
    Timer {
        id: followSoon
        interval: 60
        onTriggered: {
            let view = root.parent
            while (view && !(view instanceof Flickable)) view = view.parent
            if (!view) return
            const foot = root.mapToItem(view.contentItem, 0, root.height).y + Math.round(24 * root.d)
            const to = Math.min(foot - view.height, Math.max(0, view.contentHeight - view.height))
            if (to <= view.contentY) return
            follow.target = view
            follow.to = to
            follow.restart()
        }
    }
    NumberAnimation { id: follow; property: "contentY"; duration: 260; easing.type: Easing.OutCubic }

    function worn(key: string): string { return String(CompositorConfig.value({ comp: "effects", key: key, fallback: "" })) }
    function choicesOf(key: string): var { return CompositorConfig.choicesFor({ comp: "effects", key: key }) }
    function entryOf(key: string): var {
        const now = root.worn(key)
        return root.choicesOf(key).find(choice => String(choice.value) === now) ?? { label: now, value: now }
    }
    function toggle(key: string): void { root.open = root.open === key ? "" : key }
    readonly property bool has: root.parts.length > 0
    readonly property real aspect: {
        const rect = CompositorConfig.output ? CompositorConfig.logicalRect(CompositorConfig.output) : null
        return rect && rect.width > 0 && rect.height > 0 ? Math.max(1.2, Math.min(2.4, rect.width / rect.height)) : 16 / 9
    }

    spacing: Math.round(10 * root.d)

    Rectangle {
        id: desk
        width: root.width
        height: Math.round(Math.max(220, Math.min(330, root.width * 0.42)) * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fill

        Rectangle {
            id: bezel
            anchors.centerIn: parent
            height: desk.height - Math.round(36 * root.d)
            width: Math.min(desk.width - Math.round(36 * root.d), Math.round(bezel.height * root.aspect))
            radius: Math.round(7 * root.d) // iris-literal: a drawn monitor's bezel, not a shell surface
            color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme

            Item {
                id: glass
                anchors.fill: parent
                anchors.margins: Math.max(2, Math.round(3 * root.d))
                clip: true

                Image {
                    anchors.fill: parent
                    source: Wallpapers.effectiveWallpaperUrl
                    sourceSize.width: Math.round(480 * root.d)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: "#0b0b0c" // iris-literal: a screen turned down, the bezel's own black
                    opacity: root.hovered === "screen" || root.open === "screen" ? 0.18 : 0.3
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.parts.some(part => part.key === "screen")
                    onContainsMouseChanged: root.hovered = containsMouse ? "screen" : root.hovered === "screen" ? "" : root.hovered
                    onClicked: root.toggle("screen")
                }

                // The window, its border band around it: a press on the edge is the border's, inside it the window's.
                Item {
                    id: window
                    x: Math.round(glass.width * 0.14)
                    y: Math.round(glass.height * 0.16)
                    width: Math.round(glass.width * 0.52)
                    height: Math.round(glass.height * 0.62)

                    // Pulse: a lit ring in the accent with its light around it.
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Math.round(7 * root.d)
                        radius: frame.radius + Math.round(7 * root.d)
                        color: "transparent"
                        border.width: Math.round(5 * root.d)
                        border.color: IrisStyle.accent
                        opacity: root.worn("border").length > 0 ? 0.28 : 0
                    }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -Math.round(2 * root.d)
                        radius: frame.radius + Math.round(2 * root.d)
                        color: "transparent"
                        border.width: Math.round(2 * root.d)
                        border.color: IrisStyle.accent
                        opacity: root.worn("border").length > 0 ? 1 : 0
                    }
                    Rectangle {
                        id: frame
                        anchors.fill: parent
                        radius: Math.round(6 * root.d) // iris-literal: a drawn window's corner, not a shell surface
                        color: IrisStyle.surfaceHighOpaque // an app window is opaque, whatever glass the shell wears
                        border.width: 1
                        border.color: root.hovered === "border" || root.open === "border" ? IrisStyle.accent : IrisStyle.hairline
                        clip: true
                        Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        // The window answers the pointer with its own light, the way a raised window does.
                        Rectangle {
                            anchors.fill: parent
                            color: IrisStyle.fillHover
                            opacity: root.hovered === "window" || root.open === "window" ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        }
                        Column {
                            x: Math.round(10 * root.d)
                            y: Math.round(10 * root.d)
                            spacing: Math.round(6 * root.d)
                            Rectangle { width: Math.round(frame.width * 0.42); height: Math.round(5 * root.d); radius: IrisStyle.capsule(height); color: IrisStyle.text }
                            Rectangle { width: Math.round(frame.width * 0.7); height: Math.round(4 * root.d); radius: IrisStyle.capsule(height); color: IrisStyle.textTertiary }
                            Rectangle { width: Math.round(frame.width * 0.56); height: Math.round(4 * root.d); radius: IrisStyle.capsule(height); color: IrisStyle.textTertiary }
                        }
                        // Scanlines: an old screen's lines across the window.
                        Column {
                            visible: root.worn("window") === "scanlines"
                            anchors.fill: parent
                            spacing: Math.max(2, Math.round(2 * root.d))
                            Repeater {
                                model: Math.ceil(frame.height / Math.max(3, Math.round(3 * root.d)))
                                Rectangle { width: frame.width; height: 1; color: "#000000"; opacity: 0.32 } // iris-literal: the scanline's own black
                            }
                        }
                    }
                    MouseArea {
                        readonly property real band: Math.round(9 * root.d)
                        anchors.fill: parent
                        anchors.margins: -band
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        function partAt(x: real, y: real): string {
                            const edge = Math.min(x, y, width - x, height - y)
                            return edge < band * 2 && root.parts.some(part => part.key === "border") ? "border" : "window"
                        }
                        onPositionChanged: mouse => root.hovered = partAt(mouse.x, mouse.y)
                        onExited: if (root.hovered === "window" || root.hovered === "border") root.hovered = ""
                        onClicked: mouse => root.toggle(partAt(mouse.x, mouse.y))
                    }
                }

                // Vignette: the screen's edges fall into shade.
                Item {
                    anchors.fill: parent
                    visible: root.worn("screen") === "vignette"
                    Rectangle { width: parent.width; height: parent.height * 0.3; gradient: Gradient { GradientStop { position: 0; color: "#b0000000" } GradientStop { position: 1; color: "#00000000" } } } // iris-literal: shade
                    Rectangle { y: parent.height * 0.7; width: parent.width; height: parent.height * 0.3; gradient: Gradient { GradientStop { position: 0; color: "#00000000" } GradientStop { position: 1; color: "#b0000000" } } } // iris-literal: shade
                    Rectangle { width: parent.width * 0.22; height: parent.height; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#a0000000" } GradientStop { position: 1; color: "#00000000" } } } // iris-literal: shade
                    Rectangle { x: parent.width * 0.78; width: parent.width * 0.22; height: parent.height; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "#00000000" } GradientStop { position: 1; color: "#a0000000" } } } // iris-literal: shade
                }

                // The pointer and what follows it.
                Item {
                    id: pointer
                    readonly property string wearing: root.worn("cursor")
                    readonly property real glowSize: Math.round(76 * root.d)
                    x: Math.round(glass.width * 0.78)
                    y: Math.round(glass.height * 0.6)
                    width: Math.round(18 * root.d)
                    height: width
                    // Glow: light in the accent, fading as it spreads.
                    Shape {
                        visible: pointer.wearing === "glow"
                        x: Math.round(4 * root.d) - pointer.glowSize / 2
                        y: Math.round(4 * root.d) - pointer.glowSize / 2
                        width: pointer.glowSize
                        height: pointer.glowSize
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: pointer.glowSize / 2; centerY: pointer.glowSize / 2; centerRadius: pointer.glowSize / 2
                                focalX: pointer.glowSize / 2; focalY: pointer.glowSize / 2
                                GradientStop { position: 0; color: Qt.rgba(IrisStyle.accent.r, IrisStyle.accent.g, IrisStyle.accent.b, 0.62) }
                                GradientStop { position: 0.45; color: Qt.rgba(IrisStyle.accent.r, IrisStyle.accent.g, IrisStyle.accent.b, 0.22) }
                                GradientStop { position: 1; color: Qt.rgba(IrisStyle.accent.r, IrisStyle.accent.g, IrisStyle.accent.b, 0) }
                            }
                            PathAngleArc { centerX: pointer.glowSize / 2; centerY: pointer.glowSize / 2; radiusX: pointer.glowSize / 2; radiusY: pointer.glowSize / 2; startAngle: 0; sweepAngle: 360 }
                        }
                    }
                    Repeater {
                        // Trail: the preset's own violet to gold, smaller and fainter behind; the long one curves away.
                        model: pointer.wearing === "trail" ? 6 : pointer.wearing === "trail-path" ? 12 : 0
                        Rectangle {
                            required property int index
                            readonly property bool long: pointer.wearing === "trail-path"
                            readonly property real step: index + 1
                            readonly property real size: Math.max(2, Math.round((long ? 7 - index * 0.4 : 8 - index) * root.d))
                            x: Math.round(4 * root.d) - step * Math.round((long ? 9 : 7) * root.d) - size / 2
                            y: Math.round(4 * root.d) - step * Math.round((long ? 3 : 5) * root.d) + (long ? Math.pow(step, 2) * 0.55 * root.d : 0) - size / 2
                            width: size
                            height: size
                            radius: size / 2
                            color: Qt.tint("#9a7bff", Qt.rgba(1, 0.83, 0.4, index / (long ? 12 : 6))) // iris-literal: the shipped trail's fixed violet and gold
                            opacity: 1 - index / (long ? 13 : 7)
                        }
                    }
                    MaterialSymbol {
                        text: "arrow_selector_tool"
                        iconSize: Math.round(20 * root.d)
                        fill: 1
                        color: "#ffffff" // iris-literal: the pointer is white over any wallpaper
                        style: Text.Outline // a pointer's black outline, as the real one wears
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Math.round(14 * root.d)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.parts.some(part => part.key === "cursor")
                        onContainsMouseChanged: root.hovered = containsMouse ? "cursor" : root.hovered === "cursor" ? "" : root.hovered
                        onClicked: root.toggle("cursor")
                    }
                }

                // Each part names what it wears, where it is: lit in the accent once it wears something.
                Repeater {
                    model: root.parts.length
                    Rectangle {
                        id: tag
                        required property int index
                        readonly property var part: root.parts[tag.index]
                        readonly property var entry: root.entryOf(tag.part.key)
                        readonly property bool used: String(tag.entry.value).length > 0
                        readonly property bool lit: root.open === tag.part.key || root.hovered === tag.part.key || tap.containsMouse || tag.activeFocus
                        readonly property point at: tag.part.key === "screen" ? Qt.point(Math.round(10 * root.d), Math.round(10 * root.d))
                            : tag.part.key === "window" ? Qt.point(window.x + Math.round(10 * root.d), window.y + window.height - tag.height - Math.round(10 * root.d))
                            : tag.part.key === "border" ? Qt.point(window.x + window.width - tag.width / 2, window.y + Math.round(window.height * 0.3))
                            : Qt.point(pointer.x + Math.round(22 * root.d), pointer.y + Math.round(16 * root.d))
                        x: Math.min(glass.width - tag.width - Math.round(6 * root.d), tag.at.x)
                        y: tag.at.y
                        z: 4
                        width: words.implicitWidth + Math.round(18 * root.d)
                        height: Math.round(24 * root.d)
                        radius: IrisStyle.capsule(height)
                        color: tag.used ? IrisStyle.accent : "#0b0b0c" // iris-literal: an idle tag is the screen's own dark
                        opacity: tag.used || tag.lit ? 1 : 0.72
                        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                        Behavior on color { ColorAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }

                        activeFocusOnTab: true
                        Accessible.role: Accessible.Button
                        Accessible.name: tag.part.name + ", " + Translation.tr(String(tag.entry.label))
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.toggle(tag.part.key)
                                event.accepted = true
                            } else if (event.key === Qt.Key_Escape && root.open === tag.part.key) {
                                root.open = ""
                                event.accepted = true
                            }
                        }
                        IrisText {
                            id: words
                            anchors.centerIn: parent
                            text: tag.used ? Translation.tr(String(tag.entry.label)) : tag.part.name
                            color: tag.used ? IrisStyle.inkOnAccent : "#ffffff" // iris-literal: a name over a wallpaper turned down
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(tag.used ? Font.DemiBold : Font.Medium)
                        }
                        MouseArea {
                            id: tap
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { tag.forceActiveFocus(); root.toggle(tag.part.key) }
                        }
                    }
                }
            }
        }
    }

    IrisText {
        width: root.width
        visible: root.openPart === null
        text: Translation.tr("Press the screen, a window, its border or the pointer to choose what the compositor draws on it.")
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeFootnote
        wrapMode: Text.WordWrap
    }

    Column {
        width: root.width
        visible: root.openPart !== null
        spacing: Math.round(6 * root.d)
        IrisText {
            width: parent.width
            text: root.openPart?.name ?? ""
            font.pixelSize: IrisStyle.typeBody
            font.weight: IrisStyle.weight(Font.DemiBold)
            elide: Text.ElideRight
        }
        Loader {
            width: parent.width
            active: root.openPart !== null
            sourceComponent: IrisChoiceGrid {
                options: root.choicesOf(root.open)
                current: root.worn(root.open)
                accessibleName: root.openPart?.name ?? ""
                onPicked: value => CompositorConfig.set({ comp: "effects", key: root.open }, value)
                onDismissed: root.open = ""
            }
        }
        IrisText {
            width: parent.width
            readonly property string said: String(root.entryOf(root.open).detail ?? "")
            visible: said.length > 0
            text: Translation.tr(said)
            color: IrisStyle.subtext
            font.pixelSize: IrisStyle.typeFootnote
            wrapMode: Text.WordWrap
        }
    }
}
