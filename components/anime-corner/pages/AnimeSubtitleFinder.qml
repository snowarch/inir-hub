pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.state
import "../state"

// Subtitles from OpenSubtitles and SubDL for the episode that is playing: one press searches, one press loads.
// Release names come from the services and are shown as written, never read as markup.
ColumnLayout {
    id: root
    property real d: IrisStyle.density
    property real radius: IrisStyle.radiusChip
    readonly property bool open: CornerWatch.subtitleSearching || CornerWatch.subtitleResults.length > 0 || CornerWatch.subtitleNotes.length > 0
    spacing: Math.round(4 * root.d)

    MouseArea {
        id: finder
        Layout.fillWidth: true
        implicitHeight: Math.round(28 * root.d)
        enabled: CornerWatch.phase === "playing" && !CornerWatch.subtitleSearching
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: finderLabel.text
        onClicked: CornerWatch.findSubtitles()
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: finder.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet
            Behavior on color { ColorAnimation { duration: IrisStyle.duration(120); easing.type: IrisStyle.feedbackEasing } }
        }
        IrisText {
            id: finderLabel
            anchors.centerIn: parent
            text: CornerWatch.subtitleSearching ? Translation.tr("Looking for subtitles…") : Translation.tr("Find subtitles online")
            color: IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeFootnote
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
    }

    Repeater {
        model: CornerWatch.subtitleNotes
        IrisText {
            required property var modelData
            Layout.fillWidth: true
            text: CornerWatch.subtitleNote(String(modelData))
            textFormat: Text.PlainText
            color: IrisStyle.muted
            wrapMode: Text.WordWrap
            font.pixelSize: IrisStyle.typeFootnote
        }
    }

    IrisText {
        Layout.fillWidth: true
        visible: !CornerWatch.subtitleSearching && root.open && CornerWatch.subtitleResults.length === 0
            && CornerWatch.subtitleNotes.every(note => !/refused|did not answer/.test(String(note)))
            && (CornerWatch.hasKey("opensubtitles") || CornerWatch.hasKey("subdl"))
        text: Translation.tr("No subtitles for this episode in your languages")
        color: IrisStyle.muted
        font.pixelSize: IrisStyle.typeFootnote
    }

    Repeater {
        model: CornerWatch.subtitleResults.slice(0, 8)
        MouseArea {
            id: result
            required property var modelData
            readonly property bool fetching: CornerWatch.subtitleFetching === String(result.modelData.id)
            Layout.fillWidth: true
            implicitHeight: Math.round(30 * root.d)
            enabled: CornerWatch.subtitleFetching.length === 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: [result.modelData.lang, result.modelData.name].join(", ")
            onClicked: CornerWatch.fetchSubtitle(result.modelData)
            Rectangle {
                anchors.fill: parent
                radius: root.radius
                color: result.containsMouse || result.fetching ? IrisStyle.fillHover : "transparent"
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Math.round(8 * root.d)
                anchors.rightMargin: Math.round(8 * root.d)
                spacing: Math.round(8 * root.d)
                IrisText {
                    text: String(result.modelData.lang ?? "").toUpperCase()
                    textFormat: Text.PlainText
                    color: IrisStyle.identity.pink
                    font.family: IrisStyle.fontNumbers
                    font.pixelSize: IrisStyle.typeFootnote
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: result.fetching ? Translation.tr("Loading…") : String(result.modelData.name ?? "")
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: IrisStyle.typeFootnote
                }
                IrisText {
                    text: result.modelData.service === "subdl" ? "SubDL" : "OpenSubtitles"
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
        }
    }
}
