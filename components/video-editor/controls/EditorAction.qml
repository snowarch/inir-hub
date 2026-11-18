// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.waffle.looks

Loader {
    id: root
    property string label: ""
    property string symbol: ""
    property string hint: ""
    property bool primary: false
    property bool selected: false
    property bool chrome: false
    signal clicked()
    active: visible
    sourceComponent: EditorSkin.iris ? irisAction : EditorSkin.waffle ? waffleAction : materialAction
    Component {
        id: irisAction
        IrisChip {
            id: chip
            label: root.label
            glyph: root.symbol
            emphasized: root.primary
            selected: root.selected
            buttonRadius: EditorSkin.classic && !root.chrome ? EditorSkin.smallRadius : height / 2
            buttonRadiusPressed: buttonRadius
            foreground: root.primary ? EditorSkin.inkOnSolid
                : root.selected ? EditorSkin.rowOnInk
                : EditorSkin.colors.text
            colBackground: root.primary ? EditorSkin.solid
                : root.selected ? EditorSkin.rowOn
                : root.chrome ? (EditorSkin.prism ? "transparent" : IrisStyle.fillQuiet) // literal: bare chrome key in Prism
                : EditorSkin.plate
            colBackgroundHover: root.primary ? Qt.tint(EditorSkin.solid, IrisStyle.fillQuiet)
                : root.selected ? EditorSkin.rowOn
                : IrisStyle.fillHover
            colBackgroundToggled: root.primary ? EditorSkin.solid : EditorSkin.rowOn
            colBackgroundToggledHover: root.primary ? Qt.tint(EditorSkin.solid, IrisStyle.fillQuiet) : EditorSkin.rowOn
            onClicked: root.clicked()
            Accessible.name: root.label || root.hint
            Rectangle {
                anchors.fill: parent
                visible: EditorSkin.edgeWidth > 0 && !root.primary && !root.chrome
                radius: chip.buttonRadius
                color: "transparent" // literal: hairline edge on Prism plates
                border.width: EditorSkin.edgeWidth
                border.color: EditorSkin.edge
            }
        }
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
