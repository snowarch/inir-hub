pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Status: a phone's status bar in one capsule: the time at the start, at the end the connection as bars and the
// battery as a lit capsule with its figure inside (or the volume where there is no battery).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: clock.implicitWidth + ends.implicitWidth + Math.round(46 * root.d)
    readonly property int bars: Network.ethernet ? 4 : !Network.wifiEnabled || !Network.online ? 0
        : Math.max(1, Math.min(4, Math.ceil(Number(Network.networkStrength) / 25)))
    readonly property real level: Battery.available ? Battery.percentage : Audio.value
    readonly property color pill: Battery.available && Battery.isLow && !Battery.isCharging ? IrisStyle.danger
        : Battery.isCharging ? IrisStyle.identity.green : IrisStyle.text

    IrisClock {
        id: clock
        anchors.left: parent.left
        anchors.leftMargin: Math.round(18 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
    Row {
        id: ends
        anchors.right: parent.right
        anchors.rightMargin: Math.round(14 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(8 * root.d)
        // The connection: four rising bars, the lit ones its strength; a cable fills them all.
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(1.5 * root.d))
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: Math.max(2, Math.round(3 * root.d))
                    height: Math.round((5 + index * 2.5) * root.d)
                    radius: width / 2
                    color: index < root.bars ? IrisStyle.text : IrisStyle.fillActive
                }
            }
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(1 * root.d))
            Rectangle {
                width: Math.round(30 * root.d)
                height: Math.round(17 * root.d)
                radius: height / 2
                color: root.pill
                IrisText {
                    anchors.centerIn: parent
                    text: Math.round(root.level * 100)
                    color: IrisStyle.onTintFor(root.pill)
                    font.pixelSize: Math.round(11 * root.d)
                    font.weight: IrisStyle.weight(Font.Bold)
                    font.features: ({ "tnum": 1 })
                }
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.available
                width: Math.max(1.5, Math.round(2 * root.d))
                height: Math.round(6 * root.d)
                radius: width / 2
                color: root.pill
                opacity: 0.6
            }
        }
    }
}
