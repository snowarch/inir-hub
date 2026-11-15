pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks
import qs.modules.waffle.settings

// Settings › Devices, as Windows' Bluetooth & devices: the keyboard, the mouse, the trackpad, the pointer, a pen
// tablet and a touch screen, each an expander of what the compositor can set for it. A device the running compositor
// has nothing for hides; the trackpad shows only on a machine that has one.
WSettingsPage {
    id: root
    settingsPageIndex: 21
    pageTitle: Translation.tr("Devices")
    pageIcon: "phone-desktop"
    pageDescription: Translation.tr("Keyboard, mouse, trackpad, pen, touch")

    Component.onCompleted: CompositorConfig.ensure()

    Repeater {
        model: [
            { group: "Keyboard", icon: "keyboard", title: Translation.tr("Keyboard"), line: Translation.tr("Layout, repeat and Num Lock") },
            { group: "Mouse", icon: "cursor-click", title: Translation.tr("Mouse"), line: Translation.tr("Speed, scrolling and buttons") },
            { group: "Trackpad", icon: "tap-single", title: Translation.tr("Trackpad"), line: Translation.tr("Tapping, scrolling and speed") },
            { group: "Pointer", icon: "cursor", title: Translation.tr("Pointer"), line: Translation.tr("Cursor, focus and where the pointer goes") },
            { group: "Tablet", icon: "pen", title: Translation.tr("Tablet"), line: Translation.tr("Which screen the pen draws on") },
            { group: "Touch screen", icon: "tablet", title: Translation.tr("Touch screen"), line: Translation.tr("Which screen takes touch") }
        ]
        WCompositorGroup {
            required property var modelData
            group: modelData.group
            icon: modelData.icon
            title: modelData.title
            description: modelData.line
        }
    }
}
