import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A row's cover: its page's art in small (`.claude/ref/language`, the collection's covers), dark in every scheme like
// a record sleeve, its glyph printed white over it. The same palette as the page's poster, so a row found anywhere
// still says where it lives.
Item {
    id: root
    property string glyph: "circle"
    property string tint: "grey"
    property real size: PrismTheme.dp(36)
    // What else tells this cover from its neighbours (a row's name): two rows of one glyph still differ.
    property string salt: ""
    width: root.size
    height: root.size

    PrismFlow {
        anchors.fill: parent
        radius: Math.round(root.size * 0.26)
        dark: true
        tint: root.tint
        // Each glyph its own turn of the ribbon, so a list of covers never repeats one picture.
        seed: Array.from(root.glyph + root.salt).reduce((n, letter) => n + letter.charCodeAt(0), 0) % 17 * 0.61
        centre: Qt.point(0.5, 0.5)
        thickness: 0.42
    }
    PrismGlyph {
        anchors.centerIn: parent
        text: root.glyph
        filled: true
        iconSize: Math.round(root.size * 0.48)
        color: PrismTheme.paper
    }
}
