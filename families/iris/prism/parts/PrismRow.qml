import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One setting as a line of the reference's table: its number, a cover, its name, what it does, the control, and a pin.
// A folded choice lays its chips out under the line, in place.
Item {
    id: root
    required property var row
    property int number: 1
    property bool showPage: false   // search and Changes say where a row lives
    property real aboutWidth: PrismTheme.dp(220)
    property real controlWidth: PrismTheme.dp(280)
    property bool flash: false

    readonly property var value: PrismModel.read(root.row)
    readonly property bool changed: PrismModel.changed(root.row)
    readonly property bool hovered: hover.hovered
    property bool open: false

    implicitHeight: line.height + (chips.visible ? chips.height + PrismTheme.dp(14) : 0)
        + (designs.visible ? designs.height + PrismTheme.dp(16) : 0)
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
    clip: true

    HoverHandler { id: hover }
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -PrismTheme.dp(10)
        anchors.rightMargin: -PrismTheme.dp(10)
        radius: PrismTheme.dp(12)
        color: root.flash ? Qt.alpha(PrismTheme.accent, 0.16) : root.hovered ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(root.flash ? 120 : 600) } }
    }

    Item {
        id: line
        width: parent.width
        height: Math.max(PrismTheme.dp(58), name.implicitHeight + PrismTheme.dp(20))

        PrismText {
            id: number
            width: PrismTheme.dp(30)
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.number).padStart(2, "0")
            figures: true
            color: root.changed ? PrismTheme.accent : PrismTheme.ink3
            font.pixelSize: PrismTheme.small
            font.weight: root.changed ? Font.Bold : Font.Normal
        }
        PrismThumb {
            id: thumb
            anchors.left: number.right
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.row.glyph ?? "circle"
            tint: PrismModel.page(root.row.page).tint
        }
        Column {
            id: name
            anchors.left: thumb.right
            anchors.leftMargin: PrismTheme.dp(14)
            anchors.right: about.visible ? about.left : control.left
            anchors.rightMargin: PrismTheme.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            PrismText {
                width: parent.width
                text: Translation.tr(root.row.label)
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
            PrismText {
                width: parent.width
                visible: root.showPage || !about.visible
                text: root.showPage ? Translation.tr(PrismModel.page(root.row.page).name) + " · " + Translation.tr(root.row.section)
                    : Translation.tr(root.row.detail ?? "")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                wrapMode: Text.WordWrap
                maximumLineCount: root.showPage ? 1 : 2
            }
        }
        PrismText {
            id: about
            visible: root.aboutWidth > 0 && String(root.row.detail ?? "").length > 0
            width: root.aboutWidth
            anchors.right: control.left
            anchors.rightMargin: PrismTheme.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr(root.row.detail ?? "")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            lineHeight: 1.1
        }

        Item {
            id: control
            width: Math.min(root.controlWidth, kind.item?.implicitWidth ?? 0)
            height: parent.height
            anchors.right: tail.left
            anchors.rightMargin: PrismTheme.dp(8)
            Loader {
                id: kind
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: root.row.kind === "switch" ? switchKind : root.row.kind === "range" ? rangeKind
                    : root.row.kind === "swatch" ? swatchKind : root.row.kind === "text" ? textKind
                    : root.row.kind === "designs" ? nowKind : choiceKind
            }
        }

        // Pin, and the way back to the factory value when the row has left it.
        Row {
            id: tail
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            width: PrismTheme.dp(56)
            layoutDirection: Qt.RightToLeft
            PrismGlyph {
                width: PrismTheme.dp(28); height: PrismTheme.dp(28)
                text: "keep"
                readonly property bool pinned: PrismState.pinned(root.row.path)
                filled: pinned
                iconSize: PrismTheme.dp(16)
                color: pinned ? PrismTheme.accent : pinArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                opacity: pinned || root.hovered ? 1 : 0
                MouseArea { id: pinArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PrismState.togglePin(root.row.path) }
            }
            PrismGlyph {
                width: PrismTheme.dp(28); height: PrismTheme.dp(28)
                text: "restart_alt"
                iconSize: PrismTheme.dp(16)
                visible: root.changed && !PrismModel.virtual(root.row)
                color: resetArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                opacity: root.hovered ? 1 : 0
                MouseArea { id: resetArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PrismModel.write(root.row, root.row.invert ? !root.row.def : root.row.def) }
            }
        }
    }

    PrismChips {
        id: chips
        visible: root.open
        anchors.top: line.bottom
        anchors.left: parent.left
        anchors.leftMargin: name.x
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(56)
        choices: root.row.choices ?? []
        current: root.value
        onPicked: value => { PrismModel.write(root.row, value); root.open = false }
    }

    // Designs are drawn under the row; the row itself says the one in use.
    PrismDesigns {
        id: designs
        visible: root.row.kind === "designs"
        anchors.top: line.bottom
        anchors.left: parent.left
        anchors.leftMargin: name.x
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(56)
        choices: visible ? (root.row.choices ?? []) : []
        current: root.value
        onPicked: value => PrismModel.write(root.row, value)
    }

    Component {
        id: nowKind
        PrismText {
            text: PrismModel.say(root.row, root.value)
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
            font.weight: Font.DemiBold
        }
    }
    Component {
        id: switchKind
        PrismSwitch {
            checked: Boolean(root.value)
            onToggled: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: rangeKind
        PrismSlider {
            id: slider
            width: Math.min(PrismTheme.dp(240), root.controlWidth)
            from: Number(root.row.min ?? 0)
            to: Number(root.row.max ?? 100)
            stepSize: Number(root.row.step ?? 1)
            value: Number(root.value)
            glyph: root.row.glyph ?? ""
            label: PrismModel.figure(root.row, slider.live)
            onMoved: value => PrismModel.preview(root.row, value)
            onCommitted: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: choiceKind
        PrismChoice {
            choices: root.row.choices ?? []
            current: root.value
            room: root.controlWidth
            open: root.open
            onPicked: value => PrismModel.write(root.row, value)
            onToggleOpen: root.open = !root.open
        }
    }
    Component {
        id: swatchKind
        PrismSwatches {
            readonly property var palette: root.row.path === "iris.appearance.highlight" ? IrisStyle.highlights : IrisStyle.accents
            choices: (root.row.choices ?? []).map(choice => ({ label: choice.label, value: choice.value,
                colour: choice.value === "accent" ? IrisStyle.accent : (palette?.[choice.value] ?? PrismTheme.ink3) }))
            current: root.value
            onPicked: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: textKind
        PrismField {
            width: Math.min(PrismTheme.dp(200), root.controlWidth)
            text: String(root.value ?? "")
            onCommitted: text => { if (text.trim().length > 0) PrismModel.write(root.row, text.trim()) }
        }
    }
}
