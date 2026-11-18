pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// A page of options: each section's name over its pane of glass.
NScroller {
    id: root

    required property var sections
    required property var host

    spacing: NihilStyle.s(22)
    topPad: NihilStyle.s(8)
    bottomPad: NihilStyle.s(32)
    sidePad: NihilStyle.s(14)

    Repeater {
        model: root.sections

        delegate: Column {
            id: section
            required property var modelData
            width: root.innerWidth
            spacing: NihilStyle.s(8)

            NText {
                x: NihilStyle.s(6)
                text: Translation.tr(section.modelData.title)
                font.pixelSize: NihilStyle.textLarge
                font.weight: Font.Medium
            }

            NGlass {
                width: section.width
                height: rows.implicitHeight + NihilStyle.s(12)
                radius: NihilStyle.rCard

                Column {
                    id: rows
                    x: NihilStyle.s(16)
                    y: NihilStyle.s(6)
                    width: parent.width - NihilStyle.s(32)

                    Repeater {
                        model: section.modelData.rows

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
