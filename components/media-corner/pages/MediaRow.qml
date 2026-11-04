pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

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
    property bool seeAll: true
    // A title the shelf leaves out (the one whose page it is on).
    property string exclude: ""
    signal openShow(var show)
    signal openAll()

    readonly property real d: IrisStyle.density
    property var fetched: []
    readonly property var items: root.local !== null ? root.local : root.fetched
    property bool asked: false

    // The last answer came back (found or not), for pages that say «nothing found».
    property bool settled: false
    function load(): void {
        if (root.filter === null || root.local !== null) return
        root.asked = true
        root.settled = false
        const wanted = root.filter
        root.store.page(wanted, 1, (result, error) => {
            // A newer filter is out: this answer is for a page nobody is on.
            if (wanted !== root.filter) return
            root.fetched = error ? [] : result.items.filter(s => s.id !== root.exclude).slice(0, 24)
            root.settled = true
        })
    }
    onFilterChanged: Qt.callLater(root.load)
    Component.onCompleted: Qt.callLater(root.load)

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
            visible: root.seeAll
            quiet: true
            text: Translation.tr("See all")
            onClicked: root.openAll()
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
                onOpen: root.openShow(modelData)
            }
            // A vertical wheel walks the shelf only while Shift is held; otherwise it scrolls Home.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse
                acceptedModifiers: Qt.ShiftModifier
                onWheel: event => shelf.flick(event.angleDelta.y * 8, 0)
            }
            Behavior on contentX { enabled: !shelf.moving; NumberAnimation { duration: IrisStyle.duration(260); easing.type: IrisStyle.feedbackEasing } }
        }
        // Arrows on hover step a shelf's width, for a mouse without a horizontal wheel.
        HoverHandler { id: shelfHover }
        // On a plate, so it reads over the posters.
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Math.round(4 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Math.round(24 * root.d)
            visible: shelfHover.hovered && !shelf.atXBeginning
            width: leftArrow.width + Math.round(6 * root.d)
            height: width
            radius: width / 2
            color: IrisStyle.artVeilHeavy
            border.width: 1
            border.color: IrisStyle.hairline
            IrisIconButton {
                id: leftArrow
                anchors.centerIn: parent
                materialIcon: "chevron_left"
                Accessible.name: Translation.tr("Back")
                onClicked: shelf.contentX = Math.max(0, shelf.contentX - shelf.width * 0.8)
            }
        }
        // On a plate, so it reads over the posters.
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: Math.round(4 * root.d)
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -Math.round(24 * root.d)
            visible: shelfHover.hovered && !shelf.atXEnd
            width: rightArrow.width + Math.round(6 * root.d)
            height: width
            radius: width / 2
            color: IrisStyle.artVeilHeavy
            border.width: 1
            border.color: IrisStyle.hairline
            IrisIconButton {
                id: rightArrow
                anchors.centerIn: parent
                materialIcon: "chevron_right"
                Accessible.name: Translation.tr("Forward")
                onClicked: shelf.contentX = Math.min(shelf.contentWidth - shelf.width, shelf.contentX + shelf.width * 0.8)
            }
        }
    }
}
