pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.widgets

// Notes in Prism: the folder's head is the note's (its name and how many words), and the page is the pane and the foot
// together: the widget's own editor writes there, below the tab, so the text never runs under the head.
PrismFolder {
    id: root

    readonly property bool blank: String(root.widget.noteText ?? "").length === 0 && !root.widget.editing
    readonly property int words: String(root.widget.noteText ?? "").trim().split(/\s+/).filter(word => word.length > 0).length

    shelf: root.nothing ? root.signal : root.inked(IrisStyle.identity.yellow)
    tabGlyph: "edit_note"
    tabText: Translation.tr("Notes")
    flapText: root.words > 0 ? (root.small ? String(root.words) : Translation.tr("%1 words").arg(root.words)) : ""
    lightPass: root.blank ? 1 : 0.4

    // The editor's top, given to the widget while this face draws it.
    readonly property real textTop: root.paneTop + root.pick(10, 10, 14)
    Component.onCompleted: root.widget.faceTextTop = root.textTop
    onTextTopChanged: root.widget.faceTextTop = root.textTop
    Component.onDestruction: root.widget.faceTextTop = -1

    FaceText {
        face: root
        visible: root.blank
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: Translation.tr("Write something")
        size: root.type(15, 18, 24)
        weight: Font.Bold
    }
    FaceText {
        face: root
        visible: root.blank
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: Translation.tr("Click anywhere on the page to start")
        color: root.inkSecondary
        size: root.type(11.5, 12.5, 14)
        weight: Font.Medium
        wrapMode: Text.WordWrap
    }
}
