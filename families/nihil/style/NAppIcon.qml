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
    // On a paper tile the one-colour icon prints dark.
    property bool onPaper: false

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
        brightness: root.onPaper === NihilStyle.dark ? -0.45 : 0.12
    }
}
