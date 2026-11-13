import QtQuick
import qs.services
import qs.modules.iris.prism.core

// Pieces picked from a set, in the order they were switched on: every choice a chip, the picked ones solid with
// their place as a small figure. A long set (forty cities, every piece) shows what is picked in its order first, then
// what is left, filtered as the person types.
Column {
    id: root
    property var choices: []
    property var picked: []          // values, in order
    property bool ordered: true      // a flags row is a set: no figures
    property bool enabled_: true
    signal changed(var next)

    readonly property var pickedValues: Array.from(root.picked ?? []).map(entry => String(entry))
    readonly property bool searchable: root.choices.length > 12
    property string typed: ""
    readonly property string query: root.typed.trim().toLowerCase()
    property bool everything: false
    readonly property var added: root.pickedValues.map(value => root.choices.find(choice => String(choice.value) === value)).filter(Boolean)
    readonly property var rest: root.choices.filter(choice => !root.pickedValues.includes(String(choice.value))
        && (root.query.length === 0 || Translation.tr(String(choice.label)).toLowerCase().includes(root.query)
            || String(choice.value).toLowerCase().includes(root.query)))
    readonly property int cap: root.everything || root.query.length > 0 ? 9999 : 16
    spacing: PrismTheme.dp(10)
    opacity: root.enabled_ ? 1 : 0.38

    function toggle(value: string): void {
        if (!root.enabled_) return
        const next = root.pickedValues.filter(entry => entry !== value)
        if (!root.pickedValues.includes(value)) next.push(value)
        root.changed(next)
    }

    component Chip: Item {
        id: chip
        required property var modelData
        readonly property int place: root.pickedValues.indexOf(String(chip.modelData.value))
        readonly property bool on: chip.place >= 0
        readonly property string glyph: String(chip.modelData.glyph ?? "")
        implicitWidth: chipRow.implicitWidth + PrismTheme.dp(24)
        implicitHeight: PrismTheme.dp(30)
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chip.on ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
            Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        }
        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: PrismTheme.dp(6)
            Rectangle {
                visible: chip.on && root.ordered
                anchors.verticalCenter: parent.verticalCenter
                width: PrismTheme.dp(16)
                height: width
                radius: width / 2
                color: PrismTheme.inkSolid
                PrismText {
                    anchors.centerIn: parent
                    text: String(chip.place + 1)
                    figures: true
                    color: PrismTheme.solid
                    font.pixelSize: PrismTheme.dp(9)
                    font.weight: Font.Bold
                }
            }
            PrismGlyph {
                visible: chip.glyph.length > 0 && !(chip.on && root.ordered)
                anchors.verticalCenter: parent.verticalCenter
                text: chip.glyph
                iconSize: PrismTheme.dp(14)
                color: chip.on ? PrismTheme.inkSolid : PrismTheme.ink2
            }
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr(String(chip.modelData.label ?? chip.modelData.value))
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                color: chip.on ? PrismTheme.inkSolid : PrismTheme.ink
            }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle(String(chip.modelData.value))
        }
    }

    // A short set: every chip in its own place, the picked ones solid.
    Flow {
        visible: !root.searchable
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.searchable ? [] : root.choices
            delegate: Chip {}
        }
    }

    // A long set: what is picked, in its order, then the rest under a filter.
    PrismText {
        visible: root.searchable
        text: root.added.length > 0 ? (root.ordered ? Translation.tr("Added, in this order") : Translation.tr("On")) : Translation.tr("Nothing added yet")
        color: PrismTheme.ink3
        font.pixelSize: PrismTheme.caption
        font.weight: Font.DemiBold
    }
    Flow {
        visible: root.searchable && root.added.length > 0
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.searchable ? root.added : []
            delegate: Chip {}
        }
    }
    PrismField {
        id: finder
        visible: root.searchable
        width: Math.min(root.width, PrismTheme.dp(320))
        height: PrismTheme.dp(32)
        glyph: "search"
        placeholder: Translation.tr("Filter %1 available").arg(root.rest.length)
        onEdited: text => root.typed = text
        // Return adds the first match and clears the filter for the next one.
        Connections {
            target: finder.input
            function onAccepted() {
                if (root.rest.length > 0 && root.query.length > 0) root.toggle(String(root.rest[0].value))
                finder.input.text = ""
                root.typed = ""
            }
        }
    }
    Flow {
        visible: root.searchable
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.searchable ? root.rest.slice(0, root.cap) : []
            delegate: Chip {}
        }
        Item {
            visible: root.rest.length > root.cap
            implicitWidth: allWords.implicitWidth + PrismTheme.dp(24)
            implicitHeight: PrismTheme.dp(30)
            Rectangle { anchors.fill: parent; radius: height / 2; color: allArea.containsMouse ? PrismTheme.fillHover : "transparent"; border.width: 0 }
            PrismText {
                id: allWords
                anchors.centerIn: parent
                text: Translation.tr("All %1").arg(root.rest.length)
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                color: PrismTheme.ink2
            }
            MouseArea { id: allArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.everything = true }
        }
    }
}
