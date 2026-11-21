pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.common
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Displays opens on the screen itself, live, as Keyboard opens on the keyboard (his 11-20: "el mismo trato que le
// dimos a la página mouse y keyboard"). The chosen screen at its own shape, wearing its wallpaper, on its stand or as
// a laptop's lid. Inside it one window of a fixed size in the screen's own points, so Scale and Resolution show what
// they change while they change it; Night Light warms the picture. Beside it what no row says: the name on the box,
// its size and shape, how fine its pixels are and the size Scale makes it look. Reads CompositorConfig, so it is
// the same under Niri and Umbriel.
Rectangle {
    id: root

    readonly property var screen: CompositorConfig.output
    readonly property string port: String(root.screen?.name ?? "")
    readonly property bool laptop: /^(eDP|LVDS|DSI)/i.test(root.port)
    // The room for windows, in points: the pixels over the scale, turned with the screen.
    readonly property var room: CompositorConfig.logicalRect(root.screen)
    readonly property real aspect: CompositorConfig.aspectOf(root.screen)
    readonly property var pixels: String(root.screen?.current_resolution ?? "0x0").split("x").map(Number)
    readonly property real inches: CompositorConfig.inchesOf(root.screen)
    readonly property int ppi: root.inches > 0 ? Math.round(Math.hypot(root.pixels[0], root.pixels[1]) / root.inches) : 0
    // The shape people buy a screen by; a turned screen says it the other way up.
    readonly property string shape: {
        const across = Math.max(root.pixels[0], root.pixels[1]), down = Math.min(root.pixels[0], root.pixels[1])
        if (!(across > 0 && down > 0)) return ""
        const ratio = across / down
        const named = [[16 / 9, "16:9"], [16 / 10, "16:10"], [64 / 27, "21:9"], [43 / 18, "21:9"], [21 / 9, "21:9"], [32 / 9, "32:9"],
            [32 / 10, "32:10"], [4 / 3, "4:3"], [3 / 2, "3:2"], [5 / 4, "5:4"]].find(([value]) => Math.abs(value - ratio) / value < 0.02)
        if (!named) return ""
        return root.room.height > root.room.width ? named[1].split(":").reverse().join(":") : named[1]
    }
    // Night Light on the picture: nothing at 6500 K, a deep amber at 2500 K.
    readonly property real warmth: Hyprsunset.active ? Math.max(0, Math.min(1, (6500 - Hyprsunset.colorTemperature) / 4000)) : 0
    // Beside the drawing where the card has the room, under it where it does not.
    readonly property bool wide: root.width >= PrismTheme.dp(560)
    readonly property real pad: PrismTheme.dp(20)

    implicitHeight: root.wide ? stage.height + 2 * root.pad : stage.height + plate.implicitHeight + 3 * root.pad
    radius: PrismTheme.cardRadius
    color: PrismTheme.card

    Accessible.role: Accessible.Graphic
    Accessible.name: [CompositorConfig.screenName(root.screen), root.inches > 0 ? Math.round(root.inches) + "″" : "", root.shape,
        Translation.tr("Looks like") + " " + root.room.width + " × " + root.room.height].filter(part => part.length > 0).join(", ")

    Item {
        id: stage
        x: root.pad
        y: root.pad
        width: root.wide ? Math.round((root.width - 3 * root.pad) * 0.6) : root.width - 2 * root.pad
        height: Math.round(Math.max(PrismTheme.dp(170), Math.min(PrismTheme.dp(270), stage.width * 0.56)))

        // What stands under the screen: a laptop's deck, or a monitor's neck and foot.
        readonly property real base: root.laptop ? PrismTheme.dp(10) : Math.round(stage.height * 0.14)
        readonly property real fitW: Math.min(stage.width * 0.94, (stage.height - stage.base) * root.aspect)
        readonly property real bezel: Math.max(3, PrismTheme.dp(root.laptop ? 7 : 6))

        Rectangle {
            id: lid
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(stage.fitW)
            height: Math.round(stage.fitW / root.aspect)
            y: Math.round((stage.height - stage.base - height) / 2)
            radius: PrismTheme.dp(9)
            color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme
            border.width: 1
            border.color: PrismTheme.line
            Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }

            // A panel is square inside its rounded bezel: the picture needs no mask.
            Item {
                id: picture
                anchors.fill: parent
                anchors.margins: stage.bezel
                clip: true

                Image {
                    anchors.fill: parent
                    // Its own wallpaper where each screen keeps one.
                    source: {
                        const own = WallpaperListener.multiMonitorEnabled ? WallpaperListener.effectivePerMonitor?.[root.port]?.path : ""
                        return own ? Wallpapers.stillUrlFor(own) : Wallpapers.effectiveWallpaperUrl
                    }
                    sourceSize.width: Math.round(PrismTheme.dp(560))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                }

                // One window of 960 × 600 points, drawn at the screen's own points: a larger scale or fewer pixels
                // make it take more of the screen, as every window will.
                Item {
                    id: sample
                    // Drawing pixels per point; it glides when Scale or Resolution moves.
                    property real k: root.room.width > 0 ? picture.width / root.room.width : 0
                    Behavior on k { NumberAnimation { duration: PrismTheme.ms(320); easing.type: Easing.OutCubic } }
                    function pt(value: real): real { return value * sample.k }
                    width: Math.min(picture.width * 0.92, sample.pt(960))
                    height: Math.min(picture.height * 0.86, sample.pt(600))
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: Math.round(picture.height * 0.03)

                    RectangularShadow {
                        anchors.fill: body
                        radius: body.radius
                        blur: Math.max(4, sample.pt(28))
                        offset.y: Math.max(1, sample.pt(8))
                        color: Qt.rgba(0, 0, 0, 0.45) // iris-literal: a window's lift off the wallpaper, as the compositor draws it
                    }
                    Rectangle {
                        id: body
                        anchors.fill: parent
                        radius: Math.max(2, sample.pt(12))
                        color: PrismTheme.light ? "#f7f7f9" : "#1c1c1f" // iris-literal: a plain app window in the scheme
                        clip: true
                        // Its title bar, a heading, three lines of text and its one button, each in points.
                        Rectangle {
                            width: parent.width
                            height: sample.pt(34)
                            color: PrismTheme.fill
                        }
                        Repeater {
                            model: [[0.36, 22, 56], [0.72, 12, 96], [0.58, 12, 122], [0.66, 12, 148]]
                            Rectangle {
                                required property var modelData
                                required property int index
                                x: sample.pt(24)
                                y: sample.pt(modelData[2])
                                width: (body.width - sample.pt(48)) * modelData[0]
                                height: Math.max(1, sample.pt(modelData[1]))
                                radius: height / 2
                                color: index === 0 ? Qt.alpha(PrismTheme.ink, 0.5) : Qt.alpha(PrismTheme.ink, 0.16)
                            }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: sample.pt(20)
                            width: sample.pt(104)
                            height: sample.pt(32)
                            radius: height / 2
                            color: PrismTheme.accent
                        }
                    }
                }

                // Night Light, warming the picture as it warms the screen.
                Rectangle {
                    anchors.fill: parent
                    color: "#ff8a3d" // iris-literal: Night Light's amber over the drawn screen
                    opacity: root.warmth * 0.34
                    Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(300); easing.type: Easing.OutCubic } }
                }
            }
        }

        // A laptop's deck: the lid's hinge on a slab a little wider than the lid.
        Rectangle {
            visible: root.laptop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lid.bottom
            width: Math.round(lid.width * 1.14)
            height: stage.base
            radius: Math.round(height / 2)
            color: "#26262a" // iris-literal: the laptop's body, the same in every scheme
            border.width: 1
            border.color: PrismTheme.line
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(lid.width * 0.16)
                height: Math.max(2, Math.round(parent.height * 0.32))
                radius: height / 2
                color: "#0b0b0c" // iris-literal: the hinge's notch
            }
        }
        // A monitor's neck and foot.
        Rectangle {
            id: neck
            visible: !root.laptop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lid.bottom
            width: Math.max(PrismTheme.dp(12), Math.round(lid.width * 0.07))
            height: Math.round(stage.base * 0.72)
            gradient: Gradient {
                GradientStop { position: 0; color: "#08080a" } // iris-literal: the neck in the bezel's shadow
                GradientStop { position: 1; color: "#26262a" } // iris-literal: the stand's metal
            }
        }
        Rectangle {
            visible: !root.laptop
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: neck.bottom
            width: Math.round(lid.width * 0.32)
            height: Math.max(3, Math.round(stage.base * 0.22))
            radius: height / 2
            color: "#26262a" // iris-literal: the stand's metal
            border.width: 1
            border.color: PrismTheme.line
        }
    }

    // What the screen is, and what its numbers mean for the person.
    Column {
        id: plate
        x: root.wide ? stage.x + stage.width + root.pad : root.pad
        y: root.wide ? Math.round((root.height - plate.implicitHeight) / 2) : stage.y + stage.height + root.pad
        width: root.wide ? root.width - plate.x - root.pad : root.width - 2 * root.pad
        spacing: PrismTheme.dp(3)

        PrismText {
            width: parent.width
            visible: CompositorConfig.screenName(root.screen) !== root.port
            text: root.port
            mono: true
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.caption
        }
        PrismText {
            width: parent.width
            text: CompositorConfig.screenName(root.screen)
            color: PrismTheme.ink
            font.pixelSize: PrismTheme.head
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
        }
        PrismText {
            width: parent.width
            visible: text.length > 0
            text: [root.inches > 0 ? `${Math.round(root.inches * 10) / 10}″` : "", root.shape].filter(part => part.length > 0).join("  ·  ")
            figures: true
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
        }
        Item { width: 1; height: PrismTheme.dp(12) }
        Flow {
            width: parent.width
            spacing: PrismTheme.dp(22)
            Fact { label: Translation.tr("Looks like"); value: `${root.room.width} × ${root.room.height}` }
            Fact { visible: root.ppi > 0; label: Translation.tr("Pixel density"); value: `${root.ppi} ppi` }
        }
    }

    component Fact: Column {
        property string label
        property string value
        spacing: PrismTheme.dp(2)
        PrismText {
            text: parent.label
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.caption
        }
        PrismText {
            text: parent.value
            figures: true
            color: PrismTheme.ink
            font.pixelSize: PrismTheme.row
            font.weight: Font.DemiBold
        }
    }
}
