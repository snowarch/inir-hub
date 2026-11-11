pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Settings › Windows › Layout, where the compositor arranges windows more than one way: each way drawn as the
// windows it makes, so the pick is seen before it is made. The workspace in front follows at once.
Flow {
    id: root

    property var spec: ({})
    readonly property real d: IrisStyle.settingsDensity
    readonly property string mode: String(CompositorConfig.value({ comp: "layout", key: "mode", fallback: "scrolling" }))
    // Each way as window boxes in a 100 x 62 screen: x, y, width, height; `main` is the window in focus.
    readonly property var ways: [
        { value: "scrolling", label: Translation.tr("Scrolling"), detail: Translation.tr("Columns on an endless strip."),
          boxes: [{ x: 4, y: 5, w: 44, h: 52, main: true }, { x: 51, y: 5, w: 30, h: 52 }, { x: 84, y: 5, w: 30, h: 52 }] },
        { value: "dwindle", label: Translation.tr("Dwindle"), detail: Translation.tr("Each window halves the last."),
          boxes: [{ x: 4, y: 5, w: 45, h: 52, main: true }, { x: 52, y: 5, w: 44, h: 24.5 }, { x: 52, y: 32.5, w: 20.5, h: 24.5 }, { x: 75.5, y: 32.5, w: 20.5, h: 24.5 }] },
        { value: "master", label: Translation.tr("Main and stack"), detail: Translation.tr("One large window, the rest beside it."),
          boxes: [{ x: 4, y: 5, w: 54, h: 52, main: true }, { x: 61, y: 5, w: 35, h: 15.3 }, { x: 61, y: 23.3, w: 35, h: 15.3 }, { x: 61, y: 41.6, w: 35, h: 15.4 }] },
        { value: "stacking", label: Translation.tr("Floating"), detail: Translation.tr("Windows where you leave them."),
          boxes: [{ x: 8, y: 8, w: 46, h: 32 }, { x: 44, y: 22, w: 44, h: 30 }, { x: 22, y: 16, w: 48, h: 34, main: true }] }
    ]
    readonly property int perRow: root.width >= Math.round(560 * root.d) ? 4 : 2
    readonly property real tileWidth: Math.floor((root.width - root.spacing * (root.perRow - 1)) / root.perRow)

    spacing: Math.round(8 * root.d)

    Repeater {
        model: root.ways.length
        Item {
            id: tile
            required property int index
            readonly property var way: root.ways[tile.index]
            readonly property bool chosen: root.mode === tile.way.value
            width: root.tileWidth
            height: picture.height + words.implicitHeight + Math.round(30 * root.d)

            function choose(): void { CompositorConfig.set({ comp: "layout", key: "mode" }, tile.way.value) }

            activeFocusOnTab: true
            Accessible.role: Accessible.RadioButton
            Accessible.name: tile.way.label + ", " + tile.way.detail
            Accessible.checkable: true
            Accessible.checked: tile.chosen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    tile.choose()
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: IrisStyle.radiusTile
                color: tile.chosen ? IrisStyle.tintFillHover(IrisStyle.accent) : IrisStyle.fill
                opacity: tile.chosen ? 1 : press.containsMouse || tile.activeFocus ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: 120; easing.type: IrisStyle.feedbackEasing } }
                Behavior on color { ColorAnimation { duration: 160; easing.type: IrisStyle.feedbackEasing } }
            }

            // The screen, clipped: the strip's last column runs off its edge, which is the point of it.
            Item {
                id: picture
                anchors.top: parent.top
                anchors.topMargin: Math.round(10 * root.d)
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Math.round(20 * root.d)
                height: Math.round(picture.width * 0.62)
                clip: true
                Repeater {
                    model: tile.way.boxes.length
                    Rectangle {
                        id: box
                        required property int index
                        readonly property var at: tile.way.boxes[box.index]
                        x: Math.round(box.at.x / 100 * picture.width)
                        y: Math.round(box.at.y / 62 * picture.height)
                        width: Math.round(box.at.w / 100 * picture.width)
                        height: Math.round(box.at.h / 62 * picture.height)
                        radius: Math.round(4 * root.d) // iris-literal: a drawn window's corner, not a shell surface
                        color: box.at.main ? (tile.chosen ? IrisStyle.accent : IrisStyle.subtext) : IrisStyle.surfaceHigh
                        opacity: box.at.main ? (tile.chosen ? 1 : 0.55) : 1
                        border.width: box.at.main ? 0 : 1
                        border.color: IrisStyle.hairline
                    }
                }
            }

            Column {
                id: words
                anchors.top: picture.bottom
                anchors.topMargin: Math.round(8 * root.d)
                anchors.left: picture.left
                anchors.right: picture.right
                spacing: Math.round(2 * root.d)
                IrisText {
                    width: parent.width
                    text: tile.way.label
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(tile.chosen ? Font.DemiBold : Font.Medium)
                    wrapMode: Text.WordWrap
                }
                IrisText {
                    width: parent.width
                    text: tile.way.detail
                    color: IrisStyle.subtext
                    font.pixelSize: IrisStyle.typeFootnote
                    wrapMode: Text.WordWrap
                }
            }

            MouseArea {
                id: press
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { tile.forceActiveFocus(); tile.choose() }
            }
        }
    }
}
