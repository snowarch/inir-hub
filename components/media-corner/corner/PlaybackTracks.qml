pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.components
import "../state"

ColumnLayout {
    id: root
    visible: CornerWatch.controllable
    function options(type: string): var {
        const tracks = CornerWatch.playbackTracks.filter(track => track.type === type).map(track => ({
            value: track.id,
            label: track.lang ? Translation.tr("Track %1 (%2)").arg(track.id).arg(track.lang) : Translation.tr("Track %1").arg(track.id)
        }))
        return type === "sub" ? [{ value: "no", label: Translation.tr("None") }].concat(tracks) : tracks
    }
    component TrackRow: RowLayout {
        id: row
        required property string trackType
        required property string heading
        readonly property var choices: root.options(trackType)
        Layout.fillWidth: true
        visible: trackType === "sub" || choices.length > 0
        IrisText { Layout.fillWidth: true; text: row.heading; wrapMode: Text.WordWrap }
        IrisPopupButton {
            accessibleName: row.heading
            options: row.choices
            current: row.trackType === "audio" ? CornerWatch.audioTrack : CornerWatch.subtitleTrack
            onPicked: value => CornerWatch.selectTrack(row.trackType, value)
        }
    }
    TrackRow { trackType: "audio"; heading: Translation.tr("Audio track") }
    TrackRow { trackType: "sub"; heading: Translation.tr("Subtitle track") }
}
