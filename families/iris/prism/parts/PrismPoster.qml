pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A page's top as a poster of the collection (`.claude/ref/language`: the Design Archive posters, Vitrium Opus,
// 36 Days of Type): the way back and forward, its place and size printed small in mono columns, the page's own
// buttons at the right; its name big over the art's calm floor and what it holds now as figures (the Taskello card's
// "05 Doc"). Without art (a search, Changes, a page iRiS draws, Home and Wallpaper with heroes of their own) the same
// words stand on the page.
Item {
    id: root
    property bool art: true
    property var page: null
    property string eyebrow: ""
    property string title: ""
    // Its place among the pages ("07 / 38") and what it holds; nothing to say, nothing printed.
    property int number: 0
    property int total: 0
    property int settings: 0
    property int changed: 0
    property int restorable: 0
    property var lead: []
    property bool pills: true
    // Room kept at the top right for the side column's key, which stands there over the page.
    property real keyRoom: PrismTheme.dp(44)
    signal restore()

    readonly property bool onNight: root.art && !PrismTheme.light
    readonly property color ink: root.onNight ? PrismTheme.paper : PrismTheme.ink
    readonly property color ink2: root.onNight ? Qt.rgba(1, 1, 1, 0.66) : PrismTheme.ink2 // iris-literal: Prism's own ink over its art
    readonly property color ink3: root.onNight ? Qt.rgba(1, 1, 1, 0.46) : PrismTheme.ink3 // iris-literal: Prism's own ink over its art
    readonly property real nameSize: root.art ? PrismTheme.poster : Math.round(PrismTheme.poster * 0.86)
    readonly property real inset: root.art ? PrismTheme.dp(22) : 0
    readonly property var stats: root.art ? root.lead.slice(0, 2).map(entry => entry.fact ? { say: String(entry.say), label: String(entry.label) }
        : { say: String(PrismModel.sayNow(entry) ?? ""), label: Translation.tr(entry.label) }).filter(entry => entry.say.length > 0) : []

    implicitHeight: root.art ? PrismTheme.dp(244) : name.y + name.height + PrismTheme.dp(22)

    PrismFlow {
        visible: root.art
        anchors.fill: parent
        radius: PrismTheme.dp(24)
        tint: String(root.page?.tint ?? "grey")
        seed: root.number * 1.9 + 0.7
        centre: Qt.point(0.66, 0.34)
        thickness: 0.3
        fade: 0.5
    }

    // The top line: back and forward, then the printed columns, then the page's buttons.
    Item {
        id: top
        x: root.inset
        y: PrismTheme.dp(18)
        width: root.width - root.inset * 2
        height: PrismTheme.dp(32)
        Row {
            id: nav
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismRound { glyph: "chevron_left"; overArt: root.onNight; smoked: true; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
            PrismRound { glyph: "chevron_right"; overArt: root.onNight; smoked: true; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        }
        Row {
            id: credits
            x: nav.width + PrismTheme.dp(26)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, buttons.x - x - PrismTheme.dp(16))
            spacing: PrismTheme.dp(36)
            clip: true
            Printed {
                visible: first.length > 0
                first: root.number > 0 ? String(root.number).padStart(2, "0") + (root.total > 0 ? " / " + String(root.total).padStart(2, "0") : "") : root.eyebrow
                second: root.number > 0 ? root.eyebrow : ""
            }
            Printed {
                visible: root.settings > 0
                first: Translation.tr("%1 settings").arg(root.settings)
                second: root.changed > 0 ? Translation.tr("%1 changed").arg(root.changed) : ""
            }
        }
        Row {
            id: buttons
            visible: root.pills
            x: parent.width - width - root.keyRoom
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismPill {
                visible: root.restorable > 0
                tone: root.onNight ? "dark" : "quiet"
                glyph: "restart_alt"
                text: Translation.tr("Restore defaults")
                onClicked: root.restore()
            }
            PrismPill {
                visible: Boolean(root.page?.show)
                tone: root.onNight ? "art" : "solid"
                glyph: "play_arrow"
                text: Translation.tr(String(root.page?.show?.label ?? ""))
                onClicked: PrismModel.runShow(root.page)
            }
        }
    }

    // The name, big, at the foot; what the page holds now at the right, figures over their names.
    PrismText {
        id: name
        x: root.inset
        y: root.art ? root.height - height - PrismTheme.dp(20) : top.y + top.height + PrismTheme.dp(26)
        // A long name in a narrow window steps down in size rather than losing its end.
        width: Math.min(implicitWidth, root.width - root.inset * 2)
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: PrismTheme.head
        text: root.title
        color: root.ink
        font.pixelSize: root.nameSize
        font.weight: Font.Bold
        font.letterSpacing: -root.nameSize * 0.035
        verticalAlignment: Text.AlignBottom
    }
    // Each figure shows whole or not at all: the second goes first when the name needs the room.
    Row {
        id: figureRow
        readonly property real room: root.width - root.inset * 2 - PrismTheme.dp(4) - name.implicitWidth - PrismTheme.dp(40)
        visible: root.stats.length > 0
        anchors.right: parent.right
        anchors.rightMargin: root.inset + PrismTheme.dp(4)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: PrismTheme.dp(28)
        spacing: PrismTheme.dp(30)
        Repeater {
            id: statRepeater
            model: root.stats
            delegate: Column {
                id: stat
                required property var modelData
                required property int index
                visible: (stat.index === 0 ? 0 : (statRepeater.itemAt(0)?.implicitWidth ?? 0) + figureRow.spacing) + stat.implicitWidth <= figureRow.room
                spacing: PrismTheme.dp(4)
                PrismText {
                    text: stat.modelData.say
                    figures: true
                    color: root.ink
                    font.pixelSize: PrismTheme.title
                    font.weight: Font.Bold
                    font.letterSpacing: -0.6
                }
                PrismText {
                    text: stat.modelData.label.toUpperCase()
                    mono: true
                    color: root.ink3
                    font.pixelSize: PrismTheme.caption - 1
                    font.letterSpacing: 0.8
                }
            }
        }
    }

    // Two lines printed small in mono, the posters' columns of credits.
    component Printed: Column {
        property string first: ""
        property string second: ""
        spacing: PrismTheme.dp(3)
        PrismText {
            text: parent.first.toUpperCase()
            mono: true
            color: root.ink
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
        }
        PrismText {
            visible: text.length > 0
            text: parent.second.toUpperCase()
            mono: true
            color: root.ink3
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
        }
    }
}
