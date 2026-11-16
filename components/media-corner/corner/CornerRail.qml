pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// The right rail, as in iRiS's Settings: a greeting, what is yours (Want to watch, Watching) and, at its foot, what mpv
// plays. Prism has it once the Corner is wide enough; narrower, the places column holds Yours and the
// mini player holds what plays.
Rectangle {
    id: root
    readonly property real d: IrisStyle.density
    signal sourcesRequested()

    color: CornerSkin.column
    radius: CornerSkin.prism ? IrisStyle.radiusPanel : IrisStyle.radiusTile
    border.width: CornerSkin.edgeWidth
    border.color: CornerSkin.edge
    clip: true

    // By the minute, and only while the rail is on screen.
    SystemClock { id: clock; precision: SystemClock.Minutes; enabled: root.visible }
    readonly property int hour: clock.date.getHours()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(18 * root.d)
        spacing: Math.round(14 * root.d)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(10 * root.d)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: root.hour < 5 || root.hour >= 18 ? Translation.tr("Good evening") : root.hour < 12 ? Translation.tr("Good morning") : Translation.tr("Good afternoon")
                    color: IrisStyle.textSecondary
                    font.pixelSize: IrisStyle.typeMeta
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Media Corner")
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: CornerSkin.sectionSize
                    font.letterSpacing: CornerSkin.titleTracking
                    font.weight: IrisStyle.weight(Font.Bold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.locale.toString(clock.date, "ddd d MMM · hh:mm")
                    color: IrisStyle.textTertiary
                    font.pixelSize: IrisStyle.typeFootnote
                }
            }
            CornerRound {
                id: sourcesKey
                glyph: "extension"
                Accessible.name: Translation.tr("Sources")
                onClicked: root.sourcesRequested()
                StyledToolTip { text: sourcesKey.Accessible.name; extraVisibleCondition: sourcesKey.buttonHovered }
            }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: CornerSkin.edge }

        Flickable {
            id: yours
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: library.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            IrisScrollFeel {}
            ScrollBar.vertical: IrisScrollBar {}
            LibraryList { id: library; width: yours.width }
        }

        PlaybackCard {
            id: player
            Layout.fillWidth: true
            // The picture only where the rail has height for it.
            large: root.height >= Math.round(720 * root.d)
        }
        // Before anything was ever played: what the card will hold, and how to start.
        Rectangle {
            visible: !player.visible
            Layout.fillWidth: true
            implicitHeight: idle.implicitHeight + 2 * Math.round(18 * root.d)
            radius: CornerSkin.cardRadius
            color: CornerSkin.card
            border.width: CornerSkin.edgeWidth
            border.color: CornerSkin.edge
            RowLayout {
                id: idle
                anchors.fill: parent
                anchors.margins: Math.round(18 * root.d)
                spacing: Math.round(12 * root.d)
                Rectangle {
                    Layout.preferredWidth: Math.round(44 * root.d)
                    Layout.preferredHeight: Math.round(44 * root.d)
                    radius: width / 2
                    color: CornerSkin.plate
                    MaterialSymbol { anchors.centerIn: parent; text: "play_arrow"; fill: 1; iconSize: Math.round(22 * root.d); color: IrisStyle.textSecondary }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * root.d)
                    IrisText { Layout.fillWidth: true; text: Translation.tr("Nothing playing"); font.weight: IrisStyle.weight(Font.DemiBold); elide: Text.ElideRight }
                    IrisText { Layout.fillWidth: true; text: Translation.tr("Press Watch on any title"); color: IrisStyle.textSecondary; font.pixelSize: IrisStyle.typeMeta; wrapMode: Text.WordWrap }
                }
            }
        }
    }
}
