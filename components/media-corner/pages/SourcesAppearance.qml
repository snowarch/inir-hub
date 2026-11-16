pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// Sources › Appearance: Normal or Prism. Only the skin changes; where you are and what plays stay.
SourcesCard {
    id: root
    eyebrow: Translation.tr("Appearance")
    title: Translation.tr("Style")
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(10 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: Translation.tr("Normal follows iRiS's colours and glass; Prism is near-black with white for what is chosen.")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            wrapMode: Text.WordWrap
        }
        CornerPill {
            label: Translation.tr("Normal")
            tone: CornerState.options.style === "normal" ? "solid" : "quiet"
            onClicked: CornerState.set("style", "normal")
        }
        CornerPill {
            label: Translation.tr("Prism")
            tone: CornerState.options.style === "prism" ? "solid" : "quiet"
            onClicked: CornerState.set("style", "prism")
        }
    }
}
