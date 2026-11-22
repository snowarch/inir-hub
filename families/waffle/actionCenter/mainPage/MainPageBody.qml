import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

// One sheet: the quick settings, then the bars. Screen Time moved to the footer, by the battery.
BodyRectangle {
    id: root
    implicitWidth: Looks.dp(388)
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 0

        MainPageBodyToggles {
            id: togglesContainer
            Layout.fillWidth: true
        }

        MainPageBodySliders {
            Layout.fillWidth: true
            Layout.leftMargin: Looks.dp(16)
            Layout.rightMargin: Looks.dp(16)
            Layout.topMargin: Looks.dp(12)
            Layout.bottomMargin: Looks.dp(16)
        }
    }
}
