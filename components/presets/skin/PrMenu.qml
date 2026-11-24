import QtQuick
import qs.modules.common.widgets

// A pop-up list under an item. model: [{ text, iconName, action, danger }]. Set model, then open(anchor, at).
Item {
    id: root
    property var model: []
    function open(anchor: Item, at: point): void {
        menu.anchorItem = anchor;
        menu.model = root.model;
        menu.popupAbove = false;
        menu.requestOpen();
    }
    ContextMenu { id: menu; closeOnHoverLost: false }
}
