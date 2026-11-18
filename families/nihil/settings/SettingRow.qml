pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.nihil.style

// One option: its name on the left and the control its kind asks for on the right. While it differs from how NiHiL came,
// a key brings the original value back.
Item {
    id: root

    required property var option
    required property var host

    readonly property var value: root.host.read(root.option.key)
    readonly property bool changed: JSON.stringify(root.value) !== JSON.stringify(root.host.factory(root.option.key))
    readonly property bool isFit: root.option.fit !== undefined && root.value === root.option.fit

    function write(value: var): void {
        root.host.write(root.option.key, value)
    }

    function stepped(value: real): real {
        const step = root.option.step
        return Number((Math.round(value / step) * step).toFixed(3))
    }

    function figure(value: real): string {
        if (root.isFit)
            return Translation.tr(root.option.fitLabel)
        switch (root.option.unit) {
        case "percent": return Math.round(value * 100) + "%"
        case "px": return Math.round(value) + " px"
        case "ms": return Math.round(value) + " ms"
        case "times": return value.toFixed(2) + "x"
        default: return String(Math.round(value * 100) / 100)
        }
    }

    implicitHeight: Math.max(NihilStyle.s(52), words.implicitHeight + NihilStyle.s(16))

    Column {
        id: words
        anchors.left: parent.left
        anchors.right: undo.left
        anchors.rightMargin: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter

        NText {
            width: parent.width
            text: Translation.tr(root.option.label)
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textBody
        }
        NText {
            width: parent.width
            visible: root.option.note.length > 0
            text: Translation.tr(root.option.note)
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
    }

    NButton {
        id: undo
        anchors.right: control.left
        anchors.rightMargin: NihilStyle.s(6)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(28)
        height: NihilStyle.s(28)
        icon: "undo"
        iconSize: NihilStyle.s(15)
        opacity: root.changed ? 1 : 0
        enabled: root.changed
        Accessible.name: Translation.tr("Restore the original value")
        onClicked: root.write(root.host.factory(root.option.key))
    }

    Loader {
        id: control
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.option.type === "switch" ? switchControl
            : root.option.type === "level" ? levelControl
            : root.option.type === "screens" ? screensControl
            : root.option.options.length <= 3 ? segmentControl : menuControl
    }

    Component {
        id: switchControl

        NSwitch {
            on: root.value === true
            name: Translation.tr(root.option.label)
            onToggled: root.write(root.value !== true)
        }
    }

    Component {
        id: segmentControl

        NSegmented {
            width: NihilStyle.s(112) * root.option.options.length
            options: root.option.options.map(option => ({ value: option.value, label: Translation.tr(option.label) }))
            current: root.value
            accessibleName: Translation.tr(root.option.label)
            onPicked: value => root.write(value)
        }
    }

    Component {
        id: menuControl

        NButton {
            id: opener
            readonly property var chosen: root.option.options.find(option => option.value === root.value)
            icon: "expand_more"
            label: Translation.tr(opener.chosen?.label ?? String(root.value))
            onClicked: root.host.openMenu(root.option, opener)
        }
    }

    Component {
        id: levelControl

        Row {
            spacing: NihilStyle.s(10)

            NButton {
                visible: root.option.fit !== undefined
                anchors.verticalCenter: parent.verticalCenter
                label: Translation.tr(root.option.fitLabel ?? "")
                lit: root.isFit
                onClicked: root.write(root.isFit ? root.host.levelStart(root.option) : root.option.fit)
            }
            NSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(190)
                enabled: !root.isFit
                opacity: root.isFit ? 0.4 : 1
                from: root.option.from
                to: root.option.to
                stepSize: root.option.step
                value: root.isFit ? root.option.from : Number(root.value)
                name: Translation.tr(root.option.label)
                onMoved: value => root.write(root.stepped(value))
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(64)
                horizontalAlignment: Text.AlignRight
                figures: true
                text: root.figure(Number(root.value))
                color: NihilStyle.inkSoft
            }
        }
    }

    Component {
        id: screensControl

        Row {
            spacing: NihilStyle.s(4)

            Repeater {
                model: Quickshell.screens

                delegate: NButton {
                    id: screenKey
                    required property var modelData
                    readonly property var chosen: Array.from(root.value ?? [])
                    label: screenKey.modelData.name
                    lit: screenKey.chosen.includes(screenKey.modelData.name)
                    onClicked: root.write(screenKey.lit
                        ? screenKey.chosen.filter(name => name !== screenKey.modelData.name)
                        : [...screenKey.chosen, screenKey.modelData.name])
                }
            }
        }
    }
}
