pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../state"

// One mode: its picture and its name. The mode on now is tinted and wears the accent ring. A press answers on the way
// down; the pick happens on release, so sliding off the tile cancels it.
Rectangle {
    id: tile

    required property string mode
    required property int index
    property bool active: false
    // The keys or the pointer are on it.
    property bool focused: false
    property bool working: false
    property bool finished: false
    signal picked()
    signal pointed()

    readonly property real d: FamilyStyle.density
    readonly property bool usable: Projection.canUse(tile.mode)
    readonly property real inset: Math.round(12 * tile.d)
    readonly property real side: Math.round(8 * tile.d)

    implicitWidth: Math.round(128 * tile.d)
    implicitHeight: body.implicitHeight + caption.implicitHeight + tile.inset * 2 + Math.round(6 * tile.d)
    radius: FamilyStyle.radiusTile
    color: !tile.usable ? FamilyStyle.fillQuiet
         : area.pressed ? FamilyStyle.fillActive
         : tile.active ? (area.containsMouse ? FamilyStyle.tintFillHover(FamilyStyle.accent) : FamilyStyle.tintFill(FamilyStyle.accent))
         : area.containsMouse ? FamilyStyle.fillHover
         : FamilyStyle.fill
    border.width: Math.max(2, Math.round(2 * tile.d))
    border.color: tile.active ? FamilyStyle.accent : "transparent"
    scale: area.pressed ? FamilyStyle.pressScale(0.97) : 1

    Behavior on scale {
        NumberAnimation { duration: FamilyStyle.feedbackDuration; easing.type: FamilyStyle.feedbackEasing }
    }
    Behavior on color {
        ColorAnimation { duration: FamilyStyle.feedbackDuration }
    }
    Behavior on border.color {
        ColorAnimation { duration: FamilyStyle.duration(220) }
    }

    Accessible.role: Accessible.Button
    Accessible.name: Projection.modeName(tile.mode)
    Accessible.description: tile.active ? Translation.tr("Active") : ""

    Column {
        id: body
        anchors.top: parent.top
        anchors.topMargin: tile.inset
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - tile.side * 2
        spacing: Math.round(10 * tile.d)

        ModePicture {
            anchors.horizontalCenter: parent.horizontalCenter
            mode: tile.mode
            usable: tile.usable
            lit: tile.active || tile.focused
            opacity: tile.usable ? 1 : 0.55
        }

        StyledText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: Projection.modeName(tile.mode)
            color: !tile.usable ? FamilyStyle.textTertiary : tile.active ? FamilyStyle.textStrong : FamilyStyle.text
            font.family: FamilyStyle.fontMain
            font.pixelSize: FamilyStyle.typeLabel
            font.weight: FamilyStyle.weight(tile.active ? Font.DemiBold : Font.Medium)
        }
    }

    // On the tile's foot, so the captions line up whatever the names wrap to.
    StyledText {
        id: caption
        anchors.bottom: parent.bottom
        anchors.bottomMargin: tile.inset
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - tile.side * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: tile.finished ? Translation.tr("Done")
            : tile.working ? Translation.tr("Applying…")
            : tile.active ? Translation.tr("Active")
            : " "
        color: tile.finished ? FamilyStyle.success : FamilyStyle.accent
        font.family: FamilyStyle.fontMain
        font.pixelSize: FamilyStyle.typeFootnote
        font.weight: FamilyStyle.weight(Font.Medium)
        font.letterSpacing: FamilyStyle.typeFootnote * 0.02
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: tile.usable
        cursorShape: Qt.PointingHandCursor
        onEntered: tile.pointed()
        onClicked: tile.picked()
    }
}
