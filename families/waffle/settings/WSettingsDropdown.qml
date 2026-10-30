pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Dropdown/ComboBox setting row - Windows 11 style
WSettingsRow {
    id: root
    
    property var options: [] // [{value: "x", displayName: "X"}, ...]
    property var currentValue
    
    signal selected(var newValue)
    
    control: Component {
        WComboBox {
            model: root.options
            currentIndex: Math.max(0, root.options.findIndex(option => option.value === root.currentValue))
            onActivated: index => {
                if (index >= 0 && index < root.options.length)
                    root.selected(root.options[index].value)
            }
        }
    }
}
