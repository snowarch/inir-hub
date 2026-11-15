pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group opened from its part on the scene (Options+'s side column, `.claude/ref/iris-prism/pin-options-plus-parts.jpg`):
// its number and name, what it holds now, and its rows, live, so a change redraws the scene beside it. Another part
// picked eases its face across (the keyboard inspector's fade and rise); its card keeps the group whole.
Item {
    id: root
    // The legend entry open here ({ title, rows, changed }) and its number on the page.
    property var entry: null
    // Its number on the page and what it holds now, asked of the page for the group shown.
    property var numberOf: null
    property var sayOf: null
    signal close()
    signal toCard(string title)

    // What the face shows follows `entry` once it has faded, so another part picked eases in instead of snapping.
    property var shown: null
    readonly property int shownNumber: root.shown && typeof root.numberOf === "function" ? root.numberOf(String(root.shown.title)) : 0
    readonly property string say: root.shown && typeof root.sayOf === "function" ? String(root.sayOf(root.shown) ?? "") : ""
    property bool fading: false
    onEntryChanged: {
        if (!root.entry) return
        // The page's groups are read again on every change of a value: the same group takes its rows as they are now
        // (a switch that shows more rows), without the fade another group gets.
        if (root.shown && String(root.shown.title) === String(root.entry.title)) { root.take(); return }
        if (!root.shown || !root.visible || !IrisStyle.motionEnabled) { root.take(); return }
        if (!root.fading) swap.restart()
    }
    function take(): void { root.shown = root.entry }
    SequentialAnimation {
        id: swap
        ScriptAction { script: root.fading = true }
        NumberAnimation { target: face; property: "opacity"; to: 0; duration: PrismTheme.ms(90); easing.type: IrisStyle.feedbackEasing }
        ScriptAction { script: { root.take(); root.fading = false; flick.contentY = 0 } }
        ParallelAnimation {
            NumberAnimation { target: face; property: "opacity"; to: 1; duration: PrismTheme.ms(220); easing.type: IrisStyle.feedbackEasing }
            NumberAnimation { target: face; property: "rise"; from: PrismTheme.dp(6); to: 0; duration: PrismTheme.ms(280); easing.type: IrisStyle.feedbackEasing }
        }
    }

    readonly property var rows: Array.from(root.shown?.rows ?? [])
    // The height that shows every row without scrolling.
    readonly property real need: head.height + list.implicitHeight + foot.height

    Item {
        id: face
        property real rise: 0
        width: root.width
        height: root.height
        y: face.rise

        // Its number, its name and the way out.
        Item {
            id: head
            width: parent.width
            height: Math.max(PrismTheme.dp(56), said.implicitHeight + PrismTheme.dp(16))
            Column {
                id: said
                x: PrismTheme.dp(14)
                anchors.verticalCenter: parent.verticalCenter
                width: close.x - x - PrismTheme.dp(8)
                spacing: PrismTheme.dp(2)
                Row {
                    width: parent.width
                    spacing: PrismTheme.dp(8)
                    PrismText {
                        id: num
                        mono: true
                        text: String(root.shownNumber).padStart(2, "0")
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption
                        anchors.baseline: title.baseline
                    }
                    // A long language takes a second line, never a cut name.
                    PrismText {
                        id: title
                        width: parent.width - num.width - parent.spacing
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideNone
                        text: Translation.tr(String(root.shown?.title ?? ""))
                        color: PrismTheme.ink
                        font.pixelSize: PrismTheme.head
                        font.weight: Font.Bold
                    }
                }
                PrismText {
                    visible: root.say.length > 0
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideNone
                    text: root.say
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                }
            }
            PrismRound {
                id: close
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: PrismTheme.dp(8)
                glyph: "close"
                glyphSize: PrismTheme.dp(16)
                onClicked: root.close()
            }
        }

        // The group's rows: a field (a range, a short choice) with its name over it, the rest on one line.
        Flickable {
            id: flick
            y: head.height
            width: parent.width
            height: foot.y - y
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: list
                x: PrismTheme.dp(6)
                width: flick.width - 2 * x
                Repeater {
                    model: root.rows.length
                    delegate: PrismRow {
                        id: line
                        required property int index
                        row: root.rows[line.index]
                        width: list.width
                        stacked: PrismModel.shapeOf(line.row) === "field"
                        aboutWidth: 0
                        // A switch keeps only its own width: its name and what it does get the rest of a narrow column.
                        controlWidth: line.stacked ? list.width
                            : line.inline === "switch" && line.controlNeed > 0 ? line.controlNeed
                            : Math.min(PrismTheme.dp(180), list.width * 0.46)
                    }
                }
            }
        }
        IrisScrollEdge {
            flick: flick
            anchors.fill: flick
            blurs: false
            reach: PrismTheme.dp(20)
            veil: PrismTheme.card
        }

        // The group whole, in its card on the page.
        Item {
            id: foot
            width: parent.width
            height: PrismTheme.dp(48)
            y: parent.height - height
            PrismPill {
                anchors.verticalCenter: parent.verticalCenter
                x: PrismTheme.dp(8)
                tone: "quiet"
                glyph: "arrow_downward"
                text: Translation.tr("Open its card")
                onClicked: root.toCard(String(root.shown?.title ?? ""))
            }
        }
    }
}
