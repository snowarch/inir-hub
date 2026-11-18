pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// NiHiL's menu: one block over its bar key. The name on paper, the signal's mode, a tile to each page; a page shows its
// rows in the same block, its name on the paper and the key beside it going back.
NPopup {
    id: root

    open: NihilState.menuOpen
    namespace: "nihil:menu"
    onDismissed: NihilState.menuOpen = false
    onOpenChanged: if (root.open) root.page = ""

    property string page: ""
    readonly property real wide: NihilStyle.s(336)
    readonly property real g: NihilStyle.seam
    readonly property bool dynamic: NihilStyle.dynamic
    readonly property var pages: [
        { id: "widgets", label: Translation.tr("Widgets"), glyph: "widgets" },
        { id: "menus", label: Translation.tr("Menus"), glyph: "tune" },
        { id: "wallpapers", label: Translation.tr("Wallpapers"), glyph: "image" },
        { id: "extras", label: Translation.tr("Extras"), glyph: "settings" },
        { id: "about", label: Translation.tr("About"), glyph: "info" }
    ]

    NRack {
        width: root.wide
        height: body.implicitHeight
        x: NihilStyle.edge + NihilStyle.button + root.g
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        Column {
            id: body
            spacing: root.g

            Row {
                spacing: root.g
                NTile {
                    id: head
                    width: root.wide - back.width - root.g
                    height: NihilStyle.s(88)
                    paper: true
                    caption: root.page.length > 0 ? "NiHiL" : Translation.tr("Menu")
                    NFigure {
                        x: head.pad
                        width: head.width - head.pad * 2
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: NihilStyle.s(4)
                        size: NihilStyle.s(40)
                        text: root.page.length > 0 ? (root.pages.find(entry => entry.id === root.page)?.label ?? "") : "NiHiL"
                        elide: Text.ElideRight
                        color: head.ink
                    }
                }
                NButton {
                    id: back
                    width: NihilStyle.s(64); height: head.height
                    square: true
                    icon: root.page.length > 0 ? "arrow_back" : "close"
                    iconSize: NihilStyle.s(26)
                    onClicked: root.page.length > 0 ? root.page = "" : NihilState.menuOpen = false
                }
            }

            NButton {
                id: signal
                visible: root.page.length === 0
                width: root.wide
                height: NihilStyle.s(56)
                square: true
                onClicked: Config.setNestedValue("nihil.theme.accent", root.dynamic ? "signal" : "dynamic")
                Rectangle {
                    x: NihilStyle.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(24); height: width
                    radius: NihilStyle.s(6)
                    color: NihilStyle.accent
                }
                NText {
                    x: NihilStyle.s(50)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Signal colour")
                    font.pixelSize: NihilStyle.s(16)
                    font.weight: Font.Black
                }
                NCaps {
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(14)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dynamic ? Translation.tr("Dynamic") : Translation.tr("Signal")
                    color: NihilStyle.inkSoft
                }
            }

            Repeater {
                model: root.page.length === 0 ? root.pages : []
                delegate: NButton {
                    id: entry
                    required property var modelData
                    width: root.wide
                    height: NihilStyle.s(56)
                    square: true
                    onClicked: root.page = entry.modelData.id
                    NIcon {
                        x: NihilStyle.s(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.glyph
                        size: NihilStyle.s(24)
                        color: entry.ink
                    }
                    NText {
                        x: NihilStyle.s(50)
                        anchors.verticalCenter: parent.verticalCenter
                        text: entry.modelData.label
                        font.pixelSize: NihilStyle.s(16)
                        font.weight: Font.Black
                    }
                    NIcon {
                        anchors.right: parent.right
                        anchors.rightMargin: NihilStyle.s(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: "chevron_right"
                        size: NihilStyle.s(20)
                        color: NihilStyle.inkSoft
                    }
                }
            }

            MenuPages {
                visible: root.page.length > 0
                page: root.page
                w: root.wide
            }
        }
    }
}
