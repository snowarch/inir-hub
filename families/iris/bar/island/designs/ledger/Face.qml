pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.widgets

// Ledger · Agenda: the time, then what is next in plain words. The rule between them fills through the last hour before
// an event and empties as a running one ends. Nothing ahead, the entry is the day.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property int minute: Math.floor(root.now.getTime() / 60000)
    readonly property real figure: root.island?.figureSize ?? IrisStyle.typeHeadline
    readonly property string face: root.island?.nothingLook ? IrisStyle.fontDot : IrisStyle.figureFace(root.figure)
    readonly property real contentWidth: row.implicitWidth

    // A slim strip keeps the entry on the time's line.
    readonly property bool stacks: root.h >= Math.round(34 * root.d)
    readonly property var entry: IrisFaceData.nextEntry(root.minute * 60000, 720)
    readonly property bool named: root.entry.title.length > 0
    readonly property bool close: root.named && (root.entry.running || (root.entry.left > 0 && root.entry.left <= 30))
    readonly property real share: root.entry.running ? root.entry.left / Math.max(1, (root.entry.end - root.entry.start) / 60000)
        : root.named && root.entry.left > 0 ? Math.max(0, 1 - root.entry.left / 60) : 0
    readonly property string lead: root.named ? root.entry.title : Translation.locale.toString(root.now, "dddd")
    readonly property string gloss: root.entry.when || Translation.locale.toString(root.now, "d MMMM")

    // A new entry slides in; the rest of the face stays put.
    onLeadChanged: if (IrisStyle.motionEnabled) comes.restart()
    ParallelAnimation {
        id: comes
        SmoothedAnimation { target: arrival; property: "y"; from: Math.round(8 * root.d); to: 0; duration: IrisStyle.duration(360); velocity: -1 }
        SmoothedAnimation { target: entryText; property: "opacity"; from: 0; to: 1; duration: IrisStyle.duration(360); velocity: -1 }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        IrisClock {
            anchors.verticalCenter: parent.verticalCenter
            pixelSize: root.figure
            family: root.face
            separatorColor: root.mark
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(2, Math.round(2 * root.d))
            height: Math.round(root.h * 0.54)
            radius: width / 2
            color: IrisStyle.textTertiary
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.round(parent.height * root.share)
                radius: width / 2
                color: root.mark
                Behavior on height { enabled: IrisStyle.motionEnabled; SmoothedAnimation { duration: IrisStyle.duration(420); velocity: -1 } }
            }
        }
        Grid {
            id: entryText
            anchors.verticalCenter: parent.verticalCenter
            columns: root.stacks ? 1 : 2
            columnSpacing: Math.round(6 * root.d)
            transform: Translate { id: arrival }
            verticalItemAlignment: Grid.AlignVCenter
            IrisText {
                width: Math.min(implicitWidth, Math.round(150 * root.d))
                text: root.lead
                elide: Text.ElideRight
                font.pixelSize: root.stacks ? IrisStyle.typeMeta : IrisStyle.typeFootnote
                font.weight: IrisStyle.weight(Font.DemiBold)
                color: IrisStyle.text
            }
            IrisText {
                text: root.gloss
                font.pixelSize: IrisStyle.typeCaption
                font.weight: IrisStyle.weight(Font.Medium)
                font.features: ({ "tnum": 1 })
                color: root.close ? root.mark : IrisStyle.textSecondary
            }
        }
    }
}
