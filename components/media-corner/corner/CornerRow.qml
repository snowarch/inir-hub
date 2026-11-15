pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// A row of a numbered list, as Settings writes its changes: a squircle (a cover or a glyph), a name over a detail, and
// its number on the right.
IrisButton {
    id: root
    property int number: 0
    property string image: ""
    property string glyph: "movie"
    property string title: ""
    property string detail: ""
    // 0..1 drawn under the detail; below 0 draws nothing.
    property real progress: -1
    // Keys of its own on the right (remove…): `trailing: [ … ]`.
    property alias trailing: tail.data
    readonly property real d: IrisStyle.density
    quiet: true
    implicitHeight: Math.round(54 * root.d)
    buttonRadius: IrisStyle.radiusRow
    Accessible.name: root.detail ? root.title + " · " + root.detail : root.title
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(6 * root.d)
        anchors.rightMargin: Math.round(10 * root.d)
        spacing: Math.round(12 * root.d)
        ClippingRectangle {
            readonly property real side: Math.round(38 * root.d)
            Layout.preferredWidth: side
            Layout.preferredHeight: side
            radius: IrisStyle.tileRadius(side)
            color: CornerSkin.plate
            IrisImage {
                anchors.fill: parent
                visible: root.image.length > 0
                source: root.image
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(Math.round(76 * root.d), Math.round(76 * root.d))
            }
            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.image.length === 0
                text: root.glyph
                fill: 1
                iconSize: Math.round(19 * root.d)
                color: IrisStyle.text
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                font.pixelSize: IrisStyle.typeLabel
                font.weight: IrisStyle.weight(Font.DemiBold)
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                visible: root.detail.length > 0
                text: root.detail
                textFormat: Text.PlainText
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeMeta
                elide: Text.ElideRight
            }
            Rectangle {
                visible: root.progress >= 0
                Layout.fillWidth: true
                implicitHeight: Math.max(2, Math.round(3 * root.d))
                radius: height / 2
                color: IrisStyle.fill
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.progress))
                    height: parent.height
                    radius: height / 2
                    color: CornerSkin.solid
                }
            }
        }
        Row { id: tail; Layout.alignment: Qt.AlignVCenter }
        IrisText {
            visible: root.number > 0
            text: String(root.number).padStart(2, "0")
            color: IrisStyle.textTertiary
            font.family: IrisStyle.fontNumbers
            font.pixelSize: IrisStyle.typeMeta
        }
    }
}
