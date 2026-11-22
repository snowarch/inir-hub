pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks

WBorderlessButton {
    id: root

    required property string entry
    property bool isPin: false
    property string pinnedText: ""
    // A history entry can itself already be pinned. Without this it showed the
    // "pin" icon like any other row and pinning it again was the only thing the
    // button could do.
    readonly property string pinnedAs: root.isPin ? root.pinnedText : Cliphist.pinnedTextFor(root.entry)
    readonly property bool isPinned: root.pinnedAs.length > 0
    property bool isSelected: false
    property bool isCopied: false
    property string searchQuery: ""

    signal deleteRequested()
    signal pinToggleRequested()

    implicitHeight: contentLayout.implicitHeight + Looks.dp(20)

    checked: isSelected

    property bool isImage: !isPin && Cliphist.entryIsImage(entry)
    property string displayText: {
        if (root.isPin) return Cliphist.pinPreview(root.pinnedText)
        let cleaned = StringUtils.cleanCliphistEntry(entry)
        if (isImage) {
            cleaned = cleaned.replace(/^\s*\[\[.*?\]\]\s*/, "")
        }
        const unwrapped = StringUtils.cliphistMarkupPreview(cleaned)
        if (unwrapped !== cleaned)
            cleaned = unwrapped.length > 0 ? unwrapped : Translation.tr("Rich text")
        return cleaned.trim()
    }

    readonly property bool isLink: !root.isImage && /^(https?|ftp):\/\/\S+$/.test(root.displayText)
    // what it is, not cliphist's number for it
    readonly property string entryType: root.isPin ? Translation.tr("Pinned")
        : root.isImage ? Translation.tr("Image")
        : root.isLink ? Translation.tr("Link")
        : Translation.tr("Text")
    readonly property string kindIcon: root.isCopied ? "checkmark"
        : root.isPin ? "pin"
        : root.isImage ? "image"
        : root.isLink ? "link"
        : "text-font"

    // each entry is a soft card of its own
    radius: Looks.radius.large
    colBackground: Qt.alpha(Looks.colors.fg, Looks.dark ? 0.04 : 0.03)

    contentItem: RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: Looks.dp(10)
        anchors.rightMargin: Looks.dp(10)
        spacing: Looks.dp(12)

        // the kind on a tile: the accent fills it for what was copied last
        Rectangle {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Looks.dp(2)
            Layout.preferredWidth: Looks.dp(32)
            Layout.preferredHeight: Looks.dp(32)
            radius: Looks.radius.medium
            color: root.isCopied ? Looks.colors.accent
                : root.isPin ? Qt.alpha(Looks.colors.accent, Looks.dark ? 0.2 : 0.14)
                : Qt.alpha(Looks.colors.fg, Looks.dark ? 0.07 : 0.06)

            FluentIcon {
                anchors.centerIn: parent
                icon: root.kindIcon
                implicitSize: Looks.dp(16)
                color: root.isCopied ? Looks.colors.accentFg : root.isPin ? Looks.colors.accent : Looks.colors.subfg
            }
        }

        // Content column
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            WText {
                text: root.entryType
                color: root.isPin ? Looks.colors.accent : Looks.colors.subfg
                font.pixelSize: Looks.font.pixelSize.small
                font.weight: Looks.font.weight.strong
            }

            // Main text
            WText {
                Layout.fillWidth: true
                text: root.displayText
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                font.pixelSize: Looks.font.pixelSize.normal
            }

            // Image preview - don't use Layout.fillWidth, let image determine its own size
            Loader {
                active: root.isImage
                sourceComponent: CliphistImage {
                    entry: root.entry
                    maxWidth: contentLayout.width - 24
                    maxHeight: 80
                    blur: false
                }
            }
        }

        // Action text on hover
        WText {
            visible: root.hovered && !deleteButton.hovered && !pinButton.hovered
            text: Translation.tr("Copy")
            color: Looks.colors.accent
            font.pixelSize: Looks.font.pixelSize.normal
        }

        // Pin button
        WBorderlessButton {
            id: pinButton
            visible: (root.hovered || root.isSelected) && (root.isPinned || Cliphist.isPinnable(root.entry))
            implicitWidth: 28
            implicitHeight: 28
            radius: Looks.radius.medium

            onClicked: root.pinToggleRequested()

            contentItem: FluentIcon {
                anchors.centerIn: parent
                icon: root.isPinned ? "pin-off" : "pin"
                implicitSize: 16
                color: pinButton.hovered ? Looks.colors.accent : Looks.colors.fg
            }

            WToolTip {
                text: root.isPinned ? Translation.tr("Unpin") : Translation.tr("Pin")
            }
        }

        // Delete button
        WBorderlessButton {
            id: deleteButton
            visible: root.hovered || root.isSelected
            implicitWidth: 28
            implicitHeight: 28
            radius: Looks.radius.medium

            onClicked: root.isPin ? root.pinToggleRequested() : root.deleteRequested()

            contentItem: FluentIcon {
                anchors.centerIn: parent
                icon: "dismiss"
                implicitSize: 16
                color: deleteButton.hovered ? Looks.colors.danger : Looks.colors.fg
            }

            WToolTip {
                text: root.isPin ? Translation.tr("Unpin") : Translation.tr("Delete")
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: root.isPin ? root.pinToggleRequested() : root.deleteRequested()
    }
}
