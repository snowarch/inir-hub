pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.waffle.looks

// A pop-up menu in the family's own: iRiS's, Waffle's or Material's. model: [{ text, iconName, action, danger }].
Item {
    id: root
    property var model: []
    // Open it under anchor; at is where the pointer went down, in the anchor's coordinates.
    function open(anchor: Item, at: point): void {
        const m = loader.item;
        if (!m) return;
        if (InkSkin.waffle) {
            m.entries = root.model;
            m.popup(anchor, at.x, at.y);
            return;
        }
        m.anchorItem = anchor;
        m.model = root.model;
        if (InkSkin.iris) m.pointerAt = at;
        else m.popupAbove = false;
        m.requestOpen();
    }
    Loader { id: loader; sourceComponent: InkSkin.iris ? irisMenu : InkSkin.waffle ? waffleMenu : materialMenu }
    Component { id: irisMenu; IrisDesktopMenu {} }
    Component { id: materialMenu; ContextMenu { closeOnHoverLost: false } }
    Component {
        id: waffleMenu
        WMenu {
            id: menu
            property var entries: []
            Instantiator {
                model: menu.entries
                delegate: Action {
                    required property var modelData
                    text: modelData.text
                    icon.name: InkSkin.fluentName(modelData.iconName ?? "")
                    onTriggered: modelData.action()
                }
                onObjectAdded: (index, object) => menu.insertAction(index, object)
                onObjectRemoved: (index, object) => menu.removeAction(object)
            }
        }
    }
}
