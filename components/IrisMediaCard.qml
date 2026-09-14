pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.mediaControls.components
import qs.modules.iris.style

Item {
    id: root
    property var player: MprisController.activePlayer
    property bool compact: false
    property bool active: visible
    property bool showBackground: true
    readonly property bool hasPlayer: root.player !== null && root.player !== undefined
    implicitHeight: body.implicitHeight + 28 * IrisStyle.density
    implicitWidth: 360 * IrisStyle.density
    PlayerBase { id: media; player: root.player; positionUpdatesActive: root.active }

    Item {
        anchors.fill: parent
        visible: root.showBackground
        Rectangle { anchors.fill: parent; radius: IrisStyle.radiusSmall; color: IrisStyle.surfaceHigh }
        Loader {
            anchors.fill: parent
            active: root.active && root.showBackground && (Config.options?.iris?.player?.artworkBackground ?? true)
                && media.displayedArtFilePath.length > 0
            sourceComponent: IrisMediaBackdrop { source: media.displayedArtFilePath; radius: IrisStyle.radiusSmall; strength: 0.5 }
        }
    }
    ColumnLayout {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14 * IrisStyle.density
        spacing: root.compact ? 6 : 12 * IrisStyle.density
        RowLayout {
            Layout.fillWidth: true
            spacing: 14 * IrisStyle.density
            IrisArtwork {
                visible: !root.compact
                source: media.displayedArtFilePath
                circular: Config.options?.iris?.player?.roundCover ?? true
                Layout.preferredWidth: 68 * IrisStyle.density
                Layout.preferredHeight: 68 * IrisStyle.density
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveTitle : Translation.tr("Nothing playing"); font.weight: Font.DemiBold; elide: Text.ElideRight }
                IrisText { Layout.fillWidth: true; text: root.hasPlayer ? media.effectiveArtist : Translation.tr("Your music appears here"); role: IrisText.Meta; elide: Text.ElideRight }
            }
        }
        IrisScrubber {
            Layout.fillWidth: true
            visible: !root.compact && media.effectiveLength > 0
            seekable: media.effectiveCanSeek
            fillColor: IrisStyle.text
            trackColor: ColorUtils.applyAlpha(IrisStyle.text, 0.22)
            value: media.effectiveLength > 0 ? media.effectivePosition / media.effectiveLength : 0
            onSeekRequested: next => media.seek(next * media.effectiveLength)
        }
        RowLayout {
            Layout.fillWidth: true
            IrisText { visible: !root.compact; text: StringUtils.friendlyTimeForSeconds(media.effectivePosition); role: IrisText.Meta }
            Item { Layout.fillWidth: true }
            IrisIconButton { materialIcon: "skip_previous"; Accessible.name: Translation.tr("Previous track"); enabled: media.effectiveCanGoPrevious; onClicked: media.previous() }
            IrisIconButton { materialIcon: media.effectiveIsPlaying ? "pause" : "play_arrow"; Accessible.name: media.effectiveIsPlaying ? Translation.tr("Pause") : Translation.tr("Play"); enabled: root.hasPlayer; onClicked: media.togglePlaying(); iconSize: 26 }
            IrisIconButton { materialIcon: "skip_next"; Accessible.name: Translation.tr("Next track"); enabled: media.effectiveCanGoNext; onClicked: media.next() }
            Item { Layout.fillWidth: true }
            IrisText { visible: !root.compact; text: StringUtils.friendlyTimeForSeconds(media.effectiveLength); role: IrisText.Meta }
        }
    }
}
