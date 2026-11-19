pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// What just arrived, on a tag pulled from the band. One notification lies on the glass itself; several each get a well.
Item {
    id: root

    // This screen's sheet is the one that shows them.
    property bool here: false

    readonly property string position: Config.options?.nihil?.notifications?.position ?? "top"
    readonly property bool atStart: root.position.endsWith("Left")
    readonly property int most: Config.options?.nihil?.notifications?.maxVisible ?? 4
    readonly property bool quiet: GlobalStates.screenLocked || (GameMode.active && GameMode.suppressNotifications)

    readonly property var arrived: root.here && !root.quiet ? Notifications.popupList.slice(0, root.most).map(item => ({
        id: item.notificationId,
        app: item.appName ?? "",
        icon: item.appIcon || item.appName || "",
        summary: item.summary ?? "",
        body: String(item.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim(),
        critical: item.urgency === "critical",
        actions: Array.from(item.actions ?? []).slice(0, 3).map(action => ({ id: action.identifier, text: action.text }))
    })) : []
    readonly property bool wanted: root.arrived.length > 0
    // What the tag still carries while it folds away.
    property var carried: []
    onArrivedChanged: if (root.arrived.length > 0) root.carried = root.arrived

    implicitWidth: NihilStyle.s(404)
    implicitHeight: stack.implicitHeight + NihilStyle.s(20)
    width: implicitWidth
    height: implicitHeight

    Component.onCompleted: Notifications.ensureInitialized()

    Column {
        id: stack
        x: NihilStyle.s(16)
        y: NihilStyle.s(10)
        width: parent.width - x * 2
        spacing: NihilStyle.gap

        Repeater {
            model: root.carried
            NotificationCard {
                required property var modelData
                width: stack.width
                notice: modelData
                alone: root.carried.length === 1
            }
        }
    }
}
