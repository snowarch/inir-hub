pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
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
    readonly property string statusLabel: ({ RELEASING: Translation.tr("Airing"), FINISHED: Translation.tr("Finished"),
        NOT_YET_RELEASED: Translation.tr("Not yet aired"), CANCELLED: Translation.tr("Cancelled"), HIATUS: Translation.tr("On hiatus") })[String(root.show.status ?? "")] ?? ""

    implicitWidth: Math.round(132 * root.d)
    implicitHeight: cover.height + Math.round(8 * root.d) + caption.implicitHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: String(root.show.title ?? "")
    Accessible.description: [Translation.tr(root.show.kind === "anime" ? "Anime" : root.show.kind === "movie" ? "Movie" : "Series"), root.detailLine, root.statusLabel].filter(x => x.length > 0).join(" · ")
    onClicked: CornerState.openShow(root.show)
    Keys.onReturnPressed: CornerState.openShow(root.show)
    Keys.onSpacePressed: CornerState.openShow(root.show)
    onActiveFocusChanged: if (activeFocus) Reveal.reveal(root)

    ToolTip {
        visible: (root.containsMouse || root.activeFocus) && titleText.truncated
        delay: 700
        contentItem: Text {
            text: String(root.show.title ?? "")
            textFormat: Text.PlainText
            color: IrisStyle.text
            font.family: IrisStyle.fontMain
            font.pixelSize: IrisStyle.typeLabel
            wrapMode: Text.Wrap
            maximumLineCount: 8
            elide: Text.ElideRight
        }
        width: Math.min(implicitWidth, Math.round(360 * root.d))
        background: Rectangle { color: IrisStyle.surfaceHighOpaque; radius: IrisStyle.radiusRow }
    }

    ClippingRectangle {
        id: cover
        width: root.width
        height: Math.round(root.width * 1.5)
        radius: IrisStyle.radiusTile
        color: CornerSkin.plate
        border.width: CornerSkin.edgeWidth
        border.color: CornerSkin.edge
        // A small lift on hover, once; nothing moves at rest.
        scale: root.containsMouse ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }

        // Stands in until the cover is there, and for one that never comes.
        MaterialSymbol {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: root.show.kind === "anime" ? "animation" : root.show.kind === "series" ? "tv" : "movie"
            fill: 1
            iconSize: Math.round(32 * root.d)
            color: IrisStyle.textTertiary
        }
        Image {
            id: art
            anchors.fill: parent
            source: String(root.show.image ?? "")
            // The size MediaCorner keeps decoded, so a poster seen twice is decoded once.
            sourceSize: Qt.size(264, 396) // literal: shared with MediaCorner's poster cache
            asynchronous: true
            cache: true
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: if (status === Image.Ready) {
                let node = root.parent
                while (node && !node.rememberPoster) node = node.parent
                if (node) node.rememberPoster(String(source))
            }
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
            id: titleText
            Layout.fillWidth: true
            text: String(root.show.title ?? "")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            font.pixelSize: IrisStyle.typeLabel
            // Two lines' room always, so the facts under it line up across a shelf.
            Layout.minimumHeight: 2 * titleText.contentHeight / Math.max(1, titleText.lineCount)
            verticalAlignment: Text.AlignTop
        }
        IrisText {
            Layout.fillWidth: true
            text: root.detailLine
            color: IrisStyle.textSecondary
            elide: Text.ElideRight
            font.pixelSize: IrisStyle.typeFootnote
        }
    }
}
