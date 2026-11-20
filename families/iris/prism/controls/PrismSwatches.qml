import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.services
import qs.modules.iris.prism.core

// A colour pick in the grammar of Prism's segmented choice: one well, the chosen colour a key of that colour that says
// its own name, the others discs beside it. A disc under the pointer names itself over the track, inside the row, so
// nothing hangs into the next line and no disc moves (his 11-07 "no dice que carajo es cada chip", 11-11 "rediseño").
// `chart` lays every colour out with its name, wrapped to the width: what a long list (themes) needs to be read.
// `palette` is a colour role's own pick (Accent, Highlight, Signal): see the palette below.
Item {
    id: root
    property var choices: []      // { label, value, colour }
    property var current
    property real room: PrismTheme.dp(300)
    property bool chart: false
    property bool palette: false
    signal picked(var value)
    property int aimed: -1

    readonly property int chosenIndex: root.choices.findIndex(choice => choice.value === root.current)
    readonly property real pad: PrismTheme.dp(3)
    readonly property real slot: PrismTheme.dp(26)
    readonly property real part: PrismTheme.dp(26)
    // The chosen part takes what the discs leave, so a long name in any language never pushes the track past its room.
    readonly property real nameRoom: Math.max(PrismTheme.dp(40), root.room - root.pad * 2 - Math.max(0, root.choices.length - 1) * root.slot - PrismTheme.dp(24))

    function ink(colour: color): color {
        return (0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b) > 0.6 ? "#000000" : "#ffffff" // iris-literal: a name that reads on any swatch
    }
    // A colour as dark (or as light) as the track it lies on gets a hairline, or it is a hole.
    function faint(colour: color): bool {
        return Math.abs((0.299 * colour.r + 0.587 * colour.g + 0.114 * colour.b)
            - (0.299 * PrismTheme.canvas.r + 0.587 * PrismTheme.canvas.g + 0.114 * PrismTheme.canvas.b)) < 0.16
    }

    implicitWidth: root.chart || root.palette ? root.width : track.width
    implicitHeight: root.palette ? paletteBody.implicitHeight : root.chart ? flow.implicitHeight : PrismTheme.dp(32)

    // ── The track.
    Item {
        id: track
        visible: !root.chart && !root.palette
        width: strip.implicitWidth + root.pad * 2
        height: PrismTheme.dp(32)
        PrismWell { anchors.fill: parent }

        PrismText {
            visible: root.aimed >= 0 && root.aimed !== root.chosenIndex
            y: -height - PrismTheme.dp(1)
            x: {
                const item = root.aimed >= 0 ? strip.children[root.aimed] : null
                return item ? Math.max(0, Math.min(track.width - width, strip.x + item.x + item.width / 2 - width / 2)) : 0
            }
            text: Translation.tr(String(root.choices[root.aimed]?.label ?? ""))
            font.pixelSize: PrismTheme.caption
            font.weight: Font.DemiBold
        }

        Row {
            id: strip
            x: root.pad
            y: root.pad
            Repeater {
                model: root.chart || root.palette ? [] : root.choices
                delegate: Item {
                    id: swatch
                    required property var modelData
                    required property int index
                    readonly property bool chosen: index === root.chosenIndex
                    readonly property color colour: modelData.colour
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: Translation.tr(String(modelData.label ?? ""))
                    Accessible.checked: swatch.chosen
                    width: swatch.chosen ? Math.min(root.nameRoom, word.implicitWidth) + PrismTheme.dp(24) : root.slot
                    height: root.part
                    Behavior on width { NumberAnimation { duration: PrismTheme.ms(240); easing.type: Easing.OutCubic } }
                    // The chosen colour is a key of that colour with its name printed on it (the keycaps collage).
                    PrismKey {
                        visible: swatch.chosen
                        anchors.fill: parent
                        face: swatch.colour
                    }
                    Rectangle {
                        visible: !swatch.chosen
                        anchors.centerIn: parent
                        width: area.containsMouse ? PrismTheme.dp(22) : PrismTheme.dp(18)
                        height: width
                        radius: height / 2
                        color: swatch.colour
                        border.width: root.faint(swatch.colour) ? 1 : 0
                        border.color: Qt.alpha(PrismTheme.ink, 0.2)
                        Behavior on width { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                    }
                    PrismText {
                        id: word
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -PrismTheme.keyLip / 2
                        width: Math.min(implicitWidth, root.nameRoom)
                        opacity: swatch.chosen ? 1 : 0
                        visible: opacity > 0
                        text: Translation.tr(String(swatch.modelData.label ?? ""))
                        color: root.ink(swatch.colour)
                        font.pixelSize: PrismTheme.small
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onContainsMouseChanged: if (containsMouse) root.aimed = swatch.index; else if (root.aimed === swatch.index) root.aimed = -1
                        onClicked: root.picked(swatch.modelData.value)
                    }
                }
            }
        }
    }

    // ── The chart: every colour with its name.
    Flow {
        id: flow
        visible: root.chart
        width: root.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: root.chart ? root.choices : []
            delegate: Item {
                id: chip
                required property var modelData
                required property int index
                readonly property bool chosen: index === root.chosenIndex
                readonly property color colour: modelData.colour
                Accessible.role: Accessible.RadioButton
                Accessible.name: name.text
                Accessible.checked: chip.chosen
                width: dot.width + name.implicitWidth + PrismTheme.dp(30)
                height: PrismTheme.dp(32)
                PrismKey {
                    anchors.fill: parent
                    face: chip.chosen ? chip.colour : PrismTheme.keyQuiet
                    hovered: chipArea.containsMouse
                    down: chipArea.pressed
                }
                Rectangle {
                    id: dot
                    x: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -PrismTheme.keyLip / 2
                    width: PrismTheme.dp(16)
                    height: width
                    radius: width / 2
                    color: chip.chosen ? root.ink(chip.colour) : chip.colour
                    border.width: !chip.chosen && root.faint(chip.colour) ? 1 : 0
                    border.color: Qt.alpha(PrismTheme.ink, 0.2)
                    PrismGlyph {
                        anchors.centerIn: parent
                        visible: chip.chosen
                        text: "check"
                        iconSize: PrismTheme.dp(12)
                        color: chip.colour
                    }
                }
                PrismText {
                    id: name
                    anchors.left: dot.right
                    anchors.leftMargin: PrismTheme.dp(8)
                    anchors.verticalCenter: dot.verticalCenter
                    text: Translation.tr(String(chip.modelData.label ?? ""))
                    color: chip.chosen ? root.ink(chip.colour) : chipArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                    font.pixelSize: PrismTheme.small
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: chipArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(chip.modelData.value)
                }
            }
        }
    }

    // ── The palette: a colour role's choices as discs on one line under its name. First where the colour comes from,
    // each disc showing its source (the wallpaper itself, the theme's palette, a link to the accent, ink), then the named
    // colours, then your own hue on the wheel. The chosen one is ringed; under the line its name and what it follows, or
    // the pointed one's while the pointer rests on it, so every disc says what it is without a word on each.
    readonly property var sourceRank: ["wallpaper", "theme", "design", "accent", "ink"]
    readonly property var sourceGlyphs: ({ theme: "palette", design: "auto_awesome", accent: "link", ink: "contrast" })
    readonly property var sourced: root.choices.filter(choice => root.sourceRank.includes(String(choice.value)))
        .sort((a, b) => root.sourceRank.indexOf(String(a.value)) - root.sourceRank.indexOf(String(b.value)))
    readonly property var own: root.choices.filter(choice => String(choice.value) === "custom")
    readonly property var named: root.choices.filter(choice => !root.sourceRank.includes(String(choice.value)) && String(choice.value) !== "custom")
    property var aimedValue: undefined
    readonly property bool aiming: root.aimedValue !== undefined && root.aimedValue !== root.current
    readonly property var said: root.choices.find(choice => choice.value === (root.aiming ? root.aimedValue : root.current)) ?? null
    function detailOf(value: var): string {
        const kind = String(value)
        if (kind === "wallpaper") return Translation.tr("Follows every new wallpaper")
        if (kind === "theme") return Translation.tr("The colour theme's own")
        if (kind === "accent") return Translation.tr("Matches the accent")
        if (kind === "custom") return Translation.tr("Any hue you choose")
        return ""
    }

    Component {
        id: discKind
        Item {
            id: disc
            required property var modelData
            readonly property string kind: String(disc.modelData.value)
            readonly property bool chosen: disc.modelData.value === root.current
            readonly property color colour: disc.modelData.colour
            readonly property string glyph: String(root.sourceGlyphs[disc.kind] ?? "")
            readonly property real side: PrismTheme.dp(28)
            width: PrismTheme.dp(36)
            height: width
            Accessible.role: Accessible.RadioButton
            Accessible.name: Translation.tr(String(disc.modelData.label ?? ""))
            Accessible.description: root.detailOf(disc.modelData.value)
            Accessible.checked: disc.chosen

            // The ring round the chosen one, with a breath of the ground between it and the colour.
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: PrismTheme.dp(2)
                border.color: PrismTheme.ink
                opacity: disc.chosen ? 1 : 0
                scale: disc.chosen ? 1 : 0.86
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(180); easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
            }
            Item {
                id: face
                anchors.centerIn: parent
                width: disc.side
                height: disc.side
                scale: discArea.pressed ? 0.92 : discArea.containsMouse && !disc.chosen ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

                // A colour, or a source's colour under its mark: the disc itself, a hairline where it is as dark (or as
                // light) as the ground.
                Rectangle {
                    visible: disc.kind !== "wallpaper" && disc.kind !== "custom"
                    anchors.fill: parent
                    radius: width / 2
                    color: disc.colour
                    border.width: root.faint(disc.colour) ? 1 : 0
                    border.color: Qt.alpha(PrismTheme.ink, 0.2)
                }
                PrismGlyph {
                    visible: disc.glyph.length > 0
                    anchors.centerIn: parent
                    text: disc.glyph
                    iconSize: PrismTheme.dp(15)
                    color: root.ink(disc.colour)
                }
                // The wallpaper: the picture itself, the colour it gives in its corner.
                Loader {
                    active: disc.kind === "wallpaper"
                    anchors.fill: parent
                    sourceComponent: Item {
                        ClippingRectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: disc.colour
                            Image {
                                anchors.fill: parent
                                source: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
                                sourceSize.width: Math.round(disc.side * 2)
                                sourceSize.height: Math.round(disc.side * 2)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                        }
                        Rectangle {
                            x: parent.width - width + PrismTheme.dp(3)
                            y: parent.height - height + PrismTheme.dp(3)
                            width: PrismTheme.dp(13)
                            height: width
                            radius: width / 2
                            color: disc.colour
                            border.width: PrismTheme.dp(2)
                            border.color: PrismTheme.canvas
                        }
                    }
                }
                // Your own: the whole wheel of hues, at the hue fader's strength.
                Loader {
                    active: disc.kind === "custom"
                    anchors.fill: parent
                    sourceComponent: Shape {
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: "transparent"
                            fillGradient: ConicalGradient {
                                centerX: disc.side / 2
                                centerY: disc.side / 2
                                angle: 90
                                GradientStop { position: 0; color: Qt.hsva(0, 0.62, 1, 1) } // iris-literal: the wheel is every hue at Prism's spectrum strength
                                GradientStop { position: 1 / 6; color: Qt.hsva(5 / 6, 0.62, 1, 1) } // iris-literal: the hue wheel
                                GradientStop { position: 2 / 6; color: Qt.hsva(4 / 6, 0.62, 1, 1) } // iris-literal: the hue wheel
                                GradientStop { position: 3 / 6; color: Qt.hsva(3 / 6, 0.62, 1, 1) } // iris-literal: the hue wheel
                                GradientStop { position: 4 / 6; color: Qt.hsva(2 / 6, 0.62, 1, 1) } // iris-literal: the hue wheel
                                GradientStop { position: 5 / 6; color: Qt.hsva(1 / 6, 0.62, 1, 1) } // iris-literal: the hue wheel
                                GradientStop { position: 1; color: Qt.hsva(0, 0.62, 1, 1) } // iris-literal: the hue wheel
                            }
                            PathAngleArc { centerX: disc.side / 2; centerY: disc.side / 2; radiusX: disc.side / 2; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
                        }
                    }
                }
            }
            MouseArea {
                id: discArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: {
                    if (containsMouse) root.aimedValue = disc.modelData.value
                    else if (root.aimedValue === disc.modelData.value) root.aimedValue = undefined
                }
                onClicked: root.picked(disc.modelData.value)
            }
        }
    }

    Column {
        id: paletteBody
        visible: root.palette
        width: root.width
        spacing: PrismTheme.dp(2)
        Flow {
            width: parent.width
            spacing: PrismTheme.dp(4)
            Repeater { model: root.palette ? root.sourced : []; delegate: discKind }
            // Where the colour comes from, then the colours: a hairline between them.
            Item {
                visible: root.palette && root.sourced.length > 0 && root.named.length + root.own.length > 0
                width: PrismTheme.dp(13)
                height: PrismTheme.dp(36)
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: PrismTheme.dp(18)
                    color: Qt.alpha(PrismTheme.ink, 0.16) // iris-literal: a hairline between two sets of discs
                }
            }
            Repeater { model: root.palette ? root.named : []; delegate: discKind }
            Repeater { model: root.palette ? root.own : []; delegate: discKind }
        }
        // The chosen one's name and what it follows; the pointed one's in the second tone while the pointer rests on it.
        Item {
            width: parent.width
            height: sayName.implicitHeight
            PrismText {
                id: sayName
                x: PrismTheme.dp(4)
                width: Math.min(implicitWidth, parent.width - x)
                text: Translation.tr(String(root.said?.label ?? ""))
                color: root.aiming ? PrismTheme.ink2 : PrismTheme.ink
                font.pixelSize: PrismTheme.small
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            PrismText {
                readonly property string detail: root.said ? root.detailOf(root.said.value) : ""
                visible: detail.length > 0
                x: sayName.x + sayName.width + PrismTheme.dp(6)
                width: Math.max(0, Math.min(implicitWidth, parent.width - x))
                text: detail
                color: PrismTheme.ink3
                font.pixelSize: PrismTheme.small
                elide: Text.ElideRight
            }
        }
    }
}
