pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.iris.pieces
import qs.modules.iris.prism.core
import qs.modules.iris.prism.fx

// Where a piece sits on the screen: the person's own screen in small (their wallpaper, dimmed so the places read), the
// Island at its top, a mark at each place it can stand; a press on a mark puts it there, a press anywhere else places it
// freely. Marks are white light; the chosen one wears the accent with its glow. Small at a row's end; `big` when it is
// the group's own choice, as wide as its room, so the group leads with the screen itself.
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

    readonly property real k: root.big ? 1.6 : 1
    readonly property real inset: PrismTheme.dp(12) * root.k
    implicitWidth: PrismTheme.dp(112)
    implicitHeight: root.big ? Math.round(root.width * 0.5) : PrismTheme.dp(64)

    function zoneLabel(zone: string): string {
        return IrisPieces.zoneChoices(true).find(choice => choice.value === zone)?.label ?? zone
    }

    ClippingRectangle {
        id: screen
        anchors.fill: parent
        radius: root.big ? PrismTheme.dp(16) : PrismTheme.dp(10)
        color: PrismTheme.night
        // The desktop's colours while there is no picture, never a black hole.
        PrismFlow {
            anchors.fill: parent
            tint: "blue"
            seed: 0.57
            centre: Qt.point(0.55, 0.4)
            thickness: 0.55
            strength: 0.7
        }
        Image {
            anchors.fill: parent
            source: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
            sourceSize.width: Math.round(screen.width * 1.5)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        // Dimmed under the marks: white light reads on any picture.
        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(PrismTheme.night, 0.5)
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        onClicked: mouse => root.placedFree(Math.max(0, Math.min(1, mouse.x / width)), Math.max(0, Math.min(1, mouse.y / height)))
    }
    // Placed freely: the mark where it stands.
    Rectangle {
        visible: root.place === "free"
        width: PrismTheme.dp(10) * root.k
        height: width
        radius: width / 2
        x: Math.round(root.fx * root.width - width / 2)
        y: Math.round(root.fy * root.height - height / 2)
        color: PrismTheme.accent
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 2.2
            height: width
            radius: width / 2
            color: Qt.alpha(PrismTheme.accent, 0.25)
            z: -1
        }
    }
    MouseArea {
        id: island
        enabled: root.hasIsland
        readonly property bool chosen: root.place === "island"
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(PrismTheme.dp(5) * root.k)
        width: Math.round(root.width * 0.26)
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
            color: island.chosen ? PrismTheme.accent : !island.enabled ? Qt.rgba(1, 1, 1, 0.14) // iris-literal: white light on the dimmed screen
                : Qt.rgba(1, 1, 1, island.containsMouse ? 0.9 : 0.42) // iris-literal: white light on the dimmed screen
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
            width: PrismTheme.dp(20) * root.k
            height: width
            x: Math.round(root.inset + mark.at.x * (root.width - root.inset * 2) - width / 2)
            y: Math.round(root.inset + mark.at.y * (root.height - root.inset * 2) - height / 2)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.RadioButton
            Accessible.name: root.label + ": " + Translation.tr(root.zoneLabel(mark.modelData))
            Accessible.checked: mark.chosen
            onClicked: root.placed(mark.modelData)
            // The chosen place glows in the accent around its mark.
            Rectangle {
                anchors.centerIn: parent
                width: dot.width * 2.3
                height: width
                radius: width / 2
                color: Qt.alpha(PrismTheme.accent, 0.28)
                opacity: mark.chosen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
            }
            Rectangle {
                id: dot
                anchors.centerIn: parent
                width: (mark.chosen ? PrismTheme.dp(9) : mark.containsMouse ? PrismTheme.dp(7) : PrismTheme.dp(5)) * root.k
                height: width
                radius: width / 2
                color: mark.chosen ? PrismTheme.accent : Qt.rgba(1, 1, 1, mark.containsMouse ? 0.95 : 0.5) // iris-literal: white light on the dimmed screen
                Behavior on width { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
            }
        }
    }
}
