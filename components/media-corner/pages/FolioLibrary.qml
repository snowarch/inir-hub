pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/watch.js" as Watch

// Classic's and Folio's Library, as Folio's «General»: grouped rows on one plate, a glyph in its tint, a name, what it holds on
// the right and a chevron, hairlines between them.
ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    readonly property int watched: Watch.historyRows(CornerWatch.progress).length
    readonly property var rows: [
        { place: "history", glyph: "history", tint: IrisStyle.identity.green, title: Translation.tr("Watch history"),
          value: root.watched > 0 ? Translation.tr("%1 titles").arg(root.watched) : Translation.tr("Nothing here yet") },
        { place: "schedule", glyph: "event", tint: IrisStyle.identity.indigo, title: Translation.tr("Upcoming episodes"), value: Translation.tr("Want to watch") },
        { place: "sources", glyph: "extension", tint: IrisStyle.identity.orange, title: Translation.tr("Sources"),
          value: CornerSources.list.length > 0 ? Translation.tr("%1 sources").arg(CornerSources.list.length) : Translation.tr("You have no sources yet") },
        { place: "sources", glyph: "palette", tint: IrisStyle.identity.purple, title: Translation.tr("Appearance"),
          value: Translation.tr(CornerSkin.looks.find(look => look.id === CornerSkin.look)?.label ?? "") }
    ]
    spacing: Math.round(10 * root.d)

    CornerHeading { title: Translation.tr("Library"); glyph: "home" }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: list.implicitHeight
        radius: IrisStyle.radiusTile
        color: CornerSkin.card
        clip: true
        ColumnLayout {
            id: list
            width: parent.width
            spacing: 0
            Repeater {
                model: root.rows
                IrisButton {
                    id: row
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Math.round(50 * root.d)
                    buttonRadius: 0
                    buttonRadiusPressed: 0
                    colBackground: "transparent"
                    colBackgroundHover: IrisStyle.fillQuiet
                    Accessible.name: row.modelData.title + ", " + row.modelData.value
                    onClicked: CornerState.pick(row.modelData.place)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(14 * root.d)
                        anchors.rightMargin: Math.round(12 * root.d)
                        spacing: Math.round(12 * root.d)
                        IrisSquircle {
                            Layout.preferredWidth: Math.round(26 * root.d)
                            Layout.preferredHeight: Math.round(26 * root.d)
                            tint: row.modelData.tint
                            glyph: row.modelData.glyph
                            // Plated as Settings plates its marks.
                            plain: IrisStyle.settingsPlainMarks
                        }
                        IrisText { Layout.fillWidth: true; text: row.modelData.title; font.pixelSize: IrisStyle.typeLabel; elide: Text.ElideRight }
                        IrisText { text: row.modelData.value; color: IrisStyle.muted; font.pixelSize: IrisStyle.typeLabel; elide: Text.ElideRight; Layout.maximumWidth: Math.round(260 * root.d) }
                        MaterialSymbol { text: "chevron_right"; iconSize: Math.round(18 * root.d); color: IrisStyle.textTertiary }
                    }
                    Rectangle {
                        visible: row.index < root.rows.length - 1
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Math.round(16 * root.d)
                        height: 1
                        color: IrisStyle.hairline
                    }
                }
            }
        }
    }
}
