pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"

// A fresh, user-requested snapshot of saved anime (CornerSchedule); no work continues when hidden.
ColumnLayout {
    id: root
    // The page on screen: the schedule is asked for while this is true and dropped when it isn't.
    property bool active: false
    readonly property real d: IrisStyle.density
    Binding { target: CornerSchedule; property: "active"; value: root.active }
    Component.onDestruction: CornerSchedule.active = false
    CornerHeading { page: true; eyebrow: Translation.tr("Library"); title: Translation.tr("Upcoming episodes") }
    IrisButton { text: Translation.tr("Refresh schedule"); enabled: !CornerSchedule.loading; onClicked: CornerSchedule.refresh() }
    IrisText { visible: CornerSchedule.loading; text: Translation.tr("Loading…") }
    IrisText { visible: CornerSchedule.failure.length > 0; text: CornerSchedule.failure; color: IrisStyle.danger; wrapMode: Text.WordWrap; Layout.fillWidth: true }
    IrisText {
        visible: !CornerSchedule.loading && !CornerSchedule.failure && CornerSchedule.entries.length === 0
        text: Translation.tr("No upcoming episodes found")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }
    IrisText {
        visible: CornerSchedule.checkedAt > 0
        text: Translation.tr("Schedule checked %1").arg(Translation.locale.toString(new Date(CornerSchedule.checkedAt * 1000), "ddd d MMM, hh:mm"))
        color: IrisStyle.textSecondary
    }
    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: CornerSchedule.entries
        delegate: IrisButton {
            required property var modelData
            width: ListView.view.width
            quiet: true
            readonly property string caption: modelData.title + " · " + Translation.tr("Ep. %1, %2").arg(modelData.episode).arg(Translation.locale.toString(new Date(modelData.airingAt * 1000), "ddd d MMM, hh:mm"))
            Accessible.name: caption
            implicitHeight: Math.round(48 * root.d)
            IrisText {
                anchors.fill: parent
                anchors.leftMargin: Math.round(12 * root.d)
                anchors.rightMargin: Math.round(12 * root.d)
                verticalAlignment: Text.AlignVCenter
                textFormat: Text.PlainText
                elide: Text.ElideRight
                text: parent.caption
            }
            onClicked: CornerState.openShow({ id: modelData.id, kind: "anime", title: modelData.title })
        }
    }
}
