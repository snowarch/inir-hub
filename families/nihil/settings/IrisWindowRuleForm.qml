pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.nihil.components
import qs.modules.nihil.style

// The controls of one app's rule (IrisWindowRules draws the pieces and the drawing): how and where its windows open,
// how wide, how see-through, whether captures leave them out, which of its windows. Each line says what it does; a
// value is written the moment it is picked (a range on release), and the drawing beside follows the drag.
ColumnLayout {
    id: root

    required property var host
    property var rule: null
    readonly property real d: IrisStyle.settingsDensity
    readonly property string app: String(root.rule?.app ?? "")
    // The field follows the rule (another app picked, Ctrl+Z) once typing broke its binding.
    readonly property string title: String(root.rule?.title ?? "")
    onAppChanged: titled.text = root.title
    onTitleChanged: titled.text = root.title
    readonly property var rules: root.host.rules
    readonly property var workspaces: {
        const out = [{ label: Translation.tr("Any"), value: "" }]
        for (let at = 1; at <= (root.rules?.positions ?? 0); at++) out.push({ label: String(at), value: at })
        for (const name of root.rules?.workspaceNames ?? []) out.push({ label: name, value: name })
        return out
    }
    readonly property var screens: [{ label: Translation.tr("Any"), value: "" }]
        .concat(CompositorConfig.outputs.map(out => ({ label: CompositorConfig.screenName(out), value: String(out.name) })))

    spacing: Math.round(14 * root.d)

    Line {
        title: Translation.tr("Opens")
        note: Translation.tr("How its windows open. As usual follows the rest of your windows.")
        IrisSegmented {
            width: parent.width
            options: root.host.opens
            current: String(root.rule?.open ?? "")
            accessibleName: Translation.tr("Opens")
            onPicked: value => root.host.change(root.app, { open: value }, root.host.opens.find(entry => entry.value === value)?.label ?? "")
        }
    }
    Line {
        visible: root.rule?.open !== "maximized" && root.rule?.open !== "fullscreen"
        title: Translation.tr("Width")
        note: root.rule?.open === "floating" ? Translation.tr("A share of the screen's width.") : Translation.tr("Its column's share of the screen's width.")
        IrisSegmented {
            width: parent.width
            options: root.host.widths
            current: root.host.widths.find(entry => Math.abs(entry.value - Number(root.rule?.width ?? 0)) < 0.01)?.value ?? 0
            accessibleName: Translation.tr("Width")
            onPicked: value => root.host.change(root.app, { width: value }, root.host.widths.find(entry => entry.value === value)?.label ?? "")
        }
    }
    Line {
        visible: root.rules?.has("workspace") === true
        title: Translation.tr("On workspace")
        note: CompositorConfig.niri ? Translation.tr("Niri opens apps only on named workspaces.") : Translation.tr("Counted from the top of its screen; past its last workspace, the last one.")
        Chips {
            options: root.workspaces
            current: root.rule?.workspace ?? ""
            onPicked: value => root.host.change(root.app, { workspace: value }, root.host.workspaceName(value) || Translation.tr("Any"))
        }
    }
    Line {
        visible: root.rules?.has("screen") === true
        title: Translation.tr("On screen")
        note: Translation.tr("Its windows open there, wherever you are working.")
        Chips {
            options: root.screens
            current: String(root.rule?.screen ?? "")
            onPicked: value => root.host.change(root.app, { screen: value }, root.screens.find(entry => entry.value === value)?.label ?? "")
        }
    }
    Line {
        title: Translation.tr("See-through")
        note: Translation.tr("How much of what is behind shows through its windows. Changes open windows too.")
        RowLayout {
            width: parent.width
            spacing: Math.round(12 * root.d)
            IrisSlider {
                id: through
                Layout.fillWidth: true
                // 30 % is as clear as a window stays readable.
                value: ((root.host.draft?.opacity ?? Number(root.rule?.opacity ?? 1)) - 0.3) / 0.7
                onMoved: next => root.host.draft = Object.assign({}, root.rule, { opacity: Math.round((0.3 + 0.7 * next) * 100) / 100 })
                onPressedChanged: {
                    if (through.pressed || !root.host.draft) return
                    const opacity = root.host.draft.opacity
                    root.host.draft = null
                    if (Math.abs(opacity - Number(root.rule?.opacity ?? 1)) > 0.004) root.host.change(root.app, { opacity: opacity }, `${Math.round(opacity * 100)} %`)
                }
            }
            IrisText {
                Layout.preferredWidth: Math.round(44 * root.d)
                horizontalAlignment: Text.AlignRight
                text: `${Math.round((root.host.draft?.opacity ?? Number(root.rule?.opacity ?? 1)) * 100)} %`
                font.pixelSize: IrisStyle.typeMeta
                font.features: ({ "tnum": 1 })
                color: IrisStyle.subtext
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(12 * root.d)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("Left out of captures")
                font.pixelSize: IrisStyle.typeBody
                font.weight: IrisStyle.weight(Font.DemiBold)
                wrapMode: Text.Wrap
            }
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("Screenshots, recordings and screen sharing show a blank where its windows are.")
                font.pixelSize: IrisStyle.typeMeta
                color: IrisStyle.subtext
                wrapMode: Text.Wrap
            }
        }
        IrisSwitch {
            name: Translation.tr("Left out of captures")
            on: root.rule?.hidden === true
            onToggled: root.host.change(root.app, { hidden: !(root.rule?.hidden === true) }, (root.rule?.hidden === true) ? Translation.tr("Off") : Translation.tr("On"))
        }
    }
    Line {
        title: Translation.tr("Only windows titled")
        note: Translation.tr("Words its title holds, for one kind of window of the app. Empty: every window.")
        IrisField {
            id: titled
            width: parent.width
            text: root.title
            font.pixelSize: IrisStyle.typeBody
            placeholderText: Translation.tr("Every window")
            // Enter hands the keys back to Settings, so Ctrl+Z after it undoes the rule, not the typing.
            onAccepted: titled.focus = false
            onEditingFinished: if (titled.text.trim() !== root.title) root.host.change(root.app, { title: titled.text.trim() }, titled.text.trim() || Translation.tr("Every window"))
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(12 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: Translation.tr("How and where a window opens applies to the next one the app opens.")
            font.pixelSize: IrisStyle.typeFootnote
            color: IrisStyle.muted
            wrapMode: Text.Wrap
        }
        IrisButton {
            text: Translation.tr("Remove rule")
            quiet: true
            danger: true
            onClicked: { root.host.change(root.app, null, Translation.tr("Removed")); root.host.picked = "" }
        }
    }

    // A line: its name, what it does, its control under them.
    component Line: ColumnLayout {
        id: line
        property string title: ""
        property string note: ""
        default property alias body: holder.data
        Layout.fillWidth: true
        spacing: Math.round(4 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: line.title
            font.pixelSize: IrisStyle.typeBody
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
        IrisText {
            Layout.fillWidth: true
            text: line.note
            font.pixelSize: IrisStyle.typeMeta
            color: IrisStyle.subtext
            wrapMode: Text.Wrap
        }
        Item {
            id: holder
            Layout.fillWidth: true
            Layout.topMargin: Math.round(4 * root.d)
            implicitHeight: holder.children.length > 0 ? holder.children[0].implicitHeight || holder.children[0].height : 0
        }
    }
    // Choices that run past a segmented track (workspaces, screens): pills that wrap.
    component Chips: Flow {
        id: chips
        property var options: []
        property var current: ""
        signal picked(var value)
        width: parent?.width ?? 0
        spacing: Math.round(6 * root.d)
        Repeater {
            model: chips.options
            Rectangle {
                id: chip
                required property var modelData
                readonly property bool chosen: chip.modelData.value === chips.current
                width: label.implicitWidth + Math.round(24 * root.d)
                height: Math.round(30 * root.d)
                radius: 0
                color: chip.chosen ? IrisStyle.tintFill(IrisStyle.accent) : tap.containsMouse ? IrisStyle.fillHover : IrisStyle.fill
                border.width: IrisStyle.edgeWidth
                border.color: IrisStyle.text
                Behavior on color { ColorAnimation { duration: IrisStyle.duration(140); easing.type: IrisStyle.feedbackEasing } }
                IrisText {
                    id: label
                    anchors.centerIn: parent
                    text: chip.modelData.label
                    font.pixelSize: IrisStyle.typeMeta
                    font.weight: IrisStyle.weight(chip.chosen ? Font.DemiBold : Font.Medium)
                    color: chip.chosen ? IrisStyle.accent : IrisStyle.text
                }
                MouseArea {
                    id: tap
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: chip.modelData.label
                    onClicked: if (!chip.chosen) chips.picked(chip.modelData.value)
                }
            }
        }
    }
}
