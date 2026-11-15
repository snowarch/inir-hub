pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.preview.parts

// Mouse & pointer: the pointer at its size crossing to a window's button, its trail spaced by the speed set (even when
// flat, quick in the middle when adaptive) and longer the faster it is set; where the compositor has hot corners
// (Umbriel), each corner that does something, with what it does.
PreviewScene {
    id: pointerRoot
    readonly property real naturalWidth: Math.round(600 * pointerRoot.d)
    readonly property real naturalHeight: Math.round(300 * pointerRoot.d)
    narrowest: Math.round(400 * pointerRoot.d)
    lowest: Math.round(220 * pointerRoot.d)
    subject: Qt.rect(arrow.x, arrow.y, arrow.width, arrow.height)
    readonly property int cursorSize: Math.max(16, Math.min(64, Number(pointerRoot.niri("input", "cursor.xcursor-size", 24))))
    readonly property real speed: Math.max(-1, Math.min(1, Number(pointerRoot.niri("input", "mouse.accel-speed", 0))))
    readonly property bool flat: String(pointerRoot.niri("input", "mouse.accel-profile", "adaptive")) === "flat"
    readonly property bool natural: pointerRoot.niri("input", "mouse.natural-scroll", false) === true
    // Hot corners, where the compositor has them: what each does, by its own names (an older base without the list
    // shows the corners bare).
    readonly property bool corners: CompositorConfig.has("corners", "top-left")
    readonly property var actions: CompositorConfig.cornerActions ?? []
    function cornerGlyph(key: string): string {
        if (!pointerRoot.corners) return ""
        const now = String(pointerRoot.niri("corners", key, ""))
        if (now.length === 0) return ""
        return String(pointerRoot.actions.find(action => action.value === now || (action.also ?? []).includes(now))?.glyph ?? "terminal")
    }
    readonly property real reach: Math.round(46 * pointerRoot.d)

    property real t: 1
    Loop on t { running: pointerRoot.playing; rest: 1600 }

    // The window the pointer goes to.
    Rectangle {
        id: win
        x: Math.round(pointerRoot.width * 0.38)
        y: Math.round(36 * pointerRoot.d)
        width: Math.round(pointerRoot.width * 0.42)
        height: Math.round(pointerRoot.height - 36 * pointerRoot.d - 60 * pointerRoot.d)
        radius: IrisStyle.radiusPlate
        color: IrisStyle.surfaceOpaque
        WindowPage { anchors.fill: parent }
    }

    // The trail: where the pointer was at even moments. Faster set, longer; adaptive, wider apart mid-way.
    // It ends on the window's first button (WindowPage's left button), coming from the wallpaper below.
    readonly property point end: Qt.point(win.x + win.width * 0.44, win.y + win.height * 0.56)
    readonly property real stretch: 0.55 + 0.45 * (pointerRoot.speed + 1) / 2
    readonly property point start: Qt.point(pointerRoot.end.x + (pointerRoot.width * 0.06 - pointerRoot.end.x) * pointerRoot.stretch,
        pointerRoot.end.y + (pointerRoot.height * 0.86 - pointerRoot.end.y) * pointerRoot.stretch)
    function along(u: real): point {
        const bow = Math.sin(Math.PI * u) * 22 * pointerRoot.d
        return Qt.point(pointerRoot.start.x + (pointerRoot.end.x - pointerRoot.start.x) * u,
            pointerRoot.start.y + (pointerRoot.end.y - pointerRoot.start.y) * u - bow)
    }
    readonly property int marks: 22
    function stepAt(i: int): real {
        const u = i / (pointerRoot.marks - 1)
        return pointerRoot.flat ? u : (1 - Math.cos(Math.PI * u)) / 2
    }
    Repeater {
        model: pointerRoot.marks - 1
        Rectangle {
            id: dot
            required property int index
            readonly property real u: pointerRoot.stepAt(dot.index)
            readonly property point at: pointerRoot.along(dot.u)
            width: Math.round((2.5 + 3.5 * dot.index / pointerRoot.marks) * pointerRoot.d)
            height: width
            radius: width / 2
            x: dot.at.x - width / 2
            y: dot.at.y - height / 2
            color: IrisStyle.onMedia
            opacity: dot.u <= pointerRoot.t ? 0.15 + 0.7 * dot.index / pointerRoot.marks : 0
        }
    }
    MaterialSymbol {
        id: arrow
        readonly property point at: pointerRoot.along(pointerRoot.t)
        x: Math.round(arrow.at.x - width * 0.28)
        y: Math.round(arrow.at.y - height * 0.18)
        text: "arrow_selector_tool"
        fill: 1
        iconSize: Math.round(pointerRoot.cursorSize * 1.3 * pointerRoot.d) // the glyph draws its arrow in about three quarters of its box
        color: IrisStyle.onMedia
    }
    // Its dark rim, as every cursor theme draws it: white alone vanished over a light window.
    MaterialSymbol {
        x: arrow.x
        y: arrow.y
        text: arrow.text
        fill: 0
        iconSize: arrow.iconSize
        color: Qt.rgba(0, 0, 0, 0.82) // iris-literal: a cursor's rim is black in every theme
    }

    // The corners that do something: a quarter lit, with what resting there does.
    Repeater {
        model: pointerRoot.corners ? [{ key: "top-left", east: false, south: false }, { key: "top-right", east: true, south: false },
            { key: "bottom-left", east: false, south: true }, { key: "bottom-right", east: true, south: true }] : []
        Item {
            id: corner
            required property var modelData
            readonly property string glyph: pointerRoot.cornerGlyph(corner.modelData.key)
            visible: corner.glyph.length > 0
            Rectangle {
                x: corner.modelData.east ? pointerRoot.width - pointerRoot.reach : -pointerRoot.reach
                y: corner.modelData.south ? pointerRoot.height - pointerRoot.reach : -pointerRoot.reach
                width: 2 * pointerRoot.reach
                height: width
                radius: width / 2
                color: IrisStyle.sceneVeilStrong
            }
            MaterialSymbol {
                readonly property real inset: Math.round(pointerRoot.reach * 0.36)
                x: corner.modelData.east ? pointerRoot.width - inset - width / 2 : inset - width / 2
                y: corner.modelData.south ? pointerRoot.height - inset - height / 2 : inset - height / 2
                text: corner.glyph
                fill: 1
                iconSize: Math.round(16 * pointerRoot.d)
                color: IrisStyle.onMedia
            }
        }
    }

    // The pointer, its trail and, where there are hot corners, the first that does something (or the first corner).
    spots: {
        const d = pointerRoot.d, s = pointerRoot.start, e = pointerRoot.end
        const lift = 22 * d
        const out = [
            { group: "Pointer", x: arrow.x + arrow.width + 12 * d, y: arrow.y + arrow.height * 0.9,
                part: Qt.rect(arrow.x - 4 * d, arrow.y - 4 * d, arrow.width + 8 * d, arrow.height + 8 * d), radius: 8 * d },
            { group: "Mouse", x: s.x + 4 * d, y: s.y - 22 * d,
                part: Qt.rect(Math.min(s.x, e.x) - 10 * d, Math.min(s.y, e.y) - lift - 10 * d, Math.abs(e.x - s.x) + 20 * d, Math.abs(e.y - s.y) + lift + 20 * d), radius: 14 * d }
        ]
        if (!pointerRoot.corners) return out
        const w = pointerRoot.width, h = pointerRoot.height, r = pointerRoot.reach
        const lit = ["top-left", "top-right", "bottom-left", "bottom-right"].find(key => pointerRoot.cornerGlyph(key).length > 0) ?? "top-left"
        const east = lit.endsWith("right"), south = lit.startsWith("bottom")
        out.push({ group: "Hot corners", x: east ? w - r - 12 * d : r + 12 * d, y: south ? h - r * 0.5 : r * 0.5,
            part: Qt.rect(east ? w - r : 0, south ? h - r : 0, r, r), radius: r / 2 })
        return out
    }

    Caption {
        glyph: "arrow_selector_tool"
        text: [Translation.tr("Cursor size") + " " + pointerRoot.cursorSize + " px", pointerRoot.natural ? Translation.tr("Natural scrolling") : ""]
            .filter(part => part.length > 0).join(" · ")
    }
}
