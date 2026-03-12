pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

Item {
    id: root
    property size sourceSize: Qt.size(32, 32)
    
    width: sourceSize.width
    height: sourceSize.height
    implicitWidth: sourceSize.width
    implicitHeight: sourceSize.height
    Layout.preferredWidth: sourceSize.width
    Layout.preferredHeight: sourceSize.height

    Rectangle {
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        color: Looks.colors.bg2Base
        visible: avatarImage.status !== Image.Ready
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: "person"
        iconSize: Math.round(root.sourceSize.width * 0.55)
        color: Looks.colors.subfg
        visible: avatarImage.status !== Image.Ready
    }

    Rectangle {
        id: avatarMask
        anchors.fill: parent
        radius: Math.min(width, height) / 2
        visible: false
    }

    Image {
        id: avatarImage
        anchors.fill: parent
        sourceSize: Qt.size(root.sourceSize.width * 2, root.sourceSize.height * 2)
        fillMode: Image.PreserveAspectCrop
        source: `file://${Directories.userAvatarPathRicersAndWeirdSystems}`
        cache: true
        smooth: true
        mipmap: true
        asynchronous: true
        visible: false
        onStatusChanged: {
            if (status === Image.Error) {
                if (String(source).indexOf(Directories.userAvatarPathAccountsService) >= 0)
                    source = `file://${Directories.userAvatarPathRicersAndWeirdSystems2}`
                else
                    source = `file://${Directories.userAvatarPathAccountsService}`
            }
        }
    }

    OpacityMask {
        anchors.fill: parent
        source: avatarImage
        maskSource: avatarMask
        visible: avatarImage.status === Image.Ready
    }
}
