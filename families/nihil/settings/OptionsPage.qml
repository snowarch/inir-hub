pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// A page of options: each section as a numbered rule over its pane of glass.
NScroller {
    id: root

    required property var sections
    required property var host

    spacing: NihilStyle.s(28)
    topPad: NihilStyle.s(8)
    bottomPad: NihilStyle.s(32)
    sidePad: NihilStyle.s(14)

    Repeater {
        model: root.sections

        // A section: its number and name on a rule, the count at its end, then its rows on one pane of glass with a
        // hairline between each.
        delegate: Column {
            id: section
            required property var modelData
            required property int index
            width: root.innerWidth
            spacing: NihilStyle.s(10)

            Item {
                width: section.width
                height: name.height

                NDisplay {
                    id: name
                    text: String(section.index + 1).padStart(2, "0") + "  " + Translation.tr(section.modelData.title)
                    size: NihilStyle.s(26)
                    bloom: 0
                }
                Rectangle {
                    anchors.left: name.right
                    anchors.leftMargin: NihilStyle.s(14)
                    anchors.right: count.left
                    anchors.rightMargin: NihilStyle.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: NihilStyle.hair
                }
                NLabel {
                    id: count
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(section.modelData.rows.length).padStart(2, "0")
                }
            }

            NGlass {
                width: section.width
                height: rows.implicitHeight + NihilStyle.s(8)
                radius: NihilStyle.rCard

                Column {
                    id: rows
                    x: NihilStyle.s(18)
                    y: NihilStyle.s(4)
                    width: parent.width - NihilStyle.s(36)

                    Repeater {
                        model: section.modelData.rows

                        delegate: SettingRow {
                            required property var modelData
                            required property int index
                            width: rows.width
                            option: modelData
                            host: root.host
                            first: index === 0
                        }
                    }
                }
            }
        }
    }
}
