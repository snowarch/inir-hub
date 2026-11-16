import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common.functions
import qs.modules.shared.mediaControls.components
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// The reference's player card: the cover fills it and a frosted sheet holds the song, the scrubber and the transport.
// With nothing playing it is not there at all and the changes above take its room (his 11-16: a card saying
// "Nothing playing" told nothing).
Item {
    id: root
    visible: root.playing
    property bool active: true
    readonly property var player: MprisController.activePlayer
    readonly property bool playing: root.player !== null && media.effectiveTitle.length > 0

    PlayerBase { id: media; player: root.player; positionUpdatesActive: root.active && root.playing }

    Item {
        id: art
        anchors.fill: parent
        visible: root.playing
        layer.enabled: root.playing
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        IrisArtwork {
            id: cover
            anchors.fill: parent
            visible: root.playing
            source: media.displayedArtFilePath
            radius: 0
            decodeSize: Math.max(width, height)
        }
        // The sheet: the cover under it blurred, darkened, with the song on top.
        ShaderEffectSource {
            id: under
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            sourceItem: root.playing ? cover : null
            sourceRect: Qt.rect(sheet.x, sheet.y, sheet.width, sheet.height)
            visible: false
            live: root.active
        }
        MultiEffect {
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            visible: root.playing
            source: under
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.18
            saturation: 0.1
            maskEnabled: true
            maskSource: sheetShape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        // The same smoked sheet as the profile's, inset and concentric with the card, no outline (his 11-16).
        Rectangle {
            id: sheet
            x: PrismTheme.dp(10)
            width: parent.width - PrismTheme.dp(20)
            height: Math.min(parent.height * 0.6, PrismTheme.dp(138))
            y: parent.height - height - PrismTheme.dp(10)
            radius: PrismTheme.dp(14)
            color: PrismTheme.glassSheet
        }
    }
    Rectangle { id: shape; anchors.fill: parent; radius: PrismTheme.dp(24); visible: false; layer.enabled: true }
    Rectangle { id: sheetShape; width: sheet.width; height: sheet.height; radius: sheet.radius; visible: false; layer.enabled: true }

    Column {
        visible: root.playing
        x: sheet.x + PrismTheme.dp(14)
        y: sheet.y + PrismTheme.dp(14)
        width: sheet.width - PrismTheme.dp(28)
        spacing: PrismTheme.dp(2)
        PrismText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: media.effectiveTitle
            color: PrismTheme.paper
            font.pixelSize: PrismTheme.row
            font.weight: Font.DemiBold
        }
        PrismText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: media.effectiveArtist
            color: Qt.rgba(1, 1, 1, 0.6) // iris-literal: Prism's own ink over its art, the same in every scheme
            font.pixelSize: PrismTheme.small
        }
        Item { width: 1; height: PrismTheme.dp(8) }
        // The scrubber, its times at each end.
        Item {
            width: parent.width
            height: PrismTheme.dp(14)
            visible: root.playing
            readonly property real share: media.effectiveIsLive ? 1 : media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0
            PrismText { id: at; anchors.verticalCenter: parent.verticalCenter; text: StringUtils.friendlyTimeForSeconds(media.effectivePosition); figures: true; color: Qt.rgba(1, 1, 1, 0.6); font.pixelSize: PrismTheme.caption * 0.9 } // iris-literal: Prism's own ink over its art, the same in every scheme
            PrismText { id: total; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: media.lengthText; figures: true; color: Qt.rgba(1, 1, 1, 0.6); font.pixelSize: PrismTheme.caption * 0.9 } // iris-literal: Prism's own ink over its art, the same in every scheme
            Rectangle {
                id: bar
                anchors.left: at.right; anchors.leftMargin: PrismTheme.dp(8)
                anchors.right: total.left; anchors.rightMargin: PrismTheme.dp(8)
                anchors.verticalCenter: parent.verticalCenter
                height: PrismTheme.dp(3)
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.22) // iris-literal: Prism's own ink over its art, the same in every scheme
                Rectangle { width: parent.width * parent.parent.share; height: parent.height; radius: parent.radius; color: PrismTheme.paper }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -PrismTheme.dp(6)
                    enabled: media.effectiveCanSeek
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => media.seek(media.effectiveLength * Math.max(0, Math.min(1, (mouse.x - PrismTheme.dp(6)) / bar.width)))
                }
            }
        }
        Item { width: 1; height: PrismTheme.dp(6) }
        Row {
            visible: root.playing
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: PrismTheme.dp(14)
            PrismRound { overArt: true; glyph: "skip_previous"; enabled_: media.effectiveCanGoPrevious; anchors.verticalCenter: parent.verticalCenter; onClicked: media.previous() }
            PrismRound { overArt: true; solid: true; implicitWidth: PrismTheme.dp(38); glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"; glyphSize: PrismTheme.dp(22); onClicked: media.togglePlaying() }
            PrismRound { overArt: true; glyph: "skip_next"; enabled_: media.effectiveCanGoNext; anchors.verticalCenter: parent.verticalCenter; onClicked: media.next() }
        }
    }
}
