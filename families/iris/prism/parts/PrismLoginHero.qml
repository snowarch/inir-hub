pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common
import qs.modules.iris.preview
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Login's head, as Lock opens on the lock screen: the greeter in miniature, drawn from the same settings it reads
// (LoginScene), so a style is seen before the next boot. Beside it the styles themselves, one press each; their row
// leaves the page's group (PrismModel's onStage). While the greeter is not installed the styles still show and say why
// they wait.
Rectangle {
    id: root

    readonly property var styleRow: PrismModel.find("lock.loginStyle")
    readonly property var screenRow: PrismModel.find("lock.loginScreen")
    readonly property string screen: String(root.screenRow ? PrismModel.read(root.screenRow) : "auto")
    // Cover, Frame and Lens are iRiS's own greeter; Classic and Waffle have one face each.
    readonly property bool styled: root.styleRow !== null && PrismModel.shown(root.styleRow)
    readonly property string style: String(root.styleRow ? PrismModel.read(root.styleRow) : "lens")
    readonly property bool locked: root.styleRow !== null && PrismModel.locked(root.styleRow)
    readonly property string waits: root.styleRow ? PrismModel.note(root.styleRow) : ""
    readonly property var glyphs: ({ cover: "wallpaper", frame: "frame_inspect", lens: "blur_on" })

    readonly property bool wide: root.width >= PrismTheme.dp(620)
    readonly property real pad: PrismTheme.dp(20)
    readonly property real gap: PrismTheme.dp(8)

    implicitHeight: root.wide ? Math.max(stage.height, side.implicitHeight) + 2 * root.pad
        : stage.height + side.implicitHeight + 3 * root.pad
    radius: PrismTheme.cardRadius
    color: PrismTheme.card

    IrisGroupPreview {
        id: stage
        x: root.pad
        y: root.pad
        width: root.wide ? Math.round((root.width - 3 * root.pad) * 0.62) : root.width - 2 * root.pad
        // The greeter's own screen shape.
        height: Math.round(stage.width * 9 / 16)
        radius: PrismTheme.dp(14)
        section: "login"
        group: "Login Screen"
        holdsStill: true
        framed: false
        captionOutside: true
        playing: root.visible
    }

    Column {
        id: side
        x: root.wide ? stage.x + stage.width + root.pad : root.pad
        y: root.wide ? root.pad : stage.y + stage.height + root.pad
        width: root.wide ? root.width - x - root.pad : root.width - 2 * root.pad
        spacing: root.gap

        PrismText {
            width: parent.width
            text: root.styled ? Translation.tr("Login style") : Translation.tr("Login screen")
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
        }
        // What the greeter looks like now, in one line under its name.
        PrismText {
            width: parent.width
            text: stage.caption
            font.pixelSize: PrismTheme.row
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            maximumLineCount: 3
        }
        Item { width: 1; height: PrismTheme.dp(4) }
        Repeater {
            model: root.styled ? (root.styleRow?.choices ?? []) : []
            delegate: PrismTile {
                id: tile
                required property var modelData
                width: side.width
                glyph: root.glyphs[String(tile.modelData.value)] ?? "login"
                label: Translation.tr(String(tile.modelData.label))
                isSwitch: false
                on: root.style === String(tile.modelData.value)
                enabled: !root.locked
                opacity: root.locked ? 0.5 : 1
                onClicked: if (!tile.on) PrismModel.write(root.styleRow, tile.modelData.value)
            }
        }
        PrismText {
            visible: root.waits.length > 0
            width: parent.width
            text: root.waits
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 4
        }
    }
}
