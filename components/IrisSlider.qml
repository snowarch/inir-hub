import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style

Item {
    id: root

    property alias value: slider.value
    signal moved(real value)

    implicitWidth: 220
    implicitHeight: Math.round(34 * IrisStyle.density)

    StyledSlider {
        id: slider
        anchors.fill: parent
        enabled: root.enabled
        enableSettingsSearch: false
        configuration: StyledSlider.Configuration.XS
        trackWidth: IrisStyle.island ? 4 : configuration
        trackRadius: IrisStyle.island ? 2 : 6
        handleHeight: IrisStyle.island ? 12 : 33
        handleDefaultWidth: IrisStyle.island ? 12 : 4
        handlePressedWidth: IrisStyle.island ? 14 : 2
        handleMargins: IrisStyle.island ? 0 : 4
        stopIndicatorValues: IrisStyle.island ? [] : [0, 1]
        highlightColor: IrisStyle.accent
        handleColor: IrisStyle.accent
        trackColor: IrisStyle.accentContainer
        dotColor: IrisStyle.subtext
        dotColorHighlighted: IrisStyle.onAccentContainer
        scrollable: true
        onMoved: root.moved(slider.value)
    }
}
