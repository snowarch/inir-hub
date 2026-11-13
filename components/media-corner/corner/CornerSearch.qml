pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// The search plate: what you type is asked once typing pauses (300 ms) or on Return; ✕ and Escape clear it.
Rectangle {
    id: root
    property string hint: ""
    property real outerRadius: 0
    property int pad: Math.round(10 * root.d)
    readonly property real d: IrisStyle.density
    // Return: a narrow window pushes the page only then, so typing keeps the field in view.
    signal submitted()

    function focusField(): void { field.forceActiveFocus(); field.selectAll() }
    function clear(): void { field.text = ""; delay.stop(); CornerState.search("") }

    Connections {
        target: CornerState
        function onQueryChanged(): void {
            if (field.text.trim() === CornerState.query) return
            field.text = CornerState.query
            delay.stop()
        }
    }

    implicitHeight: Math.round(32 * root.d)
    radius: Math.min(height / 2, Math.max(IrisStyle.radiusRow, root.outerRadius - root.pad))
    color: field.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
    border.width: field.activeFocus ? 1 : 0
    border.color: IrisStyle.tintBorder(IrisStyle.accent)
    HoverHandler { cursorShape: Qt.IBeamCursor }
    TapHandler { onTapped: field.forceActiveFocus() }

    MaterialSymbol {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: 10 * root.d
        anchors.verticalCenter: parent.verticalCenter
        text: "search"
        iconSize: Math.round(16 * root.d)
        color: IrisStyle.muted
    }
    TextInput {
        id: field
        text: CornerState.query
        cursorDelegate: TextCursor { accent: IrisStyle.accent }
        anchors.left: glyph.right
        anchors.leftMargin: 6 * root.d
        anchors.right: clearGlyph.left
        anchors.rightMargin: 4 * root.d
        anchors.verticalCenter: parent.verticalCenter
        color: IrisStyle.text
        selectionColor: IrisStyle.accentContainer
        selectedTextColor: IrisStyle.inkOnAccentContainer
        font.family: IrisStyle.fontMain
        font.pixelSize: IrisStyle.typeLabel
        clip: true
        onTextChanged: if (text.trim() !== CornerState.query) delay.restart()
        Keys.onReturnPressed: { delay.stop(); CornerState.search(text.trim()); root.submitted() }
        // The Corner's Escape steps back: with text here, the key clears it first.
        Keys.onShortcutOverride: event => { event.accepted = event.key === Qt.Key_Escape && text.length > 0 }
        Keys.onEscapePressed: root.clear()
        Timer { id: delay; interval: 300; onTriggered: CornerState.search(field.text.trim()) }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            elide: Text.ElideRight
            visible: field.text.length === 0
            text: root.hint
            color: IrisStyle.muted
            font.pixelSize: field.font.pixelSize
        }
    }
    MaterialSymbol {
        id: clearGlyph
        anchors.right: parent.right
        anchors.rightMargin: 8 * root.d
        anchors.verticalCenter: parent.verticalCenter
        visible: field.text.length > 0
        width: visible ? implicitWidth : 0
        text: "cancel"
        fill: 1
        iconSize: Math.round(15 * root.d)
        color: IrisStyle.muted
        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.clear() }
    }
}
