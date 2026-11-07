pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.settings
import qs.modules.iris.widgets.sheet
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A widget's rows from its manifest as lines of Prism's chart in the edit sheet (the host numbers them after its own):
// a switch is the ON/OFF pill, a level the white-fill pill with its figure, a choice the segmented pill (past four, or
// past its room, it folds and lays its chips under the line), words a field. A kind the chart has no control for
// (a list of pieces) is drawn by Settings' own row.
ColumnLayout {
    id: root

    property var specs: []
    property int firstNumber: 1
    readonly property var lines: {
        Config.revision
        const shown = root.specs.filter(spec => IrisOptions.shown(spec))
        return shown.map((spec, i) => Object.assign({ modelKey: String(spec.path ?? spec.label), number: root.firstNumber + i,
            last: i === shown.length - 1 }, spec))
    }
    readonly property var drawn: ["switch", "choice", "range", "text"]
    Layout.fillWidth: true
    spacing: 0

    Repeater {
        model: ScriptModel { objectProp: "modelKey"; values: root.lines }
        delegate: Loader {
            id: slot
            required property var modelData
            Layout.fillWidth: true
            sourceComponent: root.drawn.includes(slot.modelData.kind) ? lineKind : settingKind

            Component {
                id: settingKind
                IrisSetting {
                    spec: slot.modelData
                    last: slot.modelData.last
                }
            }
            Component {
                id: lineKind
                SheetLine {
                    id: line
                    readonly property var spec: slot.modelData
                    readonly property var value: {
                        Config.revision
                        return IrisOptions.currentValue(line.spec)
                    }
                    readonly property bool livePath: String(line.spec.path ?? "").length > 0 && !line.spec.bundle
                    property bool open: false
                    number: line.spec.number
                    label: Translation.tr(String(line.spec.label ?? ""))
                    changed: IrisOptions.modified(line.spec)
                    rule: !line.spec.last || line.open
                    Loader {
                        id: kind
                        sourceComponent: line.spec.kind === "switch" ? switchKind : line.spec.kind === "range" ? rangeKind
                            : line.spec.kind === "text" ? textKind : choiceKind
                    }
                    under: Loader {
                        active: line.open && (kind.item?.folded ?? false)
                        visible: active
                        width: parent?.width ?? 0
                        sourceComponent: PrismChips {
                            choices: IrisOptions.choicesOf(line.spec)
                            current: line.value
                            onPicked: value => {
                                IrisOptions.commit(line.spec, value)
                                line.open = false
                            }
                        }
                    }

                    Component {
                        id: switchKind
                        PrismSwitch {
                            checked: line.spec.invert ? !line.value : Boolean(line.value)
                            onToggled: value => IrisOptions.commit(line.spec, line.spec.invert ? !value : value)
                        }
                    }
                    Component {
                        id: choiceKind
                        PrismChoice {
                            choices: IrisOptions.choicesOf(line.spec)
                            current: line.value
                            room: PrismTheme.dp(196)
                            open: line.open
                            onPicked: value => IrisOptions.commit(line.spec, value)
                            onToggleOpen: line.open = !line.open
                        }
                    }
                    Component {
                        id: rangeKind
                        PrismSlider {
                            id: level
                            implicitWidth: PrismTheme.dp(150)
                            from: Number(line.spec.min ?? 0)
                            to: Number(line.spec.max ?? 100)
                            stepSize: Number(line.spec.step ?? 1)
                            value: Number(line.value)
                            glyph: String(line.spec.glyph ?? "")
                            label: IrisOptions.rangeText(line.spec, level.live)
                            onMoved: value => {
                                if (!line.livePath) return
                                IrisOptions.hold(line.spec)
                                Config.previewNestedValue(line.spec.path, value)
                            }
                            onCommitted: value => IrisOptions.commit(line.spec, value)
                        }
                    }
                    Component {
                        id: textKind
                        PrismField {
                            implicitWidth: PrismTheme.dp(150)
                            text: String(line.value ?? "")
                            placeholder: String(line.spec.placeholder ?? "")
                            onCommitted: text => IrisOptions.commit(line.spec, text.trim())
                        }
                    }
                }
            }
        }
    }
}
