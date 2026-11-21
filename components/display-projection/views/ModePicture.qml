pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common

// What a mode does, drawn: two small screens, lit when on. Duplicate shows the same picture on both, Extend one
// desktop across both. In the accent for the mode on and the one pointed at, neutral for the rest, faint when it can't
// be picked.
Item {
    id: picture

    required property string mode
    property bool lit: false
    property bool usable: true

    readonly property real d: FamilyStyle.density
    readonly property real screenWidth: Math.round(34 * picture.d)
    readonly property real screenHeight: Math.round(23 * picture.d)
    readonly property real stroke: Math.max(1, Math.round(1.5 * picture.d))
    readonly property real gap: picture.mode === "extend" ? 0 : Math.round(8 * picture.d)
    readonly property color ink: !picture.usable ? FamilyStyle.border : picture.lit ? FamilyStyle.accent : FamilyStyle.textSecondary
    readonly property color glow: picture.usable && picture.lit ? FamilyStyle.tintFill(FamilyStyle.accent) : FamilyStyle.fillQuiet
    readonly property int fade: FamilyStyle.duration(180)

    implicitWidth: picture.screenWidth * 2 + picture.gap
    implicitHeight: picture.screenHeight + Math.round(6 * picture.d)

    Row {
        id: screens
        spacing: picture.gap

        Repeater {
            model: 2

            Item {
                id: unit
                required property int index
                readonly property bool on: picture.mode === "pcOnly" ? unit.index === 0
                                         : picture.mode === "secondOnly" ? unit.index === 1
                                         : true
                width: picture.screenWidth
                height: picture.implicitHeight

                Rectangle {
                    id: panel
                    width: parent.width
                    height: picture.screenHeight
                    radius: Math.round(3 * picture.d)
                    color: unit.on ? picture.glow : "transparent"
                    border.width: picture.stroke
                    border.color: unit.on ? picture.ink : FamilyStyle.border
                    opacity: unit.on ? 1 : 0.6
                    Behavior on color { ColorAnimation { duration: picture.fade } }
                    Behavior on border.color { ColorAnimation { duration: picture.fade } }

                    // Duplicate: the same picture on both screens.
                    Rectangle {
                        visible: picture.mode === "duplicate"
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.42)
                        height: Math.round(parent.height * 0.36)
                        radius: Math.round(2 * picture.d)
                        color: picture.ink
                        Behavior on color { ColorAnimation { duration: picture.fade } }
                    }
                }

                // The stand under each screen.
                Rectangle {
                    anchors.top: panel.bottom
                    anchors.topMargin: Math.round(2 * picture.d)
                    anchors.horizontalCenter: panel.horizontalCenter
                    width: Math.round(12 * picture.d)
                    height: picture.stroke
                    radius: picture.stroke
                    color: unit.on ? picture.ink : FamilyStyle.border
                    opacity: panel.opacity
                    Behavior on color { ColorAnimation { duration: picture.fade } }
                }
            }
        }
    }

    // Extend: one desktop that runs across both screens.
    Rectangle {
        visible: picture.mode === "extend"
        x: Math.round(picture.screenWidth * 0.3)
        y: Math.round((picture.screenHeight - height) / 2)
        width: picture.screenWidth * 2 - Math.round(picture.screenWidth * 0.6)
        height: Math.round(picture.screenHeight * 0.36)
        radius: Math.round(2 * picture.d)
        color: picture.ink
        Behavior on color { ColorAnimation { duration: picture.fade } }
    }
}
