pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.services

// The large card's shortcuts: the person's favourites, then what they played lately. A click plays.
Column {
    id: root

    required property var card
    property int rows: 3
    readonly property var look: root.card.cardLook
    // Favourites first, then what played lately, so the rows are never half empty.
    readonly property var list: Radio.favourites.concat(Radio.recent.filter(s => !Radio.favouriteIds[s.uuid]))
    spacing: root.card.px(2)

    Text {
        width: parent.width
        text: Translation.tr("Your stations")
        elide: Text.ElideRight
        font.family: root.look.font
        font.pixelSize: root.look.small
        font.weight: Font.DemiBold
        font.capitalization: root.card.widgetCapitalization
        font.letterSpacing: root.card.px(1)
        color: root.look.faint
        bottomPadding: root.card.px(4)
    }
    Text {
        visible: root.list.length === 0
        width: parent.width
        text: Translation.tr("Star a station and it waits here")
        wrapMode: Text.WordWrap
        font.family: root.look.font
        font.pixelSize: root.look.body
        color: root.look.muted
    }
    Repeater {
        model: root.list.slice(0, root.rows)
        Item {
            id: row
            required property var modelData
            readonly property bool now: Radio.current?.uuid === row.modelData.uuid
            width: root.width
            height: root.card.px(36)
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -root.card.px(6)
                anchors.rightMargin: -root.card.px(6)
                radius: root.look.radiusSmall
                color: press.pressed ? root.look.press : press.containsMouse ? root.look.hover : "transparent"
            }
            RadioLogo {
                id: logo
                anchors.verticalCenter: parent.verticalCenter
                look: root.look
                station: row.modelData
                size: root.card.px(28)
            }
            Text {
                anchors { left: logo.right; leftMargin: root.card.px(10); right: mark.left; rightMargin: root.card.px(6); verticalCenter: parent.verticalCenter }
                text: row.modelData.name ?? ""
                elide: Text.ElideRight
                font.family: root.look.font
                font.pixelSize: root.look.body
                font.weight: row.now ? Font.DemiBold : Font.Medium
                color: row.now ? root.look.accent : root.look.ink
            }
            RadioGlyph {
                id: mark
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                readonly property bool kept: Radio.favouriteIds[row.modelData.uuid] === true
                visible: mark.kept || (row.now && Radio.playing)
                look: root.look
                name: row.now && Radio.playing ? "graphic_eq" : "star"
                filled: true
                size: root.card.px(14)
                color: row.now ? root.look.accent : root.look.faint
            }
            MouseArea {
                id: press
                anchors.fill: parent
                enabled: root.card.steerable
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Radio.play(row.modelData, root.list)
            }
        }
    }
}
