pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit

// One row of the compositor page: a function of the base's vocabulary drawn with Material's own controls.
ColumnLayout {
    id: row

    required property var modelData
    readonly property var spec: row.modelData
    readonly property var now: { CompositorConfig.revision; return CompositorConfig.value(row.spec) }
    // A fraction is shown as a percentage: Material's stepper counts whole steps.
    readonly property real factor: Number(row.spec.scale ?? (Number(row.spec.step ?? 1) < 1 ? 100 : 1))
    readonly property var picks: {
        CompositorConfig.revision
        if (row.spec.kind !== "choice") return []
        const own = (row.spec.choices ?? []).length > 0
        const found = own ? row.spec.choices : (row.spec.comp === "display" ? CompositorConfig.displayChoices(row.spec.key)
            : row.spec.choicesFrom === "cursors" ? CompositorConfig.cursorThemes.map(name => ({ label: name, value: name }))
            : CompositorConfig.choicesFor(row.spec))
        return found.map(pick => ({ displayName: own ? pick.label : Translation.tr(String(pick.label)), value: pick.value, icon: pick.glyph ?? "" }))
    }

    Layout.fillWidth: true
    spacing: 0

    Loader {
        Layout.fillWidth: true
        sourceComponent: row.spec.kind === "switch" ? switchRow : row.spec.kind === "range" ? rangeRow
            : row.spec.kind === "text" ? textRow : row.picks.length > 5 ? listRow : choiceRow
    }

    Component {
        id: switchRow
        ConfigSwitch {
            id: flip
            text: row.spec.label
            description: row.spec.description ?? ""
            Binding { target: flip; property: "checked"; value: row.now === true }
            onCheckedChanged: if (flip.checked !== (row.now === true)) CompositorConfig.set(row.spec, flip.checked)
        }
    }
    Component {
        id: rangeRow
        ConfigSpinBox {
            id: stepper
            text: row.spec.label
            description: row.spec.description ?? ""
            unit: row.factor === 100 ? "%" : String(row.spec.unit ?? "").trim()
            from: Math.round(Number(row.spec.min ?? 0) * row.factor)
            to: Math.round(Number(row.spec.max ?? 100) * row.factor)
            stepSize: Math.max(1, Math.round(Number(row.spec.step ?? 1) * row.factor))
            Binding { target: stepper; property: "value"; value: Math.round(Number(row.now ?? row.spec.fallback ?? 0) * row.factor) }
            onValueModified: CompositorConfig.set(row.spec, row.factor === 1 ? stepper.value : Math.round(stepper.value) / row.factor)
        }
    }
    Component {
        id: textRow
        ContentSubsection {
            title: row.spec.label
            tooltip: row.spec.description ?? ""
            MaterialTextField {
                id: field
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurface
                text: String(row.now ?? "")
                background: Rectangle {
                    color: Appearance.colors.colLayer1
                    radius: Appearance.rounding.small
                    border.width: field.activeFocus ? 2 : 1
                    border.color: field.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colLayer0Border
                }
                onEditingFinished: if (text.trim() !== String(row.now ?? "")) CompositorConfig.set(row.spec, text.trim())
            }
        }
    }
    Component {
        id: choiceRow
        ContentSubsection {
            title: row.spec.label
            tooltip: row.spec.description ?? ""
            ConfigSelectionArray {
                options: row.picks
                currentValue: row.now
                onSelected: newValue => CompositorConfig.set(row.spec, newValue)
            }
        }
    }
    Component {
        id: listRow
        ContentSubsection {
            title: row.spec.label
            tooltip: row.spec.description ?? ""
            StyledComboBox {
                id: combo
                Layout.fillWidth: true
                model: row.picks
                textRole: "displayName"
                Binding { target: combo; property: "currentIndex"; value: Math.max(0, row.picks.findIndex(pick => String(pick.value) === String(row.now))) }
                onActivated: index => CompositorConfig.set(row.spec, row.picks[index].value)
            }
        }
    }
}
