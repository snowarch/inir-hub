import QtQuick
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

OSDValue {
    id: root
    iconName: WIcons.volumeIcon ?? "speaker"
    label: Translation.tr("Volume")
    value: Audio.sink?.audio.volume ?? 0
    muted: Audio.sink?.audio.muted ?? false

    Connections {
        // Listen to volume changes
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            if (Audio.ready)
                root.timer.restart();
        }
        function onMutedChanged() {
            if (Audio.ready)
                root.timer.restart();
        }
    }
}
