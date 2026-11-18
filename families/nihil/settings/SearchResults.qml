pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.style

// Every setting that answers the search, grouped by its page and live: it can be changed right here.
NScroller {
    id: root

    required property string query
    readonly property var groups: SettingsModel.search(root.query)
    signal openPage(string key)

    spacing: NihilStyle.s(18)
    topPad: NihilStyle.s(22)
    bottomPad: NihilStyle.s(34)
    sidePad: NihilStyle.s(6)

    NEmpty {
        visible: root.groups.length === 0
        width: root.innerWidth
        glyph: "search_off"
        title: Translation.tr("Nothing called “%1”").arg(root.query.trim())
        line: Translation.tr("Try a shorter word, or what the setting does.")
    }

    Repeater {
        model: root.groups
        Column {
            id: group
            required property var modelData
            width: root.innerWidth
            spacing: NihilStyle.s(8)
            NButton {
                width: pageWord.implicitWidth + NihilStyle.s(46)
                height: NihilStyle.s(32)
                tone: NihilStyle.pieceRaised
                onClicked: root.openPage(group.modelData.page.key)
                NText {
                    id: pageWord
                    x: NihilStyle.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    mono: true
                    text: group.modelData.page.label.toUpperCase()
                    font.pixelSize: NihilStyle.textSmall
                }
                NIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(9)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "arrow_forward"
                    size: NihilStyle.s(15)
                }
            }
            PageSection {
                width: group.width
                section: ({ rows: group.modelData.rows })
            }
        }
    }
}
