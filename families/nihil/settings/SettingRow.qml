pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One setting, drawn from its line in SettingsModel: the control its type asks for, wired to its key. A value moved
// off its default carries a small key that puts the default back.
NRow {
    id: root

    required property var row
    readonly property string kind: String(root.row.type ?? "switch")
    readonly property string rowKey: String(root.row.key ?? "")
    readonly property bool keyed: root.rowKey.length > 0 && root.kind !== "view" && root.kind !== "action"
    readonly property var stored: root.keyed ? Config.getNestedValue(root.rowKey, root.row.fallback) : undefined
    readonly property bool moved: root.keyed && root.kind !== "switch" && root.stored !== root.row.fallback

    readonly property var options: root.row.optionsFrom === "languages" ? SettingsModel.languages : (root.row.options ?? [])

    function put(value: var): void {
        Config.setNestedValue(root.rowKey, value)
        if (root.row.after) SettingsModel.after(root.row.after, value)
    }

    visible: {
        const when = root.row.when
        return !when || (Config.getNestedValue(when.key, when.fallback) === when.is) !== (when.negate === true)
    }
    label: String(root.row.label ?? "")
    desc: String(root.row.desc ?? "")
    stacked: root.kind === "view" || root.kind === "chips" || root.row.stacked === true
    tappable: root.kind === "switch"
    wordsEndRoom: root.stacked && undo.visible ? undo.width + NihilStyle.s(8) : 0
    onTapped: root.put(!root.stored)

    Item {
        id: holder
        width: parent.width
        // Beside the control on a line of its own; at the end of the words when the control runs the full width.
        readonly property real undoRoom: undo.visible && !root.stacked ? undo.width + NihilStyle.s(8) : 0
        implicitWidth: control.implicitWidth + holder.undoRoom
        implicitHeight: Math.max(control.implicitHeight, undo.visible && !root.stacked ? undo.height : 0)

        NButton {
            id: undo
            visible: root.moved
            x: root.stacked ? parent.width - width : 0
            y: root.stacked ? -(NihilStyle.s(10) + (root.wordsHeight + height) / 2) : (parent.height - height) / 2
            width: NihilStyle.s(28)
            height: NihilStyle.s(28)
            tone: NihilStyle.pieceRaised
            icon: "undo"
            iconSize: NihilStyle.s(15)
            Accessible.role: Accessible.Button
            Accessible.name: Translation.tr("Back to the default")
            onClicked: root.put(root.row.fallback)
        }
        Loader {
            id: control
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - holder.undoRoom
            sourceComponent: root.kind === "switch" ? switchControl
                : root.kind === "choice" ? choiceControl
                : root.kind === "chips" ? chipsControl
                : root.kind === "slider" ? sliderControl
                : root.kind === "field" ? fieldControl
                : root.kind === "time" ? timeControl
                : root.kind === "action" ? actionControl
                : null
            source: root.kind === "view" ? Qt.resolvedUrl("views/" + root.row.view + ".qml") : ""
        }
    }

    Component {
        id: switchControl
        NSwitch { on: Boolean(root.stored); name: root.label; onToggled: root.put(!root.stored) }
    }
    Component {
        id: choiceControl
        NSegmented {
            options: root.options
            current: root.stored
            accessibleName: root.label
            onPicked: value => root.put(value)
        }
    }
    Component {
        id: chipsControl
        NChips {
            // A value set by hand outside the list still shows as what it is.
            options: root.options.some(option => option.value === root.stored) ? root.options
                : root.options.concat([{ value: root.stored, label: String(root.stored) }])
            current: root.stored
            onPicked: value => root.put(value)
        }
    }
    Component {
        id: sliderControl
        Item {
            id: level
            property bool holding: false
            property real heldValue: 0
            readonly property real shownValue: level.holding ? level.heldValue : Number(root.stored)
            implicitWidth: NihilStyle.s(256)
            implicitHeight: NihilStyle.s(26)
            NText {
                id: figure
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(56)
                horizontalAlignment: Text.AlignRight
                figures: true
                text: SettingsModel.format(level.shownValue, root.row.format)
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            NSlider {
                anchors.left: figure.right
                anchors.leftMargin: NihilStyle.s(10)
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                from: root.row.from
                to: root.row.to
                stepSize: root.row.step
                value: Number(root.stored)
                name: root.label
                onMoved: value => {
                    level.holding = true
                    level.heldValue = value
                    Config.previewNestedValue(root.rowKey, value)
                }
                onSeekRequested: value => {
                    level.holding = false
                    root.put(value)
                }
            }
        }
    }
    Component {
        id: fieldControl
        NField {
            value: String(root.stored ?? "")
            placeholder: String(root.row.placeholder ?? "")
            mono: root.row.figures === true || root.row.mono === true
            implicitWidth: NihilStyle.s(250)
            onCommitted: text => root.put(text)
        }
    }
    Component {
        id: timeControl
        NField {
            value: String(root.stored ?? "")
            mono: true
            implicitWidth: NihilStyle.s(92)
            accepts: text => /^([01]\d|2[0-3]):[0-5]\d$/.test(text)
            onCommitted: text => root.put(text)
        }
    }
    Component {
        id: actionControl
        NKey {
            implicitWidth: wordWidth.advanceWidth(String(root.row.actionLabel)) + NihilStyle.s(root.row.glyph ? 62 : 36)
            implicitHeight: NihilStyle.s(38)
            label: String(root.row.actionLabel)
            glyph: String(root.row.glyph ?? "")
            onClicked: SettingsModel.run(root.row.action)
            FontMetrics { id: wordWidth; font.family: NihilStyle.grotesk; font.pixelSize: NihilStyle.textSmall }
        }
    }
}
