pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.nihil.style

// A page of options: each section's name over a place pressed into the sheet. A section may be a whole group of the compositor's
// settings, as Niri or Umbriel can do them now; the screen's section also picks which screen it sets.
NScroller {
    id: root

    required property var sections
    required property var host
    // Appearance opens with the wallpaper and its lights, which stand in for the accent's row. Search still finds that row.
    property bool leadsWithLight: false

    // The screen's scale is the compositor's, though no group lists it.
    readonly property var scaleSpec: ({ comp: "display", key: "scale", kind: "choice", label: Translation.tr("Scale"), fallback: 1 })

    spacing: NihilStyle.s(26)
    bottomPad: NihilStyle.s(32)

    Loader {
        active: root.leadsWithLight
        visible: active
        width: root.innerWidth
        sourceComponent: AppearanceHero {
            host: root.host
        }
    }

    Repeater {
        model: root.sections

        // A section: its name, then its rows pressed into the sheet together.
        delegate: Column {
            id: section
            required property var modelData
            readonly property bool screens: section.modelData.screenPicker === true
            readonly property var rows: {
                CompositorConfig.revision
                let rows = []
                if (section.screens && CompositorConfig.has("display", "scale")) rows.push({ type: "compositor", spec: root.scaleSpec })
                if (section.modelData.group) rows = rows.concat(CompositorRows.of(section.modelData.group).map(spec => ({ type: "compositor", spec: spec })))
                return rows.concat(section.modelData.rows)
                    .filter(row => root.host.shown(row) && !(root.leadsWithLight && row.key === "look.accent"))
            }
            visible: section.rows.length > 0
            width: root.innerWidth
            spacing: NihilStyle.s(10)

            NText {
                x: NihilStyle.s(18)
                text: Translation.tr(section.modelData.title)
                font.pixelSize: NihilStyle.textSmall
                font.weight: Font.DemiBold
                color: NihilStyle.textSecondary
            }

            // Which screen the rows below set, with more than one.
            Row {
                visible: section.screens && CompositorConfig.outputs.length > 1
                spacing: NihilStyle.s(6)
                Repeater {
                    model: section.screens ? CompositorConfig.outputs : []
                    delegate: NButton {
                        required property var modelData
                        label: CompositorConfig.screenName(modelData)
                        highlighted: CompositorConfig.output?.name === modelData.name
                        onClicked: CompositorConfig.applyDisplay("screen", modelData.name)
                    }
                }
            }

            // A screen change that may have left nothing to see goes back by itself unless it is kept.
            NInset {
                visible: section.screens && CompositorConfig.pending !== null
                width: section.width
                height: NihilStyle.s(62)
                radius: NihilStyle.r(22)
                highlighted: 0.7
                NText {
                    x: NihilStyle.s(20)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - keep.width - revert.width - NihilStyle.s(40)
                    text: Translation.tr("Keep this display setting? It goes back in %1 s.").arg(CompositorConfig.secondsLeft)
                    elide: Text.ElideRight
                    font.weight: Font.Medium
                }
                NButton {
                    id: revert
                    anchors.right: keep.left
                    anchors.rightMargin: NihilStyle.s(6)
                    anchors.verticalCenter: parent.verticalCenter
                    label: Translation.tr("Revert")
                    onClicked: CompositorConfig.revertDisplay()
                }
                NButton {
                    id: keep
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(12)
                    anchors.verticalCenter: parent.verticalCenter
                    label: Translation.tr("Keep")
                    highlighted: true
                    onClicked: CompositorConfig.keepDisplay()
                }
            }

            Rectangle {
                width: section.width
                height: rows.implicitHeight
                radius: NihilStyle.r(22)
                color: NihilStyle.fill
                border.width: 1
                border.color: NihilStyle.border

                Column {
                    id: rows
                    x: NihilStyle.s(20)
                    width: parent.width - NihilStyle.s(40)

                    Repeater {
                        model: section.rows

                        delegate: SettingRow {
                            required property var modelData
                            width: rows.width
                            option: modelData
                            host: root.host
                        }
                    }
                }
            }
        }
    }
}
