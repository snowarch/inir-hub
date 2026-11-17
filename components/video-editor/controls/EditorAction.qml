// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

// Only adapts the three public controls' APIs; each family owns its face and input.
Loader {
    id: root
    property string label: ""
    property string symbol: ""
    property string hint: ""
    property bool primary: false
    property bool selected: false
    signal clicked()
    active: visible
    sourceComponent: EditorSkin.iris ? irisAction : EditorSkin.waffle ? waffleAction : materialAction
    Component {
        id: irisAction
        IrisChip { label: root.label; glyph: root.symbol; emphasized: root.primary; selected: root.selected; onClicked: root.clicked(); Accessible.name: root.label || root.hint }
    }
    Component {
        id: waffleAction
        WButton { text: root.label; icon.name: root.symbol ? WIcons.fluentFromMaterial(root.symbol) : ""; checked: root.primary || root.selected; onClicked: root.clicked(); Accessible.name: root.label || root.hint }
    }
    Component {
        id: materialAction
        RippleButtonWithIcon { mainText: root.label; materialIcon: root.symbol; toggled: root.primary || root.selected; onClicked: root.clicked(); Accessible.name: root.label || root.hint }
    }
    StyledToolTip { parent: root.item; text: root.hint; extraVisibleCondition: root.hint !== ""; font.family: EditorSkin.mainFont }
}
