import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.welcome
import qs.modules.iris.style
import qs.modules.iris.settings
import qs.modules.iris.preview
import qs.modules.iris.components as Iris

Flickable {
    readonly property var root: WelcomeHost.wizard
    id: irisLayoutFlickable
    width: root.stepWidth
    contentHeight: irisLayoutGrid.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    bottomMargin: 24
    topMargin: Math.max(root.compact ? 8 : 12,
        Math.min(root.compact ? 20 : 28,
            Math.round((height - irisLayoutGrid.implicitHeight - bottomMargin) / 2)))

    GridLayout {
        id: irisLayoutGrid
        width: parent.width
        columns: irisLayoutFlickable.width < 760 ? 1 : 2
        columnSpacing: root.compact ? 22 : 30
        rowSpacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: irisLayoutFlickable.width < 760
                ? irisLayoutFlickable.width : (irisLayoutFlickable.width - (root.compact ? 22 : 30)) * 0.48
            Layout.alignment: Qt.AlignTop
            spacing: 9

            RowLayout {
                spacing: 8
                MaterialSymbol { text: "open_in_full"; iconSize: 18; color: root.welcomeAccent }
                WelcomeText {
                    text: Translation.tr("Placement")
                    font.family: root.welcomeFontTitle
                    font.pixelSize: root.welcomeFontSection
                    font.weight: Font.Bold
                    color: root.welcomeOnSurface
                }
            }

            WelcomeText {
                text: Translation.tr("Island edge")
                font.pixelSize: root.welcomeFontBody
                font.weight: Font.Medium
                color: root.welcomeOnSurface
            }
            WelcomeSegmentedControl {
                Layout.fillWidth: true
                currentValue: Config.options?.iris?.bar?.position ?? "top"
                options: [
                    { displayName: Translation.tr("Top"), icon: "vertical_align_top", value: "top" },
                    { displayName: Translation.tr("Bottom"), icon: "vertical_align_bottom", value: "bottom" },
                    { displayName: Translation.tr("Left"), icon: "align_horizontal_left", value: "left" },
                    { displayName: Translation.tr("Right"), icon: "align_horizontal_right", value: "right" }
                ]
                onSelected: value => Config.setNestedValue("iris.bar.position", value)
            }

            WelcomeText {
                text: Translation.tr("Island layout")
                font.pixelSize: root.welcomeFontBody
                font.weight: Font.Medium
                color: root.welcomeOnSurface
            }
            WelcomeSegmentedControl {
                Layout.fillWidth: true
                currentValue: Config.options?.iris?.bar?.layout ?? "island"
                options: [
                    { displayName: Translation.tr("Island"), icon: "pill", value: "island" },
                    { displayName: Translation.tr("Full bar"), icon: "width_full", value: "full" }
                ]
                onSelected: value => Config.setNestedValue("iris.bar.layout", value)
            }

            WelcomeText {
                text: Translation.tr("Dock edge")
                font.pixelSize: root.welcomeFontBody
                font.weight: Font.Medium
                color: root.welcomeOnSurface
            }
            WelcomeSegmentedControl {
                Layout.fillWidth: true
                currentValue: Config.options?.iris?.dock?.position ?? "auto"
                options: [
                    { displayName: Translation.tr("Auto"), icon: "swap_calls", value: "auto" },
                    { displayName: Translation.tr("Top"), icon: "north", value: "top" },
                    { displayName: Translation.tr("Bottom"), icon: "south", value: "bottom" },
                    { displayName: Translation.tr("Left"), icon: "west", value: "left" },
                    { displayName: Translation.tr("Right"), icon: "east", value: "right" }
                ]
                onSelected: value => Config.setNestedValue("iris.dock.position", value)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                WelcomeText {
                    Layout.fillWidth: true
                    text: Translation.tr("Attach Island to edge")
                    font.pixelSize: root.welcomeFontCaption
                    color: root.welcomeOnSurface
                }
                WelcomeSegmentedControl {
                    Layout.preferredWidth: 170
                    currentValue: (Config.options?.iris?.bar?.notch ?? true) ? "on" : "off"
                    options: [
                        { displayName: Translation.tr("Off"), icon: "", value: "off" },
                        { displayName: Translation.tr("On"), icon: "", value: "on" }
                    ]
                    onSelected: value => Config.setNestedValue("iris.bar.notch", value === "on")
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                WelcomeText {
                    Layout.fillWidth: true
                    text: Translation.tr("Desktop widgets")
                    font.pixelSize: root.welcomeFontCaption
                    color: root.welcomeOnSurface
                }
                WelcomeSegmentedControl {
                    Layout.preferredWidth: 170
                    currentValue: (Config.options?.iris?.modules?.desktopWidgets ?? true) ? "on" : "off"
                    options: [
                        { displayName: Translation.tr("Off"), icon: "", value: "off" },
                        { displayName: Translation.tr("On"), icon: "", value: "on" }
                    ]
                    onSelected: value => Config.setNestedValue("iris.modules.desktopWidgets", value === "on")
                }
            }
        }

        PanelSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: irisLayoutFlickable.width < 760
                ? irisLayoutFlickable.width : (irisLayoutFlickable.width - (root.compact ? 22 : 30)) * 0.52
            Layout.alignment: Qt.AlignTop
            implicitHeight: Math.max(irisLayoutPreviewColumn.implicitHeight + 28, root.compact ? 310 : 350)
            surfaceDialect: "material"
            elevation: 2
            borderless: true
            outlined: false
            radiusOverride: IrisStyle.radiusPlate

            WelcomeFill {}

            ColumnLayout {
                id: irisLayoutPreviewColumn
                anchors.fill: parent
                anchors.margins: IrisStyle.concentricPad(IrisStyle.radiusPlate, 14)
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol { text: "desktop_windows"; iconSize: 18; color: root.welcomeAccent }
                    WelcomeText {
                        text: Translation.tr("Live layout")
                        font.family: root.welcomeFontTitle
                        font.pixelSize: root.welcomeFontSection
                        font.weight: Font.Bold
                        color: root.welcomeOnSurface
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: width / root.screenAspect
                    IrisScreenPreview {
                        anchors.fill: parent
                        screen: root.focusedScreen
                        maxScale: 1
                    }
                }

                WelcomeText {
                    Layout.fillWidth: true
                    text: Translation.tr("Auto keeps the Dock opposite the Island. Choosing the same edge swaps them.")
                    font.pixelSize: root.welcomeFontCaption
                    color: root.welcomeSecondaryText
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
