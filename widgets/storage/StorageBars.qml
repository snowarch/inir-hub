pragma ComponentBehavior: Bound

// One drive a line: its name, what is left on it, and a bar of what it holds. Every face draws its drives with this,
// in its own ink: the bar's taken part in `fill`, a drive past nine tenths in `full`, the one the face leads with in
// `lit` (Prism lays its spectrum there through `litEffect`).
import QtQuick
import "storage.js" as Logic

Item {
    id: root
    property var drives: []
    property real d: 1
    property real t: 1
    property string fontMain: ""
    property string fontNumbers: ""
    property real nameSize: 12
    property real figureSize: 12
    property real bar: 6
    property color ink: "white"
    property color inkMuted: "gray"
    property color track: "#22ffffff"
    property color fill: "white"
    property color full: "red"
    property color lit: "white"
    // Which line leads (lit), -1 none.
    property int leading: 0
    property Component litEffect: null
    // Names for drives the system mounts without a label ("/" and "/home"), in the person's language.
    property string systemName: "System"
    property string homeName: "Home"
    property string freeText: "%1 free"
    // What the figure beside a name says: "free" (what is left) or "size" (what the drive holds in all, for a face
    // whose head already says what is left).
    property string figure: "free"
    property string sizeText: "of %1"

    function nameOf(drive: var): string {
        return drive.label.length > 0 ? drive.label : drive.system ? root.systemName : root.homeName
    }
    function px(v: real): int { return Math.round(v * root.d) }

    readonly property real lineHeight: root.drives.length > 0 ? root.height / root.drives.length : 0

    Repeater {
        model: root.drives
        delegate: Item {
            id: line
            required property var modelData
            required property int index
            readonly property bool filled: line.modelData.taken >= 0.9
            readonly property bool leads: line.index === root.leading
            readonly property color tone: line.filled ? root.full : line.leads ? root.lit : root.fill
            width: root.width
            height: root.lineHeight
            y: line.index * root.lineHeight

            // Words over the bar, the block centred in its line: the eye reads name, then what is left, then the shape.
            readonly property real words: Math.max(name.implicitHeight, figure.implicitHeight)
            readonly property real blockY: Math.round((line.height - line.words - root.px(6) - root.px(root.bar)) / 2)
            Text {
                id: figure
                anchors.right: parent.right
                y: line.blockY + line.words - implicitHeight
                text: root.figure === "size" ? root.sizeText.arg(Logic.sizeOf(line.modelData.size).text)
                    : root.freeText.arg(Logic.sizeOf(line.modelData.free).text)
                color: line.filled ? root.full : root.inkMuted
                font.family: root.fontNumbers
                font.pixelSize: Math.round(root.figureSize * root.t)
                font.features: ({ "tnum": 1 })
            }
            Text {
                id: name
                anchors.left: parent.left
                anchors.right: figure.left
                anchors.rightMargin: root.px(10)
                anchors.baseline: figure.baseline
                text: root.nameOf(line.modelData)
                elide: Text.ElideRight
                color: root.ink
                font.family: root.fontMain
                font.pixelSize: Math.round(root.nameSize * root.t)
                font.weight: Font.DemiBold
            }
            Rectangle {
                id: track
                y: line.blockY + line.words + root.px(6)
                width: parent.width
                height: root.px(root.bar)
                radius: height / 2
                color: root.track
                Rectangle {
                    width: Math.max(parent.height, parent.width * line.modelData.taken)
                    height: parent.height
                    radius: parent.radius
                    color: line.tone
                    layer.enabled: line.leads && !line.filled && root.litEffect !== null
                    layer.effect: root.litEffect
                }
            }
        }
    }
}
