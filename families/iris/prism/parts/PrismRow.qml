import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.pieces
import qs.modules.iris.settings
import qs.modules.iris.widgets
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// One setting as a line of the reference's table: its number, a cover, its name, what it does, the control, and a pin.
// What needs room (a folded choice's chips, the layout cards, pieces, a piece's marks, a curve, a list the row edits
// in place, a gallery) is laid out under the line, in place. Every kind of iRiS Settings row has its Prism face here.
Item {
    id: root
    required property var row
    property int number: 1
    property bool showPage: false   // search and Changes say where a row lives
    property real aboutWidth: PrismTheme.dp(220)
    property real controlWidth: PrismTheme.dp(280)
    property bool flash: false
    // Search and Changes: a press on the row's name or its place opens it where it lives; the control still answers here.
    signal openRequested()

    readonly property var spec: root.row.spec ?? ({})
    readonly property string kind: String(root.row.kind ?? "")
    readonly property var value: PrismModel.read(root.row)
    readonly property var choices: PrismModel.choicesOf(root.row)
    readonly property bool changed: PrismModel.changed(root.row)
    readonly property bool restorable: PrismModel.restorable(root.row)
    readonly property bool locked: PrismModel.locked(root.row)
    readonly property string note: PrismModel.note(root.row)
    readonly property bool hovered: hover.hovered
    property bool open: false

    // A colour pick: every choice (but at most one, a "custom") carries the colour it gives.
    readonly property bool swatched: root.kind === "choice" && root.choices.length > 1
        && root.choices.filter(choice => choice.swatch !== undefined && choice.swatch !== null).length >= root.choices.length - 1
    readonly property bool manySwatches: root.swatched && root.choices.length > 8
    readonly property bool listed: root.kind === "pieces" || Boolean(root.spec.flags)
    // What goes under the line, if anything.
    readonly property string below: {
        if (root.listed) return "pieces"
        if (root.kind === "designs") return "designs"
        if (root.kind === "choice" && root.spec.cards === "island" && root.choices.length > 0) return "faces"
        if (root.kind === "choice" && root.manySwatches) return "swatches"
        if (root.kind === "choice" && root.open && !root.swatched) return "chips"
        if (root.kind === "list" && root.spec.view) return "view"
        if (["icon", "curve", "niriMotion", "widgets", "themes"].includes(root.kind)) return root.kind
        return ""
    }
    // What stands at the line's end.
    readonly property string inline: {
        if (root.kind === "switch") return "switch"
        if (root.kind === "range") return "range"
        if (root.kind === "hue") return "hue"
        if (root.kind === "text") return "text"
        if (root.kind === "action") return "action"
        if (root.kind === "zone") return "zone"
        if (root.kind === "designs") return "now"
        if (root.kind === "choice" && root.spec.cards === "island" && root.choices.length > 0) return "now"
        if (root.kind === "choice" && root.swatched && !root.manySwatches) return "swatches"
        if (root.kind === "choice" && root.choices.length > 0 && !root.manySwatches) return "choice"
        if (root.kind === "choice" || root.kind === "list" || root.listed) return "now"
        return ""
    }

    implicitHeight: line.height + (slot.active ? slot.height + PrismTheme.dp(16) : 0)
    Behavior on implicitHeight { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
    clip: true

    HoverHandler { id: hover }
    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: -PrismTheme.dp(10)
        anchors.rightMargin: -PrismTheme.dp(10)
        radius: PrismTheme.dp(12)
        color: root.flash ? Qt.alpha(PrismTheme.accent, 0.16) : root.hovered ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(root.flash ? 120 : 600); easing.type: Easing.OutCubic } }
    }

    Item {
        id: line
        width: parent.width
        height: Math.max(PrismTheme.dp(58), name.implicitHeight + PrismTheme.dp(20))
        opacity: root.locked ? 0.45 : 1

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
        MouseArea {
            id: placeArea
            visible: root.showPage
            anchors.left: parent.left
            anchors.right: name.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Link
            Accessible.name: Translation.tr("Open %1").arg(Translation.tr(root.row.label))
            onClicked: root.openRequested()
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
                elide: Text.ElideRight
            }
            PrismText {
                width: parent.width
                visible: text.length > 0 && !root.showPage && !about.visible
                text: Translation.tr(root.row.detail ?? "")
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            // Where a found row lives, said as a path that goes there: the page, its group, an arrow on hover.
            Row {
                visible: root.showPage
                width: parent.width
                spacing: PrismTheme.dp(4)
                PrismText {
                    id: place
                    width: Math.min(implicitWidth, parent.width - go.width - parent.spacing)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr(PrismModel.page(root.row.page).name) + (String(root.row.section ?? "").length > 0 ? "  ›  " + Translation.tr(root.row.section) : "")
                    color: placeArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    font.weight: placeArea.containsMouse ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }
                PrismGlyph {
                    id: go
                    anchors.verticalCenter: parent.verticalCenter
                    text: "arrow_forward"
                    iconSize: PrismTheme.dp(14)
                    color: PrismTheme.ink
                    opacity: placeArea.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                }
            }
            // Why the row says what it says now (a theme decides it, a key it follows).
            PrismText {
                width: parent.width
                visible: root.note.length > 0
                text: root.note
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.caption
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
        PrismText {
            id: about
            visible: root.aboutWidth > 0 && String(root.row.detail ?? "").length > 0 && root.inline.length > 0
            width: root.aboutWidth
            anchors.right: control.left
            anchors.rightMargin: PrismTheme.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            text: Translation.tr(root.row.detail ?? "")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            lineHeight: 1.1
        }

        Item {
            id: control
            width: Math.min(root.controlWidth, kind.item?.implicitWidth ?? 0)
            height: parent.height
            anchors.right: tail.left
            anchors.rightMargin: PrismTheme.dp(8)
            enabled: !root.locked
            Loader {
                id: kind
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                active: root.inline.length > 0
                sourceComponent: ({ switch: switchKind, range: rangeKind, hue: hueKind, text: textKind, action: actionKind,
                    zone: zoneKind, now: nowKind, swatches: swatchKind, choice: choiceKind })[root.inline] ?? null
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
                visible: PrismModel.pinnable(root.row)
                readonly property bool pinned: PrismModel.pinned(root.row)
                filled: pinned
                iconSize: PrismTheme.dp(16)
                color: pinned ? PrismTheme.accent : pinArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                opacity: pinned || root.hovered ? 1 : 0
                MouseArea { id: pinArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PrismModel.togglePin(root.row) }
            }
            PrismGlyph {
                width: PrismTheme.dp(28); height: PrismTheme.dp(28)
                text: "restart_alt"
                iconSize: PrismTheme.dp(16)
                visible: root.restorable && !root.locked
                color: resetArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                opacity: root.hovered ? 1 : 0
                MouseArea { id: resetArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: PrismModel.restoreRow(root.row) }
            }
        }
    }

    // Under the line: the row's own room.
    Loader {
        id: slot
        active: root.below.length > 0
        enabled: !root.locked
        opacity: root.locked ? 0.45 : 1
        anchors.top: line.bottom
        anchors.left: parent.left
        // A gallery of faces or whole looks takes the row's whole width (twice the columns, half the scroll);
        // everything else sits under the row's name.
        readonly property bool full: root.below === "faces" || root.below === "themes"
        anchors.leftMargin: slot.full ? 0 : name.x
        width: slot.full ? parent.width : parent.width - name.x - PrismTheme.dp(56)
        height: item ? item.implicitHeight : 0
        sourceComponent: ({ pieces: piecesBelow, designs: designsBelow, faces: facesBelow, swatches: swatchesBelow, chips: chipsBelow,
            view: viewBelow, icon: iconBelow, curve: curveBelow, niriMotion: niriBelow, widgets: widgetsBelow, themes: themesBelow })[root.below] ?? null
    }

    // ── At the line's end.
    Component {
        id: nowKind
        PrismText {
            text: root.kind === "list" ? String(IrisOptions.say(root.spec, root.value) || "") : PrismModel.say(root.row, root.value)
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
            from: Number(root.spec.min ?? 0)
            to: Number(root.spec.max ?? 100)
            stepSize: Number(root.spec.step ?? 1)
            value: Number(root.value ?? 0)
            glyph: root.row.glyph ?? ""
            label: PrismModel.figure(root.row, slider.live)
            onMoved: value => PrismModel.preview(root.row, value)
            onCommitted: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: hueKind
        PrismHue {
            width: Math.min(PrismTheme.dp(240), root.controlWidth)
            value: Number(root.value ?? 0)
            onMoved: value => PrismModel.preview(root.row, value)
            onCommitted: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: choiceKind
        PrismChoice {
            choices: root.choices
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
            choices: root.choices.map(choice => ({ label: choice.label, value: choice.value, colour: choice.swatch ?? PrismTheme.ink3 }))
            current: root.value
            onPicked: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: textKind
        PrismField {
            width: Math.min(PrismTheme.dp(220), root.controlWidth)
            text: String(root.value ?? "")
            placeholder: Translation.tr(String(root.spec.placeholder ?? ""))
            onCommitted: text => PrismModel.write(root.row, text.trim())
        }
    }
    Component {
        id: actionKind
        PrismPill {
            tone: "quiet"
            glyph: String(root.spec.buttonGlyph ?? "")
            text: Translation.tr(String(root.spec.button ?? root.row.label))
            onClicked: PrismModel.write(root.row, null)
        }
    }
    // Where a bubble rests: the choice in words, then the screen drawn small with its places.
    Component {
        id: zoneKind
        Row {
            id: zone
            readonly property string base: String(root.spec.path).replace(/\.place$/, "")
            spacing: PrismTheme.dp(12)
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr(String(root.choices.find(choice => choice.value === root.value)?.label ?? ""))
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
            IrisPlacePicker {
                anchors.verticalCenter: parent.verticalCenter
                place: String(root.value ?? "")
                fx: { const _ = PrismModel.revision; return Number(Config.getNestedValue(zone.base + ".fx", 0.5)) }
                fy: { const _ = PrismModel.revision; return Number(Config.getNestedValue(zone.base + ".fy", 0.5)) }
                hasIsland: root.choices.some(choice => choice.value === "island")
                label: Translation.tr(root.row.label)
                onPlaced: place => PrismModel.write(root.row, place)
                onPlacedFree: (x, y) => {
                    const updates = {}
                    updates[zone.base + ".fx"] = Math.round(x * 1000) / 1000
                    updates[zone.base + ".fy"] = Math.round(y * 1000) / 1000
                    updates[root.spec.path] = "free"
                    Config.setNestedValues(updates)
                }
            }
        }
    }

    // ── Under the line.
    Component {
        id: piecesBelow
        PrismPieces {
            width: slot.width
            choices: root.choices
            picked: Array.isArray(root.value) ? root.value : []
            ordered: !root.spec.flags
            onChanged: next => PrismModel.write(root.row, next)
        }
    }
    Component {
        id: designsBelow
        PrismDesigns {
            width: slot.width
            choices: root.choices
            current: root.value
            onPicked: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: facesBelow
        PrismIslandFaces {
            width: slot.width
            choices: root.choices
            current: root.value
            onPicked: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: swatchesBelow
        Flow {
            width: slot.width
            PrismSwatches {
                choices: root.choices.map(choice => ({ label: choice.label, value: choice.value, colour: choice.swatch ?? PrismTheme.ink3 }))
                current: root.value
                onPicked: value => PrismModel.write(root.row, value)
            }
        }
    }
    Component {
        id: chipsBelow
        PrismChips {
            width: slot.width
            choices: root.choices
            current: root.value
            // The chips stay out after a pick, so the next try is one press away (his 11-07); the row's chevron folds them.
            onPicked: value => PrismModel.write(root.row, value)
        }
    }
    Component {
        id: iconBelow
        PrismIcons {
            width: slot.width
            glyphs: root.spec.glyphs ?? []
            current: String(root.value ?? "")
            ownGlyph: IrisPieces.defaultGlyph(String(root.spec.piece ?? ""))
            onPicked: glyph => PrismModel.write(root.row, glyph)
        }
    }
    Component {
        id: curveBelow
        Item {
            width: slot.width
            implicitHeight: curve.implicitHeight
            PrismCurve {
                id: curve
                value: root.value ?? [0.16, 1, 0.3, 1]
                onCommitted: value => PrismModel.write(root.row, value)
            }
        }
    }
    // A list the row edits in place (pinned apps, devices, calendars): its own view, the row only frames it.
    Component {
        id: viewBelow
        Loader {
            width: slot.width
            source: root.spec.view
            // The view reads its own spec (Output and Input share one view).
            onLoaded: if (item && "spec" in item) item.spec = root.spec
        }
    }
    Component { id: niriBelow; IrisNiriMotionGallery { width: slot.width } }
    Component { id: widgetsBelow; IrisWidgetGallery { width: slot.width } }
    Component {
        id: themesBelow
        Loader {
            width: slot.width
            source: Qt.resolvedUrl("../../edit/IrisPresetGallery.qml")
        }
    }
}
