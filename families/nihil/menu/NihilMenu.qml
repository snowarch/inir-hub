pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// NiHiL's menu (its Settings): one piece at the screen's right. Its name in dots and the signal's mode lit under it
// (a tap switches Signal and Dynamic), five raised pills to its pages, the lit close key at its foot. A page shows its
// rows in the same piece with a back key.
NPopup {
    id: root

    open: NihilState.menuOpen
    namespace: "nihil:menu"
    onDismissed: NihilState.menuOpen = false
    onOpenChanged: if (root.open) root.page = ""

    property string page: ""
    readonly property real w: NihilStyle.s(290)
    readonly property bool dynamic: NihilStyle.dynamic
    readonly property var pages: [
        { id: "widgets", label: Translation.tr("Widgets") },
        { id: "menus", label: Translation.tr("Menus") },
        { id: "wallpapers", label: Translation.tr("Wallpapers") },
        { id: "extras", label: Translation.tr("Extras") },
        { id: "about", label: Translation.tr("About") }
    ]

    NCard {
        id: card
        pad: NihilStyle.s(14)
        width: root.w + pad * 2
        height: body.height + pad * 2
        x: parent.width - width - NihilStyle.s(120)
        y: Math.round((parent.height - root.edgeTop - root.edgeBottom - height) / 2) + root.edgeTop
        Behavior on height { NumberAnimation { duration: NihilStyle.calm; easing.type: Easing.OutCubic } }

        Column {
            id: body
            width: root.w
            spacing: NihilStyle.s(12)

            Item { width: 1; height: NihilStyle.s(4) }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.page.length > 0 ? (root.pages.find(p => p.id === root.page)?.label ?? "") : "NIHIL"
                dot: NihilStyle.s(4.2)
                spacing: NihilStyle.s(2.4)
                fitWidth: root.w - NihilStyle.s(20)
            }
            DotText {
                id: mode
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.page.length === 0
                text: root.dynamic ? "DYNAMIC" : "SIGNAL"
                color: NihilStyle.accent
                dot: NihilStyle.s(2.8)
                spacing: NihilStyle.s(1.7)
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -NihilStyle.s(6)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.setNestedValue("nihil.theme.accent", root.dynamic ? "signal" : "dynamic")
                }
            }
            Item { width: 1; height: NihilStyle.s(2) }

            Column {
                visible: root.page.length === 0
                spacing: NihilStyle.s(12)
                Repeater {
                    model: root.pages
                    delegate: NButton {
                        id: pill
                        required property var modelData
                        width: root.w
                        height: NihilStyle.s(64)
                        radius: NihilStyle.s(18)
                        tone: NihilStyle.pieceRaised
                        onClicked: root.page = pill.modelData.id
                        NText {
                            anchors.centerIn: parent
                            text: pill.modelData.label
                            font.pixelSize: NihilStyle.s(24)
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            MenuPages {
                visible: root.page.length > 0
                page: root.page
                w: root.w
            }

            Item { width: 1; height: NihilStyle.s(2) }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: NihilStyle.s(12)
                NButton {
                    visible: root.page.length > 0
                    width: NihilStyle.s(44); height: width
                    tone: NihilStyle.pieceRaised
                    icon: "arrow_back"
                    iconSize: NihilStyle.s(22)
                    onClicked: root.page = ""
                }
                NButton {
                    width: NihilStyle.s(44); height: width
                    lit: true
                    icon: "close"
                    iconSize: NihilStyle.s(24)
                    onClicked: NihilState.menuOpen = false
                }
            }
        }
    }
}
