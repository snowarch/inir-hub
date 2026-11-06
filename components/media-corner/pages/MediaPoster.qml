pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../corner/reveal.js" as Reveal
import "../state"

// One title as a 2:3 poster: its cover and its name under it. Clicking opens its page.
MouseArea {
    id: root
    required property var show
    readonly property real d: IrisStyle.density
    readonly property string detailLine: [Translation.tr(String(root.show.relation ?? "")), Number(root.show.score ?? 0) > 0 ? "★ " + Number(root.show.score).toFixed(1) : "",
        String(root.show.year ?? "").slice(0, 4), Translation.tr(String(root.show.type ?? ""))].filter(x => x.length > 0).join(" · ")

    implicitWidth: Math.round(132 * root.d)
    implicitHeight: cover.height + Math.round(8 * root.d) + caption.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: String(root.show.title ?? "")
    Accessible.description: root.detailLine
    onClicked: CornerState.openShow(root.show)
    Keys.onReturnPressed: CornerState.openShow(root.show)
    Keys.onSpacePressed: CornerState.openShow(root.show)
    onActiveFocusChanged: if (activeFocus) Reveal.reveal(root)

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

        // Stands in until the cover is there, and for one that never comes.
        MaterialSymbol {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: "movie"
            iconSize: Math.round(32 * root.d)
            color: IrisStyle.muted
        }
        IrisImage {
            id: art
            anchors.fill: parent
            source: String(root.show.image ?? "")
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
                    text: "info"
                    fill: 1
                    iconSize: Math.round(22 * root.d)
                    color: IrisStyle.text
                }
            }
        }
    }
    CornerFocusRing {
        anchors.fill: undefined
        anchors.margins: 0
        x: cover.x - 2
        y: cover.y - 2
        width: cover.width + 4
        height: cover.height + 4
        radius: cover.radius + 2
        on: root.activeFocus
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
        }
        IrisText {
            Layout.fillWidth: true
            text: root.detailLine
            color: IrisStyle.muted
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeFootnote
        }
    }
}
