pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.nihil.style

// Every key combination the compositor knows, with a field to find one.
Column {
    id: root

    property string filter: ""
    readonly property var source: CompositorService.isNiri ? NiriKeybinds.keybinds : HyprlandKeybinds.keybinds
    readonly property var groups: {
        const words = root.filter.trim().toLowerCase()
        return (root.source?.children ?? []).map(group => ({
            name: group.name,
            binds: (group.children?.[0]?.keybinds ?? []).filter(bind => words.length === 0
                || String(bind.comment ?? "").toLowerCase().includes(words)
                || String(bind.key ?? "").toLowerCase().includes(words)
                || (bind.mods ?? []).some(mod => String(mod).toLowerCase().includes(words)))
        })).filter(group => group.binds.length > 0)
    }

    spacing: NihilStyle.s(14)

    NField {
        width: root.width
        glyph: "search"
        placeholder: Translation.tr("Find a shortcut")
        clearable: true
        onEdited: text => root.filter = text
    }
    NEmpty {
        visible: root.groups.length === 0
        width: root.width
        glyph: "keyboard"
        title: root.filter.length > 0 ? Translation.tr("No shortcut matches") : Translation.tr("No shortcuts found")
    }
    Repeater {
        model: root.groups
        Column {
            id: group
            required property var modelData
            width: root.width
            spacing: NihilStyle.s(4)
            NText {
                mono: true
                text: String(group.modelData.name).toUpperCase()
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
                bottomPadding: NihilStyle.s(4)
            }
            Repeater {
                model: group.modelData.binds
                Item {
                    id: bind
                    required property var modelData
                    readonly property var caps: (bind.modelData.mods ?? []).concat([bind.modelData.key]).filter(cap => !!cap)
                    width: group.width
                    height: NihilStyle.s(36)
                    NText {
                        anchors.left: parent.left
                        anchors.right: capsRow.left
                        anchors.rightMargin: NihilStyle.s(10)
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(bind.modelData.comment ?? "")
                    }
                    Row {
                        id: capsRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: NihilStyle.s(4)
                        Repeater {
                            model: bind.caps
                            Rectangle {
                                id: cap
                                required property var modelData
                                width: Math.max(height, capWord.implicitWidth + NihilStyle.s(14))
                                height: NihilStyle.s(26)
                                radius: NihilStyle.s(8 * NihilStyle.corners)
                                color: NihilStyle.pieceRaised
                                NText {
                                    id: capWord
                                    anchors.centerIn: parent
                                    mono: true
                                    text: String(cap.modelData)
                                    font.pixelSize: NihilStyle.textSmall
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
