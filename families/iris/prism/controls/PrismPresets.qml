pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.prism.core

// Style's presets (his 11-20: a wall of cards, "full spammer", was the first thing on the page): each look a key with
// its name set in the look's own type and one dot of its accent, the worn one solid. One line under them says what the
// pointed look puts on, else the worn one's, with the worn one's share and, for one of the person's own, its removal.
Column {
    id: root
    property var pointed: null
    readonly property var shown: root.pointed ?? IrisThemes.active
    spacing: PrismTheme.dp(10)

    // What a look puts on, in words: the material, the corners, the type.
    function traitsOf(theme: var): string {
        if (!theme) return ""
        const look = IrisThemes.swatch(theme)
        const shape = Math.max(0.35, Math.min(1.45, look.shape))
        return [look.glass ? Translation.tr("Glass") : Translation.tr("Solid"),
            shape < 0.75 ? Translation.tr("Sharp") : shape > 1.15 ? Translation.tr("Round") : Translation.tr("Soft"),
            // The family's name, not the patch it wears ("JetBrainsMono Nerd Font" reads JetBrainsMono).
            String(look.titleFont).split(",")[0].replace(/ (Nerd Font( Mono| Propo)?|NF|NFM|NFP)$/, "")].join(" · ")
            + (theme.user && theme.author ? " · " + Translation.tr("by %1").arg(theme.author) : "")
    }

    Flow {
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: IrisThemes.all
            delegate: Item {
                id: look
                required property var modelData
                readonly property var swatch: IrisThemes.swatch(look.modelData)
                readonly property bool worn: IrisThemes.activeId === look.modelData.id
                implicitWidth: name.implicitWidth + PrismTheme.dp(45)
                implicitHeight: PrismTheme.dp(38)
                PrismKey {
                    anchors.fill: parent
                    face: look.worn ? PrismTheme.solid : PrismTheme.keyQuiet
                    hovered: area.containsMouse
                    down: area.pressed
                }
                // Its accent, once.
                Rectangle {
                    id: dot
                    x: PrismTheme.dp(14)
                    anchors.verticalCenter: parent.verticalCenter
                    width: PrismTheme.dp(8)
                    height: width
                    radius: width / 2
                    color: look.swatch.accent
                }
                PrismText {
                    id: name
                    anchors.left: dot.right
                    anchors.leftMargin: PrismTheme.dp(9)
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(look.modelData.name ?? "")
                    color: look.worn ? PrismTheme.inkSolid : PrismTheme.ink
                    font.family: look.swatch.titleFont
                    font.pixelSize: PrismTheme.dp(15)
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: {
                        if (area.containsMouse) root.pointed = look.modelData
                        else if (root.pointed === look.modelData) root.pointed = null
                    }
                    // On Settings' history: Ctrl+Z takes it back.
                    onClicked: IrisOptions.wearTheme(look.modelData)
                }
                Accessible.role: Accessible.Button
                Accessible.name: name.text
            }
        }
    }

    Item {
        width: root.width
        height: PrismTheme.dp(28)
        visible: root.shown !== null && root.shown !== undefined
        Row {
            anchors.left: parent.left
            anchors.right: tools.left
            anchors.rightMargin: PrismTheme.dp(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismText {
                id: shownName
                text: String(root.shown?.name ?? "")
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
            }
            PrismText {
                width: Math.max(0, parent.width - shownName.width - parent.spacing)
                text: root.traitsOf(root.shown)
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
        }
        // The worn look's own keys, while no other is pointed.
        Row {
            id: tools
            visible: root.pointed === null && IrisThemes.active !== null
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            PrismRound {
                ghost: true
                implicitWidth: PrismTheme.dp(28)
                glyph: "ios_share"
                glyphSize: PrismTheme.dp(15)
                Accessible.name: Translation.tr("Copy to share")
                onClicked: Quickshell.clipboardText = IrisThemes.exportText(IrisThemes.active)
            }
            PrismRound {
                visible: Boolean(IrisThemes.active?.user)
                ghost: true
                implicitWidth: PrismTheme.dp(28)
                glyph: "delete"
                glyphSize: PrismTheme.dp(15)
                Accessible.name: Translation.tr("Delete")
                onClicked: IrisOptions.dropTheme(IrisThemes.active)
            }
        }
    }
}
