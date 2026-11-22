pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// Keybind row with search registration
Item {
    id: root
    
    property var mods: []
    property string keyName: ""
    property string action: ""
    property var keySubstitutions: ({})
    
    // Search registration
    property int settingsPageIndex: -1
    property string settingsPageName: ""
    property string settingsSection: ""
    property int settingsSearchOptionId: -1

    // WSettingsCard lays it out as one of its rows: on the group's plate, a hairline apart
    readonly property string settingsCardRole: "row"
    property string cardStyle: "item"
    property real itemIndent: Looks.settings.cardPadding
    property real endInset: Looks.settings.cardPadding
    property bool hairline: false

    Layout.fillWidth: true
    implicitHeight: Math.max(Looks.dp(48), keybindRow.implicitHeight + Looks.dp(16))
    
    // Highlight animation for search focus
    Behavior on opacity {
        enabled: Looks.transition?.opacity !== undefined
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.normal : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    Behavior on scale {
        enabled: Looks.transition?.resize !== undefined
        animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
    }
    
    function focusFromSettingsSearch(): void {
        // Find parent Flickable
        var flick = null;
        var p = root.parent;
        while (p) {
            if (p.hasOwnProperty("contentY") && p.hasOwnProperty("contentHeight")) {
                flick = p;
                break;
            }
            p = p.parent;
        }
        
        if (flick) {
            // the row's place in the page's content, wherever the page is scrolled
            var y = root.mapToItem(flick.contentItem, 0, 0).y;
            var centerOffset = (flick.height - root.height) / 2;
            var maxY = Math.max(0, flick.contentHeight - flick.height);
            flick.contentY = Math.max(0, Math.min(y - centerOffset, maxY));
        }
        
        highlightAnim.stop();
        root.scale = 1.0;
        highlightOverlay.opacity = 0;
        highlightAnim.start();
    }
    
    Component.onCompleted: {
        if (typeof SettingsSearchRegistry === "undefined") return;
        if (!root.action) return;
        
        // Build key combo string for keywords
        var keyCombo = root.mods.concat(root.keyName ? [root.keyName] : []).join("+").toLowerCase();
        
        settingsSearchOptionId = SettingsSearchRegistry.registerOption({
            control: root,
            pageIndex: root.settingsPageIndex,
            pageName: root.settingsPageName,
            section: root.settingsSection,
            label: root.action,
            description: keyCombo,
            keywords: [keyCombo, "shortcut", "keybind", "hotkey"].concat(root.mods.map(m => m.toLowerCase()))
        });
    }
    
    Component.onDestruction: {
        if (typeof SettingsSearchRegistry !== "undefined") {
            SettingsSearchRegistry.unregisterControl(root);
        }
    }
    
    Rectangle {
        visible: root.hairline
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.itemIndent
        height: 1
        color: Looks.settings.cardStroke
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Looks.dp(4)
        radius: Looks.settings.radiusSmall
        color: Looks.settings.tile
        opacity: rowMouse.containsMouse ? 1 : 0
        Behavior on opacity {
            animation: NumberAnimation { duration: Looks.transition.enabled ? 110 : 0 }
        }
    }

    Rectangle {
        id: highlightOverlay
        anchors.fill: parent
        anchors.margins: Looks.dp(4)
        radius: Looks.settings.radiusSmall
        color: Looks.colors.accent
        opacity: 0
    }
    
    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
    
    RowLayout {
        id: keybindRow
        anchors.fill: parent
        anchors.leftMargin: root.itemIndent
        anchors.rightMargin: root.endInset
        spacing: Looks.dp(12)

        // The action leads and the keys answer at the right, as every card does: people arrive with "how do I ...".
        WText {
            Layout.fillWidth: true
            text: root.action
            font.pixelSize: Looks.settings.body
            font.weight: Looks.font.weight.thin
            elide: Text.ElideRight
        }

        // Keys, a "+" between every two: it sat only before the last, so Super Shift + E read as two chords
        Row {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: Looks.dp(4)

            Repeater {
                model: root.mods.concat(root.keyName.length > 0 ? [root.keyName] : [])
                delegate: Row {
                    id: keyCell
                    required property var modelData
                    required property int index
                    spacing: Looks.dp(4)

                    WText {
                        visible: keyCell.index > 0
                        text: "+"
                        color: Looks.colors.subfg
                        font.pixelSize: Looks.font.pixelSize.small
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Rectangle {
                        implicitWidth: Math.max(keyText.implicitWidth + Looks.dp(10), Looks.dp(26))
                        implicitHeight: Math.max(Looks.dp(24), keyText.implicitHeight + Looks.dp(4))
                        radius: Looks.dp(6)
                        color: Looks.settings.tile
                        border.width: 1
                        border.color: Looks.settings.cardStroke

                        WText {
                            id: keyText
                            anchors.centerIn: parent
                            text: root.keySubstitutions[keyCell.modelData] ?? keyCell.modelData
                            font.pixelSize: Looks.font.pixelSize.small
                            font.family: Looks.font.family.monospace
                        }
                    }
                }
            }
        }
    }
}
