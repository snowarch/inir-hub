pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// Switch setting row - Windows 11 style. A click asks (`toggled`) and the page writes the setting; `checked` stays
// bound to the setting, so a change made anywhere else still shows (a click that set `checked` cut that binding).
WSettingsRow {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    clickable: true
    onClicked: root.toggled(!root.checked)

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
                id: flip
                checked: root.checked
                // The switch flips itself on a click; it takes the row's state back once the page has answered.
                onClicked: {
                    root.toggled(!root.checked)
                    flip.checked = Qt.binding(() => root.checked)
                }
            }
        }
    }
}
