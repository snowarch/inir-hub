import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.common

// An app's icon as NiHiL shows it: its own picture with the colour taken out while `monochrome` (the bar's
// one-colour row), its detail kept, a touch brighter on a dark piece.
Item {
    id: root

    property string iconName: ""
    property bool monochrome: Config.options?.nihil?.bar?.monochromeIcons ?? true
    property real size: NihilStyle.s(24)

    implicitWidth: root.size
    implicitHeight: root.size

    IconImage {
        id: icon
        anchors.fill: parent
        source: Quickshell.iconPath(root.iconName, "application-x-executable")
        visible: !root.monochrome
        asynchronous: true
    }
    MultiEffect {
        anchors.fill: icon
        source: icon
        visible: root.monochrome
        saturation: -1
        contrast: 0.15
        brightness: NihilStyle.dark ? 0.12 : -0.05
    }
}
