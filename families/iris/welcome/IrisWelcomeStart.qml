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
    id: irisStartFlickable
    width: root.stepWidth
    contentHeight: irisStartGrid.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    interactive: contentHeight > height
    bottomMargin: 24
    topMargin: Math.max(root.compact ? 8 : 12,
        Math.min(root.compact ? 20 : 28,
            Math.round((height - irisStartGrid.implicitHeight - bottomMargin) / 2)))

    GridLayout {
        id: irisStartGrid
        width: parent.width
        columns: irisStartFlickable.width < 760 ? 1 : 2
        columnSpacing: root.compact ? 22 : 30
        rowSpacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: irisStartFlickable.width < 760
                ? irisStartFlickable.width : (irisStartFlickable.width - (root.compact ? 22 : 30)) * 0.42
            Layout.alignment: Qt.AlignTop
            spacing: 7

            RowLayout {
                spacing: 8
                MaterialSymbol { text: "view_compact"; iconSize: 18; color: root.welcomeAccent }
                WelcomeText {
                    text: Translation.tr("iRiS layout")
                    font.family: root.welcomeFontTitle
                    font.pixelSize: root.welcomeFontSection
                    font.weight: Font.Bold
                    color: root.welcomeOnSurface
                }
            }

            WelcomeText {
                Layout.fillWidth: true
                text: Translation.tr("Start with an Island or a full bar. Adjust its position next.")
                font.pixelSize: root.welcomeFontCaption
                color: root.welcomeSecondaryText
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.familyWelcome?.irisArrangements
                WelcomeChoiceRow {
                    required property var modelData
                    title: modelData.name
                    detail: modelData.description
                    symbol: modelData.icon
                    badge: modelData.badge ?? ""
                    selected: root.familyWelcome?.effectiveIrisArrangement === modelData.id
                    onClicked: root.familyWelcome.applyIrisArrangement(modelData.id)
                }
            }
        }

        PanelSurface {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: irisStartFlickable.width < 760
                ? irisStartFlickable.width : (irisStartFlickable.width - (root.compact ? 22 : 30)) * 0.58
            Layout.alignment: Qt.AlignTop
            implicitHeight: Math.max(irisStartPreviewColumn.implicitHeight + 28, root.compact ? 310 : 350)
            surfaceDialect: "material"
            elevation: 2
            borderless: true
            outlined: false
            radiusOverride: IrisStyle.radiusPlate

            WelcomeFill {}

            ColumnLayout {
                id: irisStartPreviewColumn
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol { text: "desktop_windows"; iconSize: 18; color: root.welcomeAccent }
                    WelcomeText {
                        text: root.familyWelcome?.effectiveIrisArrangement === "custom"
                            ? Translation.tr("Custom layout") : root.familyWelcome?.currentIrisArrangement?.name
                        font.family: root.welcomeFontTitle
                        font.pixelSize: root.welcomeFontSection
                        font.weight: Font.Bold
                        color: root.welcomeOnSurface
                    }
                    Item { Layout.fillWidth: true }
                    WelcomeText {
                        text: root.familyTitle
                        font.pixelSize: root.welcomeFontMeta
                        font.weight: Font.Bold
                        color: root.welcomeAccent
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

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: IrisStyle.hairline
                }

                RowLayout {
                    Layout.fillWidth: true
                    MaterialSymbol { text: "speed"; iconSize: 17; color: root.welcomeAccent }
                    WelcomeText {
                        text: Translation.tr("Effects")
                        font.family: root.welcomeFontTitle
                        font.pixelSize: root.welcomeFontBody
                        font.weight: Font.Bold
                        color: root.welcomeOnSurface
                    }
                    Item { Layout.fillWidth: true }
                    WelcomeText {
                        text: root.effectivePerformancePreset === "custom"
                            ? Translation.tr("Custom") : root.currentPerformancePreset.name
                        font.pixelSize: root.welcomeFontMeta
                        color: root.welcomeSecondaryText
                    }
                }

                WelcomeSegmentedControl {
                    Layout.fillWidth: true
                    currentValue: root.effectivePerformancePreset
                    options: root.performancePresets.map(preset => ({
                        displayName: preset.name, icon: preset.icon, value: preset.id
                    }))
                    onSelected: value => root.applyPerformancePreset(value)
                }
            }
        }
    }
}
