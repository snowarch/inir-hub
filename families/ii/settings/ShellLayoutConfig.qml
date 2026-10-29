pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    id: root

    settingsPageIndex: 26
    settingsPageName: Translation.tr("Shell Layout")

    property string liftedSurfaceId: ""
    property string confirmationSurfaceId: ""
    property string confirmationSlot: ""
    readonly property string activeFamily: ShellLayoutController.activeFamily
    readonly property bool standaloneSettings:
        Quickshell.env("INIR_STANDALONE_WINDOW") === "1"
    readonly property var surfaces: ShellLayoutController.surfacesForFamily(
        root.activeFamily)

    function toggleLiveEditor(): void {
        if (root.standaloneSettings) {
            Quickshell.execDetached([
                Quickshell.shellPath("scripts/inir"),
                "shellLayout",
                "open"
            ])
            Qt.quit()
            return
        }
        if (ShellEditSession.active) {
            ShellEditSession.exit()
            return
        }
        ShellEditSession.enter("")
        GlobalStates.settingsOverlayOpen = false
    }

    function stateFor(surfaceId: string): var {
        return ShellLayoutController.currentState(surfaceId,
            ShellEditSession.targetOutputName)
    }

    function place(surfaceId: string, slot: string): void {
        const validation = ShellLayoutController.validatePlacement(
            surfaceId, slot, ShellEditSession.targetOutputName)
        if (!validation.ok)
            return
        if ((validation.swapWith ?? "").length > 0
                && !(root.confirmationSurfaceId === surfaceId
                    && root.confirmationSlot === slot)) {
            root.confirmationSurfaceId = surfaceId
            root.confirmationSlot = slot
            return
        }
        const result = ShellLayoutController.moveSurface(surfaceId, slot,
            ShellEditSession.targetOutputName)
        if (result.ok) {
            root.liftedSurfaceId = ""
            root.confirmationSurfaceId = ""
            root.confirmationSlot = ""
        }
    }

    function scopeLabel(scope: string): string {
        if (scope === "enabledOutputs")
            return Translation.tr("Enabled outputs")
        if (scope === "global")
            return Translation.tr("Global")
        return scope
    }

    SettingsCardSection {
        expanded: true
        icon: "dashboard_customize"
        title: Translation.tr("Live shell layout")

        SettingsGroup {
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Move persistent shell surfaces directly on the desktop or arrange them here. Every change uses the same live layout controller.")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButtonWithIcon {
                    materialIcon: "edit"
                    mainText: ShellEditSession.active
                        ? Translation.tr("Done editing")
                        : Translation.tr("Edit live")
                    onClicked: root.toggleLiveEditor()
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Family") + ": " + root.activeFamily
                        + (ShellEditSession.targetOutputName.length > 0
                            ? " · " + ShellEditSession.targetOutputName : "")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
        }
    }

    Repeater {
        model: root.surfaces

        delegate: SettingsCardSection {
            id: surfaceSection
            required property var modelData

            readonly property string surfaceId: modelData.id
            readonly property var currentState: root.stateFor(surfaceId)
            readonly property bool lifted: root.liftedSurfaceId === surfaceId
            readonly property bool sidebarRole: surfaceId === "featureSidebar"
                || surfaceId === "systemSidebar"

            expanded: sidebarRole
            icon: modelData.icon
            title: Translation.tr(modelData.labelKey)

            SettingsGroup {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ArrangeChip {
                        icon: surfaceSection.modelData.icon
                        label: Translation.tr("Move") + " · "
                            + Translation.tr(surfaceSection.currentState?.slot ?? "")
                        lifted: surfaceSection.lifted
                        dimmed: root.liftedSurfaceId.length > 0
                            && !surfaceSection.lifted
                        onTapped: {
                            root.liftedSurfaceId = surfaceSection.lifted
                                ? "" : surfaceSection.surfaceId
                            root.confirmationSurfaceId = ""
                            root.confirmationSlot = ""
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.scopeLabel(
                            surfaceSection.currentState?.scope ?? "")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        horizontalAlignment: Text.AlignRight
                    }

                    RippleButtonWithIcon {
                        materialIcon: "restart_alt"
                        mainText: Translation.tr("Reset")
                        onClicked: ShellLayoutController.resetSurface(
                            surfaceSection.surfaceId,
                            ShellEditSession.targetOutputName)
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    visible: surfaceSection.lifted
                    spacing: 8

                    Repeater {
                        model: surfaceSection.modelData.slots

                        delegate: Row {
                            id: targetRow
                            required property string modelData
                            readonly property var validation:
                                ShellLayoutController.validatePlacement(
                                    surfaceSection.surfaceId, modelData,
                                    ShellEditSession.targetOutputName)
                            spacing: 5

                            ArrangeDropSlot {
                                compact: true
                                active: targetRow.validation.ok
                                    && surfaceSection.currentState?.slot !== targetRow.modelData
                                onPlaced: root.place(surfaceSection.surfaceId,
                                    targetRow.modelData)
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Translation.tr(targetRow.modelData)
                                    + (root.confirmationSurfaceId === surfaceSection.surfaceId
                                        && root.confirmationSlot === targetRow.modelData
                                        ? " · " + Translation.tr("Confirm swap")
                                        : targetRow.validation.swapWith?.length > 0
                                            ? " · " + Translation.tr("Swap") : "")
                                color: targetRow.validation.ok
                                    ? Appearance.colors.colOnLayer1
                                    : Appearance.colors.colError
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: surfaceSection.lifted
                        && surfaceSection.currentState?.slot?.length > 0
                    text: Translation.tr("Tap an available target. Occupied sidebar edges swap both roles atomically.")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    wrapMode: Text.Wrap
                }
            }

            SettingsGroup {
                visible: surfaceSection.sidebarRole

                ContentSubsection {
                    title: Translation.tr("Height")
                    ConfigSelectionArray {
                        enableSettingsSearch: false
                        currentValue: surfaceSection.currentState?.sizeMode ?? "full"
                        onSelected: value => ShellLayoutController.setProperty(
                            surfaceSection.surfaceId, "sizeMode", value, ShellEditSession.targetOutputName)
                        options: [
                            { displayName: Translation.tr("Full"), icon: "height", value: "full" },
                            { displayName: Translation.tr("Fit"), icon: "fit_screen", value: "fit" },
                            { displayName: Translation.tr("Custom"), icon: "tune", value: "custom" }
                        ]
                    }
                }

                ConfigSpinBox {
                    visible: (surfaceSection.currentState?.sizeMode ?? "full") === "custom"
                    enableSettingsSearch: false
                    icon: "straighten"
                    text: Translation.tr("Custom height (px)")
                    from: 320
                    to: 2160
                    stepSize: 10
                    value: surfaceSection.currentState?.customHeight ?? 720
                    onValueModified: ShellLayoutController.setProperty(
                        surfaceSection.surfaceId, "height", value, ShellEditSession.targetOutputName)
                }

                ConfigSpinBox {
                    enableSettingsSearch: false
                    icon: "width"
                    text: Translation.tr("Width (px)")
                    from: 320
                    to: 900
                    stepSize: 10
                    value: surfaceSection.currentState?.width ?? 460
                    onValueModified: ShellLayoutController.setProperty(
                        surfaceSection.surfaceId, "thickness", value, ShellEditSession.targetOutputName)
                }
            }
        }
    }
}
