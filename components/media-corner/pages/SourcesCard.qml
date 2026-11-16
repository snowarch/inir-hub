pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.iris.style
import "../corner"

// One section of Sources as a Settings card: its eyebrow and title, then what it holds.
Rectangle {
    id: root
    property string eyebrow: ""
    property string title: ""
    // The glyph and tint its title wears in Classic and Folio.
    property string glyph: "label"
    property color tint: IrisStyle.identity.gray
    default property alias content: body.data
    readonly property real d: IrisStyle.density
    implicitHeight: body.implicitHeight + 2 * Math.round(18 * root.d)
    radius: CornerSkin.cardRadius
    color: CornerSkin.card
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge
    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Math.round(18 * root.d) }
        spacing: Math.round(10 * root.d)
        // In Classic and Folio the title is Settings' group title, which says enough without the eyebrow.
        CornerHeading { eyebrow: CornerSkin.prism ? root.eyebrow : ""; title: root.title; glyph: root.glyph; tint: root.tint; visible: root.title.length > 0 }
    }
}
