pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// One card of Home's deck, as Settings' «Live» card: a picture, an eyebrow and a name at its foot, and a round key.
ClippingRectangle {
    id: root
    property var show: null
    property string eyebrow: ""
    property string glyph: "play_arrow"
    property string action: ""
    signal opened()
    signal acted()
    readonly property real d: IrisStyle.density
    radius: IrisStyle.radiusCard
    color: CornerSkin.card
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge
    IrisImage {
        anchors.fill: parent
        source: String(root.show?.banner || root.show?.imageLarge || root.show?.image || "")
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.35; color: "transparent" }
            GradientStop { position: 1; color: IrisStyle.veilHeavy }
        }
    }
    MouseArea {
        id: open
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.show !== null
        activeFocusOnTab: enabled
        Accessible.role: Accessible.Button
        Accessible.name: String(root.show?.title ?? "")
        onClicked: root.opened()
        Keys.onReturnPressed: root.opened()
        Keys.onSpacePressed: root.opened()
    }
    CornerFocusRing { on: open.activeFocus }
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Math.round(18 * root.d)
        spacing: Math.round(10 * root.d)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            IrisText {
                Layout.fillWidth: true
                text: root.eyebrow
                color: IrisStyle.inkOnDark
                opacity: 0.72 // literal: an eyebrow over art reads quieter than the title
                font.pixelSize: IrisStyle.typeMeta
            }
            IrisText {
                Layout.fillWidth: true
                text: String(root.show?.title ?? "")
                textFormat: Text.PlainText
                color: IrisStyle.inkOnDark
                font.pixelSize: IrisStyle.typeTitle
                font.weight: IrisStyle.weight(Font.Bold)
                elide: Text.ElideRight
            }
        }
        CornerRound {
            visible: root.action.length > 0 && root.show !== null
            solid: true
            glyph: root.glyph
            Accessible.name: root.action
            onClicked: root.acted()
        }
    }
}
