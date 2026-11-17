import QtQuick
import QtQuick.Shapes
import qs.modules.iris.prism.core
import qs.modules.iris.prism.fx

// A group as a folder (`.claude/ref/language`: the glass folders, the Taskello card, Délavé's dividers): the front
// sheet with a tab at its top left that carries the group's number and name, and behind the tab's step the folder's
// art, the page's colours in a ribbon of its own, with what the group holds now printed on it. The host lays the
// tab's words and the rows over the front sheet; this draws only the two sheets.
Item {
    id: root
    // The tab's width (its words and their air), and how far it rises over the front's top edge.
    property real tabWidth: PrismTheme.dp(240)
    property real rise: PrismTheme.dp(46)
    property real radius: PrismTheme.dp(24)
    property string tint: "grey"
    property int turn: 0
    property real seed: 0
    property color sheet: PrismTheme.card
    // Room on the art for what it says, so the ribbon gathers away from it.
    property real sayWidth: 0
    // Off, only the front sheet is drawn: the host lays its own art behind the step (the page's lead folder).
    property bool art: true

    readonly property real slope: Math.round(root.rise * 1.25)
    readonly property real tab: Math.max(root.radius * 2, Math.min(root.tabWidth, root.width - root.slope - root.radius * 2))
    readonly property real shoulder: Math.round(root.radius * 0.7)
    // Where the art shows: right of the step, above the front's top edge.
    readonly property real artX: root.tab + root.slope * 0.5
    readonly property real artWidth: root.width - root.artX

    // The back sheet. It starts under the step and goes down past the front's shoulder, so the round corner there
    // shows art behind it as a real folder's would. A page holds many folders under one loud poster: the back rests
    // quieter and greyer than the poster (his 11-16: every card's colour pulled the eye), and over the desktop's glass
    // it is smoke with the light inside it (white frost in light), so the blur behind reads through it as through the rest.
    PrismFlow {
        visible: root.art
        bare: PrismTheme.glass
        frostColour: PrismTheme.light ? Qt.rgba(1, 1, 1, 0.42) : Qt.rgba(0, 0, 0, 0.18) // iris-literal: the back sheet's smoke, under the front's
        strength: PrismTheme.light ? 0.58 : 0.66
        mute: 0.22
        x: root.tab - PrismTheme.dp(4)
        width: root.width - x
        height: root.rise + root.shoulder + PrismTheme.dp(2)
        tint: root.tint
        turn: root.turn
        seed: root.seed
        // The ribbon gathers between the step and the words.
        centre: Qt.point(Math.max(0.15, Math.min(0.7, (root.artWidth - root.sayWidth) / Math.max(1, width) * 0.55)), 0.46)
        // Thick enough to read as a diffused field of colour, not a line of neon.
        thickness: 0.58
        topRightRadius: root.radius
        topLeftRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: 0
        // Over glass the front sheet is frosted: the art and its frost end exactly at its edge, never seen through it.
        cut: PrismTheme.glass ? Qt.vector4d(PrismTheme.dp(4), root.slope, root.rise, root.shoulder) : Qt.vector4d(0, 0, 0, 0)
    }

    // The front sheet: the tab, a soft step down to the front's edge, its round shoulder, then the card. No outline:
    // its fill alone sets it off (his 11-16).
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.sheet
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg {
                readonly property real w: root.width
                readonly property real h: Math.max(root.height, root.rise + root.radius * 2)
                readonly property real r: root.radius
                readonly property real t: root.tab
                readonly property real s: root.slope
                readonly property real k: root.rise
                readonly property real o: root.shoulder
                path: `M 0 ${r} Q 0 0 ${r} 0 L ${t} 0 `
                    + `C ${t + s * 0.5} 0 ${t + s * 0.5} ${k} ${t + s} ${k} `
                    + `L ${w - o} ${k} Q ${w} ${k} ${w} ${k + o} `
                    + `L ${w} ${h - r} Q ${w} ${h} ${w - r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h - r} Z`
            }
        }
    }

    // The front sheet is frosted (folders-glass): the art behind it glows through its top, blurred, and dies away
    // before the first row. The same ribbon a step lower, so the light that shows is the light behind the step.
    PrismFlow {
        visible: root.art
        x: root.tab
        y: root.rise
        width: root.width - x
        height: Math.min(PrismTheme.dp(96), Math.max(0, root.height - root.rise))
        tint: root.tint
        turn: root.turn
        seed: root.seed
        centre: Qt.point(Math.max(0.15, Math.min(0.7, (root.artWidth - root.sayWidth) / Math.max(1, width) * 0.55)), -0.1)
        thickness: 0.5
        fade: 0.08
        side: 0.3
        bare: true
        mute: 0.22
        opacity: PrismTheme.light ? 0.24 : 0.3
        topRightRadius: root.shoulder
        topLeftRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: 0
    }
}
