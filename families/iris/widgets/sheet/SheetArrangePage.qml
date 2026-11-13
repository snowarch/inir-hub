pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The sheet's Arrange page: where it stands (the nine places of the screen as keys, or free, or the quietest spot),
// the stack it can join, then the lock and what can be done to it as the chart's last lines.
ColumnLayout {
    id: page
    required property var controls
    // The stack it can join, drawn by the host (the stack's own controls live beside the sheet).
    property Component joinControls: null
    readonly property var widget: page.controls.widget
    Layout.fillWidth: true
    Layout.fillHeight: false
    Layout.alignment: Qt.AlignTop
    spacing: PrismTheme.dp(18)

    readonly property var zoneGlyphs: ({ topLeft: "north_west", topCenter: "north", topRight: "north_east",
        centerLeft: "west", center: "filter_center_focus", centerRight: "east",
        bottomLeft: "south_west", bottomCenter: "south", bottomRight: "south_east" })
    readonly property string strategy: page.widget.placementStrategy

    component Choice: Item {
        id: choice
        property bool chosen: false
        property string glyph: ""
        property string label: ""
        signal picked()
        Layout.fillWidth: true
        implicitHeight: PrismTheme.dp(34)
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: choice.chosen ? PrismTheme.solid : choiceArea.pressed ? PrismTheme.fillPress : choiceArea.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        }
        Row {
            anchors.left: parent.left
            anchors.leftMargin: PrismTheme.dp(12)
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismGlyph {
                anchors.verticalCenter: parent.verticalCenter
                text: choice.glyph
                filled: true
                iconSize: PrismTheme.dp(16)
                color: choice.chosen ? PrismTheme.inkSolid : PrismTheme.ink2
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - PrismTheme.dp(24)
                text: choice.label
                color: choice.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
            }
        }
        MouseArea { id: choiceArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: choice.picked() }
        Accessible.role: Accessible.RadioButton
        Accessible.name: choice.label
        Accessible.checked: choice.chosen
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: PrismTheme.dp(8)
        SheetCaption {
            text: Translation.tr("Position")
            note: page.strategy === "free" ? Translation.tr("Free position")
                : page.strategy === "leastBusy" ? Translation.tr("Quietest spot") : ""
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: PrismTheme.dp(12)
            Grid {
                columns: 3
                spacing: PrismTheme.dp(4)
                Repeater {
                    model: page.widget.placement.zones
                    Rectangle {
                        id: zone
                        required property string modelData
                        readonly property bool chosen: page.strategy === zone.modelData
                        width: PrismTheme.dp(36)
                        height: PrismTheme.dp(30)
                        radius: PrismTheme.dp(10)
                        color: zone.chosen ? PrismTheme.solid : zoneArea.pressed ? PrismTheme.fillPress : zoneArea.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                        PrismGlyph {
                            anchors.centerIn: parent
                            text: page.zoneGlyphs[zone.modelData] ?? "circle"
                            iconSize: PrismTheme.dp(16)
                            color: zone.chosen ? PrismTheme.inkSolid : zoneArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                        }
                        MouseArea { id: zoneArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.widget.placement.snapToZone(zone.modelData) }
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: zone.modelData
                        Accessible.checked: zone.chosen
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: PrismTheme.dp(6)
                Choice {
                    glyph: "open_with"
                    label: Translation.tr("Free position")
                    chosen: page.strategy === "free"
                    onPicked: page.widget._setOutputValues({ placementStrategy: "free",
                        x: Math.round(page.widget.x), y: Math.round(page.widget.y) })
                }
                Choice {
                    glyph: "auto_awesome"
                    label: Translation.tr("Quietest spot")
                    chosen: page.strategy === "leastBusy"
                    onPicked: page.widget._setOutputValue("placementStrategy", "leastBusy")
                }
            }
        }
    }

    Loader {
        active: page.joinControls !== null
        visible: active && (item?.visible ?? false)
        Layout.fillWidth: true
        sourceComponent: page.joinControls
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        SheetLine {
            number: 1
            label: Translation.tr("Lock position")
            changed: page.widget.locked
            PrismSwitch {
                checked: page.widget.locked
                onToggled: value => page.widget._setOutputValue("locked", value)
            }
        }
        SheetLine {
            number: 2
            tappable: true
            glyph: "flip_to_front"
            label: Translation.tr("Bring to front")
            onTapped: page.widget._bringToFront()
        }
        SheetLine {
            number: 3
            tappable: true
            glyph: "restart_alt"
            label: Translation.tr("Reset widget")
            onTapped: page.widget.resetToDefaults()
        }
        SheetLine {
            number: 4
            tappable: true
            danger: true
            rule: false
            glyph: "remove_circle"
            label: page.controls.onLock ? Translation.tr("Remove widget") : Translation.tr("Remove from desktop")
            onTapped: {
                const widget = page.widget
                const onLock = page.controls.onLock
                page.controls.close()
                if (onLock) widget._setOutputValue("enable", false)
                else widget.takeAway()
            }
        }
    }
}
