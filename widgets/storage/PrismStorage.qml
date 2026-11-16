pragma ComponentBehavior: Bound

// The desktop card in Prism (the widget design "Prism" of iRiS): the tab names it, the flap says what is left on the
// drive it leads with, and the bars are the body; the lead drive's bar is the one thing the light breaks on (it wears
// the spectrum), a drive past nine tenths the warning colour. Small: the lead drive. Medium: three. Large: six.
import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.widgets
import qs.modules.iris.widgets.prism

PrismFolder {
    id: root

    readonly property var card: root.widget
    readonly property bool drawn: root.card.emptyText.length === 0
    readonly property var shown: root.small ? (root.card.leadDrive ? [root.card.leadDrive] : []) : root.card.drivesFor(root.large ? 6 : 3)

    tabGlyph: "hard_drive"
    tabText: Translation.tr("Storage")
    // The flap says what the lines do not: what is left on the lead drive (small) or on all (large); medium counts them.
    flapText: !root.drawn ? "" : root.medium ? root.card.countText : root.large ? root.card.totalFree : root.card.leadFree
    flapSuffix: root.drawn && !root.medium ? root.card.freeWord : ""
    flapGlyph: ""
    lightPass: root.card.leadDrive && root.card.leadDrive.taken >= 0.9 ? 0.55 : 1

    readonly property real barsTop: root.paneTop + root.pick(root.folded ? 8 : 4, root.folded ? 8 : 4, root.folded ? 12 : 6)
    readonly property real barsBottom: root.folded ? root.paneBottom - root.pick(8, 8, 12) : root.height - root.inset

    StorageBars {
        visible: root.drawn
        x: root.inset
        y: root.barsTop
        width: root.innerWidth
        height: root.barsBottom - root.barsTop
        drives: root.shown
        leading: root.card.leadIn(root.shown)
        d: root.k
        t: root.t
        fontMain: root.fontMain
        fontNumbers: root.fontNumbers
        nameSize: root.type(12, 12.5, 13)
        figureSize: root.type(11, 11.5, 12)
        bar: root.small ? 8 : 6
        ink: root.ink
        inkMuted: root.inkSecondary
        track: root.fillQuiet
        fill: root.inkTertiary
        full: root.danger
        lit: root.ink
        systemName: root.card.systemName
        homeName: root.card.homeName
        freeText: root.card.freeText
        sizeText: root.card.sizeText
        figure: root.small ? "size" : "free"
        litEffect: Component { PrismSpectrum { mono: root.nothing; white: 0.1 } }
    }
    FaceText {
        visible: !root.drawn
        face: root
        x: root.inset
        y: root.barsTop
        width: root.innerWidth
        height: root.height - root.inset - root.barsTop
        text: root.card.emptyText
        color: root.inkSecondary
        size: root.type(12, 13, 14)
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
