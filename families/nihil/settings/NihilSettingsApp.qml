pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// NiHiL's Settings: a window of its own, the rail of pages on the left and the open page beside it, over the
// wallpaper when the person keeps it there. Opened at a page by the shell through QS_SETTINGS_PAGE and _SECTION.
ApplicationWindow {
    id: root

    property string pageKey: "home"
    property string jumpTo: ""
    property string query: ""
    readonly property bool searching: root.query.trim().length > 0
    readonly property bool compact: root.width < NihilStyle.s(1000)
    readonly property var page: SettingsModel.page(root.pageKey)
    readonly property bool backdrop: Config.options?.nihil?.settings?.backdrop ?? true
    readonly property real gutter: NihilStyle.s(12)

    function open(key: string, section: string): void {
        root.query = ""
        search.clear()
        root.pageKey = SettingsModel.resolve(key)
        root.jumpTo = section
    }
    function stepPage(by: int): void {
        const pages = SettingsModel.pages
        const at = pages.findIndex(entry => entry.key === root.pageKey)
        root.open(pages[(at + by + pages.length) % pages.length].key, "")
    }

    visible: true
    title: Translation.tr("NiHiL Settings")
    width: 1180
    height: 780
    minimumWidth: 720
    minimumHeight: 560
    color: NihilStyle.paper
    onClosing: Qt.quit()

    Component.onCompleted: {
        const start = String(Quickshell.env("QS_SETTINGS_PAGE") ?? "")
        if (start.length > 0) root.open(start, String(Quickshell.env("QS_SETTINGS_SECTION") ?? ""))
    }

    // A page asked for by the shell while this window is already up.
    FileView {
        id: pageAsk
        property bool armed: false
        property bool present: false
        path: `${Directories.stateUserPath}/nihil/settings-page`
        // A file that is not there yet cannot be watched.
        watchChanges: pageAsk.present
        onFileChanged: reload()
        onSaved: pageAsk.present = true
        onLoaded: {
            const asked = pageAsk.text().trim().split(" ")[0]
            if (pageAsk.armed && asked.length > 0) root.open(asked, "")
            pageAsk.armed = true
            pageAsk.present = true
        }
        onLoadFailed: {
            pageAsk.armed = true
            pageAsk.setText("")
        }
    }

    Shortcut { sequence: "Ctrl+F"; onActivated: search.take() }
    Shortcut { sequence: "Ctrl+PgDown"; onActivated: root.stepPage(1) }
    Shortcut { sequence: "Ctrl+PgUp"; onActivated: root.stepPage(-1) }
    Shortcut { sequence: "Ctrl+W"; onActivated: root.close() }

    Image {
        anchors.fill: parent
        visible: root.backdrop
        source: root.backdrop ? Wallpapers.effectiveWallpaperUrl : ""
        sourceSize.width: 1280
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }
    Rectangle {
        anchors.fill: parent
        visible: root.backdrop
        // Dense enough that small words keep their contrast over the brightest wallpaper.
        color: NihilStyle.tone(NihilStyle.dark ? 0.05 : 0.95, NihilStyle.dark ? 0.8 : 0.88)
    }

    Rectangle {
        id: rail
        x: root.gutter
        y: root.gutter
        width: root.compact ? NihilStyle.s(70) : NihilStyle.s(238)
        height: parent.height - root.gutter * 2
        radius: NihilStyle.cardRadius
        color: NihilStyle.piece

        Item {
            id: brand
            x: NihilStyle.s(19)
            y: NihilStyle.s(20)
            width: parent.width - x * 2
            height: root.compact ? NihilStyle.s(14) : NihilStyle.s(58)

            DotText {
                visible: !root.compact
                text: "NIHIL"
                dot: NihilStyle.s(4)
                color: NihilStyle.ink
            }
            Row {
                visible: !root.compact
                anchors.bottom: parent.bottom
                spacing: NihilStyle.s(6)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(7)
                    height: width
                    radius: NihilStyle.squareDots ? 0 : width / 2
                    color: NihilStyle.accent
                }
                NText {
                    figures: true
                    text: SettingsModel.accentWord.toUpperCase()
                    font.pixelSize: NihilStyle.s(10)
                    color: NihilStyle.inkSoft
                }
            }
            Rectangle {
                visible: root.compact
                anchors.centerIn: parent
                width: NihilStyle.s(12)
                height: width
                radius: NihilStyle.squareDots ? 0 : width / 2
                color: NihilStyle.accent
            }
        }

        NScroller {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: root.compact ? NihilStyle.s(50) : NihilStyle.s(146)
            anchors.bottomMargin: NihilStyle.s(10)
            sidePad: root.compact ? 0 : NihilStyle.s(10)
            spacing: NihilStyle.s(2)
            Repeater {
                model: SettingsModel.pages
                NavPill {
                    required property var modelData
                    entry: modelData
                    compact: root.compact
                    chosen: !root.searching && root.pageKey === modelData.key
                    onClicked: root.open(modelData.key, "")
                    onHoveredChanged: {
                        if (!root.compact) return
                        tip.word = hovered ? modelData.label : ""
                        tip.y = mapToItem(root.contentItem, 0, 0).y + (height - tip.height) / 2
                    }
                }
            }
        }
    }

    Item {
        id: stage
        anchors.left: rail.right
        anchors.leftMargin: NihilStyle.s(14)
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(8)
        anchors.top: parent.top
        anchors.topMargin: root.compact ? root.gutter + search.height : 0
        anchors.bottom: parent.bottom

        SettingsPage {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, NihilStyle.s(1320))
            visible: !root.searching
            page: root.page
            jump: root.jumpTo
            onLanded: root.jumpTo = ""
        }
        Loader {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, NihilStyle.s(1320))
            active: root.searching
            sourceComponent: SearchResults {
                query: root.query
                onOpenPage: key => root.open(key, "")
            }
        }
    }

    // In the rail while there is room for it, over the page once the rail folds to its glyphs.
    NField {
        id: search
        x: root.compact ? stage.x + NihilStyle.s(6) : rail.x + NihilStyle.s(12)
        y: root.compact ? root.gutter : rail.y + NihilStyle.s(92)
        width: root.compact ? stage.width - NihilStyle.s(12) : rail.width - NihilStyle.s(24)
        glyph: "search"
        placeholder: Translation.tr("Search settings")
        clearable: true
        onEdited: text => root.query = text
    }

    // The name of a page while the rail shows only glyphs.
    Rectangle {
        id: tip
        property string word: ""
        visible: root.compact && tip.word.length > 0
        x: rail.x + rail.width + NihilStyle.s(6)
        z: 10
        width: tipWord.implicitWidth + NihilStyle.s(22)
        height: NihilStyle.s(30)
        radius: NihilStyle.keyRadius(width, height, false)
        color: NihilStyle.pieceRaised
        NText { id: tipWord; anchors.centerIn: parent; text: tip.word; font.pixelSize: NihilStyle.textSmall }
    }

    // A press of the pointer ends keyboard travel: the focus ring lets go, a field being left keeps what it has, and
    // the press carries on to whatever is under it.
    MouseArea {
        id: pointer
        anchors.fill: parent
        z: 100
        acceptedButtons: Qt.AllButtons
        onPressed: event => {
            const held = root.activeFocusItem
            const inField = held?.cursorPosition !== undefined && held.contains(held.mapFromItem(pointer, event.x, event.y))
            if (!inField) root.contentItem.forceActiveFocus(Qt.MouseFocusReason)
            event.accepted = false
        }
    }
}
