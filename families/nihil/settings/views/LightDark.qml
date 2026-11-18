import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Light or dark, for the whole shell.
NSegmented {
    implicitWidth: NihilStyle.s(240)
    accessibleName: Translation.tr("Light or dark")
    options: [{ value: false, label: "Light", glyph: "light_mode" }, { value: true, label: "Dark", glyph: "dark_mode" }]
    current: Appearance.m3colors.darkmode
    onPicked: value => MaterialThemeLoader.setDarkMode(value)
}
