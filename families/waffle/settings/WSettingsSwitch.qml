pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Switch setting row - Windows 11 style
WSettingsRow {
    id: root
    
    property bool checked: false
    
    clickable: true
    onClicked: root.checked = !root.checked
    
    // Windows puts the state in words left of the toggle (ToggleSwitch OnContent / OffContent)
    control: Component {
        RowLayout {
            spacing: Looks.dp(12)
            WText {
                text: root.checked ? Translation.tr("On") : Translation.tr("Off")
                font.pixelSize: Looks.settings.body
                font.weight: Looks.font.weight.thin
            }
            WSwitch {
                checked: root.checked
                onClicked: root.checked = !root.checked
            }
        }
    }
}
