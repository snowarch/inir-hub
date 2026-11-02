pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Tiles · Mosaic: the time laid in tiles, one per figure, like the pieces of a board game, and the day on two lit tiles
// after it. A figure that changes turns its tile over; nothing else moves. Only the resting clock; the engine draws the rest.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: row.implicitWidth
    readonly property date now: DateTime.clock.date
    readonly property real tile: Math.round(root.h - 14 * root.d)
    readonly property var parts: {
        const raw = String(DateTime.timeDisplay ?? "").trim()
        const period = raw.match(/\s*([^\d:.\s]+)$/)
        const pieces = (period ? raw.slice(0, period.index) : raw).split(/[:.]/)
        return { hours: String(pieces[0] ?? ""), minutes: String(pieces[1] ?? ""), period: period ? period[1] : "" }
    }
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(3 * root.d)

        Repeater {
            model: root.parts.hours.split("")
            Piece { required property string modelData; figure: modelData }
        }
        // The separator is two pegs between the groups, in the accent.
        Column {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: Math.round(2 * root.d)
            rightPadding: Math.round(2 * root.d)
            spacing: Math.round(root.tile * 0.2)
            Repeater {
                model: 2
                Rectangle { width: Math.round(3.5 * root.d); height: width; radius: width / 2; color: root.mark }
            }
        }
        Repeater {
            model: root.parts.minutes.split("")
            Piece { required property string modelData; figure: modelData }
        }
        IrisText {
            visible: root.parts.period.length > 0
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: Math.round(3 * root.d)
            text: root.parts.period
            font.pixelSize: Math.round(10 * root.d)
            font.weight: IrisStyle.weight(Font.Bold)
            color: IrisStyle.subtext
        }
        Item { width: Math.round(6 * root.d); height: 1 }
        Repeater {
            model: Translation.locale.toString(root.now, "dd").split("")
            Piece { required property string modelData; figure: modelData; small: true; lit: true }
        }
    }

    // One tile: a lit plate (lighter at its top, as every iRiS body) with its figure; a new figure turns it over.
    component Piece: Item {
        id: piece
        property string figure: ""
        property bool small: false
        property bool lit: false
        property string shown: ""
        anchors.verticalCenter: parent?.verticalCenter
        width: Math.round((piece.small ? 0.82 : 1) * root.tile * 0.74)
        height: Math.round((piece.small ? 0.82 : 1) * root.tile)
        Component.onCompleted: piece.shown = piece.figure
        onFigureChanged: {
            if (!IrisStyle.motionEnabled || piece.shown.length === 0) { piece.shown = piece.figure; return }
            turnOver.restart()
        }
        SequentialAnimation {
            id: turnOver
            NumberAnimation { target: turn; property: "angle"; to: 90; duration: IrisStyle.duration(140); easing.type: Easing.InQuad }
            ScriptAction { script: piece.shown = piece.figure }
            NumberAnimation { target: turn; property: "angle"; from: -90; to: 0; duration: IrisStyle.duration(200); easing.type: Easing.OutCubic }
        }
        transform: Rotation { id: turn; origin.x: piece.width / 2; origin.y: piece.height / 2; axis { x: 1; y: 0; z: 0 } }
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.tileRadius(piece.width)
            color: piece.lit ? IrisStyle.tintFill(root.mark) : IrisStyle.fillQuiet
            border.width: 1
            border.color: piece.lit ? ColorUtils.applyAlpha(root.mark, 0.35) : IrisStyle.hairline
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: parent.radius * 0.6
                anchors.topMargin: 1
                height: 1
                color: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
            }
        }
        IrisText {
            anchors.centerIn: parent
            text: piece.shown
            font.pixelSize: Math.round(piece.height * 0.62)
            font.family: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.fontNumbers
            font.weight: IrisStyle.weight(Font.Bold)
            font.features: ({ "tnum": 1 })
            color: piece.lit ? root.mark : IrisStyle.text
        }
    }
}
