// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

Item {
    id: root
    property color color: EditorSkin.card
    property real radius: EditorSkin.cardRadius
    property int borderWidth: EditorSkin.edgeWidth
    property color borderColor: EditorSkin.edge
    property real bleedX: 0
    property real bleedY: 0
    property bool section: false
    property bool panel: false
    readonly property bool painted: !root.section || EditorSkin.cards
    default property alias content: host.data
    Loader {
        x: -root.bleedX
        y: -root.bleedY
        width: root.width + root.bleedX * 2
        height: root.height + root.bleedY * 2
        active: root.visible && root.painted
        sourceComponent: EditorSkin.iris ? (root.panel ? irisPanel : irisCard) : EditorSkin.waffle ? waffleSurface : materialSurface
    }
    Component {
        id: irisCard
        Rectangle {
            color: root.color
            radius: root.radius
            border.width: root.borderWidth
            border.color: root.borderColor
        }
    }
    Component {
        id: irisPanel
        Item {
            IrisMorphSurface {
                anchors.fill: parent
                open: true
                settles: true
                motionSurface: "settings"
                glass: !EditorSkin.prism
                color: root.color
                radius: root.radius
            }
            Rectangle {
                anchors.fill: parent
                visible: root.borderWidth > 0
                radius: root.radius
                color: "transparent" // literal: hairline edge on Prism prompt
                border.width: root.borderWidth
                border.color: root.borderColor
            }
        }
    }
    Component {
        id: materialSurface
        PanelSurface {
            elevation: 1
            opaqueSurface: EditorSkin.prism
            cardStyle: EditorSkin.cards
            radiusOverride: root.radius
            borderWidthOverride: root.borderWidth
        }
    }
    Component {
        id: waffleSurface
        Rectangle {
            id: paper
            color: root.color
            radius: root.radius
            border.width: root.borderWidth
            border.color: root.borderColor
            WRectangularShadow { target: paper; z: -1 }
            WAmbientShadow { target: paper }
        }
    }
    Item { id: host; anchors.fill: parent }
}
