pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// The Settings island: what a change just did and the way back, said as the Dynamic Island says a Live Activity. One
// black object at the sheet's foot that changes shape, never a toast that slides in:
// - compact, a capsule: the row's mark (or the colour it now has), its name, the value it holds now in its own colour,
//   and one key (Undo; Redo after an undo). It grows from a point, and recedes into one after a few seconds.
// - expanded, a card: a display change waiting for Keep, its countdown drawn as a ring, Revert and Keep.
// A press on the capsule takes the page to the row it speaks of. Hover holds it.
Item {
    id: root

    property real d: IrisStyle.settingsDensity
    // The width it may take (the sheet's).
    property real room: 600
    // Kept off while another sheet covers the body (Home's editor).
    property bool allowed: true
    function u(n: real): int { return Math.round(n * root.d) }

    readonly property var told: IrisOptions.told
    readonly property var pending: IrisNiri.pending
    property bool rested: true
    readonly property string mode: !root.allowed ? "" : root.pending ? "display" : root.told && !root.rested ? "told" : ""
    readonly property bool shown: root.mode.length > 0

    // ── What the compact island says.
    readonly property var entry: root.told
    readonly property var step: root.entry?.steps?.[0] ?? null
    readonly property var row: root.entry?.row ?? root.step?.spec ?? null
    readonly property bool undone: root.entry?.how === "undone"
    readonly property bool restoreEntry: root.entry?.kind === "restore"
    readonly property bool pinEntry: root.entry?.kind === "pin" || root.entry?.kind === "unpin"
    // A preset worn: said by its name and its accent, the one before it when undone.
    readonly property bool themeEntry: root.entry?.kind === "theme"
    // Said with no way back (a theme copied to share): no key, nothing to undo.
    readonly property bool noteEntry: root.entry?.kind === "note"
    // An entry that brings its own words (a note, a theme deleted): { glyph, name, say, sayBefore, swatch }.
    readonly property bool ownWords: root.noteEntry || root.entry?.kind === "dropTheme"
    // What is true now: an undone pin is a row off Home again.
    readonly property bool pinnedNow: (root.entry?.kind === "pin") !== root.undone
    readonly property var shownValue: root.step ? (root.undone ? root.step.before : root.step.after) : null
    readonly property var area: {
        const spec = root.row
        return spec ? IrisOptions.sectionById(String(spec.origin?.section ?? spec.section ?? "")) : null
    }
    readonly property color tint: root.pinEntry ? IrisStyle.accent : root.area?.tint ?? IrisStyle.identity.gray
    readonly property var swatch: root.themeEntry ? ((root.undone ? root.entry.swatchBefore : root.entry.swatch) || null)
        : root.ownWords ? (root.entry.swatch || null)
        : !root.restoreEntry && !root.pinEntry && root.row ? IrisOptions.swatchOf(root.row, root.shownValue) : null
    readonly property string glyph: {
        if (root.undone) return "undo"
        if (root.restoreEntry) return "restart_alt"
        if (root.pinEntry) return root.pinnedNow ? "keep" : "keep_off"
        if (root.ownWords) return String(root.entry.glyph ?? "check")
        const spec = root.row
        if (!spec) return "settings"
        const choice = IrisOptions.choicesOf(spec).find(choice => String(choice.value) === String(root.shownValue))
        return String(choice?.glyph ?? spec.glyph ?? IrisOptions.groupGlyphs[String(spec.origin?.group ?? spec.group ?? "")] ?? root.area?.icon ?? "settings")
    }
    readonly property string name: root.restoreEntry ? (root.undone ? Translation.tr("Back as they were") : Translation.tr("Defaults restored"))
        : root.ownWords ? String(root.entry.name ?? "")
        : root.themeEntry && root.undone && !root.entry.sayBefore ? Translation.tr("Back as they were")
        : root.themeEntry ? Translation.tr(String(root.row?.group ?? "Presets"))
        : root.pinEntry ? (root.pinnedNow ? Translation.tr("Pinned to Home") : Translation.tr("Removed from Home"))
        : root.row ? Translation.tr(String(IrisOptions.leads(root.row) ? root.row.group : root.row.label ?? "")) : ""
    readonly property string value: {
        Config.revision
        if (root.restoreEntry) return Translation.tr("%1 settings").arg(root.entry.steps.length)
        if (root.pinEntry) return Translation.tr(String(root.row?.label ?? ""))
        if (root.themeEntry || root.ownWords) return String((root.undone ? root.entry.sayBefore : root.entry.say) ?? "")
        return root.row ? IrisOptions.say(root.row, root.shownValue) : ""
    }
    readonly property string keyName: root.undone ? Translation.tr("Redo") : Translation.tr("Undo")

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

    // ── Its life: a few seconds after it last spoke, held while the pointer rests on it.
    readonly property int lifespan: root.undone || root.noteEntry ? 2600 : root.restoreEntry ? 7000 : 5000
    Timer { id: life; interval: root.lifespan; onTriggered: root.rested = true }
    Connections {
        target: IrisOptions
        function onToldStampChanged(): void {
            if (!IrisOptions.told) { root.rested = true; return }
            const fresh = root.rested
            root.rested = false
            if (!hover.hovered) life.restart()
            if (!fresh) swap.restart()
        }
    }
    readonly property bool hovered: hover.hovered
    onHoveredChanged: if (root.hovered) life.stop(); else if (root.mode === "told") life.restart()

    // ── The shape. Growing takes the emerge spring (it overshoots a little, as the Island does opening); shrinking the
    // recede one (critically damped: it settles without a bounce). Set together so the curve is picked before it moves.
    readonly property int compactHeight: root.u(44)
    readonly property int expandedHeight: root.u(118)
    // The question is never cut: a long language widens the island up to the room it has.
    readonly property real wantedW: root.mode === "display" ? Math.min(root.room - root.u(32), Math.max(root.u(452), displayFace.needs))
        : root.mode === "told" ? Math.min(root.room - root.u(32), compactFace.implicitWidth)
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
        scale: (root.shown ? 1 : 0.4) * (press.pressed ? IrisStyle.pressScale(0.97) : 1)
        Behavior on width { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on height { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on radius { NumberAnimation { duration: root.springTime; easing.type: Easing.BezierSpline; easing.bezierCurve: root.springCurve } }
        Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(root.shown ? 120 : 200); easing.type: IrisStyle.feedbackEasing } }
        Behavior on scale { NumberAnimation { duration: root.shown ? IrisStyle.emergeDuration : IrisStyle.recedeDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.shown ? IrisStyle.emergeCurve : IrisStyle.recedeCurve } }
        clip: true

        HoverHandler { id: hover }
        // The capsule takes the page to the row it speaks of (Ctrl+Z from another page said a change made there).
        MouseArea {
            id: press
            anchors.fill: parent
            enabled: root.mode === "told" && !root.restoreEntry && !root.noteEntry
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                const spec = root.row?.origin ?? root.row
                if (!spec || root.pinEntry) return
                const section = String(spec.section ?? "")
                if (section.length > 0) GlobalStates.openSettingsAt("iris", section + (String(spec.group ?? "").length > 0 ? "/" + spec.group : ""))
            }
        }

        // ── Compact: mark · name · value · key, the content a beat after the shape starts (HIG: content follows).
        Item {
            id: compactFace
            readonly property int pad: Math.round((root.compactHeight - mark.width) / 2)
            // The key sits a little nearer the end: a capsule in a capsule, concentric.
            readonly property int endPad: compactFace.pad - root.u(2)
            // Text widths come fractional: rounded up, or a name a fraction short of its own width elides.
            // The key and the gap before it; a note has none.
            readonly property int keyRoom: key.visible ? root.u(14) + Math.ceil(key.width) : 0
            implicitWidth: compactFace.pad + mark.width + root.u(10) + Math.ceil(compactName.implicitWidth) + root.u(8)
                + Math.ceil(compactValue.implicitWidth) + compactFace.keyRoom + compactFace.endPad
            // Short of room (a narrow window, a long language) the key keeps its glyph and the name keeps its words.
            readonly property int keyWide: Math.ceil(keyGlyph.width + keyRow.spacing + keyWords.implicitWidth) + root.u(24)
            readonly property bool keyNamed: compactFace.pad + mark.width + root.u(10) + Math.ceil(compactName.implicitWidth) + root.u(8)
                + Math.ceil(compactValue.implicitWidth) + root.u(14) + compactFace.keyWide + compactFace.endPad <= root.room - root.u(32)
            // Laid out at the width it is growing to, centred: the plate uncovers it from the middle, nothing reflows.
            width: root.mode === "told" ? root.goalW : Math.max(root.goalW, compactFace.implicitWidth)
            height: root.compactHeight
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.mode === "told" ? 1 : 0
            Behavior on opacity {
                SequentialAnimation {
                    PauseAnimation { duration: root.mode === "told" ? Math.round(root.springTime * 0.22) : 0 }
                    NumberAnimation { duration: IrisStyle.duration(root.mode === "told" ? 170 : 90); easing.type: IrisStyle.feedbackEasing }
                }
            }
            // A new change replaces the last in place: its words rise into their line (HIG: content replace).
            Item {
                id: words
                anchors.fill: parent
                SequentialAnimation {
                    id: swap
                    NumberAnimation { target: words; property: "opacity"; to: 0.15; duration: IrisStyle.duration(70); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.recedeCurve }
                    PropertyAction { target: words; property: "y"; value: root.u(5) }
                    ParallelAnimation {
                        NumberAnimation { target: words; property: "opacity"; to: 1; duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing }
                        NumberAnimation { target: words; property: "y"; to: 0; duration: IrisStyle.duration(220); easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.moveCurve }
                    }
                }
                // The mark: the colour itself when the value is one (Accent, Signal), else the row's own glyph.
                Item {
                    id: mark
                    x: compactFace.pad
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.u(28)
                    height: width
                    IrisSquircle {
                        anchors.fill: parent
                        visible: !root.swatch
                        plain: false
                        tint: root.tint
                        glyph: root.glyph
                    }
                    Rectangle {
                        visible: !!root.swatch
                        anchors.fill: parent
                        radius: width / 2
                        // Drawn for the island's black, as its value is: a light scheme's deeper accent sank into it.
                        color: !root.swatch ? "transparent" : Qt.color(root.swatch).hslSaturation < 0.1 ? root.swatch : IrisStyle.liveIslandHue(root.swatch)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            visible: root.undone
                            text: "undo"
                            iconSize: root.u(16)
                            color: IrisStyle.liveIslandInk
                        }
                    }
                }
                IrisText {
                    id: compactName
                    anchors.left: mark.right
                    anchors.leftMargin: root.u(10)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, Math.min(Math.ceil(implicitWidth), compactFace.width - x - root.u(8) - Math.ceil(compactValue.implicitWidth) - compactFace.keyRoom - compactFace.endPad))
                    text: root.name
                    color: IrisStyle.liveIslandQuiet
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.Medium)
                    elide: Text.ElideRight
                }
                IrisText {
                    id: compactValue
                    anchors.left: compactName.right
                    anchors.leftMargin: root.u(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.value
                    // A colour value wears its own colour, never the page's next to its swatch.
                    color: root.pinEntry || root.restoreEntry ? IrisStyle.liveIslandInk : IrisStyle.liveIslandHue(root.swatch ?? root.tint)
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.Bold)
                    font.features: { "tnum": 1 }
                }
                // One direct action (HIG): the way back, then the way forward again.
                Rectangle {
                    id: key
                    visible: !root.noteEntry
                    anchors.right: parent.right
                    anchors.rightMargin: compactFace.endPad
                    anchors.verticalCenter: parent.verticalCenter
                    height: root.u(32)
                    width: compactFace.keyNamed ? compactFace.keyWide : height
                    radius: height / 2
                    color: keyArea.pressed ? IrisStyle.liveIslandKeyHover : keyArea.containsMouse ? IrisStyle.liveIslandKeyHover : IrisStyle.liveIslandKey
                    scale: keyArea.pressed ? IrisStyle.pressScale(0.94) : 1
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                    Row {
                        id: keyRow
                        anchors.centerIn: parent
                        spacing: root.u(5)
                        MaterialSymbol {
                            id: keyGlyph
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.undone ? "redo" : "undo"
                            iconSize: root.u(16)
                            color: IrisStyle.liveIslandInk
                        }
                        IrisText {
                            id: keyWords
                            visible: compactFace.keyNamed
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.keyName
                            color: IrisStyle.liveIslandInk
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(Font.DemiBold)
                        }
                    }
                    MouseArea {
                        id: keyArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.undone ? IrisOptions.redo() : IrisOptions.undo()
                    }
                    Accessible.role: Accessible.Button
                    Accessible.name: root.keyName
                }
            }
        }

        // ── Expanded: a display change waiting. The compact line grown into a card: its mark and words keep their
        // place at the top (HIG: an expanded presentation is an enlarged compact one), the answers under them.
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
                property real level: root.pending ? IrisNiri.secondsLeft / Math.max(1, IrisNiri.revertAfter) : 1
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
                    text: String(IrisNiri.secondsLeft)
                    pixelSize: IrisStyle.typeLabel
                    weight: IrisStyle.weight(Font.Bold)
                    color: IrisStyle.liveIslandInk
                    countDown: true
                }
                Accessible.role: Accessible.StaticText
                Accessible.name: Translation.tr("Keep this display setting? It goes back in %1 s.").arg(IrisNiri.secondsLeft)
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
                            onClicked: answer.modelData.keep ? IrisNiri.keepDisplay() : IrisNiri.revertDisplay()
                        }
                        Accessible.role: Accessible.Button
                        Accessible.name: answer.modelData.name
                    }
                }
            }
        }
    }

    Accessible.role: Accessible.AlertMessage
    Accessible.name: root.mode === "display" ? Translation.tr("Keep this display setting?") : [root.name, root.value].filter(part => part.length > 0).join(", ")
}
