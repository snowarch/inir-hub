// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtMultimedia
import Quickshell
import qs.services

Scope {
    id: root
    required property EditorSession session
    property alias videoOutput: media.videoOutput
    readonly property real position: media.position
    readonly property bool playing: media.playbackState === MediaPlayer.PlayingState
    readonly property bool loading: media.mediaStatus === MediaPlayer.LoadingMedia || media.mediaStatus === MediaPlayer.BufferingMedia

    function pause(): void { media.pause(); }
    function play(): void { if (root.session.ready) media.play(); }
    function toggle(): void { if (root.playing) root.pause(); else root.play(); }
    function seek(position): void { if (root.session.ready) media.position = Math.max(root.session.startMs, Math.min(root.session.effectiveEndMs, position)); }
    function step(direction): void { root.pause(); root.seek(media.position + direction * root.session.frameMs); }
    function stop(): void { media.stop(); }

    MediaPlayer {
        id: media
        source: root.session.ready ? root.session.metadata.url || "" : ""
        autoPlay: true
        loops: MediaPlayer.Infinite
        playbackRate: root.session.playbackRate
        audioOutput: audio.item
        onPositionChanged: {
            if (!root.playing || !root.session.ready || root.session.renderOpen) return;
            if (media.position >= root.session.effectiveEndMs || media.position < root.session.startMs) media.position = root.session.startMs;
        }
        onErrorChanged: if (error !== MediaPlayer.NoError) {
            root.session.status = "error";
            root.session.errorMessage = Translation.tr("The video could not be played.");
            root.session.errorDetail = errorString;
        }
    }
    Loader {
        id: audio
        active: root.session.ready && root.session.metadata.audio?.present === true
        sourceComponent: AudioOutput { volume: root.session.mute ? 0 : root.session.volume }
    }
    Connections {
        target: root.session
        function onLoadRequested(): void { root.stop(); }
        function onRenderOpenChanged(): void { if (root.session.renderOpen) root.pause(); }
    }
}
