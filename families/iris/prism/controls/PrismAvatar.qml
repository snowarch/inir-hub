import QtQuick
import QtQuick.Effects
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core

// The person's picture in a circle: the first avatar file that loads, else their initial on the raised grey.
Item {
    id: root
    property int sourceIndex: 0
    readonly property string name: String(SystemInfo.displayName || SystemInfo.username || "")
    implicitWidth: PrismTheme.dp(36)
    implicitHeight: root.implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: PrismTheme.keyQuiet
        visible: photo.status !== Image.Ready
        PrismText {
            anchors.centerIn: parent
            text: root.name.charAt(0).toUpperCase()
            font.pixelSize: Math.round(root.width * 0.42)
            font.weight: Font.DemiBold
            color: PrismTheme.ink
        }
    }
    Image {
        id: photo
        anchors.fill: parent
        source: Directories.avatarSourceAt(root.sourceIndex)
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        onStatusChanged: if (status === Image.Error && root.sourceIndex + 1 < Directories.userAvatarPaths.length) Qt.callLater(() => root.sourceIndex++)
    }
    MultiEffect {
        anchors.fill: parent
        visible: photo.status === Image.Ready
        source: photo
        maskEnabled: true
        maskSource: round
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
    Rectangle { id: round; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
}
