import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

// A section's name, the way iRiS's Settings writes it: a small eyebrow over a bold title, and a link on the right.
RowLayout {
    id: root
    property string eyebrow: ""
    property string title: ""
    // «See all», «Edit»…; empty hides it.
    property string link: ""
    // The page's own title is larger than a section's.
    property bool page: false
    signal linkClicked()
    Layout.fillWidth: true
    spacing: Math.round(8 * IrisStyle.density)
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        IrisText {
            Layout.fillWidth: true
            visible: root.eyebrow.length > 0
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
            font.weight: IrisStyle.weight(Font.Bold)
            elide: Text.ElideRight
        }
    }
    IrisButton {
        visible: root.link.length > 0
        Layout.alignment: Qt.AlignBottom
        quiet: true
        text: root.link
        onClicked: root.linkClicked()
    }
}
