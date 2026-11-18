pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.iris.pieces
import qs.modules.iris.prism.core

// Where a piece sits on the screen: the screen in small, the Island at its top, a mark at each place it can stand; a
// press on a mark puts it there, a press anywhere else places it freely. Small at a row's end; `big` when it is the
// group's own choice, as wide as its room, so the page leads with the screen itself.
Item {
    id: root
    property string place: "island"
    property real fx: 0.5
    property real fy: 0.5
    property bool hasIsland: false
    property string label: ""
    property bool big: false
    signal placed(string zone)
    signal placedFree(real x, real y)

    readonly property real k: root.big ? 1.7 : 1
    readonly property real inset: PrismTheme.dp(10) * root.k
    implicitWidth: PrismTheme.dp(112)
    implicitHeight: root.big ? Math.round(root.width * 0.52) : PrismTheme.dp(64)

    function zoneLabel(zone: string): string {
        return IrisPieces.zoneChoices(true).find(choice => choice.value === zone)?.label ?? zone
    }

    Rectangle {
        anchors.fill: parent
        radius: root.big ? PrismTheme.dp(18) : PrismTheme.dp(10)
        color: PrismTheme.light ? PrismTheme.sunk : PrismTheme.night
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onClicked: mouse => root.placedFree(Math.max(0, Math.min(1, mouse.x / width)), Math.max(0, Math.min(1, mouse.y / height)))
    }
    // Placed freely: the mark where it stands.
    Rectangle {
        visible: root.place === "free"
        width: PrismTheme.dp(9) * root.k
        height: width
        radius: width / 2
        x: Math.round(root.fx * root.width - width / 2)
        y: Math.round(root.fy * root.height - height / 2)
        color: PrismTheme.accent
    }
    MouseArea {
        id: island
        enabled: root.hasIsland
        readonly property bool chosen: root.place === "island"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(PrismTheme.dp(4) * root.k)
        width: Math.round(root.width * 0.3)
        height: Math.round(PrismTheme.dp(12) * root.k)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.RadioButton
        Accessible.name: root.label + ": " + Translation.tr("Island")
        Accessible.checked: island.chosen
        onClicked: root.placed("island")
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - PrismTheme.dp(6)
            height: Math.round(PrismTheme.dp(6) * root.k)
            radius: height / 2
            color: island.chosen ? PrismTheme.accent : !island.enabled ? PrismTheme.fill
                : island.containsMouse ? PrismTheme.ink : PrismTheme.ink3
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
        }
    }
    Repeater {
        model: IrisPieces.zones
        MouseArea {
            id: mark
            required property string modelData
            readonly property bool chosen: root.place === mark.modelData
            readonly property point at: IrisPieces.zoneAnchor(mark.modelData)
            width: PrismTheme.dp(18) * root.k
            height: width
            x: Math.round(root.inset + mark.at.x * (root.width - root.inset * 2) - width / 2)
            y: Math.round(root.inset + mark.at.y * (root.height - root.inset * 2) - height / 2)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.RadioButton
            Accessible.name: root.label + ": " + Translation.tr(root.zoneLabel(mark.modelData))
            Accessible.checked: mark.chosen
            onClicked: root.placed(mark.modelData)
            Rectangle {
                anchors.centerIn: parent
                width: (mark.chosen ? PrismTheme.dp(9) : PrismTheme.dp(6)) * root.k
                height: width
                radius: width / 2
                color: mark.chosen ? PrismTheme.accent : mark.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                Behavior on width { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
            }
        }
    }
}
