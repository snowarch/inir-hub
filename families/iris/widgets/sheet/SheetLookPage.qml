pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The sheet's Look page: its design as small drawings of each (Prism among them), what stands behind it as samples
// on the wallpaper itself, then the plate's corners and opacity and the look rows of its manifest as the numbered chart.
ColumnLayout {
    id: page
    required property var controls
    readonly property var widget: page.controls.widget
    readonly property bool plated: page.controls.plated
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    spacing: PrismTheme.dp(18)

    ColumnLayout {
        visible: !page.widget.stacked && page.widget.designChoices.length > 1
        Layout.fillWidth: true
        spacing: PrismTheme.dp(8)
        SheetCaption {
            text: Translation.tr("Design")
            note: page.widget.widgetDesignShared ? Translation.tr("Same as every widget") : Translation.tr("This widget only")
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: PrismTheme.dp(6)
            Repeater {
                model: page.widget.designChoices
                SheetCard {
                    id: designCard
                    required property var modelData
                    chosen: page.widget.widgetDesign === designCard.modelData.value
                    label: designCard.modelData.label
                    onPicked: page.widget.pickDesign(designCard.modelData.value)
                    SheetSpecimen {
                        anchors.fill: parent
                        design: designCard.modelData.value
                        glyph: designCard.modelData.icon ?? "widgets"
                        lit: designCard.chosen
                    }
                }
            }
        }
        PrismPill {
            visible: page.widget.widgetDesignMatchable
            tone: "quiet"
            glyph: "select_all"
            text: Translation.tr("Use on every widget")
            onClicked: page.widget.useDesignEverywhere()
        }
    }

    ColumnLayout {
        visible: page.controls.faced
        Layout.fillWidth: true
        spacing: PrismTheme.dp(8)
        SheetCaption {
            text: Translation.tr("Background")
            note: page.controls.surface === "auto"
                ? (page.controls.materials.find(entry => entry.value === page.controls.sharedMaterial)?.label ?? "") + " · " + Translation.tr("from Settings") : ""
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: PrismTheme.dp(6)
            Repeater {
                model: page.controls.materials
                SheetCard {
                    id: swatch
                    required property var modelData
                    readonly property string shown: swatch.modelData.value === "none" ? "clear"
                        : swatch.modelData.value === "auto" ? page.controls.sharedMaterial : swatch.modelData.value
                    artHeight: PrismTheme.dp(40)
                    chosen: page.controls.surface === swatch.modelData.value
                    label: swatch.modelData.label
                    onPicked: page.controls.pickSurface(swatch.modelData.value)
                    // The wallpaper itself, with a little plate of this material on it.
                    ClippingRectangle {
                        anchors.fill: parent
                        radius: PrismTheme.dp(9)
                        color: PrismTheme.fill
                        IrisImage {
                            anchors.fill: parent
                            source: page.controls.wallpaperUrl
                            layer.enabled: swatch.shown === "glass"
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: IrisStyle.glassBlur
                                blurMax: Math.round(IrisStyle.glassBlurMax / 3)
                                saturation: IrisStyle.glassSaturation
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: PrismTheme.dp(8)
                            radius: PrismTheme.dp(6)
                            color: page.controls.materialColor(swatch.modelData.value)
                            border.width: swatch.shown === "clear" ? 0 : 1
                            border.color: IrisStyle.rim
                            PrismText {
                                anchors.centerIn: parent
                                text: "Aa"
                                color: IrisStyle.text
                                font.pixelSize: PrismTheme.body
                                font.weight: Font.Bold
                                style: swatch.shown === "clear" ? Text.Raised : Text.Normal
                                styleColor: IrisStyle.plateShadow
                            }
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        // Stay while there's no plate, dimmed: picking a background never moves the sheet under the pointer.
        SheetLine {
            visible: page.controls.faced
            enabled: page.plated
            opacity: page.plated ? 1 : 0.4
            number: 1
            label: Translation.tr("Corners")
            changed: page.controls.cornerValue >= 0
            PrismSlider {
                id: corners
                implicitWidth: PrismTheme.dp(150)
                from: 0
                to: page.controls.cornerMax
                stepSize: 2
                value: Math.max(0, page.controls.cornerValue)
                glyph: "rounded_corner"
                label: corners.live <= 0 ? Translation.tr("Auto") : Math.round(corners.live) + " px"
                onMoved: value => page.widget.previewValue("cornerRadius", value <= 0 ? -1 : Math.round(value))
                onCommitted: value => page.widget.commitValue("cornerRadius", value <= 0 ? -1 : Math.round(value))
            }
        }
        SheetLine {
            visible: page.controls.faced
            enabled: page.plated
            opacity: page.plated ? 1 : 0.4
            number: 2
            label: Translation.tr("Surface opacity")
            rule: looks.active
            PrismSlider {
                id: veil
                implicitWidth: PrismTheme.dp(150)
                from: page.controls.opacityMin
                to: 100
                stepSize: 5
                value: page.controls.opacityValue
                glyph: "opacity"
                label: Math.round(veil.live) + "%"
                onMoved: value => page.widget.previewValue("iris.opacity", Math.round(value))
                onCommitted: value => {
                    const chosen = Math.round(value)
                    page.widget.commitValue("iris.opacity",
                        chosen === Math.round(Number(Config.options?.iris?.widgets?.opacity ?? 100)) ? -1 : chosen)
                }
            }
        }
        Loader {
            id: looks
            active: page.controls.optionRows !== null && page.controls.lookRows.length > 0
            visible: active
            Layout.fillWidth: true
            sourceComponent: page.controls.optionRows
            onLoaded: {
                item.firstNumber = page.controls.faced ? 3 : 1
                item.specs = Qt.binding(() => page.controls.lookRows)
            }
        }
    }
}
