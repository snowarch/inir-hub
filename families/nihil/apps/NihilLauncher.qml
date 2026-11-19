pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// The launcher, a page of the sheet: the search on top, the kinds of app under it and the grid. Typing turns the grid into
// what was found. The field keeps the keys the whole time and steers whatever is on show.
FocusScope {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 1000
    property bool open: false

    readonly property var options: Config.options?.nihil?.apps ?? ({})
    readonly property bool searching: NihilState.view === "search"
        && (NihilState.query.length > 0 || NihilState.searchScope !== "all")
    readonly property real pad: NihilStyle.s(32)
    property string kind: "all"

    readonly property var kinds: [
        { id: "all", word: Translation.tr("All") },
        { id: "internet", word: Translation.tr("Internet") },
        { id: "creation", word: Translation.tr("Creation") },
        { id: "games", word: Translation.tr("Games") },
        { id: "work", word: Translation.tr("Work") },
        { id: "system", word: Translation.tr("System") }
    ].filter(item => item.id === "all" || (grid.item?.kindsHeld ?? []).includes(item.id))
    readonly property var scopes: [
        { id: "all", word: Translation.tr("All") },
        { id: "windows", word: Translation.tr("Windows") },
        { id: "recent", word: Translation.tr("Recent files") }
    ]

    implicitWidth: Math.round((root.screen?.width ?? 1920) * (root.options.pageWidth ?? 0.667))
    implicitHeight: Math.min(root.room, Math.round((root.screen?.height ?? 1080) * (root.options.pageHeight ?? 0.78)))

    onOpenChanged: if (root.open) field.resume()
    Component.onCompleted: if (root.open) field.resume()

    function setScope(scope: string): void {
        NihilState.searchScope = scope
        NihilState.setQuery(NihilState.query)
    }

    Keys.onEscapePressed: {
        if (NihilState.query.length > 0 || NihilState.searchScope !== "all") {
            NihilState.searchScope = "all"
            field.clear()
        } else {
            NihilState.leaveLauncher()
        }
    }
    Keys.onPressed: event => {
        if (root.searching || (event.key !== Qt.Key_PageDown && event.key !== Qt.Key_PageUp))
            return
        grid.item?.turn(event.key === Qt.Key_PageDown ? 1 : -1)
        event.accepted = true
    }

    NField {
        id: field
        x: root.pad
        y: NihilStyle.s(24)
        width: root.width - root.pad * 2
        height: NihilStyle.s(68)
        radius: NihilStyle.r(22)
        glyph: "search"
        glyphSize: NihilStyle.s(26)
        textSize: NihilStyle.s(22)
        textWeight: Font.Light
        clearable: true
        placeholder: Translation.tr("Search apps, windows and files")
        value: NihilState.query
        onEdited: text => NihilState.setQuery(text)
        onEntered: root.searching ? results.item?.activateFirst() : grid.item?.activateFirst()
        onStepped: by => root.searching ? results.item?.step(by) : grid.item?.step(by * (grid.item?.columns ?? 1))
        onWalked: by => root.searching ? results.item?.step(by) : grid.item?.step(by)
    }

    // The kinds of app, or what a search looks through.
    Row {
        id: chips
        x: root.pad
        y: field.y + field.height + NihilStyle.s(14)
        height: NihilStyle.s(32)
        spacing: NihilStyle.s(4)

        Repeater {
            model: root.searching ? root.scopes : root.kinds

            MouseArea {
                id: chip
                required property var modelData
                readonly property bool chosen: root.searching ? NihilState.searchScope === chip.modelData.id
                    : root.kind === chip.modelData.id

                width: word.implicitWidth + NihilStyle.s(28)
                height: chips.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.RadioButton
                Accessible.name: chip.modelData.word
                Accessible.checked: chip.chosen
                onClicked: {
                    if (root.searching) root.setScope(chip.modelData.id)
                    else root.kind = chip.modelData.id
                }

                Rectangle {
                    anchors.fill: parent
                    radius: NihilStyle.rKey
                    color: chip.chosen ? NihilStyle.chosen : chip.containsMouse ? NihilStyle.piece : "transparent"
                    Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
                }
                NText {
                    id: word
                    anchors.centerIn: parent
                    text: chip.modelData.word
                    font.pixelSize: NihilStyle.textSmall
                    font.weight: chip.chosen ? Font.Medium : Font.Normal
                    color: chip.chosen || chip.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
                }
            }
        }
    }

    Item {
        id: area
        x: root.pad
        y: chips.y + chips.height + NihilStyle.s(14)
        width: root.width - root.pad * 2
        height: root.height - y - NihilStyle.s(24)

        Loader {
            id: grid
            anchors.fill: parent
            active: root.options !== undefined
            visible: !root.searching
            sourceComponent: NihilApps {
                takesKeys: false
                kind: root.kind
                onFolderClosed: field.resume()
            }
        }
        Loader {
            id: results
            anchors.fill: parent
            active: root.searching
            source: "NihilSearchResults.qml"
        }
    }
}
