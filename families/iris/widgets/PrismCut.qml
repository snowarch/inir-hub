import QtQuick
import qs.modules.common

// How a Prism face's glass is cut, read in one place for every Prism face (PrismFolder and Now Playing's own), so the
// cut picked for every widget reaches each of them (his 11-20: the music widget kept its folder while the rest
// changed). The widget's own cut (`iris.prism`), else the cut every widget wears (`iris.widgets.prism`). A lens stays a
// slab, and so does a widget with its background off (no glass to cut: a lit sheet's ink would stand on the wallpaper);
// beam is a slab already. "taskello" is the board's name from before it was one.
QtObject {
    id: cut
    required property var face
    property real width: 0
    property real height: 0
    // The head band's foot and the tab's lean, in the face's pixels.
    property real paneTop: 0
    property real lean: 0
    // The face rounds itself past the widget's corners (the clock's lens).
    property bool lens: false

    function pick(small: real, medium: real, large: real): real {
        return cut.face.dp(cut.face.small ? small : cut.face.medium ? medium : large)
    }

    readonly property var forms: ["quiet", "beam", "folder", "pocket", "archive", "smoked", "board"]
    readonly property string chosen: {
        const own = String(cut.face.widget?.familyOption("prism", "auto") ?? "auto")
        const picked = own === "auto" ? String(Config.options?.iris?.widgets?.prism ?? "quiet") : own
        const name = picked === "taskello" ? "board" : picked
        return cut.forms.includes(name) ? name : "quiet"
    }
    readonly property string form: (cut.face.clear || cut.lens) && cut.chosen !== "beam" ? "quiet" : cut.chosen
    readonly property bool folded: cut.form === "folder"

    // A stack's sheets (PrismBody: rects [left, right, bottom, corners], steps [left height, right height, middle,
    // lean]) and where its head sits: the name's and the fact's rows, and which of them stands on the lit sheet. All of
    // it inside the head band, so the middle and the foot are the front glass on every form.
    readonly property var stack: {
        const W = cut.width, h = cut.height, H = cut.paneTop, R = cut.face.radius, L = cut.lean
        const at = share => Math.round(H * share)
        const across = (small, other) => Math.round(W * (cut.face.small ? small : other))
        const flat = y => [y, y, 0, 0]
        if (cut.form === "pocket") {
            // A lit sheet with its tab on the right, behind a glass pocket with its tab on the left.
            return { lit: [0, W, H + R, R], litStep: [at(0.36), 0, across(0.62, 0.6), L],
                front: [0, W, h, R], frontStep: [at(0.3), at(0.64), across(0.44, 0.4), L],
                nameY: at(0.65), nameLit: false, factY: at(0.32), factLit: true, side: 0 }
        }
        if (cut.form === "smoked") {
            // A lit card out at the top left, over a smoked pocket whose tab rises on the right.
            const top = cut.pick(3, 3, 5)
            return { lit: [cut.face.dp(4), W - cut.face.dp(4), H + R, Math.max(0, R - cut.face.dp(3))], litStep: flat(top),
                front: [0, W, h, R], frontStep: [at(0.82), at(0.3), across(0.56, 0.46), L],
                nameY: Math.round((top + at(0.82)) / 2), nameLit: true, factY: at(0.65), factLit: false, side: 0 }
        }
        if (cut.form === "archive") {
            // Glass shoulders, a lit sheet standing up between them, a glass pocket in front.
            const side = Math.round(W * 0.11), top = cut.pick(3, 3, 6), row = Math.round((top + at(0.6)) / 2)
            return { base: [0, W, h, R], baseStep: flat(at(0.34)), shade: 0.3,
                lit: [side, W - side, H + R, cut.pick(12, 14, 16)], litStep: flat(top),
                front: [0, W, h, R], frontStep: [at(0.6), at(0.84), across(0.56, 0.46), L],
                nameY: row, nameLit: true, factY: row, factLit: true, side: side }
        }
        if (cut.form === "board") {
            // A darker tray, a lit header inside it, a glass sheet with its tab on the left.
            const b = cut.pick(5, 6, 7), r = Math.max(0, R - b), row = Math.round((b + at(0.54)) / 2)
            return { base: [0, W, h, R], baseStep: flat(0), shade: 0.5,
                lit: [b, W - b, H + R, r], litStep: flat(b),
                front: [b, W - b, h - b, r], frontStep: [at(0.54), at(0.86), across(0.56, 0.46), L],
                nameY: row, nameLit: true, factY: row, factLit: true, side: b }
        }
        return null
    }
    // Where the name ends before a stack's step: a pocket's lit tab, a smoked pocket's rising tab; -1 where only the
    // fact beside it bounds the name.
    readonly property real stepEnd: !cut.stack ? -1
        : cut.form === "pocket" ? cut.stack.litStep[2] - cut.lean / 2 - cut.pick(6, 8, 10)
        : cut.form === "smoked" ? cut.stack.frontStep[2] - cut.lean / 2 - cut.pick(6, 8, 10) : -1
}
