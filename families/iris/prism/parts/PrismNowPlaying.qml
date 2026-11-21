import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common.functions
import qs.modules.shared.mediaControls.components
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// What is playing, in the side column. As the cover (iris.appearance.settingsPlayer: cover) it fills the card and a
// frosted sheet holds the song, the scrubber and the transport; as the bar, one line on the cover's own blur. With
// nothing playing it is not there at all (no filler).
Item {
    id: root
    property bool active: true
    property string form: "cover"
    readonly property bool bar: root.form === "bar"
    readonly property var player: MprisController.activePlayer
    readonly property bool playing: root.player !== null && media.effectiveTitle.length > 0
    readonly property real share: media.effectiveIsLive ? 1 : media.effectiveLength > 0 ? Math.min(1, media.effectivePosition / media.effectiveLength) : 0
    implicitHeight: root.bar ? PrismTheme.dp(64) : width

    PlayerBase { id: media; player: root.player; positionUpdatesActive: root.active && root.playing }

    Item {
        id: art
        anchors.fill: parent
        visible: root.playing && !root.bar
        layer.enabled: art.visible
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
            source: art.visible ? media.displayedArtFilePath : ""
            radius: 0
            decodeSize: Math.max(width, height)
        }
        // The sheet: the cover under it blurred, darkened, with the song on top.
        ShaderEffectSource {
            id: under
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            sourceItem: art.visible ? cover : null
            sourceRect: Qt.rect(sheet.x, sheet.y, sheet.width, sheet.height)
            visible: false
            live: root.active
        }
        MultiEffect {
            x: sheet.x; y: sheet.y; width: sheet.width; height: sheet.height
            visible: art.visible
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
        Rectangle {
            id: sheet
            x: PrismTheme.dp(8)
            width: parent.width - PrismTheme.dp(16)
            // As tall as what it holds: no empty foot under the keys, and the cover keeps the rest.
            height: Math.min(parent.height - PrismTheme.dp(16), song.implicitHeight + PrismTheme.dp(30))
            y: parent.height - height - PrismTheme.dp(8)
            radius: PrismTheme.dp(18)
            color: Qt.rgba(0.07, 0.07, 0.09, 0.42) // iris-literal: Prism's own ink over its art, the same in every scheme
            // Glass catches light on its top edge only, brightest in the middle: a rim, never an outline.
            Rectangle {
                x: sheet.radius * 0.6
                y: 0
                width: sheet.width - x * 2
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.26) } // iris-literal: Prism's own ink over its art, the same in every scheme
                    GradientStop { position: 1; color: "transparent" }
                }
            }
        }
    }
    // The bar: the cover blurred into its own ground, the cover small at the left, the song, its two keys, and the time
    // as a hairline along the foot.
    Item {
        id: strip
        anchors.fill: parent
        visible: root.playing && root.bar
        layer.enabled: strip.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: shape
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        IrisArtwork {
            id: ground
            anchors.fill: parent
            source: strip.visible ? media.displayedArtFilePath : ""
            radius: 0
            decodeSize: PrismTheme.dp(96)
        }
        ShaderEffectSource {
            id: groundBlurSource
            anchors.fill: parent
            sourceItem: strip.visible ? ground : null
            hideSource: true
            visible: false
            live: root.active
        }
        MultiEffect {
            anchors.fill: parent
            source: groundBlurSource
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.3
            saturation: 0.15
        }
        // With no picture the ground is Prism's own smoke.
        Rectangle {
            anchors.fill: parent
            color: ground.bare ? PrismTheme.glassSheet : "transparent"
        }
        IrisArtwork {
            id: thumb
            x: PrismTheme.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            width: PrismTheme.dp(44)
            height: width
            radius: PrismTheme.dp(10)
            source: strip.visible ? media.displayedArtFilePath : ""
            decodeSize: width * 2
        }
        Column {
            anchors.left: thumb.right
            anchors.leftMargin: PrismTheme.dp(12)
            anchors.right: barKeys.left
            anchors.rightMargin: PrismTheme.dp(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(1)
            PrismText {
                width: parent.width
                text: media.effectiveTitle
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.body
                font.weight: Font.DemiBold
            }
            PrismText {
                width: parent.width
                text: media.effectiveArtist
                color: Qt.rgba(1, 1, 1, 0.64) // iris-literal: Prism's own ink over its art, the same in every scheme
                font.pixelSize: PrismTheme.small
            }
        }
        Row {
            id: barKeys
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(4)
            PrismRound { overArt: true; solid: true; implicitWidth: PrismTheme.dp(34); glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"; glyphSize: PrismTheme.dp(20); anchors.verticalCenter: parent.verticalCenter; onClicked: media.togglePlaying() }
            PrismRound { overArt: true; implicitWidth: PrismTheme.dp(30); glyph: "skip_next"; enabled_: media.effectiveCanGoNext; anchors.verticalCenter: parent.verticalCenter; onClicked: media.next() }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * root.share * 2) / 2
            height: PrismTheme.dp(2)
            color: Qt.rgba(1, 1, 1, 0.8) // iris-literal: Prism's own ink over its art, the same in every scheme
        }
    }

    Rectangle { id: shape; anchors.fill: parent; radius: root.bar ? PrismTheme.dp(18) : PrismTheme.dp(22); visible: false; layer.enabled: true }
    Rectangle { id: sheetShape; width: sheet.width; height: sheet.height; radius: sheet.radius; visible: false; layer.enabled: true }

    Column {
        id: song
        visible: art.visible
        x: sheet.x + PrismTheme.dp(14)
        y: sheet.y + PrismTheme.dp(15)
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
                Rectangle { width: Math.round(parent.width * root.share * 2) / 2; height: parent.height; radius: parent.radius; color: PrismTheme.paper }
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
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: PrismTheme.dp(14)
            PrismRound { overArt: true; glyph: "skip_previous"; enabled_: media.effectiveCanGoPrevious; anchors.verticalCenter: parent.verticalCenter; onClicked: media.previous() }
            PrismRound { overArt: true; solid: true; implicitWidth: PrismTheme.dp(38); glyph: media.effectiveIsPlaying ? "pause" : "play_arrow"; glyphSize: PrismTheme.dp(22); onClicked: media.togglePlaying() }
            PrismRound { overArt: true; glyph: "skip_next"; enabled_: media.effectiveCanGoNext; anchors.verticalCenter: parent.verticalCenter; onClicked: media.next() }
        }
    }
}