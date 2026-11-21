pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.widgets

// Prism worn as every widget's design (`iris.widgets.design` = prism; each widget's face is the part
// `widgetPrism.<face>`). One body for all of them (`PrismBody`, his 11-16 "un cuerpo, mismo lenguaje"): smoked frosted
// glass in dark, white frost in light, its material and opacity the widget's own (`iris.material`, `iris.opacity`), no
// rim and no art on it. Its head is a mark and a name with the one fact; the data is drawn in white, the one live mark in
// the widget's colour. Each widget picks how that glass is cut (`iris.prism`):
//   quiet (the factory): one slab; beam: the slab with white light crossing it;
//   folder: Now Playing's folder, a glass tab for the name and a flap lit in the widget's colour for the fact;
//   pocket, archive, smoked, board: a stack of sheets:
//     a sheet lit in the widget's colour stands behind the glass the face draws on, its tab, the archive's shoulders or
//     the board's frame around it.
// Every form keeps the same places for the face (head over `paneTop`, the middle to `paneBottom`, the foot), so every
// face reads in every form. Measures are per size (176 x 176 small, 368 x 176 medium, 368 x 368 large).
IrisWidgetFace {
    id: root
    ownBody: true
    padding: 0

    function pick(small: real, medium: real, large: real): real { return root.dp(root.small ? small : root.medium ? medium : large) }
    function type(small: real, medium: real, large: real): real { return root.small ? small : root.medium ? medium : large }

    // The slab's corners: a face may round itself further (the clock's lens).
    property real slabRadius: root.radius

    // How the glass is cut. A lens stays a slab, and so does a widget with its background off (no glass to cut: a lit
    // sheet's ink would stand on the wallpaper). "taskello" is the board's name from before it was one.
    readonly property var forms: ["quiet", "beam", "folder", "pocket", "archive", "smoked", "board"]
    readonly property string chosenForm: {
        const own = String(root.widget?.familyOption("prism", "quiet") ?? "quiet")
        const name = own === "taskello" ? "board" : own
        return root.forms.includes(name) ? name : "quiet"
    }
    readonly property string form: (root.clear || root.slabRadius > root.radius + 0.5) && root.chosenForm !== "beam"
        ? "quiet" : root.chosenForm
    readonly property bool folded: root.form === "folder"

    // What the head says: a mark and a name, the one fact at the right end.
    property string tabGlyph: ""
    property string tabText: ""
    property string flapText: ""
    // Raised small beside the fact (a 12-hour clock's AM/PM, a unit).
    property string flapSuffix: ""
    property string flapGlyph: ""
    property bool head: true
    // The face's one quick action, a key at the head's right end (the month back to today, copy the palette).
    property bool capInteractive: false
    property string capGlyph: ""
    property string capName: ""
    signal capClicked()

    // The widget's colour: the head's mark and fact, the one mark that is live.
    property color shelf: root.nothing ? root.signal : root.accent
    readonly property color inkOnShelf: root.onFill(root.shelf)
    // Where the white light meets the glass, and how much passes: on the slab's rim near its top right. A face moves it
    // onto its live thing.
    // The folder breaks it at the pane's foot, just before what the pane holds (a core across the figure washed it out).
    property point prism: root.folded ? Qt.point(Math.round(root.inset * 0.5), root.paneBottom - root.pick(10, 10, 16))
        : Qt.point(root.width - root.pick(28, 40, 48), root.pick(2, 2, 4))
    property real lightPass: 1

    // The places every face fills: the head over `paneTop`, the middle to `paneBottom`, the foot to `footBottom`.
    readonly property real inset: root.pick(16, 22, 26)
    readonly property real innerWidth: Math.max(1, root.width - 2 * root.inset)
    readonly property real paneTop: root.pick(44, 42, 79)
    readonly property real paneBottom: root.pick(112, 120, 200)
    readonly property real paneHeight: Math.max(1, root.paneBottom - root.paneTop)
    readonly property real paneMiddle: Math.round((root.paneTop + root.paneBottom) / 2)
    readonly property real footTop: root.paneBottom
    readonly property real footBottom: root.height - root.pick(6, 8, 10)
    readonly property real footHeight: Math.max(1, root.footBottom - root.footTop)
    readonly property real headY: Math.round(root.paneTop * 0.52)
    readonly property bool label: root.nothing

    // The folder: the tab's right edge and its lean, the flap's top and right edge.
    readonly property real lean: root.pick(22, 24, 40)
    readonly property real tabRight: root.pick(98, 196, 214)
    readonly property real flapTop: root.pick(12, 14, 29)
    readonly property real flapRight: root.width - root.pick(14, 30, 26)
    readonly property real flapMiddle: Math.round((root.flapTop + root.paneTop) / 2)
    readonly property real flapLeft: root.folded ? body.edgeAt(root.flapMiddle) : root.inset

    // A stack's sheets (PrismBody: rects [left, right, bottom, corners], steps [left height, right height, middle,
    // lean]) and where its head sits: the name's and the fact's rows, and which of them stands on the lit sheet. All of
    // it inside the head band, so the middle and the foot are the front glass on every form.
    readonly property var stack: {
        const W = root.width, h = root.height, H = root.paneTop, R = root.radius, L = root.lean
        const at = share => Math.round(H * share)
        const across = (small, other) => Math.round(W * (root.small ? small : other))
        const flat = y => [y, y, 0, 0]
        if (root.form === "pocket") {
            // A lit sheet with its tab on the right, behind a glass pocket with its tab on the left.
            return { lit: [0, W, H + R, R], litStep: [at(0.36), 0, across(0.62, 0.6), L],
                front: [0, W, h, R], frontStep: [at(0.3), at(0.64), across(0.44, 0.4), L],
                nameY: at(0.65), nameLit: false, factY: at(0.32), factLit: true, side: 0 }
        }
        if (root.form === "smoked") {
            // A lit card out at the top left, over a smoked pocket whose tab rises on the right.
            const top = root.pick(3, 3, 5)
            return { lit: [root.dp(4), W - root.dp(4), H + R, Math.max(0, R - root.dp(3))], litStep: flat(top),
                front: [0, W, h, R], frontStep: [at(0.82), at(0.3), across(0.56, 0.46), L],
                nameY: Math.round((top + at(0.82)) / 2), nameLit: true, factY: at(0.65), factLit: false, side: 0 }
        }
        if (root.form === "archive") {
            // Glass shoulders, a lit sheet standing up between them, a glass pocket in front.
            const side = Math.round(W * 0.11), top = root.pick(3, 3, 6), row = Math.round((top + at(0.6)) / 2)
            return { base: [0, W, h, R], baseStep: flat(at(0.34)), shade: 0.3,
                lit: [side, W - side, H + R, root.pick(12, 14, 16)], litStep: flat(top),
                front: [0, W, h, R], frontStep: [at(0.6), at(0.84), across(0.56, 0.46), L],
                nameY: row, nameLit: true, factY: row, factLit: true, side: side }
        }
        if (root.form === "board") {
            // A darker tray, a lit header inside it, a glass sheet with its tab on the left.
            const b = root.pick(5, 6, 7), r = Math.max(0, R - b), row = Math.round((b + at(0.54)) / 2)
            return { base: [0, W, h, R], baseStep: flat(0), shade: 0.5,
                lit: [b, W - b, H + R, r], litStep: flat(b),
                front: [b, W - b, h - b, r], frontStep: [at(0.54), at(0.86), across(0.56, 0.46), L],
                nameY: row, nameLit: true, factY: row, factLit: true, side: b }
        }
        return null
    }

    // The head on this form: where the name starts, its row and how far it runs; the fact's row and right end (the
    // folder centres it on its flap) and its room; the inks of what stands on the lit sheet.
    readonly property real sidePad: root.pick(10, 12, 14)
    readonly property real nameX: root.form === "archive" ? root.stack.side + root.sidePad : root.inset
    readonly property real nameY: root.stack ? root.stack.nameY : root.headY
    readonly property real nameEnd: root.folded ? body.edgeAt(root.nameY) - root.pick(8, 10, 12)
        : root.form === "pocket" ? root.stack.litStep[2] - root.lean / 2 - root.pick(6, 8, 10)
        : root.form === "smoked" ? root.stack.frontStep[2] - root.lean / 2 - root.pick(6, 8, 10)
        : headEnd.x - root.pick(8, 10, 12)
    readonly property real factY: root.folded ? root.flapMiddle : root.stack ? root.stack.factY : root.headY
    readonly property real factRight: root.form === "archive" ? root.width - root.stack.side - root.sidePad
        : root.width - root.inset
    readonly property real factRoom: root.folded ? root.flapRight - root.flapLeft - root.pick(10, 14, 18)
        : root.form === "pocket" ? root.factRight - root.stack.litStep[2] - root.lean / 2 - root.pick(6, 8, 10)
        : root.innerWidth * 0.5
    readonly property bool nameLit: root.stack?.nameLit ?? false
    readonly property bool factLit: root.folded || (root.stack?.factLit ?? false)
    readonly property color markInk: root.nameLit ? root.inkOnShelf : root.label ? root.ink : root.shelf
    readonly property color nameInk: root.nameLit ? root.inkOnShelf : root.label ? root.inkSecondary : root.ink
    readonly property color factInk: root.factLit ? root.inkOnShelf : root.label ? root.ink : root.shelf

    PrismBody {
        id: body
        anchors.fill: parent
        face: root
        paneTop: root.paneTop
        paneBottom: root.paneBottom
        paneRadius: root.pick(13, 14, 16)
        prism: root.prism
        entry: root.small ? Qt.point(-root.width * 0.3, root.height * 1.05)
            : root.medium ? Qt.point(-root.width * 0.2, root.height * 1.15) : Qt.point(-root.width * 0.16, root.height * 0.9)
        fanAngle: root.small ? -0.55 : root.medium ? -0.4 : -0.46
        fanSpread: root.small ? 0.34 : root.medium ? 0.28 : 0.3
        lightPass: root.lightPass
        shelf: root.shelf
        tabRight: root.tabRight
        lean: root.lean
        tabRadius: root.pick(16, 20, 26)
        flapTop: root.flapTop
        flapRight: root.flapRight
        flapRadius: root.pick(18, 22, 30)
        slab: !root.folded && root.stack === null
        slabRadius: root.slabRadius
        beamPass: root.form === "beam" ? 0.8 : 0
        sheets: root.stack !== null
        baseRect: root.stack?.base ?? [0, 0, 0, 0]
        baseStep: root.stack?.baseStep ?? [0, 0, 0, 0]
        baseShade: root.stack?.shade ?? 0
        litRect: root.stack?.lit ?? [0, 0, 0, 0]
        litStep: root.stack?.litStep ?? [0, 0, 0, 0]
        frontRect: root.stack?.front ?? [0, 0, 0, 0]
        frontStep: root.stack?.frontStep ?? [0, 0, 0, 0]
    }

    // ── the head: a mark and a name ──
    MaterialSymbol {
        id: tabMark
        visible: root.head && root.tabGlyph.length > 0
        x: root.nameX
        y: Math.round(root.nameY - height / 2)
        text: root.tabGlyph
        fill: 1
        iconSize: root.px(root.type(14, 15, 18))
        color: root.markInk
    }
    FaceText {
        id: tabName
        visible: root.head
        face: root
        x: tabMark.visible ? tabMark.x + tabMark.width + root.pick(5, 6, 7) : tabMark.x
        y: Math.round(root.nameY - height / 2)
        width: Math.max(0, root.nameEnd - x)
        text: root.label ? root.tabText.toUpperCase() : root.tabText
        color: root.nameInk
        size: root.label ? root.type(9.5, 10.5, 12) : root.type(12, 13, 15)
        weight: Font.Bold
        font.family: root.label ? root.fontLabel : root.fontMain
        // Caps take more room: a Nothing label spaces its letters only where the tab has the room for it, and shrinks
        // before it would cut a word ("NOVEMBER" on a small tab).
        font.letterSpacing: root.label ? (root.small ? root.px(10) * 0.03 : root.px(12) * 0.08) : -root.px(root.type(12, 13, 15)) * 0.02
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: root.px(root.label ? root.type(7.5, 9, 11) : root.type(9, 10, 11))
    }

    // ── the head ends on its one fact, in the widget's colour, and the face's quick action ──
    Row {
        id: headEnd
        visible: root.head
        x: root.folded ? Math.round((root.flapLeft + root.flapRight) / 2 + root.dp(3) - width / 2) : root.factRight - width
        y: Math.round(root.factY - height / 2)
        spacing: root.dp(6)
        Row {
            visible: quietFigure.text.length > 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.dp(2)
            MaterialSymbol {
                visible: root.flapGlyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: root.flapGlyph
                fill: 1
                iconSize: root.px(root.type(12, 13, 15))
                color: root.factInk
            }
            FaceText {
                id: quietFigure
                face: root
                width: Math.max(0, Math.min(Math.ceil(implicitWidth), root.factRoom))
                text: root.label ? root.flapText.toUpperCase() : root.flapText
                color: root.factInk
                size: root.label ? root.type(9.5, 10.5, 12) : root.type(12, 13, 15)
                weight: Font.Bold
                font.family: root.label ? root.fontLabel : root.fontNumbers
                font.features: ({ "tnum": 1 })
            }
            FaceText {
                visible: text.length > 0
                face: root
                y: Math.round(quietFigure.height * 0.06)
                text: root.flapSuffix
                color: root.factInk
                size: root.type(7, 7.5, 9)
                weight: Font.Bold
            }
        }
        // The quick action: a round key of the glass's own fill, its glyph white; pointed, it brightens. On the lit sheet
        // it is a veil of that sheet's ink.
        Rectangle {
            id: capKey
            visible: root.capInteractive && root.capGlyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            width: root.pick(24, 24, 28)
            height: width
            radius: width / 2
            color: root.factLit ? Qt.rgba(root.inkOnShelf.r, root.inkOnShelf.g, root.inkOnShelf.b,
                    capArea.pressed ? 0.3 : capArea.containsMouse ? 0.22 : 0.14)
                : capArea.pressed ? root.fillActive : capArea.containsMouse ? root.fillHover : root.fill
            Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.capGlyph
                fill: 1
                iconSize: Math.round(capKey.width * 0.58)
                color: root.factLit ? root.inkOnShelf : root.ink
            }
            MouseArea {
                id: capArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.capClicked()
            }
            Accessible.role: Accessible.Button
            Accessible.name: root.capName
        }
    }
}
