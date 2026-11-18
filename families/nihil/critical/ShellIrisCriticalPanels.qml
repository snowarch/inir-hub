pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.nihil.background
import qs.modules.nihil.bar
import qs.modules.nihil.frame
import qs.modules.nihil.style

Item {
    id: root

    IrisVerbs {}
    IrisDevSims {}

    component CriticalPanelLoader: LazyLoader {
        required property string identifier
        property bool extraCondition: true
        active: Config.ready && IrisGate.official
            && (Config.options?.enabledPanels ?? []).includes(identifier)
            && extraCondition
    }

    CriticalPanelLoader {
        identifier: "irisBackground"
        extraCondition: !(Config.options?.nihil?.modules?.desktopWidgets ?? true)
        component: IrisBackground {}
    }

    LazyLoader {
        active: Config.ready && IrisGate.official
        component: IrisReservations {}
    }

    CriticalPanelLoader {
        identifier: "irisBar"
        component: IrisBar {}
    }
}
