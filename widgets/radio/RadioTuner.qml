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
        { id: "favourites", glyph: "star", label: Translation.tr("Favourites") },
        { id: "recent", glyph: "history", label: Translation.tr("Recent") },
        { id: "popular", glyph: "trophy", label: Translation.tr("Popular") },
        { id: "trending", glyph: "trending_up", label: Translation.tr("Trending") },
        { id: "countries", glyph: "public", label: Translation.tr("Countries") },
        { id: "tags", glyph: "sell", label: Translation.tr("Genres") },
        { id: "languages", glyph: "translate", label: Translation.tr("Languages") }
    ]
    // Opens where the person's own stations are; set once, so playing one never moves the page.
    property string section: ""
    property var drill: null           // { kind, key, name }: a country, genre or language opened from its list
    readonly property bool indexView: root.drill === null && ["countries", "tags", "languages"].includes(root.section)
    readonly property string query: field.text.trim()
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
        field.text = ""
        root.moving = false
        root.load()
    }
    function open(entry: var): void {
        const kind = root.section === "countries" ? "country" : root.section === "tags" ? "tag" : "language"
        root.moving = true
        root.drill = { kind: kind, key: entry.key, name: entry.name }
        field.text = ""
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
        border.width: 1
        border.color: root.look.line
        opacity: 0
        scale: 0.97
        NumberAnimation on opacity { to: 1; duration: 160; easing.type: Easing.OutCubic }
        NumberAnimation on scale { to: 1; duration: 200; easing.type: Easing.OutCubic }
        // A click on the card never reaches the room, and gives the keyboard back to the search.
        MouseArea { anchors.fill: parent; onClicked: field.forceActiveFocus() }

        // ── Ways in ──
        Item {
            id: rail
            width: Math.round(208 * root.d)
            anchors { top: parent.top; bottom: foot.top; left: parent.left }
            Rectangle {
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: root.look.line
            }

            Row {
                id: brand
                x: Math.round(18 * root.d)
                y: Math.round(20 * root.d)
                spacing: Math.round(8 * root.d)
                RadioGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    look: root.look
                    name: "radio"
                    filled: true
                    size: Math.round(20 * root.d)
                    color: root.look.accent
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Radio")
                    font.family: root.look.font
                    font.pixelSize: root.look.title
                    font.weight: Font.Bold
                    color: root.look.ink
                }
            }
            Column {
                anchors { top: brand.bottom; topMargin: Math.round(16 * root.d); left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round(8 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
                spacing: Math.round(2 * root.d)
                Repeater {
                    model: root.sections
                    delegate: Item {
                        id: way
                        required property var modelData
                        readonly property bool here: root.section === way.modelData.id && !root.searching
                        width: parent.width
                        height: Math.round(38 * root.d)
                        Rectangle {
                            anchors.fill: parent
                            radius: root.look.radiusSmall
                            color: way.here ? root.look.selected : wayMouse.containsMouse ? root.look.hover : "transparent"
                        }
                        RadioGlyph {
                            id: wayGlyph
                            x: Math.round(12 * root.d)
                            anchors.verticalCenter: parent.verticalCenter
                            look: root.look
                            name: way.modelData.glyph
                            filled: way.here
                            size: Math.round(18 * root.d)
                            color: way.here ? root.look.accent : root.look.muted
                        }
                        Text {
                            anchors.left: wayGlyph.right
                            anchors.leftMargin: Math.round(12 * root.d)
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: way.modelData.label
                            elide: Text.ElideRight
                            font.family: root.look.font
                            font.pixelSize: root.look.body
                            font.weight: way.here ? Font.DemiBold : Font.Normal
                            color: root.look.ink
                        }
                        MouseArea {
                            id: wayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.go(way.modelData.id)
                        }
                    }
                }
            }
            // The old radio's gift, kept: a station somewhere playing what the person likes, picked for them.
            Item {
                anchors { bottom: parent.bottom; bottomMargin: Math.round(14 * root.d); left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round(8 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
                height: Math.round(52 * root.d)
                Rectangle {
                    anchors.fill: parent
                    radius: root.look.radiusSmall
                    color: luckMouse.pressed ? root.look.press : luckMouse.containsMouse ? root.look.hover : "transparent"
                    border.width: 1
                    border.color: root.look.line
                }
                RadioGlyph {
                    id: luckGlyph
                    x: Math.round(12 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    look: root.look
                    name: "shuffle"
                    size: Math.round(18 * root.d)
                    color: root.look.accent
                }
                Column {
                    anchors.left: luckGlyph.right
                    anchors.leftMargin: Math.round(12 * root.d)
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(8 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: Translation.tr("Surprise me")
                        elide: Text.ElideRight
                        font.family: root.look.font
                        font.pixelSize: root.look.body
                        font.weight: Font.DemiBold
                        color: root.look.ink
                    }
                    Text {
                        width: parent.width
                        text: Radio.genres.length > 0 ? Radio.genres.join(", ") : Translation.tr("Anywhere, any genre")
                        elide: Text.ElideRight
                        font.family: root.look.font
                        font.pixelSize: root.look.small
                        color: root.look.muted
                    }
                }
                MouseArea {
                    id: luckMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Radio.tune()
                }
            }
        }

        // ── The list ──
        Item {
            id: body
            anchors { top: parent.top; bottom: foot.top; left: rail.right; right: parent.right }

            Rectangle {
                id: searchBox
                anchors { top: parent.top; left: parent.left; right: close.left }
                anchors.topMargin: Math.round(14 * root.d)
                anchors.leftMargin: Math.round(16 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
                height: Math.round(38 * root.d)
                radius: root.look.radiusSmall
                color: root.look.raised
                border.width: field.activeFocus ? 1 : 0
                border.color: root.look.accent
                RadioGlyph {
                    id: searchGlyph
                    x: Math.round(12 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    look: root.look
                    name: "search"
                    size: Math.round(18 * root.d)
                    color: root.look.muted
                }
                TextInput {
                    id: field
                    anchors.left: searchGlyph.right
                    anchors.leftMargin: Math.round(10 * root.d)
                    anchors.right: clear.left
                    anchors.verticalCenter: parent.verticalCenter
                    focus: true
                    clip: true
                    font.family: root.look.font
                    font.pixelSize: root.look.body
                    color: root.look.ink
                    selectionColor: root.look.accent
                    selectedTextColor: root.look.onAccent
                    onTextChanged: {
                        if (root.indexView || root.moving) return
                        if (root.query.length === 0) { typing.stop(); root.load() }
                        else typing.restart()
                    }
                    Keys.onEscapePressed: event => {
                        if (field.text.length > 0) field.text = ""
                        else root.dismissed()
                    }
                    Keys.onReturnPressed: root.first()
                    Keys.onEnterPressed: root.first()
                    Keys.onDownPressed: list.forceActiveFocus()
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text.length === 0
                        text: root.indexView
                            ? (root.section === "countries" ? Translation.tr("Find a country")
                                : root.section === "tags" ? Translation.tr("Find a genre") : Translation.tr("Find a language"))
                            : Translation.tr("Search every station by name")
                        font: field.font
                        color: root.look.faint
                    }
                }
                RadioButton {
                    id: clear
                    anchors.right: parent.right
                    anchors.rightMargin: Math.round(4 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text.length > 0
                    width: visible ? implicitWidth : 0
                    look: root.look
                    glyph: "close"
                    size: Math.round(28 * root.d)
                    label: Translation.tr("Clear")
                    onClicked: field.text = ""
                }
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
                anchors { top: searchBox.bottom; topMargin: Math.round(12 * root.d); left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round(16 * root.d)
                anchors.rightMargin: Math.round(16 * root.d)
                height: Math.round(32 * root.d)
                RadioButton {
                    id: back
                    anchors.verticalCenter: parent.verticalCenter
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
                    anchors.right: count.left
                    anchors.rightMargin: Math.round(8 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.drill !== null && root.drill.kind === "country" && !root.searching
                        ? `${R.flag(root.drill.key)} ${root.heading}` : root.heading
                    elide: Text.ElideRight
                    font.family: root.look.font
                    font.pixelSize: root.look.title
                    font.weight: Font.Bold
                    color: root.look.ink
                }
                Text {
                    id: count
                    anchors.right: clearRecent.left
                    anchors.rightMargin: Math.round(6 * root.d)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.shown > 0 && !root.loading
                    text: root.indexView ? Translation.tr("%1 to pick from").arg(root.shown)
                        // A fetched list stops at the directory's 120 most voted: said, never passed off as all.
                        : root.shown >= 100 && !["favourites", "recent"].includes(root.section) ? Translation.tr("Top %1").arg(root.shown)
                        : (root.shown === 1 ? Translation.tr("1 station") : Translation.tr("%1 stations").arg(root.shown))
                    font.family: root.look.font
                    font.pixelSize: root.look.small
                    color: root.look.muted
                }
                Text {
                    id: clearRecent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.section === "recent" && root.drill === null && !root.searching && Radio.recent.length > 0
                    width: visible ? implicitWidth : 0
                    text: Translation.tr("Clear")
                    font.family: root.look.font
                    font.pixelSize: root.look.small
                    font.weight: Font.DemiBold
                    color: clearMouse.containsMouse ? root.look.ink : root.look.accent
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
                anchors { top: head.bottom; topMargin: Math.round(6 * root.d); bottom: parent.bottom; left: parent.left; right: parent.right }
                anchors.leftMargin: Math.round(8 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
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
                    if (list.currentIndex <= 0) field.forceActiveFocus()
                    else event.accepted = false
                }
                Keys.onEscapePressed: field.forceActiveFocus()
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
