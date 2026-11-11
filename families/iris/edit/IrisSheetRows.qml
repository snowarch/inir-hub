pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.shared.background.widgets
import qs.modules.iris.settings
import qs.modules.iris.widgets.sheet
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A widget's rows from its manifest as lines of Prism's chart in the edit sheet (the host numbers them after its own):
// a switch is the ON/OFF pill, a level the white-fill pill with its figure, a choice the segmented pill (past four, or
// past its room, it folds and lays its chips under the line, or hands them to `fold` where there is no room under it),
// words a field, an action the whole line with its arrow. A kind the chart has no control for (a list of pieces) is
// drawn by Settings' own row. A spec's `caption` is said under its name (the shelf names a group's first line so).
ColumnLayout {
    id: root

    property var specs: []
    property int firstNumber: 1
    // Set by a host with no room under a line (the edit shelf): a folded choice's chips open there instead.
    property var fold: null
    readonly property var lines: {
        Config.revision
        const shown = root.specs.filter(spec => IrisOptions.shown(spec))
        return shown.map((spec, i) => Object.assign({ modelKey: String(spec.path ?? spec.label), number: root.firstNumber + i,
            last: i === shown.length - 1 }, spec))
    }
    readonly property var drawn: ["switch", "choice", "range", "text", "action"]
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
                    readonly property bool coloured: line.spec.kind === "choice" && (line.spec.choices?.[0]?.colour ?? "").length > 0
                    detail: {
                        Config.revision
                        return line.spec.picks ? DesktopWidgetOptions.captionOf(line.spec) : line.spec.caption ? Translation.tr(String(line.spec.caption)) : ""
                    }
                    onRestore: IrisOptions.restore([line.spec])
                    tappable: line.spec.kind === "action"
                    glyph: line.spec.kind === "action" ? "arrow_forward" : ""
                    onTapped: line.spec.run?.()
                    changed: IrisOptions.modified(line.spec)
                    rule: !line.spec.last || line.open
                    Loader {
                        id: kind
                        active: line.spec.kind !== "action"
                        sourceComponent: line.spec.kind === "switch" ? switchKind : line.spec.kind === "range" ? rangeKind
                            : line.spec.kind === "text" ? textKind : line.coloured ? colourKind : choiceKind
                    }
                    under: Loader {
                        active: line.open && (kind.item?.folded ?? false)
                        visible: active
                        width: parent?.width ?? 0
                        sourceComponent: line.coloured ? swatchesUnder : chipsUnder
                    }
                    Component {
                        id: chipsUnder
                        PrismChips {
                            choices: IrisOptions.choicesOf(line.spec)
                            current: line.value
                            onPicked: value => {
                                IrisOptions.commit(line.spec, value)
                                line.open = false
                            }
                        }
                    }
                    Component {
                        id: swatchesUnder
                        PrismSwatches {
                            chart: true
                            choices: line.spec.choices
                            current: line.value
                            onPicked: value => {
                                IrisOptions.commit(line.spec, value)
                                line.open = false
                            }
                        }
                    }
                    // A colour: the one in use as a disc with its name; its swatches open under the line.
                    Component {
                        id: colourKind
                        Item {
                            id: ink
                            readonly property bool folded: true
                            readonly property var chosen: line.spec.choices.find(choice => String(choice.value).toLowerCase() === String(line.value).toLowerCase()) ?? null
                            implicitWidth: disc.width + PrismTheme.dp(8) + named.implicitWidth
                            implicitHeight: PrismTheme.dp(32)
                            Rectangle {
                                id: disc
                                anchors.verticalCenter: parent.verticalCenter
                                width: PrismTheme.dp(22)
                                height: width
                                radius: width / 2
                                color: String(line.value ?? "").length > 0 ? String(line.value) : "transparent"
                                border.width: 1
                                border.color: Qt.alpha(PrismTheme.ink, 0.28)
                            }
                            PrismText {
                                id: named
                                anchors.left: disc.right
                                anchors.leftMargin: PrismTheme.dp(8)
                                anchors.verticalCenter: parent.verticalCenter
                                text: ink.chosen ? Translation.tr(String(ink.chosen.label)) : String(line.value ?? "")
                                color: PrismTheme.ink2
                                font.pixelSize: PrismTheme.small
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: line.open = !line.open }
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
                            onToggleOpen: {
                                if (root.fold) root.fold(line.spec)
                                else line.open = !line.open
                            }
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
                            // A widget's own option is also previewed on the widget itself: its keys may live in the
                            // screen's record, where a Config preview does not reach it.
                            readonly property var drawer: {
                                const widget = DesktopEditStage.inspected?.widget ?? null
                                return line.spec.widget && widget?.configEntryName === line.spec.widget ? widget : null
                            }
                            onMoved: value => {
                                if (!line.livePath) return
                                IrisOptions.hold(line.spec)
                                Config.previewNestedValue(line.spec.path, value)
                                if (line.spec.widget) level.drawer?.previewValue(String(line.spec.key), value)
                            }
                            onCommitted: value => {
                                const drawer = level.drawer
                                IrisOptions.commit(line.spec, value)
                                drawer?.settlePreview()
                            }
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
