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
    id: irisAppearanceFlickable
    width: root.stepWidth
    contentHeight: irisAppearanceGrid.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    bottomMargin: 24
    topMargin: Math.max(root.compact ? 8 : 12,
        Math.min(root.compact ? 20 : 28,
            Math.round((height - irisAppearanceGrid.implicitHeight - bottomMargin) / 2)))

    GridLayout {
        id: irisAppearanceGrid
        width: parent.width
        columns: irisAppearanceFlickable.width < 760 ? 1 : 2
        columnSpacing: root.compact ? 22 : 30
        rowSpacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: irisAppearanceFlickable.width < 760
                ? irisAppearanceFlickable.width : (irisAppearanceFlickable.width - (root.compact ? 22 : 30)) * 0.42
            Layout.alignment: Qt.AlignTop
            spacing: 5

            RowLayout {
                spacing: 8
                MaterialSymbol { text: "palette"; iconSize: 18; color: root.welcomeAccent }
                WelcomeText {
                    text: Translation.tr("Themes")
                    font.family: root.welcomeFontTitle
                    font.pixelSize: root.welcomeFontSection
                    font.weight: Font.Bold
                    color: root.welcomeOnSurface
                }
            }

            WelcomeText {
                Layout.fillWidth: true
                text: Translation.tr("Material, shape and motion. More themes in Studio.")
                font.pixelSize: root.welcomeFontCaption
                color: root.welcomeSecondaryText
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.familyWelcome?.irisWelcomeThemes
                WelcomeChoiceRow {
                    required property var modelData
                    compactRow: true
                    title: modelData.name
                    symbol: modelData.id === "terminal" ? "terminal"
                        : modelData.id === "adaptive" ? "auto_awesome"
                        : modelData.id === "frost" ? "ac_unit"
                        : modelData.id === "aurora" ? "gradient"
                        : modelData.id === "liquid-glass" ? "water_drop" : "visibility"
                    selected: IrisThemes.activeId === modelData.id && !IrisThemes.modified
                    onClicked: root.familyWelcome.applyIrisTheme(modelData.id)
                }
            }
        }

        PanelSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: irisAppearanceFlickable.width < 760
                ? irisAppearanceFlickable.width : (irisAppearanceFlickable.width - (root.compact ? 22 : 30)) * 0.58
            Layout.alignment: Qt.AlignTop
            implicitHeight: Math.max(irisThemePreviewColumn.implicitHeight + 28, root.compact ? 310 : 350)
            surfaceDialect: "material"
            elevation: 2
            borderless: true
            outlined: false
            radiusOverride: IrisStyle.radiusPlate

            WelcomeFill {}

            ColumnLayout {
                id: irisThemePreviewColumn
                anchors.fill: parent
                anchors.margins: IrisStyle.concentricPad(IrisStyle.radiusPlate, 14)
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        WelcomeText {
                            text: IrisThemes.active?.name ?? Translation.tr("Custom theme")
                            font.family: root.welcomeFontTitle
                            font.pixelSize: root.welcomeFontSection
                            font.weight: Font.Bold
                            color: root.welcomeOnSurface
                        }
                        WelcomeText {
                            Layout.fillWidth: true
                            text: IrisThemes.modified
                                ? Translation.tr("Modified")
                                : (IrisThemes.active?.description ?? "")
                            font.pixelSize: root.welcomeFontCaption
                            color: root.welcomeSecondaryText
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                        }
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Repeater {
                        model: [
                            { icon: "texture", value: IrisStyle.glassy ? Translation.tr("Glass") : Translation.tr("Solid") },
                            { icon: "rounded_corner", value: String(Math.round(IrisStyle.shapeScale * 100)) + "%" },
                            { icon: "motion_mode", value: IrisStyle.morphName }
                        ]
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 5
                            MaterialSymbol { text: modelData.icon; iconSize: 15; color: root.welcomeAccent }
                            WelcomeText {
                                Layout.fillWidth: true
                                text: modelData.value
                                font.pixelSize: root.welcomeFontMeta
                                font.weight: Font.DemiBold
                                color: root.welcomeSecondaryText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
