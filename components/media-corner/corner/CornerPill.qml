import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// A capsule action: `solid` is the main one (white in Prism, the accent in Normal), `quiet` sits on the page, `art`
// reads over a picture.
IrisButton {
    id: root
    property string glyph: ""
    property string label: ""
    property string tone: "quiet"
    readonly property real d: IrisStyle.density
    readonly property color ink: root.tone === "solid" ? CornerSkin.inkOnSolid : root.tone === "art" ? IrisStyle.inkOnDark : IrisStyle.text
    foreground: root.ink
    colBackground: root.tone === "solid" ? CornerSkin.solid : root.tone === "art" ? IrisStyle.veilStrong : CornerSkin.plate
    colBackgroundHover: root.tone === "solid" ? Qt.tint(CornerSkin.solid, IrisStyle.fillQuiet) : root.tone === "art" ? IrisStyle.veilHeavy : IrisStyle.fillHover
    buttonRadius: height / 2
    buttonRadiusPressed: height / 2
    implicitHeight: Math.round(36 * root.d)
    implicitWidth: content.implicitWidth + Math.round(30 * root.d)
    Accessible.name: root.label
    Row {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(6 * root.d)
        MaterialSymbol {
            visible: root.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            fill: 1
            iconSize: Math.round(17 * root.d)
            color: root.ink
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            textFormat: Text.PlainText
            color: root.ink
            font.pixelSize: IrisStyle.typeLabel
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }
}
