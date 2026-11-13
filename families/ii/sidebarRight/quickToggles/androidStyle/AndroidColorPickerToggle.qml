import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root

    name: Translation.tr("Color picker")
    statusText: ""
    toggled: false
    buttonIcon: "colorize"

    // The picker waits for the sidebar to leave before it reads the screen.
    mainAction: () => {
        GlobalStates.sidebarRightOpen = false;
        GlobalStates.screenColorPickerOpen = true;
    }

    StyledToolTip {
        text: Translation.tr("Color picker")
    }
}
