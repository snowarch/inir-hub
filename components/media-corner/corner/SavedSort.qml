import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

// How Yours is sorted: a round key beside the saved search that steps through title, date added and recent activity;
// its name says the order in use.
IrisButton {
    id: root
    readonly property var orders: ["title", "added", "activity"]
    readonly property int selected: Math.max(0, orders.indexOf(CornerState.options.savedOrder))
    readonly property var labels: [Translation.tr("Title"), Translation.tr("Date added"), Translation.tr("Recent activity")]
    readonly property var glyphs: ["sort_by_alpha", "calendar_today", "schedule"]
    implicitWidth: Math.round(32 * IrisStyle.density)
    implicitHeight: Math.round(32 * IrisStyle.density)
    buttonRadius: height / 2
    buttonRadiusPressed: height / 2
    colBackground: IrisStyle.fillQuiet
    colBackgroundHover: IrisStyle.fillHover
    Accessible.name: Translation.tr("Sort saved: %1").arg(labels[selected])
    onClicked: CornerState.set("savedOrder", orders[(selected + 1) % orders.length])
    MaterialSymbol { anchors.centerIn: parent; text: root.glyphs[root.selected]; iconSize: Math.round(17 * IrisStyle.density); color: IrisStyle.text }
    StyledToolTip { text: root.Accessible.name; extraVisibleCondition: root.buttonHovered }
}
