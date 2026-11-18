pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One app on the bar: its icon on a round piece, in ink while NiHiL draws icons in one colour. A dot under the icon
// says it is open, in the signal colour while it has the focus. A click focuses, hides or launches it, as Waffle's.
NButton {
    id: root

    required property var modelData
    readonly property var entry: AppSearch.lookupDesktopEntry(root.modelData.appId)
    readonly property bool open: (root.modelData.toplevels ?? []).length > 0
    readonly property bool focused: (root.modelData.toplevels ?? []).some(t => t.activated)
    readonly property bool monochrome: Config.options?.nihil?.bar?.monochromeIcons ?? true

    function windowIds(): var {
        return (root.modelData.toplevels ?? []).map(t => Number(t?.niriWindowId ?? -1)).filter(id => id > 0)
    }

    onClicked: {
        if (CompositorService.isNiri) {
            const ids = root.windowIds()
            if (root.focused && ids.length > 0) {
                const focusedTop = root.modelData.toplevels.find(t => t.activated)
                MinimizedWindows.minimize(focusedTop?.niriWindowId ?? ids[0])
                return
            }
            if (MinimizedWindows.countMinimizedForApp(root.modelData.appId) > 0) {
                MinimizedWindows.restoreLatestForApp(root.modelData.appId)
                return
            }
            if (ids.length > 0) { NiriService.focusWindow(ids[0]); return }
        } else if (root.open) {
            root.modelData.toplevels[0]?.activate()
            return
        }
        if (root.entry) AppSearch.launchEntry(root.entry)
    }
    onRightClicked: TaskbarApps.togglePin(root.modelData.appId)

    NAppIcon {
        anchors.centerIn: parent
        size: Math.round(root.width * 0.46)
        iconName: AppSearch.guessIcon(root.modelData.appId)
        monochrome: root.monochrome
    }
    Rectangle {
        visible: root.open
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(5)
        width: NihilStyle.s(root.focused ? 10 : 4)
        height: NihilStyle.s(4)
        radius: height / 2
        color: root.focused ? NihilStyle.accent : root.ink
        Behavior on width { NumberAnimation { duration: NihilStyle.quick } }
    }
}
