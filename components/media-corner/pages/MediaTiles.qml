pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../corner/reveal.js" as Reveal
import "../state"

// A page of names as tinted tiles (the genres): each opens its own list.
MediaPage {
    id: root
    property string title: ""
    property string subtitle: ""
    // Untranslated names; shown translated.
    property var names: []
    property string emptyText: ""
    // Why the names didn't come, in words.
    property string failed: ""
    readonly property var tints: [IrisStyle.identity.pink, IrisStyle.identity.orange, IrisStyle.identity.yellow, IrisStyle.identity.green,
        IrisStyle.identity.teal, IrisStyle.identity.sky, IrisStyle.identity.blue, IrisStyle.identity.purple, IrisStyle.identity.red]
    signal picked(string name)

    spacing: Math.round(14 * root.d)

    ColumnLayout {
        spacing: 0
        IrisText {
            text: root.title
            font.family: IrisStyle.fontTitle
            font.pixelSize: IrisStyle.typeTitle
            font.weight: IrisStyle.weight(Font.Bold)
        }
        IrisText {
            visible: text.length > 0
            text: root.subtitle
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
        }
    }
    RowLayout {
        visible: root.names.length === 0
        spacing: Math.round(12 * root.d)
        IrisText {
            text: root.failed.length > 0 ? root.failed : root.emptyText
            color: IrisStyle.muted
        }
        IrisButton {
            visible: root.failed.length > 0
            quiet: true
            text: Translation.tr("Retry")
            onClicked: CornerState.attempt++
        }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: Math.max(2, Math.floor(root.width / Math.round(190 * root.d)))
        columnSpacing: Math.round(10 * root.d)
        rowSpacing: Math.round(10 * root.d)
        Repeater {
            model: root.names
            delegate: MouseArea {
                id: tile
                required property string modelData
                required property int index
                readonly property color tint: root.tints[tile.index % root.tints.length]
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(64 * root.d)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr(tile.modelData)
                onClicked: root.picked(tile.modelData)
                Keys.onReturnPressed: root.picked(tile.modelData)
                Keys.onSpacePressed: root.picked(tile.modelData)
                onActiveFocusChanged: if (activeFocus) Reveal.reveal(tile)
                Rectangle {
                    anchors.fill: parent
                    radius: IrisStyle.tileRadius(height)
                    color: tile.containsMouse ? IrisStyle.tintFillHover(tile.tint) : IrisStyle.tintFill(tile.tint)
                    border.width: 1
                    border.color: tile.containsMouse ? IrisStyle.tintBorder(tile.tint) : IrisStyle.trackOf(tile.tint)
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
                    CornerFocusRing { on: tile.activeFocus }
                    IrisText {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Math.round(12 * root.d) }
                        text: Translation.tr(tile.modelData)
                        font.pixelSize: IrisStyle.typeBody
                        font.weight: IrisStyle.weight(Font.Bold)
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
