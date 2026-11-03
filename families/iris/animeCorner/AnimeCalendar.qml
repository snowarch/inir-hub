pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.pieces

// The week's broadcasts, a day at a time, at your local hour. Its own question to AniList: AnimeService's schedule is
// the Material shell's and stays as it is.
Item {
    id: root
    required property AnimeCornerData store
    signal openShow(var show)

    readonly property real d: IrisStyle.density
    // 0 = today, up to 6 days ahead.
    property int day: 0
    property var entries: []
    property bool loading: false
    property string error: ""
    property int _ticket: 0

    readonly property var days: Array.from({ length: 7 }, (_, i) => {
        const date = new Date()
        date.setHours(0, 0, 0, 0)
        date.setDate(date.getDate() + i)
        return { value: i, date, label: i === 0 ? Translation.tr("Today") : i === 1 ? Translation.tr("Tomorrow") : Qt.locale().toString(date, "ddd d") }
    })

    function load(): void {
        const ticket = ++root._ticket
        const start = root.days[root.day].date
        const from = Math.floor(start.getTime() / 1000)
        root.loading = true
        root.error = ""
        root.entries = []
        root.store.schedule(from - 1, from + 86400, (list, error) => {
            if (ticket !== root._ticket) return
            root.loading = false
            root.error = error
            root.entries = list
        })
    }
    onDayChanged: root.load()
    Component.onCompleted: root.load()

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.round(12 * root.d)

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    text: Translation.tr("Calendar")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeTitle
                    font.weight: IrisStyle.weight(Font.Bold)
                }
                IrisText {
                    text: Translation.tr("New episodes, at your local time")
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
        }
        IrisSegmented {
            Layout.fillWidth: true
            accessibleName: Translation.tr("Day")
            options: root.days.map(day => ({ value: day.value, label: day.label }))
            current: root.day
            onPicked: value => root.day = value
        }

        ListView {
            id: list
            IrisScrollFeel {}
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.entries.length > 0
            clip: true
            spacing: Math.round(4 * root.d)
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: IrisScrollBar {}
            model: root.entries
            delegate: MouseArea {
                id: entry
                required property var modelData
                readonly property bool aired: entry.modelData.airingAt * 1000 <= Date.now()
                readonly property bool followed: IrisPieces.animeFollows(entry.modelData.show.id)
                width: list.width - Math.round(12 * root.d)
                height: Math.round(64 * root.d)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: String(entry.modelData.show.title)
                onClicked: root.openShow(entry.modelData.show)
                Rectangle {
                    anchors.fill: parent
                    radius: IrisStyle.radiusRow
                    color: entry.containsMouse ? IrisStyle.fillQuiet : "transparent"
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(8 * root.d)
                    anchors.rightMargin: Math.round(8 * root.d)
                    spacing: Math.round(12 * root.d)
                    IrisText {
                        Layout.preferredWidth: Math.round(56 * root.d)
                        text: Qt.formatTime(new Date(entry.modelData.airingAt * 1000), "hh:mm")
                        color: entry.aired ? IrisStyle.muted : IrisStyle.text
                        font.family: IrisStyle.fontNumbers
                        font.pixelSize: IrisStyle.typeBody
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    ClippingRectangle {
                        Layout.preferredWidth: Math.round(36 * root.d)
                        Layout.preferredHeight: Math.round(54 * root.d)
                        radius: Math.round(6 * root.d)
                        color: IrisStyle.fillQuiet
                        IrisImage { anchors.fill: parent; source: String(entry.modelData.show.imageSmall || entry.modelData.show.image || "") }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        IrisText {
                            Layout.fillWidth: true
                            text: String(entry.modelData.show.title)
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(entry.followed ? Font.Bold : Font.DemiBold)
                            color: entry.followed ? IrisStyle.identity.pink : IrisStyle.text
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: [Translation.tr("Episode %1").arg(entry.modelData.episode), entry.aired ? Translation.tr("aired") : "",
                                   (entry.modelData.show.genres ?? []).slice(0, 2).map(g => Translation.tr(g)).join(", ")].filter(x => x.length > 0).join(" · ")
                            color: IrisStyle.muted
                            font.pixelSize: IrisStyle.typeFootnote
                            elide: Text.ElideRight
                        }
                    }
                    MaterialSymbol {
                        visible: entry.followed
                        text: "bookmark"
                        fill: 1
                        iconSize: Math.round(16 * root.d)
                        color: IrisStyle.identity.pink
                    }
                }
            }
        }

        IrisText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.entries.length === 0
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: IrisStyle.muted
            text: !Network.online ? Network.offlineReason
                : root.loading ? Translation.tr("Asking AniList…")
                : root.error.length > 0 ? Translation.tr("AniList didn't answer (´・ω・`)")
                : Translation.tr("Nothing airs this day")
        }
    }
}
