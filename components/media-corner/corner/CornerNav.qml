pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "reveal.js" as Reveal

// The Corner's places: the search plate, a glyph and a name for each, the open one an inverted capsule, and at the foot
// the key that moves it between the desktop and a window. In a narrow window the rows are taller, to push into.
Rectangle {
    id: root
    property bool narrow: false
    property bool prism: false
    property bool windowed: false
    // [{ id, title, icon, caption? }]: titles untranslated, a caption opens a group.
    property var places: []
    property string section: ""
    property string hint: ""
    property real outerRadius: 0
    property int pad: Math.round(10 * root.d)
    readonly property alias search: searchPlate
    readonly property real d: IrisStyle.density
    signal picked(string id)
    signal submitted()
    signal switchHost()
    signal closeRequested()

    function isOn(id: string): bool {
        // "anime:genres" is on for each of its genres too ("anime:genre:Drama").
        return CornerState.query.length === 0 && (root.section === id
            || (id.endsWith(":genres") && root.section.startsWith(id.slice(0, -"genres".length) + "genre:")))
    }

    readonly property color accentInk: IrisStyle.readableAccent(IrisStyle.accent)
    readonly property var navPlaces: {
        if (!root.prism) return root.places
        const anime = root.section.startsWith("anime:")
        const movies = root.section.startsWith("movie:")
        const result = [root.places[0], { id: "anime:popular", title: "Anime", icon: "animation", group: "anime", caption: "Anime" }]
        if (anime) result.push(...root.places.slice(1, 7).map(p => Object.assign({}, p, { caption: "", child: true })))
        result.push({ id: "movie:movies", title: "Films and series", icon: "movie", group: "movie", caption: "Films and series" })
        if (movies) result.push(...root.places.slice(7, 12).map(p => Object.assign({}, p, { caption: "", child: true })))
        result.push(root.places[12])
        return result
    }
    color: root.prism ? IrisStyle.surfaceHigh : IrisStyle.readingSidebar
    border.width: root.prism ? 1 : 0
    border.color: IrisStyle.hairline
    clip: true

    Rectangle {
        visible: root.prism
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.round(150 * root.d)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(IrisStyle.accent, 0.12) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 0

        RowLayout {
            visible: root.prism
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(8 * root.d)
            IrisIconButton {
                id: closeKey
                materialIcon: "close"
                Accessible.name: Translation.tr("Close")
                onClicked: root.closeRequested()
                StyledToolTip { text: closeKey.Accessible.name; extraVisibleCondition: closeKey.buttonHovered }
            }
            Item { Layout.fillWidth: true }
            IrisIconButton {
                id: topHostKey
                materialIcon: root.windowed ? "layers" : "open_in_new"
                Accessible.name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
                onClicked: root.switchHost()
                StyledToolTip { text: topHostKey.Accessible.name; extraVisibleCondition: topHostKey.buttonHovered }
            }
        }
        CornerSearch {
            id: searchPlate
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(6 * root.d)
            hint: root.hint
            outerRadius: root.outerRadius
            pad: root.pad
            onSubmitted: root.submitted()
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
                spacing: Math.round(2 * root.d)
                Repeater {
                    model: root.navPlaces
                    delegate: PlaceRow {}
                }
                IrisText {
                    visible: root.prism && watchList.count > 0
                    text: Translation.tr("Watching")
                    color: IrisStyle.textTertiary
                    font.pixelSize: 11 * IrisStyle.typeScale
                    font.letterSpacing: 0.6
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    font.capitalization: Font.AllUppercase
                    leftPadding: Math.round(12 * root.d)
                    topPadding: Math.round(12 * root.d)
                    bottomPadding: Math.round(4 * root.d)
                }
                Repeater {
                    id: watchList
                    model: root.prism ? Object.keys(CornerWatch.progress).filter(key => {
                        const entry = CornerWatch.progress[key]
                        return entry && entry.show && CornerWatch.resumeAt(key) > 0
                    }).sort((a, b) => CornerWatch.progress[b].at - CornerWatch.progress[a].at).slice(0, 5) : []
                    delegate: RowLayout {
                        id: watched
                        required property string modelData
                        width: list.width
                        HoverHandler { id: watchedHover }
                        IrisButton {
                            Layout.fillWidth: true
                            quiet: true
                            text: String(CornerWatch.progress[watched.modelData]?.show?.title ?? "")
                            onClicked: {
                                const entry = CornerWatch.progress[watched.modelData]
                                if (!entry?.show) return
                                CornerState.openShow(entry.show)
                                CornerWatch.begin(entry.show, entry.episode ?? null)
                            }
                        }
                        IrisIconButton {
                            materialIcon: "close"
                            opacity: watchedHover.hovered || activeFocus ? 1 : 0
                            Accessible.name: Translation.tr("Remove")
                            onClicked: CornerWatch.forget(watched.modelData)
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            visible: CornerState.options.style !== "normal" && CornerState.options.style !== "prism"
            Layout.fillWidth: true
            IrisButton { text: Translation.tr("Normal"); Layout.fillWidth: true; onClicked: CornerState.set("style", "normal") }
            IrisButton { text: Translation.tr("Prism"); Layout.fillWidth: true; onClicked: CornerState.set("style", "prism") }
        }
        IrisIconButton {
            id: hostKey
            visible: !root.prism
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Math.round(8 * root.d)
            materialIcon: root.windowed ? "layers" : "web_asset"
            Accessible.name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
            onClicked: root.switchHost()
            StyledToolTip { text: hostKey.Accessible.name; extraVisibleCondition: hostKey.buttonHovered }
        }
    }

    component PlaceRow: MouseArea {
        id: row
        required property var modelData
        readonly property bool selected: row.modelData.group ? root.section.startsWith(row.modelData.group + ":") : root.isOn(row.modelData.id)
        readonly property real rowHeight: Math.round((root.narrow ? 40 : 34) * root.d * Math.max(1, IrisStyle.typeScale))
        readonly property string caption: Translation.tr(String(row.modelData.caption ?? ""))
        readonly property real washY: row.caption.length > 0 ? Math.round(9 * root.d) + captionText.implicitHeight + Math.round(2 * root.d) : 0
        width: parent ? parent.width : 0
        height: row.washY + row.rowHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Translation.tr(row.modelData.title)
        onClicked: root.picked(row.modelData.id)
        Keys.onReturnPressed: root.picked(row.modelData.id)
        Keys.onSpacePressed: root.picked(row.modelData.id)
        onActiveFocusChanged: if (activeFocus) Reveal.reveal(row)
        IrisText {
            id: captionText
            visible: row.caption.length > 0
            x: Math.round(12 * root.d)
            y: Math.round(9 * root.d)
            width: row.width - x
            text: row.caption
            color: root.prism && row.selected ? root.accentInk : IrisStyle.textTertiary
            font.family: root.prism ? IrisStyle.fontMain : IrisStyle.fontMono
            font.pixelSize: root.prism ? 11 * IrisStyle.typeScale : IrisStyle.typeCaption
            font.letterSpacing: root.prism ? 0.6 : 0
            font.weight: IrisStyle.weight(root.prism ? Font.DemiBold : Font.Medium)
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
        }
        Rectangle {
            visible: root.prism && Boolean(row.modelData.child)
            x: Math.round(20 * root.d)
            y: 0
            width: 1
            height: row.height
            color: IrisStyle.hairline
        }
        Rectangle {
            y: row.washY
            x: row.modelData.child ? Math.round(16 * root.d) : 0
            width: parent.width - x
            height: row.rowHeight
            radius: root.prism ? IrisStyle.radiusRow : IrisStyle.capsule(height)
            color: root.prism ? (row.selected ? Qt.alpha(IrisStyle.accent, IrisStyle.light ? 0.13 : 0.16) : row.containsMouse ? IrisStyle.fillHover : "transparent") : row.selected ? IrisStyle.text : row.containsMouse ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(root.prism ? 160 : 110); easing.type: IrisStyle.feedbackEasing } }
            Rectangle {
                visible: root.prism && row.selected && !row.modelData.child
                x: -root.pad
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(3 * root.d)
                height: Math.round(18 * root.d)
                radius: width / 2
                color: root.accentInk
            }
            CornerFocusRing { on: row.activeFocus }
            MaterialSymbol {
                id: ink
                x: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.icon
                iconSize: Math.round(18 * root.d)
                fill: row.selected ? 1 : 0
                color: row.selected ? (root.prism ? root.accentInk : IrisStyle.surfaceOpaque) : IrisStyle.text
            }
            IrisText {
                x: ink.x + Math.round(30 * root.d)
                width: parent.width - x - Math.round((root.narrow ? 36 : 12) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                role: IrisText.Name
                text: Translation.tr(row.modelData.title)
                color: row.selected ? (root.prism ? root.accentInk : IrisStyle.surfaceOpaque) : IrisStyle.text
                font.weight: IrisStyle.weight(row.selected ? Font.Bold : Font.DemiBold)
                elide: Text.ElideRight
            }
            MaterialSymbol {
                visible: root.narrow
                anchors.right: parent.right
                anchors.rightMargin: Math.round(6 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                iconSize: Math.round(18 * root.d)
                color: row.selected ? IrisStyle.surfaceOpaque : IrisStyle.muted
            }
        }
    }
}
