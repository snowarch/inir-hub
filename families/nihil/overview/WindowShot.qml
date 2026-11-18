pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.modules.common.widgets
import qs.services
import qs.modules.nihil.style

// A window's picture: the last still, the live stream over it where the runtime has one, its app's icon until then.
ClippingRectangle {
    id: root

    required property int windowId
    property string appId: ""
    property bool live: true
    property bool iconWhileEmpty: true
    property int decodeWidth: 960

    color: NihilStyle.piece

    NAppIcon {
        anchors.centerIn: parent
        visible: root.iconWhileEmpty && shot.status !== Image.Ready && !stream.streaming
        appId: root.appId
        size: Math.min(root.width, root.height) * 0.5
    }
    Image {
        id: shot
        anchors.fill: parent
        visible: !stream.streaming
        source: root.windowId >= 0 ? WindowPreviewService.getPreviewUrl(root.windowId) : ""
        sourceSize.width: root.decodeWidth
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        retainWhileLoading: true
    }
    LiveWindowCapture {
        id: stream
        anchors.fill: parent
        windowId: root.windowId
        active: root.live
    }
}
