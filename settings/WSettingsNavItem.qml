pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.waffle.looks

// Navigation item for Windows 11 style settings sidebar
Button {
    id: root
    
    property string navIcon: ""
    property bool selected: false
    property bool expanded: true
    
    implicitHeight: 44
    implicitWidth: expanded ? 220 : 48
    
    background: Rectangle {
        radius: Looks.radius.large
        color: {
            if (root.selected) return Looks.colors.bg2Hover
            if (root.down) return Looks.colors.bg2Active
            if (root.hovered) return Looks.colors.bg2Hover
            return "transparent"
        }
        
        // Selection indicator - Win11 pill style
        Rectangle {
            visible: root.selected
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: 3.5
            height: root.down ? 8 : 18
            radius: 2
            color: Looks.colors.accent
            
            Behavior on height {
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.fast : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
            }
        }

        Behavior on color {
            animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
        }
    }
    
    contentItem: RowLayout {
        spacing: root.expanded ? 12 : 0
        
        Item {
            implicitWidth: 22
            implicitHeight: 22
            Layout.leftMargin: root.expanded ? 16 : 0
            Layout.fillWidth: !root.expanded
            Layout.alignment: root.expanded ? Qt.AlignVCenter : Qt.AlignCenter
            
            FluentIcon {
                anchors.centerIn: parent
                icon: root.navIcon
                implicitSize: root.expanded ? 18 : 20
                color: root.selected ? Looks.colors.accent : Looks.colors.subfg
                
                Behavior on color {
                    animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                }
            }
        }
        
        WText {
            visible: root.expanded
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Looks.font.pixelSize.large
            font.weight: root.selected ? Looks.font.weight.strong : Looks.font.weight.thin
            color: root.selected ? Looks.colors.fg : Looks.colors.subfg
            elide: Text.ElideRight
            
            Behavior on color {
                animation: ColorAnimation { duration: Looks.transition.enabled ? 70 : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
            }
        }
    }
    
    WToolTip {
        visible: !root.expanded && root.hovered
        text: root.text
    }
}
