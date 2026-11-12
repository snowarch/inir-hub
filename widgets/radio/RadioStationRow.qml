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

    width: ListView.view?.width ?? 0
    height: Math.round(58 * root.d)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Math.round(4 * root.d)
        anchors.rightMargin: Math.round(4 * root.d)
        radius: root.look.radiusSmall
        color: mouse.pressed ? root.look.press : mouse.containsMouse || (root.ListView.isCurrentItem && (root.ListView.view?.activeFocus ?? false)) ? root.look.hover : "transparent"
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
        x: Math.round(14 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        look: root.look
        station: root.modelData
        size: Math.round(40 * root.d)
    }
    Column {
        anchors.left: logo.right
        anchors.leftMargin: Math.round(12 * root.d)
        anchors.right: quality.left
        anchors.rightMargin: Math.round(10 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(2 * root.d)
        Row {
            width: parent.width
            spacing: Math.round(6 * root.d)
            Rectangle {
                visible: root.now
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(6 * root.d)
                height: width
                radius: width / 2
                color: root.look.accent
            }
            Text {
                width: parent.width - (root.now ? Math.round(12 * root.d) : 0)
                text: root.modelData.name
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.body
                font.weight: Font.DemiBold
                color: root.now ? root.look.accent : root.look.ink
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
