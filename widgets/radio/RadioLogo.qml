pragma ComponentBehavior: Bound

import QtQuick
import "radio.js" as R

// A station's face: its logo on a quiet tile when it has one that loads, else its first letter.
Rectangle {
    id: root

    property var look
    property var station: null
    property real size: 40

    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size
    radius: Math.min(root.size / 4, root.look?.radiusSmall ?? 8)
    color: root.look?.raised ?? "transparent"

    // The address is tried quietly first; only one that answered with an image is handed to the Image.
    readonly property string address: root.station?.logo ?? ""
    property string checked: ""
    onAddressChanged: root.check()
    Component.onCompleted: root.check()
    function check(): void {
        root.checked = ""
        const asked = root.address
        if (asked.length > 0) R.checkLogo(asked, ok => { if (ok && root && root.address === asked) root.checked = asked })
    }
    readonly property bool shows: picture.status === Image.Ready
    Image {
        id: picture
        anchors.fill: parent
        anchors.margins: Math.round(root.size * 0.12)
        source: root.checked
        sourceSize.width: Math.round(root.size * 2)
        sourceSize.height: Math.round(root.size * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
        visible: root.shows
    }
    Text {
        anchors.centerIn: parent
        visible: !root.shows && root.station !== null
        text: String(root.station?.name ?? "").replace(/^[^\p{L}\p{N}]+/u, "").charAt(0).toUpperCase()
        font.family: root.look?.font ?? ""
        font.pixelSize: Math.round(root.size * 0.42)
        font.weight: Font.DemiBold
        color: root.look?.muted ?? "gray" // literal: only while the look is still arriving
    }
    // Nothing tuned yet: the radio's own mark.
    RadioGlyph {
        anchors.centerIn: parent
        visible: root.station === null
        look: root.look
        name: "radio"
        size: Math.round(root.size * 0.5)
        color: root.look?.muted ?? "gray" // literal: only while the look is still arriving
    }
}
