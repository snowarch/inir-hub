pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Start's app column: a raised piece listing every app (or what the search finds), each its icon on a round key,
// the keys lit and dark in turn, its name in mono beside it. Words no app answers go to the web search.
Rectangle {
    id: root

    property string query: ""
    readonly property var apps: root.query.trim().length > 0
        ? AppSearch.fuzzyQuery(root.query)
        : AppSearch.list.map(entry => ({ name: entry.name, icon: entry.icon, originalEntry: entry }))
    readonly property var first: root.apps.length > 0 ? root.apps[0] : null
    readonly property string asked: root.query.trim()
    signal launched()

    function searchWeb(): void {
        const engine = Config.options?.search?.engineBaseUrl ?? "https://www.google.com/search?q="
        Qt.openUrlExternally(engine + encodeURIComponent(root.asked))
        root.launched()
    }
    function launch(app): void {
        if (!app) {
            if (root.asked.length > 0) root.searchWeb()
            return
        }
        AppSearch.launchEntry(app.originalEntry ?? app)
        root.launched()
    }

    radius: NihilStyle.s(20)
    color: NihilStyle.pieceRaised

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: NihilStyle.s(8)
        clip: true
        spacing: NihilStyle.s(4)
        model: root.apps
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            width: list.width
            height: NihilStyle.s(48)
            radius: height / 2
            color: hover.hovered ? NihilStyle.hoverVeil : "transparent"

            NButton {
                id: key
                x: NihilStyle.s(4)
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(40); height: width
                lit: row.index % 2 === 1
                tone: NihilStyle.piece
                NAppIcon {
                    anchors.centerIn: parent
                    size: NihilStyle.s(20)
                    iconName: row.modelData.icon ?? ""
                }
                onClicked: root.launch(row.modelData)
            }
            NText {
                anchors.left: key.right
                anchors.leftMargin: NihilStyle.s(14)
                anchors.right: parent.right
                anchors.rightMargin: NihilStyle.s(8)
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: row.modelData.name ?? ""
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.launch(row.modelData) }
        }
    }

    Column {
        anchors.centerIn: parent
        visible: root.apps.length === 0
        spacing: NihilStyle.s(12)
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            figures: true
            text: Translation.tr("No app found")
            color: NihilStyle.inkSoft
            font.pixelSize: NihilStyle.textSmall
        }
        NKey {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.asked.length > 0
            width: NihilStyle.s(176)
            height: NihilStyle.s(40)
            glyph: "travel_explore"
            label: Translation.tr("Search the web")
            onClicked: root.searchWeb()
        }
    }
}
