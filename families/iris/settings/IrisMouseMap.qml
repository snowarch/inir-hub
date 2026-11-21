pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import "IrisBinds.js" as IrisBinds

// Settings › Mouse: the mouse drawn from above, each part saying what it does. Plain, it says what the buttons and the
// wheel do with the person's settings: left-handed swaps the buttons, natural scrolling turns the wheel, the middle
// click pastes or not, both buttons click the middle one. A layer of modifiers says what each part does with them: the
// binds of Niri or Umbriel, and under Niri the drags built into Mod (move, resize, move the view). A real press or roll
// over the drawing lights its part; the wheel still scrolls the page.
Column {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity

    // ── The person's settings, as Settings reads them ────────────────────────────────────────────────────────────────
    function setting(key: string): var {
        CompositorConfig.revision
        const spec = IrisOptions.settings.find(one => one.comp === "input" && one.key === key)
        return spec ? CompositorConfig.value(spec) : undefined
    }
    function on(value: var): bool { return value === true || value === "true" }
    readonly property bool leftHanded: root.on(root.setting("mouse.left-handed"))
    readonly property bool natural: root.on(root.setting("mouse.natural-scroll"))
    readonly property bool bothButtons: root.on(root.setting("mouse.middle-emulation"))
    readonly property bool pastes: { const value = root.setting("middle-click-paste"); return value !== false && value !== "false" }
    readonly property string modKey: String(root.setting("mod-key") || "Super")

    // ── What the binds give the mouse ──────────────────────────────────────────────────────────────────────────────
    readonly property var triggers: ["mouseleft", "mouseright", "mousemiddle", "mouseback", "mouseforward",
        "wheelscrollup", "wheelscrolldown", "wheelscrollleft", "wheelscrollright"]
    readonly property var bindIndex: {
        const out = {}
        for (const bind of NiriKeybinds.allBinds ?? []) {
            if (bind.commented) continue
            const key = IrisBinds.comboKey(bind.key_combo, root.modKey)
            if (root.triggers.includes(key.split("|")[1]) && !(key in out)) out[key] = bind
        }
        return out
    }
    // Niri drags with Mod held: the left button moves a window, the right one resizes it, the middle one moves the view.
    // A bind on the same button takes its place.
    readonly property var builtIn: CompositorService.niriNative ? {
        mouseleft: { text: Translation.tr("Drag: move the window"), category: "Move Windows" },
        mouseright: { text: Translation.tr("Drag: resize the window"), category: "Resize" },
        mousemiddle: { text: Translation.tr("Drag: move the view"), category: "Focus" }
    } : ({})
    // Every set of modifiers the mouse answers to, the busiest first: one press shows its layer.
    readonly property var layers: {
        const counts = {}
        for (const key of Object.keys(root.bindIndex)) {
            const mods = key.split("|")[0]
            if (mods.length > 0) counts[mods] = (counts[mods] ?? 0) + 1
        }
        const own = Object.keys(root.builtIn).filter(trigger => !(("Mod|" + trigger) in root.bindIndex)).length
        if (own > 0) counts.Mod = (counts.Mod ?? 0) + own
        return Object.keys(counts).sort((a, b) => counts[b] - counts[a]).map(mods => ({ mods: mods.split("+"), count: counts[mods] }))
    }
    property var held: []
    readonly property bool doing: root.held.length > 0
    readonly property bool modOnly: root.held.length === 1 && root.held[0] === "Mod"
    function sameLayer(mods: var): bool { return mods.length === root.held.length && mods.every(mod => root.held.includes(mod)) }
    function nameOf(mod: string): string { return mod === "Mod" ? Translation.tr(root.modKey) : Translation.tr(mod) }

    // ── What each part says ──────────────────────────────────────────────────────────────────────────────────────────
    // Left-handed swaps what the two buttons send: the drawing keeps the hand's place and moves the meaning.
    function triggerOf(part: string): string {
        if (part === "left") return root.leftHanded ? "mouseright" : "mouseleft"
        if (part === "right") return root.leftHanded ? "mouseleft" : "mouseright"
        return ({ wheel: "mousemiddle", back: "mouseback", forward: "mouseforward" })[part] ?? ""
    }
    function bindOf(trigger: string): var { return root.bindIndex[IrisBinds.heldKey(root.held, trigger)] ?? null }
    function said(text: string): var { return { text: text, glyph: "", tint: "", free: false } }
    function freeLine(form: string): var {
        const free = Translation.tr("Unbound")
        return { text: form.length > 0 ? form.arg(free) : free, glyph: "", tint: "", free: true }
    }
    function bindLine(bind: var, form: string): var {
        const what = String(bind.description || bind.action || "")
        const category = String(bind.category ?? "")
        return { text: form.length > 0 ? form.arg(what) : what, glyph: IrisBinds.glyphOf(category), tint: IrisBinds.tintOf(category), free: false }
    }
    function plainOf(trigger: string): var {
        switch (trigger) {
        case "mouseleft": return [root.said(Translation.tr("Click"))]
        case "mouseright": return [root.said(Translation.tr("Opens the menu"))]
        case "mousemiddle": return [root.said(Translation.tr("Middle click"))]
            .concat(root.pastes ? [root.said(Translation.tr("Pastes the selection"))] : [])
            .concat(root.bothButtons ? [root.said(Translation.tr("Both buttons together too"))] : [])
        case "mouseback": return [root.said(Translation.tr("Previous page"))]
        case "mouseforward": return [root.said(Translation.tr("Next page"))]
        }
        return [root.freeLine("")]
    }
    function linesOf(trigger: string): var {
        const bind = root.bindOf(trigger)
        if (bind) return [root.bindLine(bind, "")]
        if (!root.doing) return root.plainOf(trigger)
        const built = root.modOnly ? root.builtIn[trigger] ?? null : null
        return built ? [{ text: built.text, glyph: IrisBinds.glyphOf(built.category), tint: IrisBinds.tintOf(built.category), free: false }]
            : [root.freeLine("")]
    }
    // A wheel's two ways as one part; null when neither is bound in this layer.
    function wayLines(one: string, other: string, oneForm: string, otherForm: string): var {
        const first = root.bindOf(one)
        const second = root.bindOf(other)
        if (!first && !second) return null
        return [first ? root.bindLine(first, oneForm) : root.freeLine(oneForm), second ? root.bindLine(second, otherForm) : root.freeLine(otherForm)]
    }
    // Each callout: its part, its name, where its line meets the drawing (in the drawing's units, 100 × 164) and what
    // it says. Each side runs in the order that keeps its lines apart: on the right, the wheel's press comes last, as its
    // line reaches past the right button to the middle.
    readonly property var leftCallouts: [
        { part: "left", title: Translation.tr("Left button"), ax: 24, ay: 30, lines: root.linesOf(root.triggerOf("left")) },
        { part: "forward", title: Translation.tr("Forward"), ax: -2, ay: 82, lines: root.linesOf("mouseforward") },
        { part: "back", title: Translation.tr("Back"), ax: -2, ay: 101, lines: root.linesOf("mouseback") }
    ]
    readonly property var rightCallouts: {
        const roll = root.wayLines("wheelscrollup", "wheelscrolldown", Translation.tr("Up: %1"), Translation.tr("Down: %1"))
            ?? [root.doing ? root.freeLine("") : root.said(root.natural ? Translation.tr("Scrolls the other way") : Translation.tr("Scrolls"))]
        const tilt = root.wayLines("wheelscrollleft", "wheelscrollright", Translation.tr("Left: %1"), Translation.tr("Right: %1"))
        return [{ part: "roll", title: Translation.tr("Wheel"), ax: 50, ay: 22, lines: roll }]
            .concat(tilt ? [{ part: "tilt", title: Translation.tr("Wheel tilt"), ax: 55, ay: 32, lines: tilt }] : [])
            .concat([
                { part: "right", title: Translation.tr("Right button"), ax: 86, ay: 44, lines: root.linesOf(root.triggerOf("right")) },
                { part: "wheel", title: Translation.tr("Wheel press"), ax: 50, ay: 41, lines: root.linesOf("mousemiddle") }
            ])
    }

    // ── What the pointer does on the drawing ─────────────────────────────────────────────────────────────────────────
    property string hovered: ""
    property string pressedPart: ""
    // The way the wheel last rolled over the drawing, for a moment.
    property string rolled: ""
    Timer { id: rollFade; interval: 320; onTriggered: root.rolled = "" }
    readonly property bool wheelLit: root.pressedPart === "wheel" || root.rolled.length > 0
    function partOfButton(button: int): string {
        if (button === Qt.LeftButton) return root.leftHanded ? "right" : "left"
        if (button === Qt.RightButton) return root.leftHanded ? "left" : "right"
        if (button === Qt.MiddleButton) return "wheel"
        if (button === Qt.BackButton) return "back"
        if (button === Qt.ForwardButton) return "forward"
        return ""
    }
    // The part under a point of the drawing, in its units.
    function partAt(u: real, v: real): string {
        if (u >= 41 && u <= 59 && v >= 12 && v <= 52) return "wheel"
        if (u < 3 && v >= 72 && v <= 111) return v < 91.5 ? "forward" : "back"
        const seam = 60 + 8 * (1 - Math.pow((u - 50) / 47, 2))
        const half = v >= 60 ? 50 : 50 * Math.sqrt(Math.max(0, 1 - Math.pow((60 - v) / 62, 2)))
        if (v < seam && Math.abs(u - 50) <= half) return u < 50 ? "left" : "right"
        return ""
    }
    function wheelish(part: string): bool { return part === "wheel" || part === "roll" || part === "tilt" }
    function calloutLit(part: string): bool {
        return root.hovered === part || root.pressedPart === part
            || (root.hovered === "wheel" && root.wheelish(part))
            || (part === "roll" && (root.rolled === "up" || root.rolled === "down"))
            || (part === "tilt" && (root.rolled === "left" || root.rolled === "right"))
    }
    // A part's colour: the accent while pressed; under a layer, its bind's tint, or quiet when free; a hover lifts it.
    readonly property color quietFill: Qt.rgba(IrisStyle.fill.r, IrisStyle.fill.g, IrisStyle.fill.b, IrisStyle.fill.a * 0.5)
    function toneOf(part: string): color {
        if (part === "wheel" ? root.wheelLit : root.pressedPart === part) return IrisStyle.accent
        let rest = IrisStyle.fill
        if (root.doing) {
            const lines = root.leftCallouts.concat(root.rightCallouts)
                .filter(one => part === "wheel" ? root.wheelish(one.part) : one.part === part)
                .reduce((all, one) => all.concat(one.lines), [])
            const tinted = lines.find(line => !line.free && line.tint.length > 0)
            rest = tinted ? ColorUtils.applyAlpha(IrisStyle.identityColor(tinted.tint), IrisStyle.tintWash) : root.quietFill
        }
        const lifted = part === "wheel" ? root.wheelish(root.hovered) : root.hovered === part
        return lifted ? ColorUtils.mix(rest, IrisStyle.text, 0.88) : rest
    }
    function scaled(path: string, k: real): string {
        return path.replace(/-?\d+(\.\d+)?/g, n => String(Math.round(Number(n) * k * 100) / 100))
    }

    width: parent ? parent.width : 0
    spacing: Math.round(16 * root.d)

    // The layers: what the buttons do, then each set of modifiers the mouse answers to, with how many parts it has.
    Flow {
        width: root.width
        spacing: Math.round(6 * root.d)
        visible: root.layers.length > 0
        IrisButton {
            text: Translation.tr("What each button does")
            selected: !root.doing
            quiet: root.doing
            onClicked: root.held = []
        }
        Repeater {
            model: root.layers
            delegate: IrisButton {
                required property var modelData
                text: modelData.mods.map(mod => root.nameOf(mod)).join(" + ") + "  " + modelData.count
                selected: root.sameLayer(modelData.mods)
                quiet: !selected
                onClicked: root.held = Array.from(modelData.mods)
            }
        }
    }

    Item {
        id: stage
        readonly property real gutter: Math.round(44 * root.d)
        width: root.width
        height: Math.max(drawing.y + drawing.height + Math.round(12 * root.d), leftColumn.y + leftColumn.height, rightColumn.y + rightColumn.height)

        // Colours that ease, read by the drawing.
        Item {
            id: tones
            visible: false
            readonly property int ease: IrisStyle.motionEnabled ? 140 : 0
            property color leftButton: root.toneOf("left")
            property color rightButton: root.toneOf("right")
            property color wheel: root.toneOf("wheel")
            property color back: root.toneOf("back")
            property color forward: root.toneOf("forward")
            readonly property color seam: ColorUtils.applyAlpha(IrisStyle.text, 0.16)
            Behavior on leftButton { ColorAnimation { duration: tones.ease; easing.type: IrisStyle.feedbackEasing } }
            Behavior on rightButton { ColorAnimation { duration: tones.ease; easing.type: IrisStyle.feedbackEasing } }
            Behavior on wheel { ColorAnimation { duration: tones.ease; easing.type: IrisStyle.feedbackEasing } }
            Behavior on back { ColorAnimation { duration: tones.ease; easing.type: IrisStyle.feedbackEasing } }
            Behavior on forward { ColorAnimation { duration: tones.ease; easing.type: IrisStyle.feedbackEasing } }
        }

        // The mouse from above, 100 × 164 units: two buttons split down the middle over the palm, the wheel in its
        // groove between them, Forward and Back on the thumb's side.
        Item {
            id: drawing
            readonly property real k: Math.round(220 * root.d) / 164
            width: Math.round(100 * drawing.k)
            height: Math.round(164 * drawing.k)
            x: Math.round((stage.width - width) / 2)
            y: Math.round(12 * root.d)

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.quietFill
                    strokeColor: tones.seam
                    strokeWidth: 1
                    PathSvg { path: root.scaled("M 3 60 Q 26.5 68 50 68 Q 73.5 68 97 60 C 98 76 100 92 100 108 C 100 142 79 164 50 164 C 21 164 0 142 0 108 C 0 92 2 76 3 60 Z", drawing.k) }
                }
                ShapePath {
                    fillColor: tones.leftButton
                    strokeColor: tones.seam
                    strokeWidth: 1
                    PathSvg { path: root.scaled("M 50 0 C 21 0 4 20 3 60 Q 26.5 68 50 68 Z", drawing.k) }
                }
                ShapePath {
                    fillColor: tones.rightButton
                    strokeColor: tones.seam
                    strokeWidth: 1
                    PathSvg { path: root.scaled("M 50 0 C 79 0 96 20 97 60 Q 73.5 68 50 68 Z", drawing.k) }
                }
            }

            // Forward ahead of Back, standing out of the left flank.
            Repeater {
                model: [{ part: "forward", at: 74 }, { part: "back", at: 93 }]
                delegate: Rectangle {
                    required property var modelData
                    x: -Math.round(5 * drawing.k)
                    y: Math.round(modelData.at * drawing.k)
                    width: Math.round(6 * drawing.k)
                    height: Math.round(16 * drawing.k)
                    radius: width / 2
                    color: modelData.part === "forward" ? tones.forward : tones.back
                    border.width: 1
                    border.color: tones.seam
                }
            }

            Rectangle {
                id: groove
                x: Math.round(42 * drawing.k)
                y: Math.round(13 * drawing.k)
                width: Math.round(16 * drawing.k)
                height: Math.round(38 * drawing.k)
                radius: width / 2
                color: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
                Rectangle {
                    id: wheel
                    anchors.centerIn: parent
                    width: Math.round(10 * drawing.k)
                    height: parent.height - Math.round(8 * drawing.k)
                    radius: width / 2
                    color: tones.wheel
                    clip: true
                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(3 * drawing.k)
                        Repeater {
                            model: 6
                            delegate: Rectangle {
                                width: Math.round(wheel.width * 0.56)
                                height: Math.max(1, Math.round(root.d))
                                radius: height / 2
                                color: ColorUtils.applyAlpha(root.wheelLit ? IrisStyle.inkOnAccent : IrisStyle.text, 0.3)
                            }
                        }
                    }
                }
            }
            // The way the wheel rolled, for a moment around it.
            Repeater {
                model: [
                    { way: "up", glyph: "keyboard_arrow_up", u: 50, v: 6 }, { way: "down", glyph: "keyboard_arrow_down", u: 50, v: 58 },
                    { way: "left", glyph: "keyboard_arrow_left", u: 35, v: 32 }, { way: "right", glyph: "keyboard_arrow_right", u: 65, v: 32 }
                ]
                delegate: MaterialSymbol {
                    required property var modelData
                    x: Math.round(modelData.u * drawing.k - width / 2)
                    y: Math.round(modelData.v * drawing.k - height / 2)
                    text: modelData.glyph
                    iconSize: Math.round(14 * root.d)
                    color: IrisStyle.accent
                    opacity: root.rolled === modelData.way ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: IrisStyle.motionEnabled ? 160 : 0 } }
                }
            }

            // The real mouse over the drawing: a press lights its part, a roll its way; the roll goes on to the page.
            MouseArea {
                id: feel
                x: -Math.round(7 * drawing.k)
                width: drawing.width - x
                height: drawing.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton
                cursorShape: root.hovered.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPositionChanged: mouse => root.hovered = root.partAt((mouse.x + feel.x) / drawing.k, mouse.y / drawing.k)
                onExited: root.hovered = ""
                onPressed: mouse => root.pressedPart = root.partOfButton(mouse.button)
                onReleased: root.pressedPart = ""
                onCanceled: root.pressedPart = ""
                onWheel: wheel => {
                    // The way the hand rolled: natural scrolling turns what the event says.
                    const flip = wheel.inverted ? -1 : 1
                    const dx = wheel.angleDelta.x * flip
                    const dy = wheel.angleDelta.y * flip
                    root.rolled = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? "left" : "right") : (dy > 0 ? "up" : "down")
                    rollFade.restart()
                    wheel.accepted = false
                }
            }
        }

        Column {
            id: leftColumn
            readonly property bool onLeft: true
            width: Math.max(0, drawing.x - stage.gutter)
            y: Math.max(0, Math.round(drawing.y + drawing.height * 0.36 - height / 2))
            spacing: Math.round(18 * root.d)
            Repeater { model: root.leftCallouts; delegate: calloutKind }
        }
        Column {
            id: rightColumn
            readonly property bool onLeft: false
            x: drawing.x + drawing.width + stage.gutter
            width: Math.max(0, stage.width - x)
            y: Math.max(0, Math.round(drawing.y + drawing.height * 0.3 - height / 2))
            spacing: Math.round(14 * root.d)
            Repeater { model: root.rightCallouts; delegate: calloutKind }
        }
    }

    IrisText {
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        text: Translation.tr("Press a button or roll the wheel over the mouse")
        color: IrisStyle.textTertiary
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.Wrap
    }

    // One part's name and what it does, with a line to its place on the drawing: the left side reads toward the mouse.
    Component {
        id: calloutKind
        Item {
            id: callout
            required property var modelData
            readonly property string part: String(callout.modelData.part)
            readonly property bool onLeft: callout.parent?.onLeft === true
            readonly property bool lit: root.calloutLit(callout.part)
            readonly property color lineTone: callout.lit ? IrisStyle.accent : ColorUtils.applyAlpha(IrisStyle.text, 0.28)
            // Where the line meets the drawing, in this callout's own space.
            readonly property real ax: drawing.x + Number(callout.modelData.ax) * drawing.k - (callout.parent?.x ?? 0) - callout.x
            readonly property real ay: drawing.y + Number(callout.modelData.ay) * drawing.k - (callout.parent?.y ?? 0) - callout.y
            readonly property real lineY: Math.round(title.height / 2)
            readonly property real edge: callout.onLeft ? callout.width + Math.round(6 * root.d) : -Math.round(6 * root.d)
            readonly property real elbow: callout.edge + (callout.onLeft ? 1 : -1) * Math.round(10 * root.d)
            width: callout.parent ? callout.parent.width : 0
            height: body.implicitHeight

            HoverHandler {
                onHoveredChanged: root.hovered = hovered ? callout.part : root.hovered === callout.part ? "" : root.hovered
            }

            Column {
                id: body
                width: parent.width
                spacing: Math.round(2 * root.d)
                IrisText {
                    id: title
                    width: parent.width
                    horizontalAlignment: callout.onLeft ? Text.AlignRight : Text.AlignLeft
                    text: String(callout.modelData.title)
                    color: callout.lit ? IrisStyle.accent : IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeMeta
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: IrisStyle.motionEnabled ? 140 : 0; easing.type: IrisStyle.feedbackEasing } }
                }
                Repeater {
                    model: callout.modelData.lines
                    delegate: Row {
                        id: line
                        required property var modelData
                        readonly property bool marked: String(line.modelData.glyph).length > 0
                        x: callout.onLeft ? body.width - width : 0
                        spacing: Math.round(6 * root.d)
                        MaterialSymbol {
                            visible: line.marked
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(line.modelData.glyph)
                            iconSize: Math.round(16 * root.d)
                            fill: 1
                            color: IrisStyle.identityColor(String(line.modelData.tint))
                        }
                        IrisText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, body.width - (line.marked ? Math.round(22 * root.d) : 0))
                            text: String(line.modelData.text)
                            color: line.modelData.free ? IrisStyle.textTertiary : IrisStyle.text
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: line.modelData.free ? Font.Normal : Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Shape {
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: callout.lineTone
                    strokeWidth: Math.max(1, root.d)
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: callout.edge
                    startY: callout.lineY
                    PathLine { x: callout.elbow; y: callout.lineY }
                    PathLine { x: callout.ax; y: callout.ay }
                }
            }
            Rectangle {
                width: Math.round(6 * root.d)
                height: width
                radius: width / 2
                x: Math.round(callout.ax - width / 2)
                y: Math.round(callout.ay - height / 2)
                color: callout.lit ? IrisStyle.accent : IrisStyle.textSecondary
            }
        }
    }
}
