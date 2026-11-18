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
    property bool first: false

    // A compositor row reads and writes the compositor's own setting, for Niri and Umbriel alike.
    readonly property var compositorSpec: root.option.type === "compositor"
        ? CompositorRows.rows.find(row => row.comp === root.option.comp && row.key === root.option.key) ?? null : null
    readonly property var value: root.compositorSpec ? CompositorConfig.value(root.compositorSpec) : root.host.read(root.option.key)
    readonly property var factoryValue: root.compositorSpec ? (CompositorConfig.factory(root.compositorSpec) ?? root.compositorSpec.fallback)
        : root.host.factory(root.option.key)
    readonly property bool changed: JSON.stringify(root.value) !== JSON.stringify(root.factoryValue)
    readonly property bool isFit: root.option.fit !== undefined && root.value === root.option.fit

    function write(value: var): void {
        if (root.compositorSpec) CompositorConfig.set(root.compositorSpec, value)
        else root.host.write(root.option.key, value)
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

    implicitHeight: Math.max(NihilStyle.s(56), words.implicitHeight + NihilStyle.s(20))

    Rectangle {
        visible: !root.first
        width: parent.width
        height: 1
        color: NihilStyle.line
    }
    HoverHandler { id: hover }
    // Changed from how NiHiL came: a short line of light at the row's edge.
    NSpectrum {
        visible: root.changed
        vertical: true
        x: -NihilStyle.s(18)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(2)
        height: parent.height - NihilStyle.s(24)
    }

    Column {
        id: words
        anchors.left: parent.left
        anchors.right: undo.left
        anchors.rightMargin: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter

        spacing: NihilStyle.s(2)

        NText {
            width: parent.width
            text: Translation.tr(root.option.label)
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textBody
            font.weight: Font.Medium
            color: hover.hovered ? NihilStyle.ink : Qt.alpha(NihilStyle.ink, 0.88)
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
        onClicked: root.write(root.factoryValue)
    }

    Loader {
        id: control
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: root.option.type === "switch" ? switchControl
            : root.option.type === "level" || (root.compositorSpec?.kind === "range") ? levelControl
            : root.compositorSpec?.kind === "switch" ? switchControl
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
            NDisplay {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(72)
                horizontalAlignment: Text.AlignRight
                text: root.figure(Number(root.value))
                size: NihilStyle.s(20)
                bloom: 0
                color: root.changed ? NihilStyle.ink : NihilStyle.inkSoft
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
