pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// One title as a 2:3 poster: its cover, its name under it and where you are in it. Clicking opens it; the bookmark
// follows it.
MouseArea {
    id: root
    required property var show
    readonly property real d: IrisStyle.density
    readonly property bool followed: CornerState.follows(String(root.show.id ?? ""))
    // A title from Continue watching carries `watch` and `progress` (0-1 of the film or episode seen).
    readonly property bool local: root.show.watch !== undefined
    signal open()

    implicitWidth: Math.round(132 * root.d)
    implicitHeight: cover.height + Math.round(8 * root.d) + caption.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    Accessible.role: Accessible.Button
    Accessible.name: String(root.show.title ?? "")
    onClicked: root.open()

    ClippingRectangle {
        id: cover
        width: root.width
        height: Math.round(root.width * 1.5)
        // A card's corner, not a pill's: half a tile's radius at this size.
        radius: IrisStyle.tileRadius(width * 0.5)
        color: IrisStyle.fillQuiet
        // A small lift on hover, once; nothing moves at rest.
        scale: root.containsMouse ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }

        IrisImage {
            anchors.fill: parent
            source: String(root.show.image ?? root.show.imageSmall ?? "")
        }
        // Under the pointer: a veil and what a click does, the show's page.
        Rectangle {
            anchors.fill: parent
            visible: root.containsMouse
            color: IrisStyle.artVeil
            Rectangle {
                anchors.centerIn: parent
                width: Math.round(40 * root.d)
                height: width
                radius: width / 2
                color: IrisStyle.artVeilHeavy
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.local ? "play_arrow" : "info"
                    fill: 1
                    iconSize: Math.round(22 * root.d)
                    color: IrisStyle.text
                }
            }
        }
        // How far into the episode, along the cover's foot.
        Rectangle {
            visible: root.local && Number(root.show.progress ?? 0) > 0
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.round(4 * root.d)
            color: IrisStyle.fill
            Rectangle {
                width: parent.width * Math.min(1, Number(root.show.progress ?? 0))
                height: parent.height
                color: IrisStyle.identity.orange
            }
        }
        // Follow, on the cover's corner: a plate so it reads over any artwork.
        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: Math.round(6 * root.d) }
            visible: !root.local && (root.followed || root.containsMouse)
            width: Math.round(28 * root.d)
            height: width
            radius: width / 2
            color: followArea.containsMouse ? IrisStyle.fillHover : IrisStyle.fill
            MaterialSymbol {
                anchors.centerIn: parent
                text: "bookmark"
                fill: root.followed ? 1 : 0
                iconSize: Math.round(17 * root.d)
                color: root.followed ? IrisStyle.identity.pink : IrisStyle.text
            }
            MouseArea {
                id: followArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.CheckBox
                Accessible.checked: root.followed
                Accessible.name: Translation.tr("Follow %1").arg(String(root.show.title ?? ""))
                onClicked: CornerState.toggleFollow(root.show)
            }
        }
    }

    ColumnLayout {
        id: caption
        anchors { top: cover.bottom; topMargin: Math.round(8 * root.d); left: parent.left; right: parent.right }
        spacing: 0
        IrisText {
            Layout.fillWidth: true
            text: String(root.show.title ?? "")
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(root.followed ? Font.DemiBold : Font.Normal)
        }
        IrisText {
            Layout.fillWidth: true
            text: root.local ? (root.show.kind === "series" ? Translation.tr("S%1 E%2").arg(root.show.season).arg(root.show.episode)
                    : Translation.tr("%1% seen").arg(Math.round(Number(root.show.progress ?? 0) * 100)))
                : [Number(root.show.score ?? 0) > 0 ? "★ " + Number(root.show.score).toFixed(1) : "", String(root.show.year ?? "").slice(0, 4),
                   Translation.tr(String(root.show.type ?? ""))].filter(x => String(x ?? "").length > 0).join(" · ")
            color: root.followed ? IrisStyle.identity.pink : IrisStyle.muted
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeFootnote
        }
    }
}
