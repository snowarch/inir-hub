pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.nihil.style

// A section of a page: its rows, live.
NSection {
    id: root

    required property var section
    readonly property string sectionKey: String(root.section.key ?? root.section.title ?? "")

    title: String(root.section.title ?? "")

    Repeater {
        model: root.section.rows
        SettingRow {
            required property var modelData
            row: modelData
            width: root.width - NihilStyle.sectionPad * 2
        }
    }
}
