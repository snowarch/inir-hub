pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Sources › Appearance: Classic, Folio or Prism. Only the skin changes; where you are and what plays stay.
SourcesCard {
    id: root
    eyebrow: Translation.tr("Appearance")
    title: Translation.tr("Style")
    glyph: "palette"
    tint: IrisStyle.identity.purple
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(10 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: Translation.tr("Based on iRiS's Settings: Classic and Folio in iRiS's colours, Prism near-black with white for what is chosen.")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            wrapMode: Text.WordWrap
        }
        Repeater {
            model: CornerSkin.looks
            // The same choice as the switch over the page: the style in use on a plate, the others bare.
            CornerPill {
                required property var modelData
                glyph: modelData.glyph
                label: Translation.tr(modelData.label)
                tone: CornerSkin.look === modelData.id ? (CornerSkin.prism ? "solid" : "quiet") : "bare"
                onClicked: CornerState.set("style", modelData.id)
            }
        }
    }
}
