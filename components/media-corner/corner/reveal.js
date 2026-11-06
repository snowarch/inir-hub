.pragma library

// Scrolls every Flickable around `item` just enough to show it, for the keyboard landing on something out of view.
function reveal(item) {
    for (let view = item.parent; view; view = view.parent) {
        if (view.contentItem === undefined || view.contentY === undefined) continue
        const at = item.mapToItem(view.contentItem, 0, 0)
        if (view.contentHeight > view.height) view.contentY = Math.max(0, Math.min(view.contentHeight - view.height,
            Math.min(at.y, Math.max(view.contentY, at.y + item.height - view.height))))
        if (view.contentWidth > view.width) view.contentX = Math.max(0, Math.min(view.contentWidth - view.width,
            Math.min(at.x, Math.max(view.contentX, at.x + item.width - view.width))))
    }
}
