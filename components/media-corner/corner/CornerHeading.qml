import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

// A page's or a section's name, the way iRiS's Settings writes it in each style.
// Prism: a small eyebrow over a bold title, a quiet link on the right.
// Normal (Folio): a page's title over its subtitle; a section's glyph and title in its tint, the note after it, and
// the link as a pill.
RowLayout {
    id: root
    property string eyebrow: ""
    property string title: ""
    // A section's glyph and tint in Normal.
    property string glyph: "label"
    property color tint: IrisStyle.identity.gray
    // «See all», «Edit»…; empty hides it.
    property string link: ""
    // The page's own title is larger than a section's.
    property bool page: false
    signal linkClicked()
    readonly property real d: IrisStyle.density
    readonly property bool folio: !CornerSkin.prism
    Layout.fillWidth: true
    spacing: Math.round(8 * root.d)

    // Prism, and a Normal page: words stacked.
    ColumnLayout {
        visible: !root.folio || root.page
        Layout.fillWidth: true
        spacing: root.folio ? Math.round(4 * root.d) : 0
        IrisText {
            Layout.fillWidth: true
            visible: !root.folio && root.eyebrow.length > 0
            text: root.eyebrow
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.Medium)
            elide: Text.ElideRight
        }
        IrisText {
            Layout.fillWidth: true
            text: root.title
            textFormat: Text.PlainText
            font.family: IrisStyle.fontTitle
            font.pixelSize: root.page ? CornerSkin.titleSize : CornerSkin.sectionSize
            font.letterSpacing: CornerSkin.titleTracking
            font.weight: IrisStyle.weight(root.page ? CornerSkin.titleWeight : Font.Bold)
            elide: Text.ElideRight
        }
        IrisText {
            Layout.fillWidth: true
            visible: root.folio && root.eyebrow.length > 0
            text: root.eyebrow
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeLabel
            elide: Text.ElideRight
        }
    }
    // A Normal section: Settings' group title.
    IrisGroupTitle {
        visible: root.folio && !root.page
        text: root.title
        glyph: root.glyph
        tint: root.tint
        maxWidth: Math.round(420 * root.d)
    }
    IrisText {
        visible: root.folio && !root.page && root.eyebrow.length > 0
        Layout.fillWidth: true
        text: root.eyebrow
        color: IrisStyle.textTertiary
        font.pixelSize: IrisStyle.typeMeta
        elide: Text.ElideRight
    }
    Item { visible: root.folio && !root.page && root.eyebrow.length === 0; Layout.fillWidth: true }
    IrisButton {
        visible: root.link.length > 0 && !root.folio
        Layout.alignment: Qt.AlignBottom
        quiet: true
        text: root.link
        onClicked: root.linkClicked()
    }
    CornerPill {
        visible: root.link.length > 0 && root.folio
        implicitHeight: Math.round(32 * root.d)
        label: root.link
        onClicked: root.linkClicked()
    }
}
