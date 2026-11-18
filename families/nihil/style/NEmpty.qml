import QtQuick

// Nothing here yet, or something went wrong: a glyph, what happened in one line, what to do about it.
Column {
    id: root

    property string glyph: "blur_circular"
    property string title: ""
    property string line: ""
    property string actionLabel: ""
    property bool busy: false
    signal action()

    spacing: NihilStyle.s(8)
    topPadding: NihilStyle.s(18)
    bottomPadding: NihilStyle.s(18)

    NSpinner {
        visible: root.busy
        anchors.horizontalCenter: parent.horizontalCenter
    }
    NIcon {
        visible: !root.busy
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.glyph
        size: NihilStyle.s(30)
        color: NihilStyle.inkSoft
    }
    NText {
        visible: root.title.length > 0
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        font.pixelSize: NihilStyle.textBody
        font.weight: Font.Medium
    }
    NText {
        visible: root.line.length > 0
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        text: root.line
        font.pixelSize: NihilStyle.textSmall
        color: NihilStyle.inkSoft
    }
    NKey {
        visible: root.actionLabel.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidthOfLabel.advanceWidth(root.actionLabel) + NihilStyle.s(36)
        height: NihilStyle.s(36)
        label: root.actionLabel
        onClicked: root.action()
        FontMetrics { id: implicitWidthOfLabel; font.family: NihilStyle.grotesk; font.pixelSize: NihilStyle.textSmall }
    }
}
