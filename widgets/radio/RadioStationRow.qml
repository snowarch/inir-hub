pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import "radio.js" as R

// One station in a tuner list: its logo, name, where it is and what it plays, the stream's quality and its star.
// The station that plays now wears the accent.
Item {
    id: root

    required property var modelData
    required property int index
    property var look
    property var list: []
    readonly property real d: root.look?.d ?? 1
    readonly property bool now: Radio.current?.uuid === root.modelData.uuid
    readonly property bool kept: Radio.favouriteIds[root.modelData.uuid] === true
    // Prism's grammar: a chart, each row numbered, a squircle mark, hairlines between rows.
    readonly property bool prism: root.look?.grammar === "prism"
    readonly property bool lit: mouse.containsMouse || (root.ListView.isCurrentItem && (root.ListView.view?.activeFocus ?? false))

    width: ListView.view?.width ?? 0
    height: Math.round(58 * root.d)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Math.round(4 * root.d)
        anchors.rightMargin: Math.round(4 * root.d)
        anchors.topMargin: root.prism ? Math.round(3 * root.d) : 0
        anchors.bottomMargin: root.prism ? Math.round(3 * root.d) : 0
        radius: root.prism ? Math.round(14 * root.d) : root.look.radiusSmall
        color: mouse.pressed ? root.look.press : root.lit ? root.look.hover : "transparent"
    }
    Rectangle {
        visible: root.prism && !root.lit
        anchors { bottom: parent.bottom; left: logo.left; right: parent.right; rightMargin: Math.round(12 * root.d) }
        height: 1
        color: root.look.line
    }
    // The chart's number; the station that plays shows it sounding instead.
    Item {
        id: rank
        visible: root.prism
        x: Math.round(10 * root.d)
        width: root.prism ? Math.round(30 * root.d) : 0
        height: parent.height
        Text {
            anchors.centerIn: parent
            visible: !root.now
            text: String(root.index + 1)
            font.family: root.look.font
            font.pixelSize: root.look.meta
            font.features: { "tnum": 1 }
            color: root.lit ? root.look.ink : root.look.faint
        }
        RadioGlyph {
            anchors.centerIn: parent
            visible: root.now
            look: root.look
            name: "graphic_eq"
            size: Math.round(16 * root.d)
            color: root.look.accentInk ?? root.look.accent
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Radio.play(root.modelData, root.list)
    }

    RadioLogo {
        id: logo
        x: root.prism ? rank.x + rank.width + Math.round(6 * root.d) : Math.round(14 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        station: root.modelData
        size: Math.round((root.prism ? 36 : 40) * root.d)
        radius: root.prism ? Math.round(9 * root.d) : Math.min(size / 4, root.look?.radiusSmall ?? 8)
    }
    Column {
        anchors.left: logo.right
        anchors.leftMargin: Math.round((root.prism ? 14 : 12) * root.d)
        anchors.right: quality.left
        anchors.rightMargin: Math.round(10 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(2 * root.d)
        Row {
            width: parent.width
            spacing: Math.round(6 * root.d)
            Rectangle {
                visible: root.now && !root.prism
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(6 * root.d)
                height: width
                radius: width / 2
                color: root.look.accent
            }
            Text {
                width: parent.width - (root.now && !root.prism ? Math.round(12 * root.d) : 0)
                text: root.modelData.name
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.body
                font.weight: Font.DemiBold
                color: root.now ? (root.prism ? root.look.accentInk : root.look.accent) : root.look.ink
            }
        }
        Text {
            width: parent.width
            text: `${R.flag(root.modelData.code)} ${R.meta(root.modelData)}`.trim()
            elide: Text.ElideRight
            font.family: root.look.font
            font.pixelSize: root.look.meta
            color: root.look.muted
        }
    }
    Text {
        id: quality
        anchors.right: star.left
        anchors.rightMargin: Math.round(8 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        text: R.quality(root.modelData)
        font.family: root.look.font
        font.pixelSize: root.look.small
        color: root.look.faint
    }
    RadioButton {
        id: star
        anchors.right: parent.right
        anchors.rightMargin: Math.round(12 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        glyph: "star"
        on: root.kept
        opacity: root.kept || mouse.containsMouse || hovered ? 1 : 0
        readonly property bool hovered: starHover.hovered
        HoverHandler { id: starHover }
        label: root.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
        onClicked: Radio.toggleFavourite(root.modelData)
    }
}
