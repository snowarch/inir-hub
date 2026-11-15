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
// plays. Normal and Prism both have it once the Corner is wide enough; narrower, the places column holds Yours and the
// mini player holds what plays.
Rectangle {
    id: root
    readonly property real d: IrisStyle.density
    signal sourcesRequested()

    color: CornerSkin.column
    radius: IrisStyle.radiusPanel
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
            Layout.fillWidth: true
            // The picture only where the rail has height for it.
            large: root.height >= Math.round(720 * root.d)
        }
    }
}
