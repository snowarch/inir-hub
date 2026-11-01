pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style

// What an app window holds in a scene: its title bar and a page, in blocks of one ink. A wide one gets a sidebar.
Item {
    id: page
    property color ink: IrisStyle.fillActive
    property real inkOpacity: 1
    // Room a border takes from the window.
    property real inset: 0
    readonly property real d: IrisStyle.density
    readonly property real pad: Math.round(14 * page.d) + page.inset
    readonly property real barHeight: Math.round(20 * page.d)
    readonly property bool sided: page.width >= Math.round(220 * page.d)
    readonly property real contentX: page.sided ? page.pad + Math.round(page.width * 0.24) + Math.round(16 * page.d) : page.pad
    readonly property real contentWidth: page.width - page.contentX - page.pad
    readonly property real bodyY: page.pad + page.barHeight + Math.round(4 * page.d)
    readonly property real bodyRoom: page.height - page.bodyY - page.pad
    readonly property real lineGap: Math.round(9 * page.d)
    readonly property real lineHeight: Math.round(6 * page.d)
    readonly property real headRoom: Math.round(10 * page.d) + page.lineGap
    readonly property real cardsRoom: Math.round(44 * page.d) + page.lineGap
    readonly property bool showsCards: page.bodyRoom - page.headRoom - 3 * (page.lineHeight + page.lineGap) >= page.cardsRoom

    // Only whole lines: a window short of room shows fewer, never one cut by its edge.
    function lines(widths, room) {
        return widths.slice(0, Math.max(0, Math.floor((room + page.lineGap) / (page.lineHeight + page.lineGap))))
    }

    component Block: Rectangle {
        radius: IrisStyle.capsule(height)
        color: page.ink
        opacity: page.inkOpacity
    }

    Row {
        x: page.pad
        y: page.pad
        spacing: Math.round(6 * page.d)
        Repeater {
            model: 3
            Block { width: Math.round(8 * page.d); height: width }
        }
    }
    Column {
        visible: page.sided
        x: page.pad
        y: page.bodyY
        spacing: page.lineGap
        Repeater {
            model: page.lines([0.9, 0.7, 0.8, 0.55, 0.65], page.bodyRoom)
            Block {
                required property real modelData
                width: Math.round(page.width * 0.24 * modelData)
                height: page.lineHeight
            }
        }
    }
    Column {
        x: page.contentX
        y: page.bodyY
        spacing: page.lineGap
        Block { width: Math.round(page.contentWidth * 0.48); height: Math.round(10 * page.d) }
        Repeater {
            model: page.lines([0.94, 0.8, 0.62], page.bodyRoom - page.headRoom)
            Block {
                required property real modelData
                width: Math.round(page.contentWidth * modelData)
                height: page.lineHeight
            }
        }
        Row {
            visible: page.showsCards
            spacing: Math.round(8 * page.d)
            topPadding: Math.round(4 * page.d)
            Repeater {
                model: 2
                Rectangle {
                    width: Math.round((page.contentWidth - 8 * page.d) / 2)
                    height: Math.round(40 * page.d)
                    radius: IrisStyle.radiusChip
                    color: page.ink
                    opacity: page.inkOpacity * 0.7
                }
            }
        }
    }
}
