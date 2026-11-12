pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import "radio.js" as R

// The tuner: find a station by name, browse the world's by country, genre and language, keep favourites, go back to
// recent ones. Ways in on the left, the list in the middle, what plays at the foot. Drawn with the `look` of the
// family whose face opened it; one window at a time, on that face's screen.
PanelWindow {
    id: root

    property var look
    property var browser
    readonly property real d: root.look?.d ?? 1
    signal dismissed()

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:radio"
    // A modal over a scrim, like a launcher: the keyboard is its while open, so typing searches at once.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── Where the person is ──
    readonly property var sections: [
        { id: "favourites", glyph: "star", label: Translation.tr("Favourites"), group: Translation.tr("Your stations") },
        { id: "recent", glyph: "history", label: Translation.tr("Recent"), group: Translation.tr("Your stations") },
        { id: "popular", glyph: "trophy", label: Translation.tr("Popular"), group: Translation.tr("Discover") },
        { id: "trending", glyph: "trending_up", label: Translation.tr("Trending"), group: Translation.tr("Discover") },
        { id: "countries", glyph: "public", label: Translation.tr("Countries"), group: Translation.tr("Browse") },
        { id: "tags", glyph: "sell", label: Translation.tr("Genres"), group: Translation.tr("Browse") },
        { id: "languages", glyph: "translate", label: Translation.tr("Languages"), group: Translation.tr("Browse") }
    ]
    // Prism's grammar (iRiS): the Settings sidebar, a pill search, a chart of numbered rows, solid main actions.
    readonly property bool prism: root.look?.grammar === "prism"
    // Opens where the person's own stations are; set once, so playing one never moves the page.
    property string section: ""
    property var drill: null           // { kind, key, name }: a country, genre or language opened from its list
    readonly property bool indexView: root.drill === null && ["countries", "tags", "languages"].includes(root.section)
    readonly property string query: search.text.trim()
    readonly property bool searching: root.query.length > 0 && !root.indexView

    // ── What the list holds ──
    property var fetched: []
    property var index: []
    property bool loading: false
    property bool failed: false
    property int asked: 0
    readonly property var stations: root.searching || root.drill !== null ? root.fetched
        : root.section === "favourites" ? Radio.favourites
        : root.section === "recent" ? Radio.recent
        : root.fetched
    readonly property var entries: {
        const q = root.query.toLowerCase()
        return q.length === 0 ? root.index : root.index.filter(e => e.name.toLowerCase().indexOf(q) >= 0)
    }
    readonly property int shown: root.indexView ? root.entries.length : root.stations.length

    function load(): void {
        const ask = ++root.asked
        root.failed = false
        const done = (ok, found) => {
            if (ask !== root.asked) return
            root.loading = false
            root.failed = !ok
            if (root.indexView) root.index = found
            else root.fetched = found
        }
        if (root.indexView) {
            root.index = root.browser.cache[root.section] ?? []
            root.loading = root.index.length === 0
            root.browser.index(root.section, done)
        } else if (root.searching) {
            root.loading = true
            root.browser.list("search", root.query, done)
        } else if (root.drill !== null) {
            root.loading = true
            root.fetched = []
            root.browser.list(root.drill.kind, root.drill.key, done)
        } else if (root.section === "popular" || root.section === "trending") {
            root.loading = true
            root.browser.list(root.section, "", done)
        } else root.loading = false
    }
    // Moving somewhere empties the field without the field asking for a search of its own.
    property bool moving: false
    function go(id: string): void {
        root.moving = true
        root.drill = null
        root.section = id
        search.text = ""
        root.moving = false
        root.load()
    }
    function open(entry: var): void {
        const kind = root.section === "countries" ? "country" : root.section === "tags" ? "tag" : "language"
        root.moving = true
        root.drill = { kind: kind, key: entry.key, name: entry.name }
        search.text = ""
        root.moving = false
        root.load()
    }
    Component.onCompleted: {
        root.section = Radio.favourites.length > 0 ? "favourites" : Radio.recent.length > 0 ? "recent" : "popular"
        root.load()
    }
    Timer { id: typing; interval: 380; onTriggered: if (!root.indexView) root.load() }

    readonly property string heading: root.searching ? Translation.tr("Stations called “%1”").arg(root.query)
        : root.drill !== null ? root.drill.name
        : root.sections.find(s => s.id === root.section)?.label ?? ""
    readonly property string emptyLine: root.failed ? Translation.tr("Radio Browser can't be reached. Check your connection")
        : root.loading ? Translation.tr("Looking…")
        : root.searching ? Translation.tr("No station is called “%1”").arg(root.query)
        : root.indexView ? Translation.tr("Nothing matches “%1”").arg(root.query)
        : root.section === "favourites" && root.drill === null ? Translation.tr("Star a station and it waits here")
        : root.section === "recent" && root.drill === null ? Translation.tr("Stations you play show up here")
        : Translation.tr("Nothing plays here right now")

    // ── The room around it: a click outside closes ──
    Rectangle {
        anchors.fill: parent
        color: root.look.scrim
        MouseArea { anchors.fill: parent; onClicked: root.dismissed() }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Math.round(880 * root.d), (root.screen?.width ?? 1280) - Math.round(48 * root.d))
        height: Math.min(Math.round(620 * root.d), (root.screen?.height ?? 800) - Math.round(96 * root.d))
        radius: root.look.radius
        color: root.look.bg
        border.width: root.prism ? 0 : 1
        border.color: root.look.line
        clip: root.prism
        opacity: 0
        scale: 0.97
        NumberAnimation on opacity { to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation on scale { to: 1; duration: 200; easing.type: Easing.OutCubic }
        // A click on the card never reaches the room, and gives the keyboard back to the search.
        MouseArea { anchors.fill: parent; onClicked: search.forceActiveFocus() }
        // The family's light over the card, when it has one (iRiS: Prism's haze from a corner).
        Loader {
            anchors.fill: parent
            active: root.look?.backdrop !== undefined && root.look?.backdrop !== null
            sourceComponent: root.look?.backdrop ?? null
        }

        // ── Ways in ──
        RadioRail {
            id: rail
            width: Math.round((root.prism ? 232 : 208) * root.d)
            anchors { top: parent.top; bottom: foot.top; left: parent.left }
            look: root.look
            sections: root.sections
            section: root.section
            searching: root.searching
            onWent: id => root.go(id)
        }

        // ── The list ──
        Item {
            id: body
            anchors { top: parent.top; bottom: foot.top; left: rail.right; right: parent.right }

            Item {
                id: searchBox
                anchors { top: parent.top; left: parent.left; right: close.left }
                anchors.topMargin: Math.round(14 * root.d)
                anchors.leftMargin: Math.round(16 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
                height: root.prism ? close.height : Math.round(38 * root.d)
            }
            RadioSearch {
                id: search
                parent: root.prism ? rail.searchSlot : searchBox
                anchors.fill: parent
                focus: true
                look: root.look
                placeholder: root.indexView
                    ? (root.section === "countries" ? Translation.tr("Find a country")
                        : root.section === "tags" ? Translation.tr("Find a genre") : Translation.tr("Find a language"))
                    : root.prism ? Translation.tr("Search stations") : Translation.tr("Search every station by name")
                onTextChanged: {
                    if (root.indexView || root.moving) return
                    if (root.query.length === 0) { typing.stop(); root.load() }
                    else typing.restart()
                }
                onEscaped: {
                    if (search.text.length > 0) search.text = ""
                    else root.dismissed()
                }
                onAccepted: root.first()
                onDown: list.forceActiveFocus()
            }
            RadioButton {
                id: close
                anchors.right: parent.right
                anchors.rightMargin: Math.round(12 * root.d)
                anchors.verticalCenter: searchBox.verticalCenter
                look: root.look
                glyph: "close"
                label: Translation.tr("Close")
                onClicked: root.dismissed()
            }

            Item {
                id: head
                anchors { top: searchBox.bottom; topMargin: Math.round((root.prism ? 2 : 12) * root.d); left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round((root.prism ? 28 : 16) * root.d)
                anchors.rightMargin: Math.round((root.prism ? 28 : 16) * root.d)
                height: Math.round((root.prism ? 60 : 32) * root.d)
                RadioButton {
                    id: back
                    anchors.verticalCenter: root.prism ? headText.verticalCenter : parent.verticalCenter
                    visible: root.drill !== null && !root.searching
                    width: visible ? implicitWidth : 0
                    look: root.look
                    glyph: "chevron_left"
                    size: Math.round(28 * root.d)
                    label: Translation.tr("Back")
                    onClicked: {
                        root.drill = null
                        root.load()
                    }
                }
                Text {
                    id: headText
                    anchors.left: back.right
                    anchors.leftMargin: back.visible ? Math.round(6 * root.d) : 0
                    anchors.right: root.prism ? clearRecent.left : count.left
                    anchors.rightMargin: Math.round(8 * root.d)
                    anchors.verticalCenter: root.prism ? undefined : parent.verticalCenter
                    anchors.bottom: root.prism ? parent.bottom : undefined
                    text: root.drill !== null && root.drill.kind === "country" && !root.searching
                        ? `${R.flag(root.drill.key)} ${root.heading}` : root.heading
                    elide: Text.ElideRight
                    font.family: root.look.font
                    font.pixelSize: root.prism ? root.look.display : root.look.title
                    font.weight: Font.Bold
                    font.letterSpacing: root.prism ? -0.4 : 0
                    color: root.look.ink
                }
                // Prism's eyebrow: how many, in quiet ink over the large title.
                Text {
                    id: count
                    anchors.right: root.prism ? undefined : clearRecent.visible ? clearRecent.left : parent.right
                    anchors.rightMargin: clearRecent.visible ? Math.round(6 * root.d) : 0
                    anchors.verticalCenter: root.prism ? undefined : parent.verticalCenter
                    anchors.left: root.prism ? headText.left : undefined
                    anchors.top: root.prism ? parent.top : undefined
                    visible: root.prism || (root.shown > 0 && !root.loading)
                    text: root.prism && (root.shown === 0 || root.loading) ? Translation.tr("Radio")
                        : root.indexView ? Translation.tr("%1 to pick from").arg(root.shown)
                        // A fetched list stops at the directory's 120 most voted: said, never passed off as all.
                        : root.shown >= 100 && !["favourites", "recent"].includes(root.section) ? Translation.tr("Top %1").arg(root.shown)
                        : (root.shown === 1 ? Translation.tr("1 station") : Translation.tr("%1 stations").arg(root.shown))
                    font.family: root.look.font
                    font.pixelSize: root.prism ? root.look.meta + 1 : root.look.small
                    color: root.look.muted
                }
                Text {
                    id: clearRecent
                    anchors.right: parent.right
                    anchors.verticalCenter: root.prism ? headText.verticalCenter : parent.verticalCenter
                    visible: root.section === "recent" && root.drill === null && !root.searching && Radio.recent.length > 0
                    text: Translation.tr("Clear")
                    font.family: root.look.font
                    font.pixelSize: root.look.small
                    font.weight: Font.DemiBold
                    color: clearMouse.containsMouse ? root.look.ink : root.prism ? root.look.muted : root.look.accent
                    leftPadding: Math.round(8 * root.d)
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Radio.forgetRecent()
                    }
                }
            }

            ListView {
                id: list
                anchors { top: head.bottom; topMargin: Math.round((root.prism ? 10 : 6) * root.d); bottom: parent.bottom; left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round((root.prism ? 16 : 8) * root.d)
                anchors.rightMargin: Math.round((root.prism ? 16 : 8) * root.d)
                anchors.bottomMargin: Math.round(8 * root.d)
                clip: true
                visible: !root.indexView && !(root.loading && root.stations.length === 0)
                model: root.indexView ? [] : root.stations
                currentIndex: -1
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                keyNavigationEnabled: true
                Keys.onReturnPressed: if (list.currentIndex >= 0) Radio.play(root.stations[list.currentIndex], root.stations)
                Keys.onUpPressed: event => {
                    if (list.currentIndex <= 0) search.forceActiveFocus()
                    else event.accepted = false
                }
                Keys.onEscapePressed: search.forceActiveFocus()
                onActiveFocusChanged: if (activeFocus && currentIndex < 0) currentIndex = 0
                delegate: RadioStationRow {
                    look: root.look
                    list: root.stations
                }
            }
            ListView {
                anchors.fill: list
                clip: true
                visible: root.indexView && root.entries.length > 0
                model: root.indexView ? root.entries : []
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                delegate: RadioIndexRow {
                    look: root.look
                    kind: root.section
                    onPicked: entry => root.open(entry)
                }
            }

            // Every state in words: looking, nothing, unreachable.
            Column {
                anchors.centerIn: list
                width: Math.min(list.width - Math.round(48 * root.d), Math.round(360 * root.d))
                spacing: Math.round(10 * root.d)
                visible: root.shown === 0 || (root.loading && root.shown === 0)
                RadioGlyph {
                    anchors.horizontalCenter: parent.horizontalCenter
                    look: root.look
                    name: root.failed ? "error" : root.loading ? "radio"
                        : root.section === "favourites" && root.drill === null && !root.searching ? "star" : "search"
                    size: Math.round(32 * root.d)
                    color: root.failed ? root.look.danger : root.look.faint
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: root.emptyLine
                    font.family: root.look.font
                    font.pixelSize: root.look.body
                    color: root.look.muted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.failed
                    text: Translation.tr("Try again")
                    font.family: root.look.font
                    font.pixelSize: root.look.body
                    font.weight: Font.DemiBold
                    color: root.look.accent
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -Math.round(8 * root.d)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.load()
                    }
                }
            }
        }

        RadioNowPlaying {
            id: foot
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            look: root.look
        }
    }

    // Enter plays the first station of the list.
    function first(): void {
        if (root.indexView) { if (root.entries.length > 0) root.open(root.entries[0]) }
        else if (root.stations.length > 0) Radio.play(root.stations[0], root.stations)
    }
}
