pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.shared.background.widgets.instrument
import qs.services

// The card in the iNstrument grammar: a label line, the station as the reading, fields under it. Small keeps the
// reading, where it is and its keys; medium adds what is on air and the volume; large the stations kept.
ColumnLayout {
    id: root

    required property var card
    readonly property var look: root.card.cardLook
    spacing: root.card.px(6)

    InstrumentLabel {
        Layout.fillWidth: true
        text: Translation.tr("Radio") + (root.card.isSmall ? "" : " / " + (root.card.station ? (Radio.tag.length > 0 ? Radio.tag : Radio.current.country) : Translation.tr("Anywhere")))
        color: root.card.widgetAccentVisible
        scaleFactor: root.card.k
        strong: true
    }
    StyledText {
        Layout.fillWidth: true
        text: root.card.title
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 0.95
        font.family: root.card.widgetNumbersFamily
        font.pixelSize: root.card.px(root.card.isSmall ? 18 : 23)
        font.weight: root.card.widgetEditorial ? Appearance.editorial.titleWeight : Font.Bold
        font.letterSpacing: -0.5
        color: root.card.widgetInk
        MouseArea {
            anchors.fill: parent
            enabled: root.card.steerable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.card.openTuner()
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: root.card.isLarge ? 1 : 2
        columnSpacing: root.card.px(14)
        rowSpacing: root.card.px(6)
        InstrumentField {
            Layout.fillWidth: root.card.isSmall || root.card.isLarge
            Layout.preferredWidth: root.card.px(150)
            label: Translation.tr("From")
            value: root.card.station ? Radio.place : "--"
            ink: root.card.widgetInk
            muted: root.card.widgetInkMuted
            family: root.card.widgetNumbersFamily
            scaleFactor: root.card.k
        }
        InstrumentField {
            visible: !root.card.isSmall
            Layout.fillWidth: true
            label: root.card.playing ? Translation.tr("On air") : Translation.tr("Status")
            value: root.card.statusLine
            ink: root.card.failed ? root.card.widgetAccentVisible : root.card.widgetInk
            muted: root.card.widgetInkMuted
            family: root.card.widgetNumbersFamily
            scaleFactor: root.card.k
        }
    }
    Rectangle {
        visible: root.card.isLarge
        Layout.fillWidth: true
        Layout.topMargin: root.card.px(6)
        Layout.bottomMargin: root.card.px(4)
        implicitHeight: 1
        color: root.look.line
    }
    RadioCardStations {
        visible: root.card.isLarge
        Layout.fillWidth: true
        card: root.card
        rows: 3
    }
    Item { Layout.fillHeight: true; Layout.fillWidth: true }
    RowLayout {
        Layout.fillWidth: true
        spacing: root.card.px(2)
        enabled: root.card.steerable
        RadioButton {
            look: root.look
            glyph: root.card.playIcon
            filled: true
            on: root.card.playing
            label: root.card.playing ? Translation.tr("Stop") : Translation.tr("Play")
            size: root.card.px(32)
            onClicked: Radio.playPause()
        }
        RadioButton {
            visible: !root.card.isSmall && root.card.station !== null
            look: root.look
            glyph: "star"
            on: Radio.kept
            label: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            size: root.card.px(32)
            onClicked: Radio.toggleFavourite(root.card.station)
        }
        RadioButton {
            look: root.look
            glyph: "explore"
            filled: true
            label: Translation.tr("Find a station")
            size: root.card.px(32)
            onClicked: root.card.openTuner()
        }
        RadioButton {
            look: root.look
            glyph: "skip_next"
            filled: true
            enabled: !root.card.waiting
            label: Translation.tr("Next station")
            size: root.card.px(32)
            onClicked: Radio.next()
        }
        Item { Layout.fillWidth: true }
        RadioVolume {
            visible: !root.card.isSmall
            look: root.look
            barWidth: root.card.px(96)
        }
    }
}
