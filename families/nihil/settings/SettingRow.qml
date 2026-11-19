pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// One option: its name on the left and the control its kind asks for on the right. While it differs from how NiHiL came,
// a key brings the original value back.
Item {
    id: root

    required property var option
    required property var host

    // A compositor row reads and writes the compositor's own setting, for Niri and Umbriel alike: its spec comes with the
    // row (a whole group) or is found by the row's `comp` and `key`.
    readonly property var spec: root.option.spec
        ?? (root.option.type === "compositor" ? CompositorRows.rows.find(row => row.comp === root.option.comp && row.key === root.option.key) ?? null : null)
    readonly property bool base: root.option.base === true
    // The control this row draws: switch, level, choice, text, screens or action.
    readonly property string kind: root.spec ? (root.spec.kind === "range" ? "level" : root.spec.kind) : root.option.type
    // A spec's words come translated from the base; NiHiL's own are translated here.
    readonly property string label: root.spec && !root.option.label ? String(root.spec.label) : Translation.tr(root.option.label)
    readonly property string note: root.spec && !root.option.label ? String(root.spec.description ?? "") : Translation.tr(root.option.note ?? "")
    // A fraction of the compositor's is shown as a percentage.
    readonly property real factor: root.spec ? Number(root.spec.scale ?? (Number(root.spec.step ?? 1) < 1 ? 100 : 1)) : 1
    readonly property real from: root.spec?.min ?? root.option.from ?? 0
    readonly property real to: root.spec?.max ?? root.option.to ?? 1
    readonly property real step: root.spec ? Number(root.spec.step ?? 1) : root.option.step ?? 1
    readonly property var choices: {
        if (root.kind !== "choice") return []
        const spec = root.spec
        if (spec) {
            CompositorConfig.revision
            const own = (spec.choices ?? []).length > 0
            const found = own ? spec.choices : spec.comp === "display" ? CompositorConfig.displayChoices(spec.key)
                : spec.choicesFrom === "cursors" ? CompositorConfig.cursorThemes.map(name => ({ label: name.replace(/[_-]/g, " "), value: name }))
                : CompositorConfig.choicesFor(spec)
            return found.map(pick => ({ value: pick.value, label: own ? String(pick.label) : Translation.tr(String(pick.label)) }))
        }
        switch (root.option.source) {
        case "languages":
            return [{ value: "auto", label: Translation.tr("Same as the system") }]
                .concat(Translation.allAvailableLanguages.map(code => ({ value: code, label: Translation.languageDisplayName(code) })))
        case "iconThemes":
            IconThemeService.ensureInitialized()
            return [{ value: "", label: Translation.tr("Same as the system") }]
                .concat(IconThemeService.availableThemes.map(name => ({ value: String(name), label: String(name).replace(/[_-]/g, " ") })))
        case "screens":
            return [{ value: "", label: Translation.tr("Automatic") }].concat(Quickshell.screens.map(screen => ({ value: screen.name, label: screen.name })))
        case "families":
            return Plugins.families.map(id => ({ value: id, label: String(Plugins.manifests[id]?.name ?? id) }))
        }
        return root.option.options.map(option => ({ value: option.value, label: Translation.tr(option.label) }))
    }

    readonly property var value: {
        if (root.spec) { CompositorConfig.revision; return CompositorConfig.value(root.spec) }
        if (root.base) return root.host.plain(Config.getNestedValue(root.option.key, root.option.fallback))
        return root.host.read(root.option.key)
    }
    readonly property var factoryValue: root.spec ? (CompositorConfig.factory(root.spec) ?? root.spec.fallback)
        : root.base ? root.option.fallback : root.host.factory(root.option.key)
    // A screen's own mode has no factory value to go back to.
    readonly property bool changed: root.kind !== "action" && root.kind !== "screens" && root.option.key !== "panelFamily" && root.spec?.comp !== "display"
        && JSON.stringify(root.value) !== JSON.stringify(root.factoryValue)
    readonly property bool isFit: root.option.fit !== undefined && root.value === root.option.fit

    function write(value: var): void {
        if (root.spec) {
            if (String(value) !== String(root.value)) CompositorConfig.set(root.spec, value)
        } else if (root.option.key === "panelFamily") {
            // A family switch goes through the shell's transition, never a bare config write.
            Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "panelFamily", "set", String(value)])
        } else if (root.base) {
            Config.setNestedValue(root.option.key, value)
        } else {
            root.host.write(root.option.key, value)
        }
    }

    function stepped(value: real): real {
        return Number((Math.round(value / root.step) * root.step).toFixed(3))
    }

    function figure(value: real): string {
        if (root.isFit)
            return Translation.tr(root.option.fitLabel)
        if (root.spec)
            return root.factor === 100 ? Math.round(value * 100) + " %" : String(Math.round(value * root.factor * 100) / 100) + String(root.spec.unit ?? "")
        switch (root.option.unit) {
        case "percent": return Math.round(value * 100) + "%"
        case "share": return Math.round(value) + "%"
        case "px": return Math.round(value) + " px"
        case "ms": return Math.round(value) + " ms"
        case "s": return Math.round(value / 1000) + " s"
        case "min": return Math.round(value) + " min"
        case "K": return Math.round(value) + " K"
        case "times": return value.toFixed(2) + "x"
        default: return String(Math.round(value * 100) / 100)
        }
    }

    implicitHeight: Math.max(NihilStyle.s(68), words.implicitHeight + NihilStyle.s(24))

    // Changed from how NiHiL came: a small dot of the accent at the row's edge.
    Rectangle {
        visible: root.changed
        x: -NihilStyle.s(11)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(5)
        height: width
        radius: width / 2
        color: NihilStyle.accent
    }

    Column {
        id: words
        anchors.left: parent.left
        anchors.right: undo.left
        anchors.rightMargin: NihilStyle.s(12)
        anchors.verticalCenter: parent.verticalCenter

        spacing: NihilStyle.s(2)

        NText {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textBody
            font.weight: Font.Medium
            color: NihilStyle.ink
        }
        NText {
            width: parent.width
            visible: root.note.length > 0
            text: root.note
            elide: Text.ElideRight
            font.pixelSize: NihilStyle.textSmall
            color: NihilStyle.inkSoft
        }
    }

    NButton {
        id: undo
        anchors.right: control.left
        anchors.rightMargin: NihilStyle.s(6)
        anchors.verticalCenter: parent.verticalCenter
        width: NihilStyle.s(28)
        height: NihilStyle.s(28)
        icon: "undo"
        iconSize: NihilStyle.s(15)
        opacity: root.changed ? 1 : 0
        enabled: root.changed
        Accessible.name: Translation.tr("Restore the original value")
        onClicked: root.write(root.factoryValue)
    }

    Loader {
        id: control
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: ({ switch: switchControl, level: levelControl, screens: screensControl, text: textControl,
                            action: actionControl })[root.kind] ?? (root.choices.length <= 3 ? segmentControl : menuControl)
    }

    Component {
        id: switchControl

        NSwitch {
            on: root.value === true
            name: root.label
            onToggled: root.write(root.value !== true)
        }
    }

    Component {
        id: segmentControl

        NSegmented {
            width: NihilStyle.s(112) * root.choices.length
            options: root.choices
            current: root.choices.find(option => String(option.value) === String(root.value))?.value ?? root.value
            accessibleName: root.label
            onPicked: value => root.write(value)
        }
    }

    Component {
        id: menuControl

        NButton {
            id: opener
            readonly property var chosen: root.choices.find(option => String(option.value) === String(root.value))
            icon: "expand_more"
            label: opener.chosen?.label ?? String(root.value ?? "")
            onClicked: root.host.openMenu(root, opener)
        }
    }

    Component {
        id: levelControl

        Row {
            spacing: NihilStyle.s(10)

            NButton {
                visible: root.option.fit !== undefined
                anchors.verticalCenter: parent.verticalCenter
                label: Translation.tr(root.option.fitLabel ?? "")
                lit: root.isFit
                onClicked: root.write(root.isFit ? root.host.levelStart(root.option) : root.option.fit)
            }
            NSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(250)
                height: NihilStyle.s(32)
                enabled: !root.isFit
                opacity: root.isFit ? 0.4 : 1
                from: root.from
                to: root.to
                stepSize: root.step
                value: root.isFit ? root.from : Number(root.value)
                name: root.label
                // The compositor rewrites its file on each change: it takes the value where the drag ends.
                onMoved: value => { if (!root.spec) root.write(root.stepped(value)) }
                onSeekRequested: value => { if (root.spec) root.write(root.stepped(value)) }
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(46)
                horizontalAlignment: Text.AlignRight
                text: root.figure(Number(root.value))
                figures: true
                font.weight: Font.Medium
                color: root.changed ? NihilStyle.ink : NihilStyle.inkSoft
            }
        }
    }

    Component {
        id: screensControl

        Row {
            spacing: NihilStyle.s(4)

            Repeater {
                model: Quickshell.screens

                delegate: NButton {
                    id: screenKey
                    required property var modelData
                    readonly property var chosen: Array.from(root.value ?? [])
                    label: screenKey.modelData.name
                    lit: screenKey.chosen.includes(screenKey.modelData.name)
                    onClicked: root.write(screenKey.lit
                        ? screenKey.chosen.filter(name => name !== screenKey.modelData.name)
                        : [...screenKey.chosen, screenKey.modelData.name])
                }
            }
        }
    }

    Component {
        id: textControl

        NField {
            width: NihilStyle.s(230)
            value: String(root.value ?? "")
            placeholder: root.option.placeholder ?? ""
            onCommitted: text => root.write(text.trim())
        }
    }

    Component {
        id: actionControl

        NButton {
            label: Translation.tr(root.option.button)
            onClicked: root.host.act(root.option.act)
        }
    }
}
