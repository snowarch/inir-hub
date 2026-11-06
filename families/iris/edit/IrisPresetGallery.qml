pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.iris.style
import qs.modules.iris.settings

// Style's presets (his 11-02: "una forma de poner una estética clara"): every theme as your own desktop would wear it,
// one tap applies the whole look and Undo takes it back. The same cards Customize shows (IrisThemeCard).
GridLayout {
    id: root
    readonly property real d: IrisStyle.settingsDensity
    readonly property int count: IrisThemes.all.length
    columns: Math.max(2, Math.min(4, Math.floor((root.width + columnSpacing) / Math.round(200 * root.d))))
    rowSpacing: Math.round(14 * root.d)
    columnSpacing: Math.round(12 * root.d)
    Repeater {
        model: IrisThemes.all
        IrisThemeCard {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: (root.width - (root.columns - 1) * root.columnSpacing) / root.columns
            Layout.alignment: Qt.AlignTop
            theme: modelData
            settingsHistory: true
            onShareRequested: {
                Quickshell.clipboardText = IrisThemes.exportText(modelData)
                // Edit's notice shows only in Customize: in Settings the island says it.
                IrisOptions.note({ glyph: "ios_share", name: String(modelData.name), say: Translation.tr("Copied. Paste it anywhere."),
                    swatch: String(IrisThemes.swatch(modelData).accent), row: IrisOptions.settings.find(spec => spec.kind === "themes") ?? null })
            }
        }
    }
}
