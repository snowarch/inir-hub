import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Services.UPower

AndroidQuickToggleButton {
    id: root

    // without a daemon (TLP and the like) the tile hides and PowerProfiles is never touched (Quickshell warns on it)
    readonly property int profile: PowerProfilePersistence.available ? PowerProfiles.profile : PowerProfile.Balanced

    name: Translation.tr("Power Profile")
    visible: PowerProfilePersistence.available
    toggled: root.profile !== PowerProfile.Balanced
    buttonIcon: switch(root.profile) {
        case PowerProfile.PowerSaver: return "energy_savings_leaf"
        case PowerProfile.Balanced: return "settings_slow_motion"
        case PowerProfile.Performance: return "local_fire_department"
    }
    statusText: switch(root.profile) {
        case PowerProfile.PowerSaver: return "Power Saver"
        case PowerProfile.Balanced: return "Balanced"
        case PowerProfile.Performance: return "Performance"
    }
    
    mainAction: () => {
        if (!PowerProfilePersistence.available)
            return
        if (PowerProfiles.hasPerformanceProfile) {
            switch(PowerProfiles.profile) {
                case PowerProfile.PowerSaver: PowerProfiles.profile = PowerProfile.Balanced
                break;
                case PowerProfile.Balanced: PowerProfiles.profile = PowerProfile.Performance
                break;
                case PowerProfile.Performance: PowerProfiles.profile = PowerProfile.PowerSaver
                break;
            }
        } else {
            PowerProfiles.profile = PowerProfiles.profile == PowerProfile.Balanced ? PowerProfile.PowerSaver : PowerProfile.Balanced
        }
    }
    StyledToolTip {
        text: Translation.tr("Click to cycle through power profiles")
    }
}
