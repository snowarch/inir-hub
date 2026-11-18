pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Bluetooth
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The panel is the poster's head rule: three groups of small type with hairlines running between them. The mark and
// the workspaces on the left open the overview; the time in the middle opens the day; the machine on the right opens
// quick settings. No pills, no plates at rest: what is open is lit, what is under the pointer brightens.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property var modelData
        readonly property var panel: Config.options?.nihil?.panel
        readonly property bool bottom: (bar.panel?.position ?? "top") === "bottom"
        readonly property string visibility: bar.panel?.visibility ?? "always"
        readonly property var outputs: Array.from(bar.panel?.screenList ?? [])
        readonly property bool listed: bar.outputs.length === 0 || bar.outputs.includes(bar.modelData.name)
        readonly property string output: bar.modelData.name
        readonly property var workspaces: NihilState.workspacesOn(bar.output)
        readonly property int at: NihilState.activeIndexOn(bar.output)
        readonly property var focused: (NiriService.windows ?? []).find(win => win.is_focused
            && win.workspace_id === bar.workspaces[bar.at]?.id) ?? null
        readonly property bool clear: NihilState.overviewOpen && (bar.panel?.overviewStyle ?? "same") === "transparent"

        screen: bar.modelData
        readonly property bool bare: NihilState.windowsOn(bar.workspaces[bar.at]?.id).length === 0
        visible: (Config.options?.nihil?.modules?.panel ?? true) && bar.listed && (GlobalStates.barOpen ?? true)
            && (bar.visibility === "always" || NihilState.overviewOpen || (bar.visibility === "desktop" && bar.bare))
        color: "transparent"
        implicitHeight: NihilStyle.barHeight
        exclusiveZone: bar.visibility === "always" ? NihilStyle.barHeight : 0
        WlrLayershell.namespace: "quickshell:nihil-panel"
        WlrLayershell.layer: bar.visibility === "always" ? WlrLayer.Top : WlrLayer.Overlay
        anchors { left: true; right: true; top: !bar.bottom; bottom: bar.bottom }

        BackgroundEffect.blurRegion: CompositorService.blurRegions && NihilStyle.blur && !bar.clear ? glass.region : null

        NGlass {
            id: glass
            anchors.fill: parent
            radius: 0
            shadow: 0
            rim: 0
            tracks: true
            tint: Qt.alpha(NihilStyle.void_, NihilStyle.glassOpacity * 0.9)
            opacity: bar.clear ? 0 : 1
            light: Qt.point(bar.width * 0.5, bar.bottom ? bar.height : 0)
            Behavior on opacity { NumberAnimation { duration: NihilStyle.calm } }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            y: bar.bottom ? 0 : parent.height - 1
            height: 1
            color: NihilStyle.line
            opacity: glass.opacity
        }

        component Key: MouseArea {
            id: key
            property bool lit: false
            readonly property color ink: key.lit || key.containsMouse ? NihilStyle.ink : NihilStyle.inkSoft
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            height: bar.height
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                y: bar.bottom ? 0 : parent.height - height
                height: NihilStyle.s(2)
                color: NihilStyle.ink
                opacity: key.lit ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: NihilStyle.quick } }
            }
        }

        // Left: the mark, where we are, and what has the keys.
        Key {
            id: lead
            anchors.left: parent.left
            anchors.leftMargin: NihilStyle.s(14)
            width: leadRow.implicitWidth
            lit: NihilState.overviewOpen
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Activities")
            onClicked: mouse => NihilState.toggleOverview(mouse.button === Qt.RightButton ? "apps" : "windows")
            onWheel: wheel => NihilState.stepWorkspace(bar.output, wheel.angleDelta.y > 0 ? -1 : 1)
            Row {
                id: leadRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: NihilStyle.s(12)
                NDisplay {
                    anchors.verticalCenter: parent.verticalCenter
                    size: NihilStyle.s(17)
                    bloom: 0
                    text: "NiHiL"
                    capitals: false
                    color: lead.ink
                }
                // One tick per workspace, the active one drawn in light.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: NihilStyle.s(3)
                    Repeater {
                        model: bar.workspaces
                        Item {
                            required property var modelData
                            width: modelData.is_active ? NihilStyle.s(18) : NihilStyle.s(6)
                            height: NihilStyle.s(2)
                            Behavior on width { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutQuint } }
                            NSpectrum { anchors.fill: parent; visible: parent.modelData.is_active }
                            Rectangle {
                                anchors.fill: parent
                                visible: !parent.modelData.is_active
                                color: NihilState.windowsOn(parent.modelData.id).length > 0 ? NihilStyle.inkSoft : NihilStyle.inkFaint
                            }
                        }
                    }
                }
                NLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(bar.at + 1).padStart(2, "0") + " / " + String(bar.workspaces.length).padStart(2, "0")
                    color: lead.ink
                }
            }
        }
        NLabel {
            id: title
            anchors.left: lead.right
            anchors.leftMargin: NihilStyle.s(14)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.max(0, middle.x - x - NihilStyle.s(80)))
            visible: (bar.panel?.windowTitle ?? true) && bar.focused !== null && width > NihilStyle.s(30)
            text: AppSearch.lookupDesktopEntry(bar.focused?.app_id ?? "")?.name ?? String(bar.focused?.app_id ?? "")
            color: NihilStyle.inkFaint
        }

        // Centre: the time leads, the day beside it.
        Key {
            id: middle
            anchors.horizontalCenter: parent.horizontalCenter
            width: timeRow.implicitWidth + NihilStyle.s(8)
            lit: NihilState.todayOpen
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Calendar and notifications")
            onClicked: NihilState.toggle("today")
            Row {
                id: timeRow
                anchors.centerIn: parent
                spacing: NihilStyle.s(10)
                NLabel {
                    anchors.verticalCenter: parent.verticalCenter
                    text: DateTime.date
                    color: middle.ink
                }
                NDisplay {
                    anchors.verticalCenter: parent.verticalCenter
                    size: NihilStyle.s(19)
                    bloom: 0
                    text: DateTime.time
                    color: middle.lit || middle.containsMouse ? NihilStyle.ink : Qt.alpha(NihilStyle.ink, 0.88)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notifications.list.length > 0
                    width: NihilStyle.s(5)
                    height: width
                    radius: width / 2
                    color: NihilStyle.live
                }
            }
        }

        // Right: the tray, then the machine as words.
        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(10)
            height: parent.height
            spacing: NihilStyle.s(2)

            Repeater {
                model: SystemTray.items
                MouseArea {
                    id: trayItem
                    required property SystemTrayItem modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(26)
                    height: NihilStyle.s(26)
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button !== Qt.RightButton) { trayItem.modelData.activate(); return }
                        if (!trayItem.modelData.hasMenu) { trayItem.modelData.secondaryActivate(); return }
                        const at = trayItem.mapToItem(bar.contentItem, 0, trayItem.height)
                        trayItem.modelData.display(bar, at.x, at.y)
                    }
                    Image {
                        anchors.centerIn: parent
                        width: NihilStyle.s(15)
                        height: NihilStyle.s(15)
                        sourceSize: Qt.size(width, height)
                        source: trayItem.modelData.icon
                        opacity: trayItem.containsMouse ? 1 : 0.72
                    }
                }
            }

            Item { width: NihilStyle.s(10); height: 1 }

            Key {
                id: status
                width: statusRow.implicitWidth + NihilStyle.s(8)
                lit: NihilState.controlOpen
                Accessible.role: Accessible.Button
                Accessible.name: Translation.tr("Quick settings")
                onClicked: NihilState.toggle("control")
                onWheel: wheel => {
                    const sink = Audio.sink?.audio
                    if (sink) sink.volume = NihilStyle.clamp(sink.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05), 0, 1)
                }
                Row {
                    id: statusRow
                    anchors.centerIn: parent
                    spacing: NihilStyle.s(14)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(5)
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Network.ethernet ? "lan" : Network.wifiEnabled ? "wifi" : "wifi_off"
                            size: NihilStyle.s(13)
                            color: status.ink
                        }
                        NLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: (bar.panel?.statusWords ?? true)
                            text: Network.ethernet ? Translation.tr("Wired") : Network.wifiEnabled ? (Network.networkName || Translation.tr("Wi-Fi")) : Translation.tr("Offline")
                            width: Math.min(implicitWidth, NihilStyle.s(110))
                            color: status.ink
                        }
                    }
                    NIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Bluetooth.defaultAdapter?.enabled ?? false
                        text: "bluetooth"
                        size: NihilStyle.s(13)
                        color: status.ink
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(5)
                        NIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (Audio.sink?.audio?.muted ?? false) ? "volume_mute" : "volume_up"
                            size: NihilStyle.s(13)
                            color: status.ink
                        }
                        NLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(Math.round((Audio.sink?.audio?.volume ?? 0) * 100))
                            color: status.ink
                        }
                    }
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Battery.available
                        spacing: NihilStyle.s(5)
                        // The charge as a drawn level, not a glyph.
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: NihilStyle.s(18)
                            height: NihilStyle.s(8)
                            radius: NihilStyle.s(2)
                            color: "transparent"
                            border.width: 1
                            border.color: status.ink
                            Rectangle {
                                x: NihilStyle.s(2)
                                anchors.verticalCenter: parent.verticalCenter
                                width: (parent.width - NihilStyle.s(4)) * Battery.percentage
                                height: parent.height - NihilStyle.s(4)
                                radius: 1
                                color: Battery.isLowAndNotCharging ? NihilStyle.live : status.ink
                            }
                        }
                        NLabel {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Battery.percentage * 100) + (Battery.isCharging ? " +" : "")
                            color: status.ink
                        }
                    }
                }
            }
        }

        // The hairlines that run between the groups.
        Rectangle {
            readonly property real from: (title.visible ? title.x + title.width : lead.x + lead.width) + NihilStyle.s(16)
            x: from
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, middle.x - NihilStyle.s(16) - from)
            height: 1
            color: NihilStyle.hair
            visible: bar.panel?.rules ?? true
        }
        Rectangle {
            x: middle.x + middle.width + NihilStyle.s(16)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, right.x - NihilStyle.s(16) - x)
            height: 1
            color: NihilStyle.hair
            visible: bar.panel?.rules ?? true
        }
    }
}
