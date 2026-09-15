pragma ComponentBehavior: Bound
import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common.widgets
import qs.modules.iris.style

Item {
    id: root
    property string source: ""
    property bool circular: true
    property real radius: circular ? width / 2 : 12 * IrisStyle.density
    // A fixed decode size for artwork whose size animates, so it is decoded
    // once instead of reloading (and flashing the placeholder) every frame.
    property real decodeSize: 0
    implicitWidth: 64 * IrisStyle.density
    implicitHeight: implicitWidth
    Image {
        id: cover
        anchors.fill: parent
        source: root.source
        sourceSize: root.decodeSize > 0 ? Qt.size(Math.ceil(root.decodeSize), Math.ceil(root.decodeSize))
            : Qt.size(Math.ceil(root.width * 2), Math.ceil(root.height * 2))
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    OpacityMask {
        anchors.fill: parent
        source: cover
        maskSource: Rectangle { width: root.width; height: root.height; radius: root.radius; color: "white" }
        visible: cover.status === Image.Ready
    }
    MaterialSymbol {
        anchors.centerIn: parent
        visible: cover.status !== Image.Ready
        text: "music_note"
        iconSize: root.width * 0.55
        color: IrisStyle.subtext
    }
}
