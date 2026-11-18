import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// A group on the shelf under the page card (the B · Carpeta study, his 11-17 pick): a folder. Its back sheet is the
// page's art, quiet, with its tab at the right; the front sheet carries the group's name on its own tab at the left,
// what it holds now under it, and the rows.
Item {
    id: root
    // { title, rows }
    property var entry: ({ title: "", rows: [] })
    property string tint: "grey"
    property int turn: 0
    property string flashPath: ""
    readonly property string title: String(root.entry?.title ?? "")

    readonly property real r: PrismTheme.dp(22)
    // Only as deep as the front sheet's step: under glass the front is smoke, and art below it would read through.
    readonly property real backHeight: root.frontY + PrismTheme.dp(30) + root.r
    readonly property real frontY: PrismTheme.dp(34)
    readonly property real padX: PrismTheme.dp(18)
    readonly property real padY: PrismTheme.dp(14)
    readonly property var glance: PrismModel.glanceOf(root.entry)
    readonly property string line: {
        const say = String(root.glance?.say ?? "")
        const label = String(root.glance?.label ?? "")
        return say.length > 0 && label.length > 0 ? say + " · " + label : say.length > 0 ? say : label
    }

    implicitHeight: root.frontY + root.padY + head.implicitHeight + PrismTheme.dp(8) + rows.implicitHeight + PrismTheme.dp(18)

    // The art the back sheet is cut from: drawn once offscreen, never shown by itself.
    PrismFlow {
        id: art
        visible: false
        layer.enabled: true
        width: root.width
        height: root.backHeight
        tint: root.tint
        turn: root.turn
        seed: 0.23 + root.turn * 0.29
        centre: Qt.point(0.62, 0.42)
        thickness: 0.8
        strength: PrismTheme.light ? 0.5 : 0.62
        mute: 0.55
    }
    PrismSheet {
        width: root.width
        height: root.backHeight
        onRight: true
        tab: PrismTheme.dp(150)
        rise: PrismTheme.dp(26)
        slope: PrismTheme.dp(44)
        radius: root.r
        art: art
    }

    PrismSheet {
        id: front
        y: root.frontY
        width: root.width
        height: root.height - root.frontY
        tab: Math.max(PrismTheme.dp(130), Math.min(root.width * 0.62, head.implicitWidth + 2 * root.padX))
        rise: PrismTheme.dp(30)
        slope: PrismTheme.dp(46)
        radius: root.r
        fill: PrismTheme.card
    }

    Column {
        id: head
        x: root.padX
        y: root.frontY + root.padY
        width: root.width - 2 * root.padX
        spacing: PrismTheme.dp(2)
        PrismText {
            width: Math.min(implicitWidth, root.width * 0.62 - 2 * root.padX)
            text: Translation.tr(root.title)
            font.pixelSize: PrismTheme.dp(15)
            font.weight: Font.DemiBold
            font.letterSpacing: -0.15
            elide: Text.ElideRight
        }
        PrismText {
            visible: root.line.length > 0
            width: Math.min(implicitWidth, root.width * 0.62 - 2 * root.padX)
            text: root.line
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.dp(11.5)
            elide: Text.ElideRight
        }
    }

    PrismSection {
        id: rows
        bare: true
        compact: true
        x: root.padX
        y: head.y + head.implicitHeight + PrismTheme.dp(8)
        width: root.width - 2 * root.padX
        title: root.title
        rows: Array.from(root.entry?.rows ?? [])
        flashPath: root.flashPath
    }
}
