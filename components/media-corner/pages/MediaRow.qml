pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// A shelf: its name, «See all», and a row of posters. It asks its store (AniList or Cinemeta) for one page of `filter`,
// or lists `local` as it is. An empty shelf hides itself, so a page only shows what has something in it.
ColumnLayout {
    id: root
    required property var store
    property string title: ""
    property string note: ""
    property var filter: null
    // Titles already at hand (a show's relations, its recommendations): listed as they are, nothing is asked.
    property var local: null
    // Where «See all» goes; empty hides it.
    property string allPlace: ""
    // A title the shelf leaves out (the one whose page it is on).
    property string exclude: ""

    readonly property real d: IrisStyle.density
    property var fetched: []
    readonly property var items: root.local !== null ? root.local : root.fetched
    // The last answer came back, found or not, and whether it failed; pages say which.
    property bool settled: false
    property bool failed: false

    function load(): void {
        root.fetched = []
        root.settled = false
        root.failed = false
        if (root.filter === null || root.local !== null) return
        const wanted = root.filter
        root.store.page(wanted, 1, (result, error) => {
            // A newer filter is out: this answer is for a page nobody is on.
            if (wanted !== root.filter) return
            root.fetched = error ? [] : result.items.filter(s => s.id !== root.exclude).slice(0, 24)
            root.failed = Boolean(error)
            root.settled = true
        })
    }
    onFilterChanged: loadLater.restart()
    Component.onCompleted: loadLater.restart()
    Timer { id: loadLater; interval: 0; onTriggered: root.load() }
    Connections {
        target: CornerState
        function onAttemptChanged(): void { if (root.failed) root.load() }
    }

    Layout.fillWidth: true
    visible: root.items.length > 0
    spacing: Math.round(8 * root.d)

    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * root.d)
        IrisText {
            text: root.title
            font.pixelSize: IrisStyle.typeHeadline
            font.weight: IrisStyle.weight(Font.Bold)
        }
        IrisText {
            Layout.fillWidth: true
            text: root.note
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeFootnote
            elide: Text.ElideRight
        }
        IrisButton {
            visible: root.allPlace.length > 0
            quiet: true
            text: Translation.tr("See all")
            onClicked: CornerState.pick(root.allPlace)
        }
    }

    Item {
        Layout.fillWidth: true
        // A poster's height: a 2:3 cover, the gap and two lines of title over one of detail.
        implicitHeight: Math.round(132 * root.d * 1.5 + 8 * root.d) + Math.ceil(2 * IrisStyle.typeLabel * 1.35 + IrisStyle.typeFootnote * 1.4)
        ListView {
            id: shelf
            anchors.fill: parent
            orientation: ListView.Horizontal
            spacing: Math.round(14 * root.d)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: Math.round(300 * root.d)
            model: root.items
            delegate: MediaPoster {
                required property var modelData
                show: modelData
            }
            // A vertical wheel walks the shelf only while Shift is held; otherwise it scrolls the page.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                acceptedModifiers: Qt.ShiftModifier
                onWheel: event => shelf.flick(event.angleDelta.y * 8, 0)
            }
            Behavior on contentX { enabled: !shelf.moving; NumberAnimation { duration: IrisStyle.duration(260); easing.type: IrisStyle.feedbackEasing } }
        }
        // Arrows on hover step a shelf's width, for a mouse without a horizontal wheel.
        HoverHandler { id: shelfHover }
        Arrow {
            anchors.left: parent.left
            shown: !shelf.atXBeginning
            glyph: "chevron_left"
            name: Translation.tr("Back")
            onStepped: shelf.contentX = Math.max(0, shelf.contentX - shelf.width * 0.8)
        }
        Arrow {
            anchors.right: parent.right
            shown: !shelf.atXEnd
            glyph: "chevron_right"
            name: Translation.tr("Forward")
            onStepped: shelf.contentX = Math.min(shelf.contentWidth - shelf.width, shelf.contentX + shelf.width * 0.8)
        }
    }

    // On a plate, so it reads over the posters.
    component Arrow: Rectangle {
        id: arrow
        property bool shown: false
        property string glyph: ""
        property string name: ""
        signal stepped()
        anchors.margins: Math.round(4 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Math.round(24 * root.d)
        visible: shelfHover.hovered && arrow.shown
        width: arrowKey.width + Math.round(6 * root.d)
        height: width
        radius: width / 2
        color: IrisStyle.artVeilHeavy
        border.width: 1
        border.color: IrisStyle.hairline
        IrisIconButton {
            id: arrowKey
            anchors.centerIn: parent
            materialIcon: arrow.glyph
            Accessible.name: arrow.name
            onClicked: arrow.stepped()
        }
    }
}
