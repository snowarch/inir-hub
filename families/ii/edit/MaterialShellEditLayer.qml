pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar as BarKit

// The sheet of the bar, a bar module or the Dock while the shell layout is arranged in place. It opens beside the thing
// it belongs to; only the sheet takes input, so the bar, the Dock and the desktop stay in reach.
Scope {
    id: root

    readonly property string kind: ShellEditSession.sheetKind
    readonly property string sheetId: ShellEditSession.sheetId

    component SheetTitle: StyledText {
        Layout.fillWidth: true
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.Medium
        color: Appearance.colors.colSubtext
    }

    component SheetKey: RippleButton {
        id: key
        required property string glyph
        required property string caption
        property bool danger: false
        Layout.fillWidth: true
        implicitHeight: 40
        buttonRadius: Appearance.rounding.small
        colBackground: key.danger ? Appearance.colors.colErrorContainer : Appearance.colors.colLayer2
        colBackgroundHover: key.danger ? Appearance.colors.colErrorContainerHover : Appearance.colors.colLayer2Hover
        contentItem: RowLayout {
            spacing: 8
            MaterialSymbol {
                Layout.leftMargin: 12
                text: key.glyph
                iconSize: 18
                color: key.danger ? Appearance.colors.colOnErrorContainer : Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: key.caption
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
                color: key.danger ? Appearance.colors.colOnErrorContainer : Appearance.colors.colOnLayer2
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: win.modelData

            readonly property bool here: root.kind.length > 0 && ShellEditSession.sheetOutput === (win.screen?.name ?? "")
            visible: win.here || sheet.opacity > 0.01
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:ii-shell-edit-sheet"
            WlrLayershell.keyboardFocus: win.here ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region { item: sheet }

            // Kept while it fades out, so the last sheet folds away instead of going blank.
            property string shownKind: ""
            property string shownId: ""
            onHereChanged: if (win.here) { win.shownKind = root.kind; win.shownId = root.sheetId }
            Connections {
                target: ShellEditSession
                function onSheetIdChanged(): void { if (win.here) win.shownId = root.sheetId }
                function onSheetKindChanged(): void { if (win.here) win.shownKind = root.kind }
            }

            readonly property var anchorRect: ShellEditSession.sheetAnchor
            readonly property real gap: 12
            // Beside the thing: below or above it for a horizontal one, to its side for a vertical one; centred when
            // the sheet was opened without a place (from the command line).
            readonly property bool vertical: win.anchorRect.height > win.anchorRect.width * 1.5
            readonly property real wantX: {
                const a = win.anchorRect
                if (a.width <= 0) return (win.width - sheet.width) / 2
                if (!win.vertical) return a.x + (a.width - sheet.width) / 2
                return a.x + a.width / 2 < win.width / 2 ? a.x + a.width + win.gap : a.x - win.gap - sheet.width
            }
            readonly property real wantY: {
                const a = win.anchorRect
                if (a.width <= 0) return (win.height - sheet.height) / 2
                if (win.vertical) return a.y + (a.height - sheet.height) / 2
                return a.y + a.height / 2 < win.height / 2 ? a.y + a.height + win.gap : a.y - win.gap - sheet.height
            }

            Item {
                id: sheet
                width: 340
                height: Math.min(body.implicitHeight + 28, win.height - 2 * win.gap)
                x: Math.round(Math.max(win.gap, Math.min(win.width - win.gap - width, win.wantX)))
                y: Math.round(Math.max(win.gap, Math.min(win.height - win.gap - height, win.wantY)))
                opacity: win.here ? 1 : 0
                scale: win.here ? 1 : 0.94
                transformOrigin: Item.Center
                focus: win.here
                Keys.onEscapePressed: ShellEditSession.handleEscape()
                Behavior on opacity {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                }

                StyledRectangularShadow { target: plate }
                Rectangle {
                    id: plate
                    anchors.fill: parent
                    radius: Appearance.rounding.large
                    color: Appearance.colors.colLayer1
                    border.width: 1
                    border.color: Appearance.colors.colOutlineVariant
                }

                StyledFlickable {
                    anchors.fill: parent
                    anchors.margins: 14
                    contentHeight: body.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: body
                        width: parent.width
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            MaterialSymbol {
                                text: win.shownKind === "module" ? BarKit.BarModules.info(win.shownId).icon
                                    : win.shownKind === "dock" ? "call_to_action" : "toolbar"
                                iconSize: 22
                                color: Appearance.colors.colPrimary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: win.shownKind === "module" ? BarKit.BarModules.info(win.shownId).name
                                    : win.shownKind === "dock" ? Translation.tr("Dock") : Translation.tr("Bar")
                                font.pixelSize: Appearance.font.pixelSize.large
                                font.weight: Font.Medium
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            RippleButton {
                                implicitWidth: 32
                                implicitHeight: 32
                                buttonRadius: Appearance.rounding.full
                                onClicked: ShellEditSession.closeSheet()
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 18
                                    color: Appearance.colors.colOnLayer1
                                }
                            }
                        }

                        Loader {
                            Layout.fillWidth: true
                            sourceComponent: win.shownKind === "module" ? moduleSheet
                                : win.shownKind === "dock" ? dockSheet
                                : win.shownKind === "bar" ? barSheet : null
                        }
                    }
                }
            }

            Component {
                id: moduleSheet
                ColumnLayout {
                    spacing: 8
                    readonly property var spot: {
                        const zones = BarKit.BarModules.zones()
                        for (const z of zones) {
                            const at = BarKit.BarModules.ids(z).indexOf(win.shownId)
                            if (at >= 0) return { zone: z, index: at }
                        }
                        return null
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: BarKit.BarModules.info(win.shownId).description
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: parent.spot !== null
                        text: Translation.tr("Drag it along the bar to move it, or off the bar to remove it.")
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    SheetKey {
                        glyph: "tune"
                        caption: Translation.tr("More options")
                        onClicked: {
                            ShellEditSession.closeSheet()
                            GlobalStates.openSettingsAt("bar", undefined)
                        }
                    }
                    SheetKey {
                        visible: parent.spot !== null
                        glyph: "delete"
                        caption: Translation.tr("Remove from bar")
                        danger: true
                        onClicked: {
                            const spot = parent.spot
                            ShellEditSession.closeSheet()
                            if (spot) BarKit.BarModules.remove(spot.zone, spot.index)
                        }
                    }
                }
            }

            Component {
                id: barSheet
                ColumnLayout {
                    id: barBody
                    spacing: 8
                    property string zone: BarKit.BarModules.zones()[0]

                    SheetTitle { text: Translation.tr("Style") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: Config.options?.material?.bar?.appearanceStyle ?? "classic"
                        onSelected: newValue => Config.setNestedValue("material.bar.appearanceStyle", newValue)
                        options: [
                            { displayName: Translation.tr("Classic"), icon: "toolbar", value: "classic" },
                            { displayName: Translation.tr("Islands"), icon: "linear_scale", value: "islands" },
                            { displayName: Translation.tr("Scenic"), icon: "gradient", value: "scenic" },
                            { displayName: Translation.tr("Frame"), icon: "crop_free", value: "frame" },
                            { displayName: Translation.tr("M3"), icon: "category", value: "m3" }
                        ]
                    }
                    SheetTitle { text: Translation.tr("Position") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: Config.options?.material?.bar?.bottom ?? false
                        onSelected: newValue => Config.setNestedValue("material.bar.bottom", newValue)
                        options: [
                            { displayName: Translation.tr("Top"), icon: "arrow_upward", value: false },
                            { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: true }
                        ]
                    }
                    SheetTitle { text: Translation.tr("Add to bar") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: barBody.zone
                        onSelected: newValue => barBody.zone = newValue
                        options: BarKit.BarModules.zones().map(z => ({ displayName: BarKit.BarModules.zoneLabel(z), value: z }))
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: BarKit.BarModules.available()
                            delegate: RippleButton {
                                id: chip
                                required property string modelData
                                readonly property var meta: BarKit.BarModules.info(chip.modelData)
                                implicitHeight: 32
                                implicitWidth: chipRow.implicitWidth + 20
                                buttonRadius: Appearance.rounding.full
                                colBackground: Appearance.colors.colSecondaryContainer
                                colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                onClicked: BarKit.BarModules.add(chip.modelData, barBody.zone, -1)
                                contentItem: Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    MaterialSymbol {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "add"
                                        iconSize: 16
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: chip.meta.name
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnSecondaryContainer
                                    }
                                }
                            }
                        }
                    }
                    SheetKey {
                        glyph: "tune"
                        caption: Translation.tr("More options")
                        onClicked: {
                            ShellEditSession.closeSheet()
                            GlobalStates.openSettingsAt("bar", undefined)
                        }
                    }
                }
            }

            Component {
                id: dockSheet
                ColumnLayout {
                    spacing: 8
                    SheetTitle { text: Translation.tr("Dock style") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: Config.options?.material?.dock?.style ?? "panel"
                        onSelected: newValue => Config.setNestedValue("material.dock.style", newValue)
                        options: [
                            { displayName: Translation.tr("Panel"), icon: "dock_to_bottom", value: "panel" },
                            { displayName: Translation.tr("Pill"), icon: "interests", value: "pill" },
                            { displayName: Translation.tr("macOS"), icon: "desktop_mac", value: "macos" },
                            { displayName: Translation.tr("Island"), icon: "blur_on", value: "island" },
                            { displayName: Translation.tr("M3"), icon: "category", value: "m3" },
                            { displayName: Translation.tr("Notch"), icon: "vertical_align_bottom", value: "notch" }
                        ]
                    }
                    SheetTitle { text: Translation.tr("Dock position") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: Config.options?.material?.dock?.position ?? "bottom"
                        onSelected: newValue => Config.setNestedValue("material.dock.position", newValue)
                        options: [
                            { displayName: Translation.tr("Top"), icon: "arrow_upward", value: "top" },
                            { displayName: Translation.tr("Left"), icon: "arrow_back", value: "left" },
                            { displayName: Translation.tr("Bottom"), icon: "arrow_downward", value: "bottom" },
                            { displayName: Translation.tr("Right"), icon: "arrow_forward", value: "right" }
                        ]
                    }
                    SheetTitle { text: Translation.tr("Reveal behavior") }
                    ConfigSelectionArray {
                        Layout.fillWidth: true
                        currentValue: Config.options?.material?.dock?.hoverToReveal ?? true
                        onSelected: newValue => Config.setNestedValue("material.dock.hoverToReveal", newValue)
                        options: [
                            { displayName: Translation.tr("Hover"), icon: "highlight_mouse_cursor", value: true },
                            { displayName: Translation.tr("Empty workspace"), icon: "desktop_windows", value: false }
                        ]
                    }
                    SheetKey {
                        glyph: "tune"
                        caption: Translation.tr("More options")
                        onClicked: {
                            ShellEditSession.closeSheet()
                            GlobalStates.openSettingsAt("dock", undefined)
                        }
                    }
                }
            }
        }
    }
}
