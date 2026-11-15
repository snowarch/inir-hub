import QtQuick
import QtQuick.Controls
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import "../state"

TextField {
    id: root
    placeholderText: Translation.tr("Want to watch") + " / " + Translation.tr("Watching")
    Accessible.name: placeholderText
    text: CornerState.savedQuery
    onTextEdited: CornerState.savedQuery = text
    color: IrisStyle.text
    placeholderTextColor: IrisStyle.muted
    font.family: IrisStyle.fontMain
    font.pixelSize: IrisStyle.typeLabel
    leftPadding: Math.round(30 * IrisStyle.density)
    implicitHeight: Math.round(32 * IrisStyle.density)
    background: Rectangle {
        radius: IrisStyle.radiusRow
        color: root.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
        border.width: root.activeFocus ? Math.max(1, Math.round(2 * IrisStyle.density)) : 0
        border.color: IrisStyle.ringInk
    }
    MaterialSymbol {
        anchors.left: parent.left
        anchors.leftMargin: Math.round(8 * IrisStyle.density)
        anchors.verticalCenter: parent.verticalCenter
        text: "search"
        iconSize: Math.round(16 * IrisStyle.density)
        color: IrisStyle.muted
    }
    Keys.onShortcutOverride: event => { event.accepted = event.key === Qt.Key_Escape && root.text.length > 0 }
    Keys.onEscapePressed: CornerState.savedQuery = ""
}
