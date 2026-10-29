import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls.FluentWinUI3
import QtQuick.Controls

TextField {
    id: root
    
    clip: true
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    color: Looks.colors.fg

    // The focus line FluentWinUI3 draws under the field.
    palette.accent: Looks.colors.accent

    font {
        hintingPreference: Font.PreferDefaultHinting
        family: Looks.font.family.ui
        weight: Looks.font.weight.thin
    }

    // WinUI 3 TextBox drawn from our tokens: FluentWinUI3 reads the app palette, which stays light in a dark
    // shell and left a grey slab (Hub search, 10-29)
    implicitHeight: Looks.dp(32)
    leftPadding: Looks.dp(11)
    rightPadding: Looks.dp(11)
    font.pixelSize: Looks.settings.body
    placeholderTextColor: Looks.colors.subfg
    selectionColor: Looks.colors.accent
    selectedTextColor: Looks.colors.accentFg
    background: Rectangle {
        radius: Looks.settings.radiusSmall
        color: root.activeFocus ? (Looks.dark ? Qt.rgba(0.12, 0.12, 0.12, 0.7) : "#FFFFFF")
            // ControlFillColorDefault is white in both themes (#0FFFFFFF dark, #B3FFFFFF light): the ink at 70 %
            // painted a dark slab on every light page (Hub search, Autostart's command line).
            : root.hovered ? Looks.settings.cardHover : Qt.rgba(1, 1, 1, Looks.dark ? 0.06 : 0.7)
        border.width: 1
        border.color: Looks.settings.cardStroke
        clip: true
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.activeFocus ? 2 : 1
            color: root.activeFocus ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.54 : 0.45)
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.IBeamCursor
    }

    TextInputContextMenu {
        target: root
    }
}
