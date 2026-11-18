// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

Rectangle {
    id: root
    property bool glyphOnly: false
    readonly property real d: EditorSkin.d
    implicitWidth: lookRow.implicitWidth + Math.round(6 * root.d)
    implicitHeight: Math.round(36 * root.d)
    radius: height / 2
    color: "transparent" // literal: bare capsule outline
    border.width: 1
    border.color: EditorSkin.edge
    Accessible.role: Accessible.PageTabList
    Accessible.name: Translation.tr("Style")

    Row {
        id: lookRow
        anchors.centerIn: parent
        spacing: Math.round(2 * root.d)
        Repeater {
            model: EditorSkin.looks
            IrisButton {
                id: look
                required property var modelData
                readonly property bool on: EditorSkin.look === look.modelData.id
                implicitHeight: Math.round(30 * root.d)
                implicitWidth: root.glyphOnly ? Math.round(34 * root.d) : lookLabel.implicitWidth + Math.round(24 * root.d)
                buttonRadius: height / 2
                buttonRadiusPressed: height / 2
                colBackground: look.on ? (EditorSkin.prism ? EditorSkin.solid : EditorSkin.plate) : "transparent" // literal: inactive style segment is bare
                colBackgroundHover: look.on ? colBackground : (EditorSkin.iris ? IrisStyle.fillQuiet : EditorSkin.plate)
                Accessible.name: Translation.tr(look.modelData.label)
                Accessible.checked: look.on
                StyledToolTip { text: Translation.tr(look.modelData.label); extraVisibleCondition: root.glyphOnly && look.buttonHovered; font.family: EditorSkin.mainFont }
                onClicked: EditorOptions.set("style", look.modelData.id)

                Row {
                    id: lookLabel
                    anchors.centerIn: parent
                    spacing: Math.round(6 * root.d)
                    readonly property color ink: look.on ? (EditorSkin.prism ? EditorSkin.inkOnSolid : EditorSkin.colors.text) : (EditorSkin.iris ? IrisStyle.muted : EditorSkin.colors.muted)
                    MaterialSymbol {
                        anchors.verticalCenter: parent.verticalCenter
                        text: look.modelData.glyph
                        iconSize: Math.round(16 * root.d)
                        color: lookLabel.ink
                    }
                    EditorText {
                        visible: !root.glyphOnly
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr(look.modelData.label)
                        color: lookLabel.ink
                        role: "meta"
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }
}
