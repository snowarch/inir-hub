pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.components
import qs.modules.iris.preview.parts
import qs.modules.iris.sidebar

// Both panels on the desktop, each with its real sections, width, height and alignment; the one being set stays lit.
PreviewScene {
    id: panelRoot
    readonly property string lit: panelRoot.group === "Focus" ? "left" : panelRoot.group === "Today" ? "right" : ""
    readonly property Item litPanel: panelRoot.lit === "left" ? focusPanel : panelRoot.lit === "right" ? todayPanel : null
    subject: panelRoot.litPanel ? Qt.rect(panelRoot.litPanel.x, panelRoot.litPanel.y, panelRoot.litPanel.width, panelRoot.litPanel.height)
        : Qt.rect(0, 0, panelRoot.width, panelRoot.height)
    readonly property real naturalWidth: (focusPanel.width + todayPanel.width) * 1.5
    readonly property real naturalHeight: Math.round(420 * panelRoot.d)

    component Panel: Plate {
        id: panel
        required property string side
        property string title: ""
        property string caption: ""
        property string day: ""
        readonly property string path: "iris.sidebars." + panel.side
        readonly property var sections: panelRoot.opt(panel.path + ".sections", [])
        readonly property string place: String(panelRoot.opt(panel.path + ".alignment", "center"))
        readonly property real inset: IrisFrame.band + (panelRoot.opt(panel.path + ".notch", false) ? 0 : IrisFrame.bodyAir)
        readonly property real room: parent.height - 2 * panel.inset
        readonly property real pad: Math.round(16 * panelRoot.d)
        readonly property real gap: Math.round(10 * panelRoot.d)
        readonly property real tile: Math.round(58 * panelRoot.d)
        // A panel hugs its sections and grows up to its maximum height.
        readonly property real hug: 2 * panel.pad + head.implicitHeight + panel.sections.length * (panel.tile + panel.gap)
        surface: "panels"
        fallbackRadius: IrisStyle.radiusPanel
        visible: Boolean(panelRoot.opt(panel.path + ".enable", true))
        opacity: panelRoot.lit.length === 0 || panelRoot.lit === panel.side ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        width: Math.max(300, Math.min(600, Number(panelRoot.opt(panel.path + ".width", 380))))
        height: Math.min(panel.hug, panel.room * Number(panelRoot.opt(panel.path + ".height", 88)) / 100)
        x: panel.side === "left" ? panel.inset : parent.width - panel.width - panel.inset
        y: panel.place === "top" ? panel.inset : panel.place === "bottom" ? parent.height - panel.height - panel.inset
            : (parent.height - panel.height) / 2
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: panel.pad
            spacing: panel.gap
            RowLayout {
                id: head
                spacing: Math.round(10 * panelRoot.d)
                IrisText {
                    visible: panel.day.length > 0
                    text: panel.day
                    color: IrisStyle.identity.red
                    font.family: IrisStyle.fontNumbers
                    font.pixelSize: IrisStyle.typeTitleLarge
                    font.weight: IrisStyle.figureWeight
                }
                ColumnLayout {
                    spacing: 0
                    IrisText {
                        text: panel.title
                        font.family: IrisStyle.fontTitle
                        font.pixelSize: IrisStyle.typeBody
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                    IrisText {
                        visible: panel.caption.length > 0
                        text: panel.caption
                        color: IrisStyle.subtext
                        font.pixelSize: IrisStyle.typeMeta
                    }
                }
            }
            Repeater {
                model: panel.sections
                Rectangle {
                    id: card
                    required property string modelData
                    readonly property var entry: IrisSidebarSections.catalog.find(section => section.id === card.modelData) ?? ({})
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: IrisStyle.radiusCard
                    color: IrisStyle.surfaceHigh
                    RowLayout {
                        x: Math.round(12 * panelRoot.d)
                        y: Math.round(12 * panelRoot.d)
                        spacing: Math.round(8 * panelRoot.d)
                        // As the real sections head themselves: a line-colour bar under a line-section Design (AIRISU),
                        // the glyph bare under a glyph-mark one, the tinted chip otherwise.
                        Rectangle {
                            visible: IrisStyle.lineSections
                            implicitWidth: Math.max(3, Math.round(4 * panelRoot.d))
                            implicitHeight: Math.round(16 * panelRoot.d)
                            color: card.entry.tint ?? IrisStyle.accent
                            antialiasing: false
                        }
                        Rectangle {
                            visible: !IrisStyle.lineSections
                            implicitWidth: Math.round(24 * panelRoot.d)
                            implicitHeight: implicitWidth
                            radius: IrisStyle.iconRadius(width)
                            color: IrisStyle.plainMarks ? "transparent" : card.entry.tint ?? IrisStyle.accent
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: card.entry.icon ?? ""
                                fill: 1
                                iconSize: Math.round(14 * panelRoot.d)
                                color: IrisStyle.plainMarks ? IrisStyle.text : IrisStyle.onTint
                            }
                        }
                        IrisText {
                            text: Translation.tr(card.entry.label ?? "")
                            font.family: IrisStyle.lineSections ? IrisStyle.fontTitle : IrisStyle.fontMain
                            font.pixelSize: IrisStyle.typeMeta
                            font.weight: IrisStyle.weight(IrisStyle.lineSections ? Font.ExtraBold : Font.DemiBold)
                        }
                    }
                }
            }
        }
    }

    Panel {
        id: focusPanel
        side: "left"
        title: Translation.tr("Focus")
    }
    OffState {
        visible: !focusPanel.visible && !todayPanel.visible
        text: Translation.tr("Side panels off")
    }
    Panel {
        id: todayPanel
        side: "right"
        title: Translation.tr("Today")
        day: Translation.locale.toString(DateTime.clock.date, "d")
        caption: Translation.locale.toString(DateTime.clock.date, "dddd, MMMM")
    }
}
