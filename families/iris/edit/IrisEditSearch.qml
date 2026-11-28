import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// The edit panel's find box: a quiet well, the accent ring while typing, a cross to clear it.
Rectangle {
    id: root

    property string placeholder: ""
    property string text: ""
    readonly property bool typing: input.activeFocus
    readonly property real d: IrisStyle.density
    function focusInput(): void { input.forceActiveFocus() }
    function clear(): void { root.text = ""; input.focus = false }

    implicitHeight: Math.round(36 * root.d)
    radius: IrisStyle.radiusRow
    color: IrisStyle.fillQuiet
    border.width: input.activeFocus ? 1.5 : 1
    border.color: input.activeFocus ? IrisStyle.accent : IrisStyle.hairline
    Behavior on border.color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Math.round(10 * root.d)
        anchors.rightMargin: Math.round(6 * root.d)
        spacing: Math.round(8 * root.d)

        MaterialSymbol {
            text: "search"
            iconSize: Math.round(17 * root.d)
            color: input.activeFocus ? IrisStyle.accent : IrisStyle.textSecondary
        }
        TextInput {
            id: input
            Layout.fillWidth: true
            color: IrisStyle.text
            selectionColor: IrisStyle.accent
            selectedTextColor: IrisStyle.inkOnAccent
            font.family: IrisStyle.fontMain
            font.pixelSize: IrisStyle.typeBody
            clip: true
            text: root.text
            onTextChanged: root.text = text
            Keys.onEscapePressed: event => {
                if (input.text.length === 0) { event.accepted = false; return }
                root.clear()
                event.accepted = true
            }

            IrisText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholder
                color: IrisStyle.textTertiary
                font.pixelSize: IrisStyle.typeBody
                visible: input.text.length === 0
            }
        }
        IrisIconButton {
            visible: root.text.length > 0
            implicitWidth: Math.round(24 * root.d)
            implicitHeight: Math.round(24 * root.d)
            materialIcon: "close"
            iconSize: Math.round(15 * root.d)
            Accessible.name: Translation.tr("Clear")
            onClicked: root.clear()
        }
    }
}
