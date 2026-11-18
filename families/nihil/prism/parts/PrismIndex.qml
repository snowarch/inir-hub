pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.nihil.prism.core
import qs.modules.nihil.prism.model
import qs.modules.nihil.prism.controls

// Home's index (Technical Minimalism, his 11-17): every page of Settings as a drawing's table of contents, chapter by
// chapter, each page numbered, a count where something differs from the factory; a press opens it. The chapters stand
// in balanced columns, in reading order.
Item {
    id: root
    readonly property real colGap: PrismTheme.dp(28)
    readonly property int columns: Math.max(2, Math.min(4, Math.floor((root.width + root.colGap) / (PrismTheme.dp(190) + root.colGap))))
    readonly property real colWidth: Math.floor((root.width - root.colGap * (root.columns - 1)) / root.columns)
    readonly property real rowHeight: PrismTheme.dp(30)
    readonly property real cap: PrismTheme.dp(9.5)

    readonly property var chapters: PrismModel.groups.filter(group => group.length > 0)
        .map((group, i) => ({ title: group, n: i + 1, pages: PrismModel.inGroup(group) }))
        .filter(chapter => chapter.pages.length > 0)
    // Chapters in order, each to the column standing shortest when its turn comes (heights in rows).
    readonly property var laid: {
        const cols = Array.from({ length: root.columns }, () => ({ rows: 0, chapters: [] }))
        const per = Math.ceil(root.chapters.reduce((sum, c) => sum + c.pages.length + 2, 0) / root.columns)
        let at = 0
        for (const chapter of root.chapters) {
            if (cols[at].rows > 0 && cols[at].rows + chapter.pages.length + 2 > per + 2 && at < root.columns - 1) at += 1
            cols[at].chapters.push(chapter)
            cols[at].rows += chapter.pages.length + 2
        }
        return cols
    }

    implicitHeight: head.height + PrismTheme.dp(14) + Math.max(0, ...root.laid.map(col => col.rows)) * root.rowHeight

    component Caption: PrismText {
        mono: true
        color: PrismTheme.ink3
        font.pixelSize: root.cap
        font.letterSpacing: root.cap * 0.1
    }

    Item {
        id: head
        width: root.width
        height: PrismTheme.dp(28)
        Caption { anchors.verticalCenter: parent.verticalCenter; text: Translation.tr("Index").toUpperCase() }
        Caption {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr("%1 pages").arg(root.chapters.reduce((sum, c) => sum + c.pages.length, 0)).toUpperCase()
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: PrismTheme.line }
    }

    Row {
        y: head.height + PrismTheme.dp(14)
        spacing: root.colGap
        Repeater {
            model: root.laid
            delegate: Column {
                id: col
                required property var modelData
                width: root.colWidth
                Repeater {
                    model: col.modelData.chapters
                    delegate: Column {
                        id: chapter
                        required property var modelData
                        width: root.colWidth
                        Item {
                            width: parent.width
                            height: root.rowHeight
                            Caption {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(chapter.modelData.n).padStart(2, "0") + "  " + Translation.tr(chapter.modelData.title).toUpperCase()
                                color: PrismTheme.ink2
                            }
                        }
                        Repeater {
                            model: chapter.modelData.pages
                            delegate: Item {
                                id: page
                                required property var modelData
                                required property int index
                                readonly property int changed: { const _ = PrismModel.revision; return PrismModel.changedOf(page.modelData.pageId).length }
                                width: root.colWidth
                                height: root.rowHeight
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.leftMargin: -PrismTheme.dp(8)
                                    anchors.rightMargin: -PrismTheme.dp(8)
                                    radius: 0
                                    color: hit.containsMouse ? PrismTheme.fill : "transparent"
                                }
                                Caption {
                                    id: number
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: PrismTheme.dp(34)
                                    text: String(chapter.modelData.n).padStart(2, "0") + "." + String(page.index + 1)
                                }
                                PrismText {
                                    anchors.left: number.right
                                    anchors.right: count.left
                                    anchors.rightMargin: PrismTheme.dp(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Translation.tr(String(page.modelData.name))
                                    color: hit.containsMouse ? PrismTheme.ink : PrismTheme.inkNav
                                    font.pixelSize: PrismTheme.body
                                }
                                Caption {
                                    id: count
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: page.changed > 0
                                    text: String(page.changed).padStart(2, "0")
                                    color: PrismTheme.mark
                                }
                                MouseArea {
                                    id: hit
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    Accessible.role: Accessible.Link
                                    Accessible.name: Translation.tr(String(page.modelData.name))
                                    onClicked: PrismState.go(page.modelData.pageId)
                                }
                            }
                        }
                        Item { width: 1; height: root.rowHeight }
                    }
                }
            }
        }
    }
}
