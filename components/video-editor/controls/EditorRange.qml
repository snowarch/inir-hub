// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

Loader {
    id: root
    property real from: 0
    property real to: 1
    property real value: 0
    property var formatValue: next => Math.round(root.to === 1 ? next * 100 : next) + "%"
    signal moved(real value)
    active: visible
    sourceComponent: EditorSkin.iris ? irisRange : EditorSkin.waffle ? waffleRange : materialRange
    Binding { target: root.item; property: "value"; value: EditorSkin.iris ? (root.value - root.from) / Math.max(1e-6, root.to - root.from) : root.value; when: root.item !== null }
    Component {
        id: irisRange
        IrisSlider { onMoved: next => root.moved(root.from + next * (root.to - root.from)); Accessible.name: root.Accessible.name }
    }
    Component {
        id: waffleRange
        WSlider { id: waffle; from: root.from; to: root.to; stepSize: 0; tooltipContent: root.formatValue(waffle.value); onMoved: root.moved(waffle.value); Accessible.name: root.Accessible.name }
    }
    Component {
        id: materialRange
        StyledSlider { id: material; from: root.from; to: root.to; tooltipContent: root.formatValue(material.value); enableSettingsSearch: false; onMoved: root.moved(material.value); Accessible.name: root.Accessible.name }
    }
}
