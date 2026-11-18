pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.settings

// What people reach for most, one tap each; a key that holds a state stays lit while it is on.
Grid {
    id: root

    readonly property var keys: [
        { glyph: "dark_mode", label: Translation.tr("Dark mode"), on: () => Appearance.m3colors.darkmode,
            tap: () => MaterialThemeLoader.setDarkMode(!Appearance.m3colors.darkmode) },
        { glyph: "notifications_off", label: Translation.tr("Do not disturb"), on: () => Config.options?.notifications?.silent ?? false,
            tap: () => Config.setNestedValue("notifications.silent", !(Config.options?.notifications?.silent ?? false)) },
        { glyph: "nightlight", label: Translation.tr("Night light"), on: () => Hyprsunset.active, tap: () => Hyprsunset.toggle() },
        { glyph: "energy_savings_leaf", label: Translation.tr("Low power"), on: () => Config.options?.performance?.lowPower ?? false,
            tap: () => Config.setNestedValue("performance.lowPower", !(Config.options?.performance?.lowPower ?? false)) },
        { glyph: "wallpaper", label: Translation.tr("Wallpaper"), on: () => false, tap: () => SettingsModel.run("wallpaper") },
        { glyph: "dashboard_customize", label: Translation.tr("Edit desktop"), on: () => false, tap: () => SettingsModel.run("editDesktop") }
    ]

    columns: root.width >= NihilStyle.s(760) ? 6 : root.width >= NihilStyle.s(420) ? 3 : 2
    spacing: NihilStyle.cellGap
    readonly property real keyWidth: (root.width - root.spacing * (root.columns - 1)) / root.columns

    Repeater {
        model: root.keys
        NButton {
            id: key
            required property var modelData
            width: root.keyWidth
            height: NihilStyle.s(92)
            square: true
            lit: key.modelData.on()
            tone: NihilStyle.pieceRaised
            activeFocusOnTab: true
            Keys.onSpacePressed: key.modelData.tap()
            Keys.onReturnPressed: key.modelData.tap()
            Accessible.role: Accessible.Button
            Accessible.name: key.modelData.label
            onClicked: key.modelData.tap()
            Column {
                anchors.centerIn: parent
                width: parent.width - NihilStyle.s(14)
                spacing: NihilStyle.s(8)
                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: key.modelData.glyph
                    size: NihilStyle.s(24)
                    color: key.ink
                }
                NText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    mono: true
                    text: key.modelData.label
                    font.pixelSize: NihilStyle.textSmall
                    color: key.ink
                }
            }
            NFocus { shown: key.activeFocus }
        }
    }
}
