pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
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
    // The way back and the credits over the name; the Board's own line says them, so there the poster starts at its name.
    property bool topLine: true
    // A picture worn as the art in place of the ribbon (Home wears the desktop's own wallpaper), and the hues it gives.
    property string picture: ""
    property var hues: []
    // What the page itself offers at the top right, beside Restore defaults (Home: the next wallpaper).
    property alias tools: toolSlot.data
    // Room kept at the top right for the side column's key, which stands there over the page.
    property real keyRoom: PrismTheme.dp(44)
    signal restore()

    readonly property bool pictured: root.art && root.picture.length > 0
    // Over art the ink is white; a picture stays dark under its floor in every scheme.
    readonly property bool onNight: root.art && (!PrismTheme.light || root.pictured)
    readonly property color ink: root.onNight ? PrismTheme.paper : PrismTheme.ink
    readonly property color ink2: root.onNight ? Qt.rgba(1, 1, 1, 0.66) : PrismTheme.ink2 // iris-literal: Prism's own ink over its art
    readonly property color ink3: root.onNight ? Qt.rgba(1, 1, 1, 0.46) : PrismTheme.ink3 // iris-literal: Prism's own ink over its art
    readonly property real nameSize: root.art ? PrismTheme.poster : Math.round(PrismTheme.poster * 0.86)
    readonly property real inset: root.art ? PrismTheme.dp(22) : 0
    readonly property var stats: root.art ? root.lead.slice(0, 2).map(entry => entry.fact ? { say: String(entry.say), label: String(entry.label) }
        : { say: String(PrismModel.sayNow(entry) ?? ""), label: Translation.tr(entry.label) }).filter(entry => entry.say.length > 0) : []

    implicitHeight: root.art ? PrismTheme.dp(244) : name.y + name.height + PrismTheme.dp(22)

    PrismFlow {
        visible: root.art && !root.pictured
        anchors.fill: parent
        radius: PrismTheme.dp(24)
        tint: String(root.page?.tint ?? "grey")
        seed: root.number * 1.9 + 0.7
        centre: Qt.point(0.66, 0.34)
        thickness: 0.3
        fade: 0.5
    }

    // The picture as the poster's field: sharp at the top, and toward the foot the same picture blurred and deepened
    // (a variable blur, the iOS lock screen's floor), so the name and figures stand on calm ground without a band.
    ClippingRectangle {
        visible: root.pictured
        anchors.fill: parent
        radius: PrismTheme.dp(24)
        color: PrismTheme.night
        Image {
            id: shot
            anchors.fill: parent
            source: root.pictured ? root.picture : ""
            sourceSize.width: PrismTheme.dp(1100)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Rectangle {
            id: floorMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            gradient: Gradient {
                GradientStop { position: 0.3; color: "transparent" }
                GradientStop { position: 0.78; color: PrismTheme.paper }
            }
        }
        MultiEffect {
            anchors.fill: parent
            source: shot
            visible: root.pictured
            blurEnabled: true
            blur: 1
            blurMax: 56
            brightness: -0.36
            saturation: 0.1
            maskEnabled: true
            maskSource: floorMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }
        // A breath of shade under the credits, where the picture's sky may be bright, and a deeper one at the foot,
        // so a light patch of the picture never sits under the figures' small names.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: PrismTheme.spotScrim }
                GradientStop { position: 0.3; color: "transparent" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1; color: PrismTheme.spotScrim }
            }
        }
    }

    // The top line: back and forward, then the printed columns, then the page's buttons.
    Item {
        id: top
        visible: root.topLine
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
                first: root.eyebrow
                second: ""
            }
            Printed {
                visible: root.settings > 0
                first: Translation.tr("%1 settings").arg(root.settings)
                second: root.changed > 0 ? Translation.tr("%1 changed").arg(root.changed) : ""
            }
            // The three hues the desktop takes from its wallpaper now, the posters' palette dots.
            Column {
                visible: root.hues.length > 0
                spacing: PrismTheme.dp(5)
                PrismText {
                    text: Translation.tr("Colours").toUpperCase()
                    mono: true
                    color: root.ink
                    font.pixelSize: PrismTheme.caption - 1
                    font.letterSpacing: 0.8
                }
                Row {
                    spacing: PrismTheme.dp(4)
                    Repeater {
                        model: root.hues
                        delegate: Rectangle {
                            required property color modelData
                            width: PrismTheme.dp(9)
                            height: width
                            radius: width / 2
                            color: modelData
                        }
                    }
                }
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
            Row {
                id: toolSlot
                spacing: PrismTheme.dp(8)
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
        y: root.art ? root.height - height - PrismTheme.dp(20) : root.topLine ? top.y + top.height + PrismTheme.dp(26) : PrismTheme.dp(22)
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
                    color: root.pictured ? root.ink2 : root.ink3
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
