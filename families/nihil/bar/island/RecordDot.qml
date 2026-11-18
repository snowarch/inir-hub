pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.components

// The recording mark, breathing (IrisPulse).
IrisPulse {
    implicitWidth: 9 * IrisStyle.density
    implicitHeight: implicitWidth
    color: IrisStyle.danger
}
