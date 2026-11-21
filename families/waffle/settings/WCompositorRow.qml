pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.waffle.looks

// One row of the compositor pages: a function of the base's vocabulary (CompositorRows) drawn as Windows' own
// setting card: a switch says On or Off, a number steps, a choice drops down, a name is typed. It writes only a value
// that differs from what the compositor holds, so a row settling on its value never touches the person's file.
Item {
    id: row

    required property var modelData
    readonly property var spec: row.modelData
    readonly property var now: { CompositorConfig.revision; return CompositorConfig.value(row.spec) }
    // A fraction is shown as a percentage: the stepper counts whole steps.
    readonly property real factor: Number(row.spec.scale ?? (Number(row.spec.step ?? 1) < 1 ? 100 : 1))
    readonly property var picks: {
        CompositorConfig.revision
        if (row.spec.kind !== "choice") return []
        const own = (row.spec.choices ?? []).length > 0
        const found = own ? row.spec.choices : (row.spec.comp === "display" ? CompositorConfig.displayChoices(row.spec.key)
            : row.spec.choicesFrom === "cursors" ? CompositorConfig.cursorThemes.map(name => ({ label: name, value: name }))
            : CompositorConfig.choicesFor(row.spec))
        return found.map(pick => ({ displayName: own ? pick.label : Translation.tr(String(pick.label)), value: pick.value }))
    }

    // WSettingsCard lays this out as one of its rows and tells it whether it sits in an expander.
    readonly property string settingsCardRole: "row"
    property string cardStyle: "card"

    Layout.fillWidth: true
    implicitHeight: face.item?.implicitHeight ?? 0

    Loader {
        id: face
        width: row.width
        sourceComponent: row.spec.kind === "switch" ? switchRow : row.spec.kind === "range" ? rangeRow
            : row.spec.kind === "text" ? textRow : choiceRow
    }

    Component {
        id: switchRow
        WSettingsSwitch {
            label: row.spec.label
            description: row.spec.description ?? ""
            cardStyle: row.cardStyle
            checked: row.now === true
            onToggled: checked => { if (checked !== (row.now === true)) CompositorConfig.set(row.spec, checked) }
        }
    }
    Component {
        id: rangeRow
        WSettingsSpinBox {
            id: stepper
            label: row.spec.label
            description: row.spec.description ?? ""
            cardStyle: row.cardStyle
            suffix: row.factor === 100 ? " %" : String(row.spec.unit ?? "")
            from: Math.round(Number(row.spec.min ?? 0) * row.factor)
            to: Math.round(Number(row.spec.max ?? 100) * row.factor)
            stepSize: Math.max(1, Math.round(Number(row.spec.step ?? 1) * row.factor))
            readonly property int held: Math.round(Number(row.now ?? row.spec.fallback ?? 0) * row.factor)
            Binding { target: stepper; property: "value"; value: stepper.held }
            onValueChanged: if (stepper.value !== stepper.held) CompositorConfig.set(row.spec, row.factor === 1 ? stepper.value : stepper.value / row.factor)
        }
    }
    Component {
        id: textRow
        WSettingsTextField {
            label: row.spec.label
            description: row.spec.description ?? ""
            cardStyle: row.cardStyle
            text: String(row.now ?? "")
            onEditingFinished: newText => { if (newText.trim() !== String(row.now ?? "")) CompositorConfig.set(row.spec, newText.trim()) }
        }
    }
    Component {
        id: choiceRow
        WSettingsDropdown {
            label: row.spec.label
            description: row.spec.description ?? ""
            cardStyle: row.cardStyle
            options: row.picks
            // Values come back as numbers or text: the one shown is the pick that reads the same.
            currentValue: row.picks.find(pick => String(pick.value) === String(row.now))?.value ?? row.now
            onSelected: newValue => { if (String(newValue) !== String(row.now)) CompositorConfig.set(row.spec, newValue) }
        }
    }
}
