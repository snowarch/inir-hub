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

// The Corner's places. Prism groups the open catalogue beneath its page; Normal keeps the original list.
Rectangle {
    id: root
    property string pendingHistoryRemoval: ""
    property bool narrow: false
    property bool prism: false
    property bool railVisible: false
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

    // The palette may still be loading; compare against the actual rail, not just the chosen scheme.
    readonly property color accentInk: {
        const readable = IrisStyle.readableAccent(IrisStyle.accent)
        if (ColorUtils.contrastRatio(readable, root.color) >= 4.5) return readable
        if (ColorUtils.contrastRatio(IrisStyle.accent, root.color) >= 4.5) return IrisStyle.accent
        return IrisStyle.text
    }
    readonly property var navPlaces: {
        if (!root.prism) return root.places
        const anime = root.section.startsWith("anime:")
        const movies = root.section.startsWith("movie:")
        const result = [root.places[0], { id: "anime:popular", title: "Anime", icon: "animation", group: "anime", caption: "Anime" }]
        if (anime) result.push(...root.places.slice(1, 7).map(p => Object.assign({}, p, { caption: "", child: true })))
        result.push({ id: "movie:movies", title: "Films and series", icon: "movie", group: "movie", caption: "Films and series" })
        if (movies) result.push(...root.places.slice(7, 12).map(p => Object.assign({}, p, { caption: "", child: true })))
        result.push(root.places[12], root.places[13], root.places[14])
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
        RowLayout {
            visible: root.prism
            Layout.fillWidth: true
            Layout.topMargin: Math.round(12 * root.d)
            Layout.bottomMargin: Math.round(18 * root.d)
            spacing: Math.round(8 * root.d)
            MaterialSymbol {
                text: "movie"
                fill: 1
                iconSize: Math.round(20 * root.d)
                color: IrisStyle.text
            }
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("Media Corner")
                font.pixelSize: IrisStyle.typeHeadline
                font.weight: IrisStyle.weight(Font.Bold)
                font.letterSpacing: -0.3
                elide: Text.ElideRight
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
        SavedFilter {
            visible: !root.railVisible
            Layout.fillWidth: true
            Layout.bottomMargin: Math.round(6 * root.d)
        }
        SavedSort { visible: !root.railVisible; Layout.fillWidth: true }
        RowLayout {
            visible: CornerWatch.progressLoadFailed
            Layout.fillWidth: true
            IrisText { Layout.fillWidth: true; text: Translation.tr("Could not load playback history"); color: IrisStyle.danger; wrapMode: Text.WordWrap }
            IrisButton { quiet: true; text: Translation.tr("Retry"); onClicked: CornerWatch.retryProgressLoad() }
        }
        ListView {
            id: list
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: contentHeight
            implicitHeight: contentHeight
            spacing: Math.round(2 * root.d)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: IrisScrollBar {}
            model: {
                const rows = root.navPlaces.map(place => ({ kind: "place", place }))
                if (CornerWatch.watchlistLoadFailed) rows.push({ kind: "error" })
                const wanted = root.railVisible ? [] : CornerWatch.sortedSavedKeys.filter(key => CornerWatch.matchesSaved(CornerWatch.watchlist[key], CornerState.savedQuery))
                if (wanted.length) rows.push({ kind: "wantedHeader" })
                for (const key of wanted) rows.push({ kind: "wanted", key })
                const watching = !root.railVisible ? Object.keys(CornerWatch.progress).filter(key => {
                    const entry = CornerWatch.progress[key]
                    return entry && entry.show && CornerWatch.matchesSaved(entry.show, CornerState.savedQuery)
                }).sort((a, b) => CornerWatch.progress[b].at - CornerWatch.progress[a].at) : []
                if (!CornerState.savedQuery.trim()) watching.splice(5)
                if (watching.length) rows.push({ kind: "watchingHeader" })
                for (const key of watching) rows.push({ kind: "watching", key })
                if (!root.railVisible && CornerState.savedQuery.trim() && !wanted.length && !watching.length)
                    rows.push({ kind: "emptySaved" })
                return rows
            }
            delegate: Loader {
                id: sidebarRow
                required property var modelData
                width: list.width
                sourceComponent: modelData.kind === "place" ? placeRow : modelData.kind === "error" ? errorRow : modelData.kind === "wantedHeader" || modelData.kind === "watchingHeader" ? headerRow : modelData.kind === "wanted" ? wantedRow : modelData.kind === "emptySaved" ? emptySavedRow : watchingRow
                Component { id: placeRow; PlaceRow { modelData: sidebarRow.modelData.place } }
                Component {
                    id: errorRow
                    RowLayout {
                        IrisText { Layout.fillWidth: true; text: Translation.tr("Could not load saved titles"); color: IrisStyle.danger; wrapMode: Text.WordWrap }
                        IrisButton { quiet: true; text: Translation.tr("Retry"); onClicked: CornerWatch.retryWatchlistLoad() }
                    }
                }
                Component { id: headerRow; IrisText {
                    text: Translation.tr(sidebarRow.modelData.kind === "wantedHeader" ? "Want to watch" : "Watching")
                    color: IrisStyle.textTertiary
                    font.pixelSize: 11 * IrisStyle.typeScale
                    font.letterSpacing: sidebarRow.modelData.kind === "watchingHeader" ? 0.6 : 0
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    font.capitalization: sidebarRow.modelData.kind === "watchingHeader" ? Font.AllUppercase : Font.MixedCase
                    leftPadding: Math.round(12 * root.d)
                    topPadding: Math.round(12 * root.d)
                    bottomPadding: sidebarRow.modelData.kind === "watchingHeader" ? Math.round(4 * root.d) : 0
                } }
                Component { id: emptySavedRow; IrisText {
                    text: Translation.tr("Nothing here yet")
                    color: IrisStyle.textTertiary
                    leftPadding: Math.round(12 * root.d)
                } }
                Component { id: wantedRow; RowLayout {
                        IrisButton {
                            Layout.fillWidth: true
                            quiet: true
                            text: String(CornerWatch.watchlist[sidebarRow.modelData.key]?.title ?? "")
                            onClicked: CornerState.openShow(CornerWatch.watchlist[sidebarRow.modelData.key])
                        }
                        IrisIconButton {
                            materialIcon: "close"
                            Accessible.name: Translation.tr("Remove")
                            onClicked: CornerWatch.toggleWatchlist(CornerWatch.watchlist[sidebarRow.modelData.key])
                        }
                } }
                Component { id: watchingRow; ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true
                        HoverHandler { id: watchedHover }
                        IrisButton {
                            Layout.fillWidth: true
                            quiet: true
                            readonly property var entry: CornerWatch.progress[sidebarRow.modelData.key]
                            text: String(entry?.show?.title ?? "") + (entry?.episode ? " · " + (entry.episode.season ? entry.episode.season + "×" : "") + entry.episode.episode : "")
                            onClicked: {
                                if (!entry?.show) return
                                CornerState.openShow(entry.show)
                                CornerWatch.begin(entry.show, entry.episode ?? null)
                            }
                        }
                        IrisIconButton {
                            materialIcon: "close"
                            enabled: !(CornerWatch.busy && CornerWatch._current?.key === sidebarRow.modelData.key)
                            opacity: watchedHover.hovered || activeFocus ? 1 : 0
                            Accessible.name: Translation.tr("Remove history entry")
                            onClicked: root.pendingHistoryRemoval = sidebarRow.modelData.key
                        }
                    }
                    IrisButton {
                        Layout.fillWidth: true
                        quiet: true
                        visible: root.pendingHistoryRemoval === sidebarRow.modelData.key
                        text: Translation.tr("Confirm remove history entry")
                        onClicked: { CornerWatch.forget(sidebarRow.modelData.key); root.pendingHistoryRemoval = "" }
                    }
                    IrisButton {
                        Layout.fillWidth: true
                        quiet: true
                        visible: root.pendingHistoryRemoval === sidebarRow.modelData.key
                        text: Translation.tr("Cancel")
                        onClicked: root.pendingHistoryRemoval = ""
                    }
                } }
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
            color: root.prism ? (!row.modelData.child && row.selected ? Qt.alpha(IrisStyle.accent, IrisStyle.light ? 0.13 : 0.16) : row.containsMouse ? IrisStyle.fillHover : "transparent") : row.selected ? IrisStyle.text : row.containsMouse ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(root.prism ? 160 : 110); easing.type: IrisStyle.feedbackEasing } }
            Rectangle {
                visible: root.prism && row.selected && !row.modelData.group
                x: parent.width - width
                anchors.verticalCenter: parent.verticalCenter
                width: Math.round(3 * root.d)
                height: Math.round(18 * root.d)
                radius: width / 2
                color: root.accentInk
            }
            CornerFocusRing { on: row.activeFocus }
            MaterialSymbol {
                id: ink
                visible: !row.modelData.child
                x: Math.round(12 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.icon
                iconSize: Math.round(18 * root.d)
                fill: row.selected ? 1 : 0
                color: row.selected ? (root.prism ? root.accentInk : IrisStyle.surfaceOpaque) : IrisStyle.text
            }
            IrisText {
                x: row.modelData.child ? Math.round(16 * root.d) : ink.x + Math.round(30 * root.d)
                width: parent.width - x - Math.round((root.narrow ? 36 : 12) * root.d)
                anchors.verticalCenter: parent.verticalCenter
                role: IrisText.Name
                text: Translation.tr(row.modelData.title)
                color: row.selected ? (root.prism ? (row.modelData.child ? IrisStyle.text : root.accentInk) : IrisStyle.surfaceOpaque) : (row.modelData.child ? IrisStyle.textSecondary : IrisStyle.text)
                font.pixelSize: root.prism ? 13 * IrisStyle.typeScale : row.modelData.child ? IrisStyle.typeFootnote : IrisStyle.typeLabel
                font.weight: IrisStyle.weight(row.selected ? Font.DemiBold : row.modelData.child ? Font.Normal : Font.DemiBold)
                elide: Text.ElideRight
            }
            MaterialSymbol {
                visible: root.narrow && !row.modelData.child
                anchors.right: parent.right
                anchors.rightMargin: Math.round(6 * root.d)
                anchors.verticalCenter: parent.verticalCenter
                text: "chevron_right"
                iconSize: Math.round(18 * root.d)
                color: row.selected ? (root.prism ? root.accentInk : IrisStyle.surfaceOpaque) : IrisStyle.muted
            }
        }
    }
}
