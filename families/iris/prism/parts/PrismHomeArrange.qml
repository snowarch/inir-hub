pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// Home, arranged by the person (his 11-18: Home is theirs, whole): what its head wears, how it greets, and which blocks
// it holds in what order. Every choice shows itself at once on the page under it.
Item {
    id: root
    signal done()

    readonly property var appearance: Config.options?.iris?.appearance ?? ({})
    readonly property var all: ["everyday", "deck", "groups", "index"]
    readonly property var shown: Array.from(root.appearance.settingsHomeBlocks ?? root.all).map(String).filter(id => root.all.includes(id))
    readonly property var listed: root.shown.concat(root.all.filter(id => !root.shown.includes(id)))
    readonly property string art: String(root.appearance.settingsHomeArt ?? "flow")
    readonly property string greeting: String(root.appearance.settingsHomeGreeting ?? "name")
    readonly property var names: ({ everyday: "Every day", deck: "Wallpaper, sound and light", groups: "Home's settings", index: "Every page" })
    readonly property var glyphs: ({ everyday: "touch_app", deck: "wallpaper", groups: "tune", index: "menu_book" })
    readonly property string wallPath: String(Wallpapers.effectiveWallpaperPath ?? "")

    function setBlocks(list: var): void { Config.setNestedValue("iris.appearance.settingsHomeBlocks", list) }
    function move(id: string, by: int): void {
        const list = Array.from(root.shown)
        const at = list.indexOf(id)
        const to = at + by
        if (at < 0 || to < 0 || to >= list.length) return
        list.splice(at, 1)
        list.splice(to, 0, id)
        root.setBlocks(list)
    }
    function show(id: string, on: bool): void {
        const list = Array.from(root.shown).filter(entry => entry !== id)
        if (on) list.push(id)
        root.setBlocks(list)
    }

    readonly property real pad: PrismTheme.dp(20)
    implicitHeight: body.implicitHeight + 2 * root.pad

    Rectangle {
        anchors.fill: parent
        radius: PrismTheme.dp(22)
        color: PrismTheme.sunk
    }

    Column {
        id: body
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: PrismTheme.dp(18)

        Item {
            width: parent.width
            height: PrismTheme.dp(32)
            PrismText {
                anchors.verticalCenter: parent.verticalCenter
                text: Translation.tr("Make Home yours")
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }
            PrismPill {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                tone: "solid"
                glyph: "check"
                text: Translation.tr("Done")
                onClicked: root.done()
            }
        }

        // The head: three looks, each shown as itself.
        Column {
            width: parent.width
            spacing: PrismTheme.dp(8)
            PrismText {
                text: Translation.tr("Its head")
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
            Row {
                spacing: PrismTheme.dp(10)
                Repeater {
                    model: [
                        { id: "flow", label: "Painted" },
                        { id: "wallpaper", label: "Your wallpaper" },
                        { id: "accent", label: "Your accent" }
                    ]
                    delegate: Column {
                        id: look
                        required property var modelData
                        readonly property bool chosen: root.art === look.modelData.id
                        spacing: PrismTheme.dp(6)
                        // The look and its name are one press.
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Config.setNestedValue("iris.appearance.settingsHomeArt", look.modelData.id) }
                        ClippingRectangle {
                            width: PrismTheme.dp(132)
                            height: PrismTheme.dp(74)
                            radius: PrismTheme.dp(14)
                            color: PrismTheme.night
                            PrismFlow {
                                anchors.fill: parent
                                visible: look.modelData.id === "flow"
                                tint: "blue"
                                seed: 0.61
                                centre: Qt.point(0.5, 0.4)
                                thickness: 0.9
                                strength: PrismTheme.light ? 0.6 : 0.72
                                mute: 0.5
                            }
                            Image {
                                anchors.fill: parent
                                visible: look.modelData.id === "wallpaper"
                                source: look.modelData.id === "wallpaper" ? Wallpapers.stillUrlFor(root.wallPath) : ""
                                sourceSize.width: PrismTheme.dp(264)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                visible: look.modelData.id === "accent"
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0; color: IrisStyle.accent }
                                    GradientStop { position: 1; color: ColorUtils.mix(IrisStyle.accent, PrismTheme.night, 0.45) }
                                }
                            }
                            Rectangle {
                                visible: look.chosen
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: PrismTheme.dp(7)
                                width: PrismTheme.dp(22)
                                height: width
                                radius: width / 2
                                color: PrismTheme.paper
                                PrismGlyph {
                                    anchors.centerIn: parent
                                    text: "check"
                                    iconSize: PrismTheme.dp(15)
                                    color: PrismTheme.night
                                }
                            }
                        }
                        PrismText {
                            text: Translation.tr(look.modelData.label)
                            color: look.chosen ? PrismTheme.ink : PrismTheme.ink2
                            font.pixelSize: PrismTheme.body
                            font.weight: look.chosen ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        // The greeting.
        Column {
            width: parent.width
            spacing: PrismTheme.dp(8)
            PrismText {
                text: Translation.tr("How it greets you")
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
            Row {
                spacing: PrismTheme.dp(6)
                Repeater {
                    model: [
                        { id: "name", label: "With your name" },
                        { id: "plain", label: "Without it" },
                        { id: "hour", label: "The hour" }
                    ]
                    delegate: Rectangle {
                        id: say
                        required property var modelData
                        readonly property bool chosen: root.greeting === say.modelData.id
                        width: sayText.implicitWidth + PrismTheme.dp(28)
                        height: PrismTheme.dp(32)
                        radius: height / 2
                        color: say.chosen ? PrismTheme.solid : sayHit.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                        PrismText {
                            id: sayText
                            anchors.centerIn: parent
                            text: Translation.tr(say.modelData.label)
                            color: say.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                            font.pixelSize: PrismTheme.body
                            font.weight: say.chosen ? Font.DemiBold : Font.Normal
                        }
                        MouseArea {
                            id: sayHit
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setNestedValue("iris.appearance.settingsHomeGreeting", say.modelData.id)
                        }
                    }
                }
            }
        }

        // The blocks: shown ones in their order, then the ones put away.
        Column {
            width: parent.width
            spacing: PrismTheme.dp(4)
            PrismText {
                bottomPadding: PrismTheme.dp(4)
                text: Translation.tr("What it holds")
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
            Repeater {
                model: root.listed
                delegate: Rectangle {
                    id: block
                    required property string modelData
                    required property int index
                    readonly property bool on: root.shown.includes(block.modelData)
                    width: parent.width
                    height: PrismTheme.dp(48)
                    radius: PrismTheme.dp(14)
                    color: PrismTheme.fill
                    opacity: block.on ? 1 : 0.6
                    PrismGlyph {
                        id: mark
                        x: PrismTheme.dp(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyphs[block.modelData] ?? "circle"
                        iconSize: PrismTheme.dp(18)
                        color: block.on ? PrismTheme.accentInk : PrismTheme.ink3
                    }
                    PrismText {
                        anchors.left: mark.right
                        anchors.leftMargin: PrismTheme.dp(12)
                        anchors.right: keys.left
                        anchors.rightMargin: PrismTheme.dp(12)
                        anchors.verticalCenter: parent.verticalCenter
                        text: Translation.tr(root.names[block.modelData] ?? block.modelData)
                        font.pixelSize: PrismTheme.row
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Row {
                        id: keys
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(10)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(6)
                        PrismRound {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: block.on
                            glyph: "arrow_upward"
                            enabled_: block.index > 0
                            Accessible.name: Translation.tr("Move up")
                            onClicked: root.move(block.modelData, -1)
                        }
                        PrismRound {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: block.on
                            glyph: "arrow_downward"
                            enabled_: block.index < root.shown.length - 1
                            Accessible.name: Translation.tr("Move down")
                            onClicked: root.move(block.modelData, 1)
                        }
                        PrismSwitch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: block.on
                            onToggled: value => root.show(block.modelData, value)
                        }
                    }
                }
            }
        }
    }
}
