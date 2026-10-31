import QtQuick
import qs.modules.iris.style

// How every iRiS list scrolls. Declared inside a Flickable, ListView or GridView (Qt hands it to the content item, whose
// parent is the view): the content stops at its ends and gives a little when a scroll runs into one, springing back as
// Qt returns the overshoot; and whatever takes keyboard focus inside the view glides into sight.
Item {
    id: root

    readonly property Flickable flick: root.parent?.parent?.contentItem === root.parent ? root.parent.parent : null
    // How far the content may give at most; Qt's overshoot (up to ~150 px on a fast flick) eases into it.
    readonly property real reach: Math.round(28 * IrisStyle.density)
    readonly property Item focused: root.Window.activeFocusItem
    visible: false

    function give(overshoot: real): real { return -root.reach * Math.tanh(overshoot / (root.reach * 3)) }

    readonly property Translate shift: Translate {
        x: root.flick ? root.give(root.flick.horizontalOvershoot) : 0
        y: root.flick ? root.give(root.flick.verticalOvershoot) : 0
    }

    function reveal(item: Item): void {
        const view = root.flick
        if (!item || !view || !view.visible || view.moving) return
        let up = item
        while (up && up !== view.contentItem) up = up.parent
        if (!up || item === root) return
        // A list that follows its current row (ListView, GridView) brings that row in itself.
        let row = item
        while (row && view.currentItem && row !== view.currentItem) row = row.parent
        if (row && view.currentItem) return
        const at = item.mapToItem(view.contentItem, 0, 0)
        const pad = Math.round(12 * IrisStyle.density)
        const fit = (pos, size, viewSize, origin, contentSize, current) => {
            let next = current
            if (pos - pad < current) next = pos - pad
            else if (pos + size + pad > current + viewSize) next = Math.min(pos - pad, pos + size + pad - viewSize)
            return Math.max(origin, Math.min(origin + Math.max(0, contentSize - viewSize), next))
        }
        const y = view.contentHeight > view.height ? fit(at.y, item.height, view.height, view.originY, view.contentHeight, view.contentY) : view.contentY
        const x = view.contentWidth > view.width ? fit(at.x, item.width, view.width, view.originX, view.contentWidth, view.contentX) : view.contentX
        if (Math.abs(y - view.contentY) < 1 && Math.abs(x - view.contentX) < 1) return
        glideY.to = y
        glideX.to = x
        glide.restart()
    }
    onFocusedChanged: root.reveal(root.focused)

    ParallelAnimation {
        id: glide
        NumberAnimation { id: glideY; target: root.flick; property: "contentY"; duration: IrisStyle.duration(240); easing.type: Easing.OutCubic }
        NumberAnimation { id: glideX; target: root.flick; property: "contentX"; duration: IrisStyle.duration(240); easing.type: Easing.OutCubic }
    }

    // Assigned once by hand: a Binding on contentItem.transform never reaches the item on qs-rs.
    Component.onCompleted: {
        const view = root.flick
        if (!view) return
        view.boundsBehavior = Flickable.DragAndOvershootBounds
        view.boundsMovement = Flickable.StopAtBounds
        const kept = []
        for (let i = 0; i < view.contentItem.transform.length; i++) kept.push(view.contentItem.transform[i])
        view.contentItem.transform = kept.concat([root.shift])
    }
}
