pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.settings

// Option rows, grouped as Settings groups them: a caption over a raised plate of rows.
ColumnLayout {
    id: root

    property var specs: []
    // A group's title wears the colour of the area it belongs to; neutral where there is none.
    property color tint: IrisStyle.label
    // The plate under the rows, nested in whatever holds it.
    property real plateRadius: IrisStyle.radiusTile
    readonly property real d: IrisStyle.density
    readonly property var groups: {
        Config.revision
        const out = []
        for (const spec of root.specs) {
            if (!IrisOptions.shown(spec)) continue
            const title = String(spec.group ?? "")
            if (out.length === 0 || out[out.length - 1].title !== title) {
                const occurrence = out.filter(group => group.title === title).length
                out.push({ title: title, modelKey: title + ":" + occurrence, rows: [] })
            }
            out[out.length - 1].rows.push(Object.assign({ modelKey: String(spec.path ?? spec.label) }, spec))
        }
        for (const group of out) root.lay(group)
        return out
    }
    // Many options lie in two columns: one tall strip ran the height of the screen. A row whose answer is a track of
    // pictured choices (three to five, under its name) takes the whole width: in half a plate its names were cut. The
    // row before it then takes the whole width too, so no cell is left empty.
    function wide(spec: var): bool {
        if (spec.kind !== "choice" || spec.cards || spec.tiles === true) return false
        const choices = IrisOptions.choicesOf(spec)
        return choices.length >= 3 && choices.length <= 5 && !choices.some(choice => choice.swatch !== undefined)
            && choices.some(choice => String(choice.glyph ?? "").length > 0)
    }
    function lay(group: var): void {
        const rows = group.rows
        group.columns = root.specs.length > 6 && rows.length > 1 ? 2 : 1
        let column = 0
        let line = 0
        for (let i = 0; i < rows.length; i++) {
            const row = rows[i]
            if (group.columns === 2 && root.wide(row)) {
                if (column === 1) {
                    rows[i - 1].span = 2
                    line++
                }
                row.span = 2
                row.line = line++
                column = 0
            } else {
                row.span = 1
                row.line = line
                column = (column + 1) % group.columns
                if (column === 0) line++
            }
        }
        const lines = column === 0 ? line : line + 1
        for (const row of rows) row.last = row.line === lines - 1
    }

    spacing: Math.round(12 * root.d)

    Repeater {
        model: ScriptModel { objectProp: "modelKey"; values: root.groups }
        ColumnLayout {
            id: group
            required property var modelData
            Layout.fillWidth: true
            spacing: Math.round(6 * root.d)
            IrisText {
                visible: group.modelData.title.length > 0
                Layout.leftMargin: Math.round(12 * root.d)
                text: Translation.tr(group.modelData.title)
                color: root.tint
                font.family: IrisStyle.fontTitle
                font.pixelSize: IrisStyle.typeMeta
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: plate.implicitHeight
                radius: root.plateRadius
                color: IrisStyle.surfaceHigh
                GridLayout {
                    id: plate
                    anchors.left: parent.left
                    anchors.right: parent.right
                    columns: group.modelData.columns
                    rowSpacing: 0
                    columnSpacing: 0
                    Repeater {
                        model: ScriptModel { objectProp: "modelKey"; values: group.modelData.rows }
                        IrisSetting {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.columnSpan: modelData.span
                            // Beside a tall answer (a list of themes) a short row reads from the top with it, not
                            // floating at the middle of the line.
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: plate.width * modelData.span / plate.columns
                            spec: modelData
                            last: modelData.last
                        }
                    }
                }
            }
        }
    }
}
