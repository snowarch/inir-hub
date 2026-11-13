pragma ComponentBehavior: Bound

// The tuner in Waffle, from its Widgets panel face or the desktop card while Waffle is worn.
import QtQuick
import org.kde.kirigami as Kirigami
import qs.modules.common.functions
import qs.modules.waffle.looks

Item {
    id: root

    // Fluent names for the Material ones the tuner asks for; the radio carries these few Fluent glyphs itself.
    readonly property var fluent: ({
        star: "star", search: "search", close: "dismiss", chevron_left: "chevron-left", chevron_right: "chevron-right",
        history: "history", public: "globe", sell: "tag", translate: "local-language", trending_up: "arrow-trending",
        trophy: "trophy", play_arrow: "play", stop: "stop", skip_next: "next", volume_up: "speaker-2",
        volume_off: "speaker-mute", content_copy: "copy", check: "checkmark", travel_explore: "globe-search",
        radio: "music-note-2", error: "warning", shuffle: "arrow-shuffle", explore: "globe-search"
    })
    function fluentSource(name: string, filled: bool): url {
        const file = root.fluent[name] ?? "music-note-2"
        return Qt.resolvedUrl(`fluent/${file}${filled ? "-filled" : ""}.svg`)
    }
    Component {
        id: fluentGlyph
        Kirigami.Icon {
            property string name: ""
            property real size: 20
            property bool filled: false
            implicitWidth: size
            implicitHeight: size
            source: root.fluentSource(name, filled)
            isMask: true
            roundToIconSize: false
        }
    }
    readonly property var look: ({
        d: Looks.dp(1),
        font: Looks.font.family.ui,
        small: Looks.font.pixelSize.normal,
        meta: Looks.font.pixelSize.large,
        body: Looks.font.pixelSize.larger,
        title: Looks.font.pixelSize.xlarger,
        bg: Looks.colors.bg0,
        raised: Looks.colors.bg2Base,
        track: Looks.colors.controlBg,
        hover: ColorUtils.applyAlpha(Looks.colors.fg, 0.06),
        press: ColorUtils.applyAlpha(Looks.colors.fg, 0.1),
        selected: ColorUtils.applyAlpha(Looks.colors.fg, 0.08),
        ink: Looks.colors.fg,
        muted: Looks.colors.subfg,
        faint: ColorUtils.applyAlpha(Looks.colors.fg, 0.46),
        line: Looks.colors.bg0Border,
        accent: Looks.colors.accent,
        onAccent: Looks.colors.accentFg,
        danger: Looks.colors.danger,
        scrim: ColorUtils.applyAlpha(Looks.colors.bg0, 0.4),
        radius: Looks.radius.large,
        radiusSmall: Looks.radius.medium,
        glyph: fluentGlyph
    })
}
