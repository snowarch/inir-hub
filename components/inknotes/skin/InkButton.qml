pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

// A button in the family's own control: iRiS's chip, Waffle's borderless button, Material's ripple button.
Loader {
    id: root
    property string label: ""
    property string symbol: ""
    property string hint: ""
    property bool primary: false
    property bool toggled: false
    property bool quiet: false
    property bool danger: false
    signal clicked()
    readonly property color ink: root.primary ? InkSkin.onAccent : root.danger ? InkSkin.danger : root.toggled ? InkSkin.rowOnInk : InkSkin.text
    active: visible
    sourceComponent: InkSkin.iris ? irisButton : InkSkin.waffle ? waffleButton : materialButton

    Component {
        id: irisButton
        IrisChip {
            label: root.label
            glyph: root.symbol
            emphasized: root.primary
            selected: root.toggled
            foreground: root.ink
            colBackground: root.primary ? InkSkin.accent : root.toggled ? InkSkin.rowOn : root.quiet ? "transparent" : InkSkin.plate
            onClicked: root.clicked()
            Accessible.name: root.label || root.hint
        }
    }
    Component {
        id: waffleButton
        WBorderlessButton {
            id: button
            implicitHeight: InkSkin.control
            implicitWidth: Math.max(implicitHeight, content.implicitWidth + InkSkin.gap * 1.5)
            radius: InkSkin.radius
            checked: root.toggled
            colBackground: root.primary ? Looks.colors.accent : root.toggled ? Looks.settings.tilePressed : root.quiet ? "transparent" : Looks.settings.tile
            colBackgroundHover: root.primary ? Looks.colors.accentHover : Looks.settings.tileHover
            colBackgroundActive: root.primary ? Looks.colors.accentActive : Looks.settings.tilePressed
            onClicked: root.clicked()
            Accessible.name: root.label || root.hint
            contentItem: Row {
                id: content
                spacing: InkSkin.small
                anchors.centerIn: parent
                InkGlyph { visible: root.symbol !== ""; anchors.verticalCenter: parent.verticalCenter; name: root.symbol; color: root.ink }
                InkText { visible: root.label !== ""; anchors.verticalCenter: parent.verticalCenter; text: root.label; color: root.ink }
            }
        }
    }
    Component {
        id: materialButton
        RippleButtonWithIcon {
            mainText: root.label
            materialIcon: root.symbol
            buttonRadius: InkSkin.radius
            colBackgroundHover: InkSkin.hover
            toggled: root.primary || root.toggled
            colBackground: root.quiet ? "transparent" : InkSkin.plate
            colBackgroundToggled: root.primary ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: root.primary ? Appearance.colors.colPrimaryHover : Appearance.colors.colSecondaryContainerHover
            contentColor: root.primary ? Appearance.colors.colOnPrimary : root.danger ? Appearance.colors.colError : root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer3
            onClicked: root.clicked()
            Accessible.name: root.label || root.hint
        }
    }
    HoverHandler { id: hover }
    StyledToolTip { parent: root; text: root.hint; extraVisibleCondition: hover.hovered; font.family: InkSkin.mainFont }
}
