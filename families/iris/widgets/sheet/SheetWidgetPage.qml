import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The sheet's Widget page: the sizes drawn as the room they take, the widget's own controls, then its settings as
// Prism's numbered chart (scale first, then every row of its manifest for this page).
ColumnLayout {
    id: page
    required property var controls
    readonly property var widget: page.controls.widget
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    spacing: PrismTheme.dp(18)

    ColumnLayout {
        visible: page.widget.sizeChoices.length > 1
        Layout.fillWidth: true
        spacing: PrismTheme.dp(8)
        SheetCaption { text: Translation.tr("Size") }
        SheetSizes { widget: page.widget }
    }

    Loader {
        active: page.widget.ownControls !== null
        visible: active
        Layout.fillWidth: true
        sourceComponent: page.widget.ownControls
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        SheetLine {
            number: 1
            label: Translation.tr("Scale")
            changed: page.controls.scaleValue !== 100
            rule: rows.active
            PrismSlider {
                id: scale
                implicitWidth: PrismTheme.dp(150)
                from: page.controls.scaleMin
                to: page.controls.scaleMax
                stepSize: 5
                value: page.controls.scaleValue
                glyph: "aspect_ratio"
                label: Math.round(scale.live) + "%"
                onMoved: value => page.widget.previewScale(Math.round(value))
                onCommitted: value => page.widget.commitIrisScale(Math.round(value))
            }
        }
        Loader {
            id: rows
            active: page.controls.optionRows !== null && page.controls.widgetRows.length > 0
            visible: active
            Layout.fillWidth: true
            sourceComponent: page.controls.optionRows
            onLoaded: {
                item.firstNumber = 2
                item.specs = Qt.binding(() => page.controls.widgetRows)
            }
        }
    }
}
