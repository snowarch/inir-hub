pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// One group of the compositor's settings as a Windows expander: its icon, its name and a line of what it holds,
// closed until pressed. Rows come from CompositorRows by group; a group the running compositor cannot do hides.
WSettingsCard {
    id: root

    property string group: ""
    property var rows: CompositorRows.of(root.group)

    collapsible: true
    expanded: false
    visible: root.rows.length > 0

    Repeater {
        model: ScriptModel { values: root.rows; objectProp: "key" }
        WCompositorRow {}
    }
}
