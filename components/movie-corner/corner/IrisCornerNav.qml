pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.settings.layouts

// A Corner's places, drawn the way the Settings layout in use draws its areas:
//   sidebar (Classic) — a pane of rows, each with its tinted mark;
//   index   (Folio)   — ink glyphs down the left, the open one an inverted capsule;
//   list    (Pocket)  — the same rows, taller, to push into;
//   tabs    (Drawer)  — capsules in one line across the top.
// The search plate heads it, and its foot holds the layout keys and the window switch, shared with Settings.
Rectangle {
    id: root
    property string look: "sidebar"
    // [{ id, title, icon, tint, caption? }]: titles untranslated, a caption opens a group.
    property var places: []
    property string section: ""
    // id -> a count shown at the row's end.
    property var badges: ({})
    property string hint: ""
    property real outerRadius: 0
    property int pad: Math.round(10 * root.d)
    // The Corner's body: layouts, chosenLayout, setLayout(), windowed, switchHost().
    property Item host
    readonly property IrisCornerSearch search: root.across ? tabsSearch : searchPlate
    readonly property real d: IrisStyle.density
    readonly property bool across: root.look === "tabs"
    readonly property real need: root.across ? tabsRow.implicitHeight + 2 * root.pad
        : column.implicitHeight + 2 * root.pad
    signal picked(string id)
    signal searched(string text)

    function tintInk(tint: color): color {
        const ink = IrisStyle.text
        return Qt.rgba(tint.r * 0.72 + ink.r * 0.28, tint.g * 0.72 + ink.g * 0.28, tint.b * 0.72 + ink.b * 0.28, 1)
    }
    function isOn(id: string): bool {
        return root.search.query.length === 0 && (root.section === id || (id === "genres" && root.section.startsWith("genre:")))
    }

    color: root.across ? "transparent"
        : root.look === "index" ? (IrisStyle.glassy ? IrisStyle.readingSidebar : Qt.rgba(IrisStyle.text.r, IrisStyle.text.g, IrisStyle.text.b, IrisStyle.light ? 0.03 : 0.035)) // iris-literal: Folio's index paper
        : IrisStyle.readingSidebar
    border.width: root.across || root.look === "index" ? 0 : 1
    border.color: IrisStyle.hairline
    clip: true

    // ── Down the side: sidebar, index, list.
    ColumnLayout {
        id: column
        visible: !root.across
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 0

        IrisCornerSearch {
            id: searchPlate
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(6 * root.d)
            hint: root.hint
            outerRadius: root.outerRadius
            pad: root.pad
            onSearched: text => root.searched(text)
        }
        Flickable {
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: list.implicitHeight
            implicitHeight: list.implicitHeight
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: IrisScrollBar {}
            Column {
                id: list
                width: parent.width
                spacing: root.look === "index" ? Math.round(2 * root.d) : 0
                Repeater {
                    model: root.across ? [] : root.places
                    delegate: PlaceRow {}
                }
            }
        }
        Item { Layout.fillHeight: true }
        Controls { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Math.round(8 * root.d) }
    }

    // ── Across the top: tabs, then the search and the keys.
    RowLayout {
        id: tabsRow
        visible: root.across
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(10 * root.d)
        Flickable {
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.preferredHeight: tabs.implicitHeight
            contentWidth: tabs.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            Row {
                id: tabs
                spacing: Math.round(4 * root.d)
                Repeater {
                    model: root.across ? root.places : []
                    delegate: TabKey {}
                }
            }
        }
        IrisCornerSearch {
            id: tabsSearch
            Layout.preferredWidth: Math.round(240 * root.d)
            hint: root.hint
            outerRadius: root.outerRadius
            pad: root.pad
            onSearched: text => root.searched(text)
        }
        Controls {}
    }

    // The layout keys (Settings' own) and over the desktop / in a window: changing them changes Settings too.
    component Controls: Row {
        spacing: Math.round(6 * root.d)
        LayoutSwitch {
            anchors.verticalCenter: parent.verticalCenter
            host: root.host
            compact: true
        }
        IrisIconButton {
            anchors.verticalCenter: parent.verticalCenter
            materialIcon: root.host?.windowed ? "layers" : "web_asset"
            Accessible.name: root.host?.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
            onClicked: root.host.switchHost()
        }
    }

    component PlaceRow: MouseArea {
        id: row
        required property var modelData
        readonly property bool selected: root.isOn(row.modelData.id)
        readonly property bool index: root.look === "index"
        readonly property color tint: row.modelData.tint
        readonly property real rowHeight: Math.round((root.look === "list" ? 40 : row.index ? 34 : 26) * root.d * Math.max(1, IrisStyle.typeScale))
        readonly property string caption: Translation.tr(String(row.modelData.caption ?? ""))
        readonly property real washY: row.caption.length > 0 ? Math.round(9 * root.d) + captionText.implicitHeight + Math.round(2 * root.d) : 0
        readonly property int count: Number(root.badges[row.modelData.id] ?? 0)
        width: parent ? parent.width : 0
        height: row.washY + row.rowHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr(row.modelData.title)
        onClicked: root.picked(row.modelData.id)
        IrisText {
            id: captionText
            visible: row.caption.length > 0
            x: Math.round((row.index ? 12 : 6) * root.d)
            y: Math.round(9 * root.d)
            width: row.width - x
            text: row.caption
            color: row.index ? IrisStyle.textTertiary : IrisStyle.plateSelection ? IrisStyle.textSecondary : root.tintInk(IrisStyle.accent)
            font.family: row.index ? IrisStyle.fontMono : IrisStyle.fontMain
            font.pixelSize: row.index ? Math.max(10, IrisStyle.typeCaption) : IrisStyle.typeFootnote
            font.weight: IrisStyle.weight(row.index ? Font.Medium : Font.Bold)
            font.capitalization: row.index ? Font.AllUppercase : Font.MixedCase
            elide: Text.ElideRight
        }
        Rectangle {
            id: wash
            y: row.washY
            width: parent.width
            height: row.rowHeight
            radius: row.index ? IrisStyle.capsule(height) : Math.min(row.rowHeight / 2, IrisStyle.tileRadius(mark.width) + mark.x)
            // The index inverts the open one; the rows wash it in their colour.
            color: row.index ? (row.selected ? IrisStyle.text : row.containsMouse ? IrisStyle.fillHover : "transparent")
                : row.selected ? (IrisStyle.plateSelection ? IrisStyle.selectionFill : "transparent")
                : row.containsMouse ? IrisStyle.fillQuiet : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
            Rectangle {
                anchors.fill: parent
                visible: row.selected && !row.index && !IrisStyle.plateSelection
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: ColorUtils.applyAlpha(IrisStyle.tintFillHover(row.tint), 0) }
                    GradientStop { position: 1; color: IrisStyle.tintFillHover(row.tint) }
                }
            }
            IrisSquircle {
                id: mark
                visible: !row.index
                x: Math.round(5 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round((root.look === "list" ? 28 : 22) * root.d)
                height: width
                tint: row.tint
                glyph: row.modelData.icon
                reversed: row.selected && IrisStyle.plateSelection
            }
            MaterialSymbol {
                id: ink
                visible: row.index
                x: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.icon
                iconSize: Math.round(18 * root.d)
                fill: row.selected ? 1 : 0
                color: row.selected ? IrisStyle.surfaceOpaque : IrisStyle.text
            }
            IrisText {
                x: row.index ? ink.x + Math.round(30 * root.d) : mark.x + mark.width + Math.round(10 * root.d)
                width: parent.width - x - Math.round((row.count > 0 || root.look === "list" ? 36 : 12) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                role: IrisText.Name
                text: Translation.tr(row.modelData.title)
                color: row.index ? (row.selected ? IrisStyle.surfaceOpaque : IrisStyle.text)
                    : row.selected && IrisStyle.plateSelection ? IrisStyle.selectionLabel
                    : row.selected ? root.tintInk(row.tint) : IrisStyle.text
                font.weight: IrisStyle.weight(row.selected ? Font.Bold : Font.DemiBold)
                elide: Text.ElideRight
            }
            IrisText {
                visible: row.count > 0
                anchors.right: parent.right
                anchors.rightMargin: Math.round((root.look === "list" ? 30 : 8) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: String(row.count)
                color: row.index && row.selected ? IrisStyle.surfaceOpaque : IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                font.features: { "tnum": 1 }
            }
            MaterialSymbol {
                visible: root.look === "list"
                anchors.right: parent.right
                anchors.rightMargin: Math.round(6 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                iconSize: Math.round(18 * root.d)
                color: IrisStyle.muted
            }
        }
    }

    component TabKey: MouseArea {
        id: key
        required property var modelData
        readonly property bool selected: root.isOn(key.modelData.id)
        width: tabLabel.implicitWidth + tabGlyph.width + Math.round(30 * root.d)
        height: Math.round(34 * root.d)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.PageTab
        Accessible.name: Translation.tr(key.modelData.title)
        Accessible.checked: key.selected
        onClicked: root.picked(key.modelData.id)
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.capsule(height)
            color: key.selected ? IrisStyle.text : key.containsMouse ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(110); easing.type: IrisStyle.feedbackEasing } }
        }
        MaterialSymbol {
            id: tabGlyph
            x: Math.round(12 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            text: key.modelData.icon
            iconSize: Math.round(17 * root.d)
            fill: key.selected ? 1 : 0
            color: key.selected ? IrisStyle.surfaceOpaque : key.modelData.tint
        }
        IrisText {
            id: tabLabel
            anchors.left: tabGlyph.right
            anchors.leftMargin: Math.round(6 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr(key.modelData.title)
            color: key.selected ? IrisStyle.surfaceOpaque : IrisStyle.text
            font.weight: IrisStyle.weight(key.selected ? Font.Bold : Font.DemiBold)
        }
    }
}
