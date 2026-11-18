pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// Start's apps: every app, or what the search finds, the one marked printed on paper. Words no app answers go to the
// web search.
NTile {
    id: root

    property string query: ""
    property int at: 0
    readonly property string asked: root.query.trim()
    readonly property var apps: root.asked.length > 0
        ? AppSearch.fuzzyQuery(root.query)
        : AppSearch.list.map(entry => ({ name: entry.name, icon: entry.icon, originalEntry: entry }))
    readonly property var marked: root.apps[root.at] ?? null
    signal launched()

    caption: root.asked.length > 0 ? Translation.tr("Found") : Translation.tr("Apps")

    function walk(by: int): void {
        if (root.apps.length === 0) return
        root.at = Math.max(0, Math.min(root.apps.length - 1, root.at + by))
        list.positionViewAtIndex(root.at, ListView.Contain)
    }
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

    ListView {
        id: list
        x: NihilStyle.s(6)
        y: NihilStyle.s(34)
        width: root.width - NihilStyle.s(12)
        height: root.height - y - NihilStyle.s(6)
        clip: true
        spacing: 0
        model: root.apps
        boundsBehavior: Flickable.StopAtBounds
        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool marked: row.index === root.at
            width: list.width
            height: NihilStyle.s(44)
            radius: NihilStyle.rowRadius
            color: row.marked ? NihilStyle.plate : "transparent"

            NAppIcon {
                id: glyph
                x: NihilStyle.s(10)
                anchors.verticalCenter: parent.verticalCenter
                size: NihilStyle.s(24)
                iconName: row.modelData.icon ?? ""
                onPaper: row.marked
            }
            NText {
                anchors.left: glyph.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.right: parent.right
                anchors.rightMargin: NihilStyle.s(10)
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name ?? ""
                font.pixelSize: NihilStyle.s(15)
                font.weight: row.marked ? Font.Bold : Font.Medium
                color: row.marked ? NihilStyle.onPlate : NihilStyle.ink
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.at = row.index
                onClicked: root.launch(row.modelData)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        visible: root.apps.length === 0
        spacing: NihilStyle.s(14)
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Translation.tr("No app found")
            font.pixelSize: NihilStyle.textLarge
            font.weight: Font.Bold
        }
        NButton {
            id: webKey
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.asked.length > 0
            width: webRow.implicitWidth + NihilStyle.s(28)
            lit: true
            onClicked: root.searchWeb()
            Row {
                id: webRow
                anchors.centerIn: parent
                spacing: NihilStyle.s(8)
                NIcon { anchors.verticalCenter: parent.verticalCenter; text: "travel_explore"; size: NihilStyle.s(18); color: webKey.ink }
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Search the web")
                    font.weight: Font.Bold
                    color: webKey.ink
                }
            }
        }
    }
}
