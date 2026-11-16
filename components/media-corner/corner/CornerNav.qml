pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "reveal.js" as Reveal

// The Corner's places, as iRiS's Settings lists its pages in each style.
// Prism: its name, a search pill, and groups under caps captions whose rows open beneath them while one of theirs is
// shown; without the rail beside the page, Yours (Want to watch, Watching) follows the places here.
// Normal (Folio): every place under its caption, the one you are in on a light pill; the search sits over the page.
Rectangle {
    id: root
    property bool narrow: false
    property bool railVisible: false
    // [{ id, title, icon, caption?, group? }]: titles untranslated; a caption starts a group.
    property var places: []
    property string section: ""
    property string hint: ""
    property real outerRadius: 0
    property int pad: Math.round(10 * root.d)
    readonly property alias search: searchPlate
    readonly property real d: IrisStyle.density
    signal picked(string id)
    signal submitted()

    function isOn(id: string): bool {
        // "anime:genres" is on for each of its genres too ("anime:genre:Drama").
        return CornerState.query.length === 0 && (root.section === id
            || (id.endsWith(":genres") && root.section.startsWith(id.slice(0, -"genres".length) + "genre:")))
    }
    // The palette may still be loading; compare against the column itself, not just the chosen scheme.
    readonly property color accentInk: {
        const readable = IrisStyle.readableAccent(IrisStyle.accent)
        if (ColorUtils.contrastRatio(readable, root.color) >= 4.5) return readable
        if (ColorUtils.contrastRatio(IrisStyle.accent, root.color) >= 4.5) return IrisStyle.accent
        return IrisStyle.text
    }
    // Home, then Anime and Films and series as groups (their rows open while one of theirs is shown), then the rest.
    readonly property var navPlaces: {
        if (!CornerSkin.prism) return root.places
        const result = [root.places[0]]
        const group = (id, title, icon, caption, children) => {
            const open = children.some(place => root.section.startsWith(id + ":"))
            result.push({ id: "group:" + id, title, icon, caption, group: id, first: children[0].id })
            if (open) for (const place of children) result.push(Object.assign({}, place, { caption: "", child: true }))
        }
        group("anime", "Anime", "animation", "Anime", root.places.slice(1, 7))
        group("movie", "Films and series", "movie", "Films and series", root.places.slice(7, 12))
        for (const place of root.places.slice(12)) result.push(place)
        return result
    }
    color: CornerSkin.column
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge
    clip: true

    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: root.pad
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        IrisScrollFeel {}
        ScrollBar.vertical: IrisScrollBar {}

        ColumnLayout {
            id: column
            width: scroller.width
            spacing: 0

            RowLayout {
                visible: CornerSkin.prism
                Layout.fillWidth: true
                Layout.topMargin: Math.round(6 * root.d)
                Layout.bottomMargin: Math.round(14 * root.d)
                Layout.leftMargin: Math.round(6 * root.d)
                spacing: Math.round(8 * root.d)
                MaterialSymbol { text: "movie"; fill: 1; iconSize: Math.round(20 * root.d); color: IrisStyle.text }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Media Corner")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeHeadline
                    font.letterSpacing: CornerSkin.titleTracking
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
            }
            CornerSearch {
                id: searchPlate
                visible: CornerSkin.prism
                Layout.fillWidth: true
                Layout.bottomMargin: Math.round(8 * root.d)
                hint: root.hint
                outerRadius: root.outerRadius
                pad: root.pad
                onSubmitted: root.submitted()
            }
            Repeater {
                model: root.navPlaces
                PlaceRow { Layout.fillWidth: true }
            }
            // The first time it opens: which look to wear. Sources › Appearance changes it later.
            ColumnLayout {
                visible: CornerState.options.style !== "normal" && CornerState.options.style !== "prism"
                Layout.fillWidth: true
                Layout.topMargin: Math.round(14 * root.d)
                spacing: Math.round(6 * root.d)
                IrisText { Layout.fillWidth: true; text: Translation.tr("Style"); color: IrisStyle.textTertiary; font.pixelSize: IrisStyle.typeMeta }
                RowLayout {
                    Layout.fillWidth: true
                    CornerPill { Layout.fillWidth: true; label: Translation.tr("Normal"); onClicked: CornerState.set("style", "normal") }
                    CornerPill { Layout.fillWidth: true; label: Translation.tr("Prism"); onClicked: CornerState.set("style", "prism") }
                }
            }
            LibraryList {
                visible: CornerSkin.prism && !root.railVisible && !root.narrow
                Layout.fillWidth: true
                Layout.topMargin: Math.round(16 * root.d)
            }
        }
    }

    component PlaceRow: MouseArea {
        id: row
        required property var modelData
        readonly property bool isGroup: Boolean(row.modelData.group)
        readonly property bool child: Boolean(row.modelData.child)
        // A group is lit while one of its rows is shown; its row is the plate.
        readonly property bool selected: row.isGroup ? CornerState.query.length === 0 && root.section.startsWith(row.modelData.group + ":") : root.isOn(row.modelData.id)
        readonly property real rowHeight: Math.round((root.narrow ? 40 : 34) * root.d * Math.max(1, IrisStyle.typeScale))
        readonly property string caption: Translation.tr(String(row.modelData.caption ?? ""))
        readonly property real washY: row.caption.length > 0 ? Math.round(12 * root.d) + captionText.implicitHeight + Math.round(4 * root.d) : 0
        implicitHeight: row.washY + row.rowHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr(row.modelData.title)
        function activate(): void { root.picked(row.isGroup ? row.modelData.first : row.modelData.id) }
        onClicked: row.activate()
        Keys.onReturnPressed: row.activate()
        Keys.onSpacePressed: row.activate()
        onActiveFocusChanged: if (activeFocus) Reveal.reveal(row)
        IrisText {
            id: captionText
            visible: row.caption.length > 0
            x: Math.round(12 * root.d)
            y: Math.round(12 * root.d)
            width: row.width - x
            text: row.caption
            color: IrisStyle.textTertiary
            font.family: CornerSkin.prism ? IrisStyle.fontMain : IrisStyle.fontMono
            font.pixelSize: CornerSkin.prism ? IrisStyle.typeFootnote : IrisStyle.typeCaption
            font.letterSpacing: CornerSkin.prism ? 0.6 : 1 // literal: caps captions need tracking to read
            font.weight: IrisStyle.weight(CornerSkin.prism ? Font.DemiBold : Font.Medium)
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
        }
        Rectangle {
            id: plate
            readonly property bool lit: row.selected && !row.isGroup
            y: row.washY
            x: row.child ? Math.round(16 * root.d) : 0
            width: row.width - x
            height: row.rowHeight
            radius: CornerSkin.prism ? IrisStyle.radiusRow : height / 2
            color: plate.lit ? CornerSkin.rowOn : row.containsMouse ? IrisStyle.fillHover : "transparent"
            readonly property color ink: plate.lit ? CornerSkin.rowOnInk : IrisStyle.text
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
            // The mark of where you are: Settings' white bar on the right in Prism, the accent in Normal.
            Rectangle {
                visible: plate.lit && CornerSkin.prism
                x: parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(3 * root.d)
                height: Math.round(18 * root.d)
                radius: width / 2
                color: CornerSkin.prism ? CornerSkin.solid : root.accentInk
            }
            CornerFocusRing { on: row.activeFocus }
            MaterialSymbol {
                id: ink
                visible: !row.child
                x: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.icon
                iconSize: Math.round(18 * root.d)
                fill: row.selected ? 1 : 0
                color: plate.ink
            }
            IrisText {
                x: row.child ? Math.round(14 * root.d) : ink.x + Math.round(30 * root.d)
                width: parent.width - x - Math.round((root.narrow ? 36 : 12) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr(row.modelData.title)
                color: row.child && !row.selected ? IrisStyle.textSecondary : plate.ink
                font.pixelSize: row.child ? IrisStyle.typeMeta : IrisStyle.typeLabel
                font.weight: IrisStyle.weight(row.selected || (!row.child && CornerSkin.prism) ? Font.DemiBold : Font.Normal)
                elide: Text.ElideRight
            }
            MaterialSymbol {
                visible: root.narrow && !row.child
                anchors.right: parent.right
                anchors.rightMargin: Math.round(6 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                iconSize: Math.round(18 * root.d)
                color: IrisStyle.muted
            }
        }
    }
}
