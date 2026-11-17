// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title: ""
    required property var choices
    property var selectedValue
    property real tolerance: 0
    signal chosen(var value)
    spacing: EditorSkin.small
    EditorText { visible: root.title !== ""; text: root.title; role: "meta" }
    Flow {
        Layout.fillWidth: true
        spacing: EditorSkin.small
        Repeater {
            model: root.choices
            EditorAction {
                required property var modelData
                label: modelData.label
                selected: root.selectedValue === modelData.value || root.tolerance > 0 && typeof root.selectedValue === "number" && Math.abs(root.selectedValue - modelData.value) < root.tolerance
                onClicked: root.chosen(modelData.value)
            }
        }
    }
}
