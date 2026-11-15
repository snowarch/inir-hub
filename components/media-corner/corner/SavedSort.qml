import QtQuick
import qs.services
import qs.modules.iris.components
import "../state"

IrisButton {
    id: root
    readonly property var orders: ["title", "added", "activity"]
    readonly property int selected: Math.max(0, orders.indexOf(CornerState.options.savedOrder))
    readonly property var labels: [Translation.tr("Title"), Translation.tr("Date added"), Translation.tr("Recent activity")]
    quiet: true
    text: Translation.tr("Sort saved: %1").arg(labels[selected])
    onClicked: CornerState.set("savedOrder", orders[(selected + 1) % orders.length])
}
