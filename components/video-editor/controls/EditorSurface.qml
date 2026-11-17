// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

// Public family surfaces own their material and shadow. Content has one stable host.
Item {
    id: root
    property color color: EditorSkin.colors.card
    property real radius: EditorSkin.radius
    default property alias content: host.data
    Loader {
        anchors.fill: parent
        active: root.visible
        sourceComponent: EditorSkin.iris ? irisSurface : EditorSkin.waffle ? waffleSurface : materialSurface
    }
    Component {
        id: irisSurface
        IrisMorphSurface { open: true; settles: true; motionSurface: "settings"; glass: false; color: root.color; radius: root.radius }
    }
    Component {
        id: materialSurface
        PanelSurface { elevation: 1; opaqueSurface: true; radiusOverride: root.radius }
    }
    Component {
        id: waffleSurface
        Rectangle {
            id: paper
            color: root.color; radius: root.radius
            WRectangularShadow { target: paper; z: -1 }
            WAmbientShadow { target: paper }
        }
    }
    Item { id: host; anchors.fill: parent }
}
