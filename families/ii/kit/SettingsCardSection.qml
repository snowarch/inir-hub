import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

// A section of a Settings page: its name in the accent, then its settings as segmented tiles. Never folded: what a
// page holds is seen by scrolling, not by opening boxes (folding hid settings people then searched for).
// Classic (SettingsMaterialPreset.classic, v2.33's look): one bordered card holding its icon, its title and its rows.
Item {
    id: root

    property string title: ""
    property string icon: ""
    // kept for pages that still set them; a section is always open
    property bool expanded: true
    property bool collapsible: false
    property string settingsTaskSection: ""
    default property alias contentData: sectionContent.data

    property bool enableSettingsSearch: true
    property int settingsSearchOptionId: -1

    Layout.fillWidth: true
    readonly property bool classic: SettingsMaterialPreset.classic
    readonly property int inset: root.classic ? SettingsMaterialPreset.cardPadding : 0
    implicitHeight: column.implicitHeight + root.inset * 2
    implicitWidth: column.implicitWidth + root.inset * 2

    // blocks the tile layout found loose in this section (SettingsMaterialPreset.layoutTiles): their tiles are here
    property var _blocks: []

    function _findSettingsContext() {
        var page = null;
        var p = root.parent;
        while (p) {
            if (p.hasOwnProperty("settingsPageIndex")) {
                page = p;
                break;
            }
            p = p.parent;
        }
        return { page: page };
    }

    function focusFromSettingsSearch() {
        root.forceActiveFocus();
    }

    function relayoutTiles(): void {
        root._blocks = SettingsMaterialPreset.layoutTiles(sectionContent)
    }

    Component.onCompleted: {
        // pages still start some sections "collapsed" and gate their content on it; every section is open now
        root.expanded = true
        Qt.callLater(root.relayoutTiles)
        if (!enableSettingsSearch || !root.title)
            return;
        if (typeof SettingsSearchRegistry === "undefined")
            return;
        if (!SettingsSearchRegistry.dynamicRegistrationEnabled)
            return;

        if (SettingsSearchRegistry.registerCollapsibleSection) {
            SettingsSearchRegistry.registerCollapsibleSection(root);
        }

        var page = _findSettingsContext().page;
        settingsSearchOptionId = SettingsSearchRegistry.registerOption({
            control: root,
            pageIndex: page && page.settingsPageIndex !== undefined ? page.settingsPageIndex : -1,
            pageName: page && page.settingsPageName ? page.settingsPageName : "",
            section: root.title,
            label: root.title,
            description: "",
            keywords: []
        });
    }

    Component.onDestruction: {
        if (typeof SettingsSearchRegistry !== "undefined") {
            if (SettingsSearchRegistry.unregisterCollapsibleSection) {
                SettingsSearchRegistry.unregisterCollapsibleSection(root);
            }
            SettingsSearchRegistry.unregisterControl(root);
        }
    }

    Rectangle {
        id: card
        visible: root.classic
        anchors.fill: parent
        radius: SettingsMaterialPreset.cardRadius
        color: SettingsMaterialPreset.cardColor
        border.width: SettingsMaterialPreset.cardBorderWidth
        border.color: SettingsMaterialPreset.cardBorderColor
    }

    Repeater {
        model: root._blocks
        delegate: Rectangle {
            id: blockTile
            required property var modelData
            readonly property Item block: blockTile.modelData.item
            readonly property Item caption: blockTile.modelData.caption ?? null
            // follows an item through every layout between it and the section, so the tile never lags a move
            function chainY(item: Item): real {
                let y = 0
                let p = item
                while (p && p !== sectionContent) {
                    y += p.y
                    p = p.parent
                }
                return y
            }
            readonly property real blockY: blockTile.block ? blockTile.chainY(blockTile.block) : 0
            readonly property real topY: blockTile.caption && blockTile.caption.visible ? blockTile.chainY(blockTile.caption) : blockTile.blockY
            visible: blockTile.block !== null && blockTile.block.visible
            x: column.x
            y: column.y + sectionContent.y + blockTile.topY - SettingsMaterialPreset.tilePaddingY
            width: column.width
            height: blockTile.blockY - blockTile.topY + (blockTile.block ? blockTile.block.height : 0) + SettingsMaterialPreset.tilePaddingY * 2
            color: SettingsMaterialPreset.rowColor
            topLeftRadius: blockTile.modelData.tileTop ? SettingsMaterialPreset.rowOuterRadius : SettingsMaterialPreset.rowInnerRadius
            topRightRadius: topLeftRadius
            bottomLeftRadius: blockTile.modelData.tileBottom ? SettingsMaterialPreset.rowOuterRadius : SettingsMaterialPreset.rowInnerRadius
            bottomRightRadius: bottomLeftRadius
        }
    }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.inset
        spacing: root.classic ? 4 : 8

        // classic: the v2.33 header, its icon in the accent beside the title
        RowLayout {
            visible: root.classic && root.title.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: SettingsMaterialPreset.tilePaddingX
            Layout.rightMargin: SettingsMaterialPreset.tilePaddingX
            Layout.topMargin: 6
            Layout.bottomMargin: 2
            spacing: 10
            MaterialSymbol {
                visible: root.icon.length > 0
                text: root.icon
                iconSize: Appearance.font.pixelSize.larger
                color: SettingsMaterialPreset.iconExpandedColor
            }
            StyledText {
                Layout.fillWidth: true
                text: Appearance.zzzEverywhere ? root.title.toUpperCase() : root.title
                wrapMode: Text.Wrap
                font.family: Appearance.editorialEverywhere ? Appearance.font.family.title : Appearance.font.family.main
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.DemiBold
                color: SettingsMaterialPreset.cardTitleColor
                Accessible.role: Accessible.Heading
            }
        }

        StyledText {
            visible: !root.classic && root.title.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: SettingsMaterialPreset.tilePaddingX
            Layout.rightMargin: SettingsMaterialPreset.tilePaddingX
            text: Appearance.zzzEverywhere ? root.title.toUpperCase() : root.title
            wrapMode: Text.Wrap
            font.family: Appearance.editorialEverywhere ? Appearance.font.family.title : Appearance.font.family.main
            font.pixelSize: SettingsMaterialPreset.subheaderSize
            font.weight: Font.Medium
            font.letterSpacing: 0.1
            color: SettingsMaterialPreset.subheaderColor
            Accessible.role: Accessible.Heading
        }

        ColumnLayout {
            id: sectionContent
            Layout.fillWidth: true
            spacing: 12
            onImplicitHeightChanged: Qt.callLater(root.relayoutTiles)
        }
    }
}
