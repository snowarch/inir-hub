pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import "IrisBinds.js" as IrisBinds

// Under the drawn keyboard: the key under the pointer or picked, with what it does under the modifiers held. On a pick
// it changes: another action (any one the config already uses, by category, or a program), moved to the next key
// picked, or freed; a free key takes one the same way. Niri writes through inir-accel, Umbriel into Settings' own file.
Column {
    id: root

    // The IrisKeyboardMap it describes.
    property var map: null
    property string code: ""
    // Picked, not only pointed at: the actions show.
    property bool sticky: false
    readonly property real d: IrisStyle.settingsDensity

    // Umbriel's keys are written by CompositorConfig.bind, which an older base lacks: there the drawing only reads.
    readonly property bool canEdit: NiriKeybinds.umbriel ? typeof CompositorConfig.bind === "function" : CompositorService.niriNative
    // What the face says: it follows `code` once the face has faded, so a key pointed at eases in instead of snapping.
    property string shown: ""
    property bool fading: false
    readonly property bool motion: IrisStyle.motionEnabled
    readonly property bool resting: root.shown.length === 0
    readonly property var bind: root.shown.length > 0 && root.map ? root.map.bindAt(root.shown) : null
    readonly property string sym: root.shown.length > 0 && root.map ? root.map.symAt(root.shown) : ""
    readonly property var mods: root.map ? root.map.layerMods : []
    readonly property string combo: root.sym.length > 0 ? IrisBinds.comboOf(root.mods, root.sym) : ""
    readonly property color tint: IrisStyle.identityColor(IrisBinds.tintOf(String(root.bind?.category ?? "")))
    // Choosing the action for the picked key.
    property bool asking: false
    property string category: ""
    property string said: ""
    onCodeChanged: {
        root.asking = false
        root.said = ""
        if (!root.motion) { root.shown = root.code; return }
        // Mid-fade the swap takes the newest key when it lands: a pass across the drawing never stutters.
        if (!root.fading) swap.restart()
    }
    SequentialAnimation {
        id: swap
        ScriptAction { script: root.fading = true }
        NumberAnimation { target: face; property: "opacity"; to: 0; duration: IrisStyle.duration(90); easing.type: IrisStyle.feedbackEasing }
        ScriptAction { script: { root.shown = root.code; root.fading = false } }
        ParallelAnimation {
            NumberAnimation { target: face; property: "opacity"; to: 1; duration: IrisStyle.duration(220); easing.type: IrisStyle.feedbackEasing }
            NumberAnimation { target: face; property: "rise"; from: Math.round(6 * root.d); to: 0; duration: IrisStyle.duration(280); easing.type: IrisStyle.feedbackEasing }
        }
    }

    // What iNiR's own files bind this key to, and whether it left that.
    readonly property var shipped: {
        if (root.sym.length === 0 || !root.map) return null
        const want = IrisBinds.comboKey(root.combo, root.map.modKey)
        return (NiriKeybinds.shippedBinds ?? []).find(one => !one.commented && IrisBinds.comboKey(one.key_combo, root.map.modKey) === want) ?? null
    }
    readonly property bool loaded: (NiriKeybinds.shippedBinds ?? []).length > 0
    readonly property bool differs: root.loaded && root.sym.length > 0
        && IrisBinds.actionKey(root.bind?.action_raw) !== IrisBinds.actionKey(root.shipped?.action_raw)
    readonly property string target: root.bind ? String(root.bind.key_combo) : root.combo

    // Every action the config already binds, once, under its category: the picker's vocabulary.
    readonly property var actions: {
        const seen = {}
        const out = []
        for (const one of NiriKeybinds.allBinds ?? []) {
            const raw = String(one.action_raw ?? "")
            if (one.commented || raw.length === 0 || seen[raw]) continue
            seen[raw] = true
            out.push({ category: String(one.category ?? ""), description: String(one.description || one.action || raw), raw: raw, options: String(one.options ?? "") })
        }
        return out
    }
    readonly property var categories: root.actions.map(one => one.category).filter((name, i, all) => name.length > 0 && all.indexOf(name) === i)
    readonly property string shownCategory: root.categories.includes(root.category) ? root.category : String(root.bind?.category ?? root.categories[0] ?? "")

    function choose(raw: string, options: string): void {
        if (root.combo.length === 0) return
        root.map.edit([{ combo: root.target, action: raw, options: options }], [root.map.stateOf(root.target, root.bind)], "changed")
        root.asking = false
    }
    function remove(): void {
        root.map.edit([{ combo: root.target, action: "" }], [root.map.stateOf(root.target, root.bind)], "removed")
    }
    function putBack(): void {
        root.map.edit([{ combo: root.shipped ? String(root.shipped.key_combo) : root.target, shipped: true }], [root.map.stateOf(root.target, root.bind)], "restored")
    }
    function program(text: string): string {
        const line = text.trim()
        return NiriKeybinds.umbriel ? "spawn " + line : "spawn-sh " + JSON.stringify(line)
    }
    Connections {
        target: NiriKeybinds
        function onBindError(message) { root.said = message }
        function onBindSaved(keyCombo) { root.said = "" }
    }

    spacing: Math.round(12 * root.d)

    Rectangle {
        width: root.width
        height: Math.round(64 * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fill

        Item {
        id: face
        property real rise: 0
        width: parent.width
        height: parent.height
        y: face.rise

        // Nothing pointed at: how the drawing is used.
        IrisText {
            visible: root.resting
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(18 * root.d)
            width: parent.width - 2 * x
            text: root.map?.moving ? Translation.tr("Pick the key it moves to")
                : Translation.tr("Point at a key to see what it does, pick it to change it. Holding the keys on your keyboard works too.")
            color: root.map?.moving ? IrisStyle.text : IrisStyle.textSecondary
            font.pixelSize: IrisStyle.typeMeta
            elide: Text.ElideRight
        }

        Row {
            id: comboRow
            visible: !root.resting
            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(14 * root.d)
            spacing: Math.round(4 * root.d)
            Repeater {
                model: root.combo.split("+").filter(part => part.length > 0)
                delegate: Rectangle {
                    required property string modelData
                    height: Math.round(30 * root.d)
                    width: Math.max(height, part.implicitWidth + Math.round(18 * root.d))
                    radius: Math.min(IrisStyle.radiusChip, Math.round(8 * root.d))
                    color: root.bind ? ColorUtils.applyAlpha(root.tint, IrisStyle.tintWash) : IrisStyle.fill
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(180); easing.type: IrisStyle.feedbackEasing } }
                    IrisText {
                        id: part
                        anchors.centerIn: parent
                        text: modelData === "Mod" ? Translation.tr(root.map?.modKey ?? "Super") : modelData
                        color: IrisStyle.text
                        font.family: IrisStyle.fontMono
                        font.pixelSize: IrisStyle.typeMeta
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Column {
            visible: !root.resting
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: comboRow.right
            anchors.leftMargin: Math.round(16 * root.d)
            anchors.right: buttons.left
            anchors.rightMargin: Math.round(12 * root.d)
            spacing: Math.round(2 * root.d)
            IrisText {
                width: parent.width
                text: root.bind ? String(root.bind.description || root.bind.action || "") : Translation.tr("Free")
                color: root.bind ? IrisStyle.text : IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeLabel
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            // Left iNiR's: what iNiR's files put here, a dot of the changed accent before it.
            Row {
                visible: root.differs && root.bind === null
                spacing: Math.round(6 * root.d)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(5 * root.d)
                    height: width
                    radius: width / 2
                    color: IrisStyle.accent
                }
                IrisText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("iNiR's: %1").arg(String(root.shipped?.description || root.shipped?.action || ""))
                    color: IrisStyle.textTertiary
                    font.pixelSize: IrisStyle.typeMeta
                }
            }
            Row {
                visible: root.bind !== null
                width: parent.width
                spacing: Math.round(6 * root.d)
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: IrisBinds.glyphOf(String(root.bind?.category ?? ""))
                    iconSize: Math.round(14 * root.d)
                    fill: 1
                    color: root.tint
                }
                IrisText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr(String(root.bind?.category ?? ""))
                    color: root.tint
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: Font.Medium
                }
                IrisText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, parent.width - x)
                    text: !root.differs ? String(root.bind?.action_raw ?? "")
                        : root.shipped ? Translation.tr("iNiR's: %1").arg(String(root.shipped.description || root.shipped.action || ""))
                        : Translation.tr("iNiR leaves it free")
                    color: IrisStyle.textTertiary
                    font.family: root.differs ? IrisStyle.fontMain : IrisStyle.fontMono
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
            }
            IrisText {
                visible: root.bind === null && !root.differs
                width: parent.width
                text: root.sticky && root.canEdit ? Translation.tr("Nothing runs on this key with these modifiers. Give it an action.")
                    : Translation.tr("Nothing runs on this key with these modifiers.")
                color: IrisStyle.textTertiary
                font.pixelSize: IrisStyle.typeMeta
                elide: Text.ElideRight
            }
        }

        Row {
            id: buttons
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Math.round(12 * root.d)
            spacing: Math.round(6 * root.d)
            visible: root.sticky && root.canEdit && !root.resting
            IrisButton {
                visible: root.differs && root.map.canStep
                text: Translation.tr("Back to iNiR's")
                quiet: true
                onClicked: root.putBack()
            }
            IrisButton {
                visible: root.bind !== null
                text: Translation.tr("Move")
                quiet: true
                onClicked: { root.map.moving = root.bind; root.map.picked = "" }
            }
            IrisButton {
                visible: root.bind !== null
                text: Translation.tr("Remove")
                quiet: true
                danger: true
                onClicked: root.remove()
            }
            IrisButton {
                text: root.bind ? Translation.tr("Change") : Translation.tr("Add")
                selected: root.asking
                emphasized: !root.asking
                onClicked: root.asking = !root.asking
            }
        }
        IrisButton {
            visible: root.resting && root.map?.moving !== null && root.map?.moving !== undefined
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Math.round(12 * root.d)
            text: Translation.tr("Cancel")
            quiet: true
            onClicked: root.map.moving = null
        }
        }
    }

    IrisText {
        visible: root.said.length > 0
        width: root.width
        text: root.said
        color: IrisStyle.danger
        font.pixelSize: IrisStyle.typeMeta
        wrapMode: Text.WordWrap
    }

    // The action for the picked key: a category, then one of what it already runs; or any program.
    Column {
        visible: root.asking && root.sticky
        width: root.width
        spacing: Math.round(10 * root.d)
        Flow {
            width: root.width
            spacing: Math.round(6 * root.d)
            Repeater {
                model: root.categories
                delegate: IrisButton {
                    required property string modelData
                    text: Translation.tr(modelData)
                    selected: root.shownCategory === modelData
                    quiet: !selected
                    onClicked: root.category = modelData
                }
            }
        }
        Flow {
            width: root.width
            spacing: Math.round(6 * root.d)
            Repeater {
                model: root.actions.filter(one => one.category === root.shownCategory)
                delegate: IrisButton {
                    required property var modelData
                    text: modelData.description
                    selected: root.bind !== null && String(root.bind.action_raw) === modelData.raw
                    onClicked: root.choose(modelData.raw, modelData.options)
                }
            }
        }
        Row {
            spacing: Math.round(8 * root.d)
            IrisField {
                id: run
                width: Math.min(root.width - use.width - parent.spacing, Math.round(420 * root.d))
                implicitHeight: Math.round(36 * root.d)
                font.pixelSize: IrisStyle.typeLabel
                placeholderText: Translation.tr("Or a program to run, as you would type it")
                onAccepted: if (text.trim().length > 0) root.choose(root.program(text), "")
            }
            IrisButton {
                id: use
                anchors.verticalCenter: run.verticalCenter
                text: Translation.tr("Run it")
                enabled: run.text.trim().length > 0
                onClicked: root.choose(root.program(run.text), "")
            }
        }
    }
}
