pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state
import qs.modules.nihil.overview

// What an app in the dock holds, shown beside its icon after a moment: its name, and a picture of each of its windows to
// click (the middle button or the cross closes one). An app without windows, or with pictures off, shows its name alone.
NGlass {
    id: root

    property var app: null
    property bool pictures: true
    property bool vertical: false

    readonly property var windows: root.app ? (NiriService.windows ?? []).filter(win => win.app_id === root.app.appId).slice(0, 6) : []
    readonly property string name: root.app ? (AppSearch.lookupDesktopEntry(root.app.appId)?.name ?? root.app.appId) : ""
    readonly property bool showsWindows: root.pictures && root.windows.length > 0
    readonly property real shotWidth: NihilStyle.s(208)
    readonly property real shotHeight: NihilStyle.s(124)
    readonly property real pad: NihilStyle.s(10)
    readonly property bool hovered: hover.hovered

    implicitWidth: root.showsWindows ? Math.max(shots.implicitWidth, title.implicitWidth) + root.pad * 2 : title.implicitWidth + NihilStyle.s(28)
    implicitHeight: root.showsWindows ? NihilStyle.s(36) + shots.implicitHeight + root.pad : NihilStyle.s(36)
    radius: root.showsWindows ? NihilStyle.radiusCard : root.height / 2
    tint: NihilStyle.menuBackground
    followPointer: true

    HoverHandler { id: hover }

    // Fresh pictures of the windows on show.
    onWindowsChanged: if (root.showsWindows && root.visible) WindowPreviewService.captureForTaskView(root.windows.map(win => win.id), 30000)

    NText {
        id: title
        x: root.showsWindows ? root.pad + NihilStyle.s(4) : (parent.width - width) / 2
        y: root.showsWindows ? NihilStyle.s(10) : (parent.height - height) / 2
        width: root.showsWindows ? Math.min(implicitWidth, parent.width - root.pad * 2) : implicitWidth
        text: root.windows.length > 1 ? Translation.tr("%1 · %2 windows").arg(root.name).arg(root.windows.length) : root.name
        font.weight: Font.DemiBold
    }

    Grid {
        id: shots
        visible: root.showsWindows
        x: root.pad
        y: NihilStyle.s(36)
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        spacing: NihilStyle.s(8)
        Repeater {
            model: root.showsWindows ? root.windows : []
            MouseArea {
                id: shot
                required property var modelData
                width: root.shotWidth
                height: root.shotHeight + NihilStyle.s(26)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                Accessible.role: Accessible.Button
                Accessible.name: shot.modelData.title ?? ""
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) NiriService.closeWindow(shot.modelData.id)
                    else NiriService.focusWindow(shot.modelData.id)
                }
                WindowShot {
                    id: picture
                    width: root.shotWidth
                    height: root.shotHeight
                    radius: NihilStyle.r(12)
                    windowId: shot.modelData.id
                    appId: shot.modelData.app_id ?? ""
                    decodeWidth: 480
                    live: root.visible
                }
                Rectangle {
                    anchors.fill: picture
                    radius: picture.radius
                    color: "transparent"
                    border.width: shot.modelData.is_focused ? 2 : 1
                    border.color: shot.modelData.is_focused ? NihilStyle.accent : shot.containsMouse ? Qt.alpha(NihilStyle.text, 0.4) : NihilStyle.border
                }
                NButton {
                    visible: shot.containsMouse
                    anchors.right: picture.right
                    anchors.top: picture.top
                    anchors.margins: NihilStyle.s(6)
                    width: NihilStyle.s(26)
                    height: width
                    icon: "close"
                    iconSize: NihilStyle.s(13)
                    tone: NihilStyle.scrim
                    Accessible.name: Translation.tr("Close")
                    onClicked: NiriService.closeWindow(shot.modelData.id)
                }
                NText {
                    anchors.bottom: parent.bottom
                    x: NihilStyle.s(2)
                    width: parent.width - NihilStyle.s(4)
                    text: shot.modelData.title ?? ""
                    font.pixelSize: NihilStyle.textSmall
                    color: shot.modelData.is_focused ? NihilStyle.text : NihilStyle.textSecondary
                }
            }
        }
    }
}
