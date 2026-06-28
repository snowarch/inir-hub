pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.settings

WSettingsPage {
    id: root
    settingsPageIndex: 12
    pageTitle: Translation.tr("Autostart")
    pageIcon: "rocket-launch"
    pageDescription: Translation.tr("Apps that start with iNiR")

    // ── Helpers (same logic as ii page) ──────────────────────────────────

    function isDesktopEnabled(desktopId: string): bool {
        const entries = Config.options?.autostart?.entries ?? []
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].type === "desktop" && entries[i].desktopId === desktopId && entries[i].enabled)
                return true
        }
        return false
    }

    function setDesktopEnabled(desktopId: string, enabled: bool): void {
        let entries = [...(Config.options?.autostart?.entries ?? [])]
        let idx = -1
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].type === "desktop" && entries[i].desktopId === desktopId) {
                idx = i
                break
            }
        }
        if (enabled && idx === -1) {
            entries.push({ type: "desktop", desktopId: desktopId, enabled: true })
        } else if (enabled && idx !== -1) {
            entries[idx].enabled = true
        } else if (!enabled && idx !== -1) {
            entries[idx].enabled = false
        }
        Config.setNestedValue("autostart.entries", entries)
    }

    function addCommand(command: string): void {
        const cmd = command.trim()
        if (cmd.length === 0)
            return
        let entries = [...(Config.options?.autostart?.entries ?? [])]
        entries.push({ type: "command", command: cmd, enabled: true })
        Config.setNestedValue("autostart.entries", entries)
        commandInput.text = ""
    }

    function removeEntry(index: int): void {
        let entries = [...(Config.options?.autostart?.entries ?? [])]
        if (index >= 0 && index < entries.length) {
            entries.splice(index, 1)
            Config.setNestedValue("autostart.entries", entries)
        }
    }

    function setEntryEnabled(index: int, enabled: bool): void {
        let entries = [...(Config.options?.autostart?.entries ?? [])]
        if (index >= 0 && index < entries.length) {
            entries[index].enabled = enabled
            Config.setNestedValue("autostart.entries", entries)
        }
    }

    function getCommandEntries(): var {
        const entries = Config.options?.autostart?.entries ?? []
        const cmds = []
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].type === "command")
                cmds.push({ entry: entries[i], originalIndex: i })
        }
        return cmds
    }

    function getFilteredApps(): var {
        const search = appSearchField.text.toLowerCase().trim()
        const apps = AppSearch.list ?? []
        const result = []
        for (let i = 0; i < apps.length; ++i) {
            const app = apps[i]
            const name = (app.name || "").toLowerCase()
            const generic = (app.genericName || "").toLowerCase()
            if (search && !name.includes(search) && !generic.includes(search))
                continue
            result.push(app)
        }
        result.sort((a, b) => {
            const aEnabled = root.isDesktopEnabled(a.id)
            const bEnabled = root.isDesktopEnabled(b.id)
            if (aEnabled !== bEnabled)
                return aEnabled ? -1 : 1
            return (a.name || "").localeCompare(b.name || "")
        })
        return result
    }

    // ── Layout ───────────────────────────────────────────────────────────

    WSettingsCard {
        title: Translation.tr("General")
        icon: "rocket-launch"

        WSettingsSwitch {
            label: Translation.tr("Start apps on launch")
            icon: "rocket-launch"
            checked: Config.options?.autostart?.enable ?? false
            onCheckedChanged: Config.setNestedValue("autostart.enable", checked)
        }
    }

    WSettingsCard {
        title: Translation.tr("Applications")
        icon: "apps"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: appSearchField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search applications...")
                font.pixelSize: Looks.font.pixelSize.small
                color: Looks.colors.fg
                placeholderTextColor: Looks.colors.subfg
                background: Rectangle {
                    color: Looks.colors.bg1
                    radius: Looks.dp(4)
                    border.width: appSearchField.activeFocus ? 2 : 1
                    border.color: appSearchField.activeFocus
                        ? Looks.colors.accent
                        : Looks.colors.bg1Border
                }
            }

            ListView {
                id: appListView
                Layout.fillWidth: true
                implicitHeight: Math.min(400, appListView.contentHeight)
                clip: true
                model: root.getFilteredApps()

                delegate: RowLayout {
                    id: appDelegate
                    required property var modelData
                    required property int index
                    width: appListView.width
                    spacing: 10

                    Item {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            anchors.fill: parent
                            source: AppSearch.getIconSource(appDelegate.modelData.icon, appDelegate.modelData.name)
                            sourceSize.width: 48
                            sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }

                        FluentIcon {
                            anchors.fill: parent
                            icon: "apps"
                            implicitSize: 20
                            color: Looks.colors.fg
                            visible: !(AppSearch.getIconSource(appDelegate.modelData.icon, appDelegate.modelData.name).length > 0)
                        }
                    }

                    WText {
                        Layout.fillWidth: true
                        text: appDelegate.modelData.name
                        font.pixelSize: Looks.font.pixelSize.normal
                    }

                    WSwitch {
                        checked: root.isDesktopEnabled(appDelegate.modelData.id)
                        onCheckedChanged: root.setDesktopEnabled(appDelegate.modelData.id, checked)
                    }
                }
            }
        }
    }

    WSettingsCard {
        title: Translation.tr("Custom Commands")
        icon: "terminal"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                WSettingsTextField {
                    id: commandInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("e.g. telegram-desktop --start-minimized")
                    onTextEdited: (newText) => { commandInput.text = newText }
                }

                WSettingsButton {
                    buttonText: Translation.tr("Add")
                    buttonIcon: "add"
                    onButtonClicked: root.addCommand(commandInput.text)
                }
            }

            ListView {
                id: commandListView
                Layout.fillWidth: true
                implicitHeight: Math.min(200, commandListView.contentHeight)
                clip: true
                model: root.getCommandEntries()

                delegate: RowLayout {
                    id: cmdDelegate
                    required property var modelData
                    required property int index
                    width: commandListView.width
                    spacing: 10

                    FluentIcon {
                        icon: "terminal"
                        implicitSize: 20
                        color: Looks.colors.fg
                    }

                    WText {
                        Layout.fillWidth: true
                        text: cmdDelegate.modelData.entry.command
                        font.pixelSize: Looks.font.pixelSize.normal
                        elide: Text.ElideRight
                    }

                    WSwitch {
                        checked: cmdDelegate.modelData.entry.enabled
                        onCheckedChanged: root.setEntryEnabled(cmdDelegate.modelData.originalIndex, checked)
                    }

                    WSettingsButton {
                        buttonText: Translation.tr("Remove")
                        buttonIcon: "delete"
                        onButtonClicked: root.removeEntry(cmdDelegate.modelData.originalIndex)
                    }
                }
            }
        }
    }
}
