pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// Lock's head (his 11-18: nothing of the lock screen missing, and what opens it): the lock screen as it stands now, in
// small, drawn from its own settings (picture, blur, colour left, dim, vignette, the clock's face, weight, size, tracking
// and colour, the date, which parts show and where they sit). A press on it opens the lock screen to arrange by hand;
// beside it that key, locking now, and the parts it shows, each a press away.
Item {
    id: root
    signal action(string id)
    signal pickGroup(string title)

    readonly property var lock: Config.options?.iris?.lock ?? ({})
    readonly property var scene: root.lock.scene ?? ({})
    readonly property var type: root.lock.type ?? ({})
    readonly property var blocks: root.lock.blocks ?? ({})
    readonly property string source: String(root.scene.source ?? "desktop")
    readonly property string picture: root.source === "custom" && String(root.scene.path ?? "").length > 0
        ? String(root.scene.path) : String(Config.options?.background?.wallpaperPath ?? "")
    readonly property bool hyprlock: Boolean(Config.options?.lock?.useHyprlock ?? false)

    readonly property var screen: Quickshell.screens[0] ?? null
    readonly property real screenW: Math.max(1, Number(root.screen?.width ?? 1920))
    readonly property real screenH: Math.max(1, Number(root.screen?.height ?? 1080))
    readonly property real gap: PrismTheme.dp(20)
    readonly property bool narrow: root.width < PrismTheme.dp(680)
    readonly property real miniW: root.narrow ? root.width : Math.round(root.width * 0.6)
    readonly property real miniH: Math.round(root.miniW * Math.min(0.75, root.screenH / root.screenW))
    // One pixel of the screen in the miniature.
    readonly property real k: root.miniW / root.screenW
    readonly property real typeScale: Number(root.type.scale ?? 100) / 100
    implicitHeight: root.narrow ? root.miniH + root.gap + side.implicitHeight : Math.max(root.miniH, side.implicitHeight)

    function on(block: string, fallback: bool): bool { return Boolean(root.blocks?.[block]?.enable ?? fallback) }
    function scaleOf(block: string): real { return Number(root.blocks?.[block]?.scale ?? 100) / 100 }
    // A zone's place as fractions of the screen: where the part's centre sits.
    function placeOf(zone: string, fallback: string): point {
        const z = String(zone || fallback)
        const x = /[Ll]eft/.test(z) ? 0.2 : /[Rr]ight/.test(z) ? 0.8 : 0.5
        const y = /^top/.test(z) ? 0.24 : /^bottom/.test(z) ? 0.8 : 0.46
        return Qt.point(x, y)
    }
    readonly property color clockInk: {
        const pick = String(root.type.accent ?? "plain")
        // The same colours the lock solves over its wallpaper.
        return ({ accent: IrisStyle.accentOnMedia, highlight: IrisStyle.highlightOnMedia, wallpaper: IrisStyle.wallpaperOnMedia })[pick] ?? PrismTheme.paper
    }
    readonly property string clockFace: {
        const pick = String(root.type.clockFont ?? "numbers")
        return pick === "main" ? IrisStyle.faceText : pick === "title" ? IrisStyle.faceTitle : IrisStyle.faceFigures
    }
    readonly property var now: DateTime.clock.date
    readonly property string dateSaid: {
        const format = ({ long: "dddd, d MMMM", short: "ddd d MMM", numeric: "d/M/yy", weekday: "dddd" })[String(root.type.dateFormat ?? "long")] ?? "dddd, d MMMM"
        return Translation.locale.toString(root.now, format)
    }
    readonly property string timeSaid: {
        const format = String(root.type.clockFormat ?? "auto")
        const twelve = format === "12h" || format === "12"
        return Qt.formatTime(root.now, twelve ? "h:mm" : "hh:mm")
    }

    ClippingRectangle {
        id: mini
        width: root.miniW
        height: root.miniH
        radius: PrismTheme.dp(22)
        color: root.source === "colour" ? ColorUtils.mix(IrisStyle.accent, PrismTheme.night, 0.22) : PrismTheme.night

        Image {
            id: picture
            visible: false
            anchors.fill: parent
            source: root.source === "colour" || root.picture.length === 0 ? "" : Wallpapers.stillUrlFor(root.picture)
            sourceSize.width: Math.round(root.miniW * 1.5)
            fillMode: String(root.scene.fit ?? "cover") === "contain" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            asynchronous: true
        }
        MultiEffect {
            anchors.fill: parent
            visible: picture.status === Image.Ready
            source: picture
            blurEnabled: Number(root.scene.blur ?? 100) > 0
            blurMax: 40
            blur: Math.min(1, Number(root.scene.blur ?? 100) / 100)
            saturation: Math.min(1, Number(root.scene.saturation ?? 15) / 100) - 1
        }
        // The vignette: the corners darkened round the middle.
        Shape {
            anchors.fill: parent
            visible: Number(root.scene.vignette ?? 0) > 0 && root.source !== "colour"
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                strokeWidth: -1
                fillGradient: RadialGradient {
                    centerX: mini.width / 2
                    centerY: mini.height / 2
                    centerRadius: Math.hypot(mini.width, mini.height) / 2
                    focalX: centerX
                    focalY: centerY
                    GradientStop { position: 0.45; color: "transparent" }
                    GradientStop { position: 1; color: ColorUtils.applyAlpha(PrismTheme.night, Number(root.scene.vignette ?? 0) / 100) }
                }
                PathRectangle { x: 0; y: 0; width: mini.width; height: mini.height }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: PrismTheme.night
            opacity: Number(root.scene.dim ?? 0) / 100
        }
        // The legibility wash, top and bottom or even.
        Rectangle {
            anchors.fill: parent
            readonly property string wash: String(root.scene.scrim ?? "gradient")
            visible: wash !== "none"
            opacity: Math.min(1, 0.32 * Number(root.scene.scrimStrength ?? 100) / 100)
            gradient: Gradient {
                GradientStop { position: 0; color: PrismTheme.night }
                GradientStop { position: 0.32; color: parent.wash === "flat" ? PrismTheme.night : "transparent" }
                GradientStop { position: 0.7; color: parent.wash === "flat" ? PrismTheme.night : "transparent" }
                GradientStop { position: 1; color: PrismTheme.night }
            }
        }

        // The clock, set as the lock sets it.
        Column {
            id: clock
            visible: root.on("clock", true)
            readonly property point at: root.placeOf(String(root.blocks?.clock?.zone ?? ""), "top")
            readonly property string look: String(root.blocks?.clock?.style ?? "stack")
            readonly property real s: root.k * root.typeScale * root.scaleOf("clock")
            x: Math.round(mini.width * clock.at.x - width / 2)
            y: Math.round(mini.height * clock.at.y - height / 2)
            spacing: 0
            PrismText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: clock.look === "stack" && Boolean(root.blocks?.clock?.date ?? true)
                text: root.dateSaid
                color: PrismTheme.paper
                opacity: 0.86
                font.pixelSize: Math.max(PrismTheme.dp(10), 22 * clock.s)
                font.weight: Font.DemiBold
            }
            PrismText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeSaid
                color: root.clockInk
                font.family: root.clockFace
                font.pixelSize: Math.max(PrismTheme.dp(12), Number(root.type.clockSize ?? 112) * clock.s * (clock.look === "minimal" ? 0.42 : 1))
                font.weight: Math.max(100, Math.min(900, Number(root.type.clockWeight ?? 700)))
                font.letterSpacing: Number(root.type.clockTracking ?? -2) * clock.s
            }
            PrismText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: clock.look !== "stack" && Boolean(root.blocks?.clock?.date ?? true)
                text: root.dateSaid
                color: PrismTheme.paper
                opacity: 0.86
                font.pixelSize: Math.max(PrismTheme.dp(10), 20 * clock.s)
                font.weight: Font.DemiBold
            }
        }
        // At a glance: what it would tell, as small smoked marks under the clock.
        Row {
            visible: root.on("glance", true)
            readonly property point at: root.placeOf(String(root.blocks?.glance?.zone ?? ""), "top")
            readonly property bool underClock: clock.visible && at.x === clock.at.x && at.y === clock.at.y
            x: Math.round(mini.width * at.x - width / 2)
            y: underClock ? clock.y + clock.height + PrismTheme.dp(6) : Math.round(mini.height * at.y - height / 2)
            spacing: PrismTheme.dp(4)
            Repeater {
                model: [
                    { on: Boolean(root.blocks?.glance?.weather ?? true), glyph: "partly_cloudy_day" },
                    { on: Boolean(root.blocks?.glance?.events ?? true), glyph: "event" },
                    { on: Boolean(root.blocks?.glance?.battery ?? true) && Battery.available, glyph: "battery_5_bar" }
                ].filter(entry => entry.on)
                delegate: Rectangle {
                    required property var modelData
                    width: PrismTheme.dp(20)
                    height: PrismTheme.dp(14)
                    radius: height / 2
                    color: PrismTheme.spot
                    PrismGlyph {
                        anchors.centerIn: parent
                        text: parent.modelData.glyph
                        iconSize: PrismTheme.dp(10)
                        color: PrismTheme.paper
                    }
                }
            }
        }
        // Now playing, on its plate or bare.
        Rectangle {
            visible: root.on("media", true)
            readonly property point at: root.placeOf(String(root.blocks?.media?.zone ?? ""), "center")
            readonly property real s: root.k * root.scaleOf("media")
            width: Math.max(PrismTheme.dp(80), 360 * s)
            height: Math.max(PrismTheme.dp(26), 88 * s)
            x: Math.round(mini.width * at.x - width / 2)
            y: Math.round(mini.height * Math.max(at.y, clock.visible ? 0.58 : 0) - height / 2)
            radius: PrismTheme.dp(8)
            color: String(root.blocks?.media?.style ?? "plate") === "bare" ? "transparent" : PrismTheme.spot
            Rectangle {
                id: art
                x: PrismTheme.dp(5)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - PrismTheme.dp(10)
                height: width
                radius: PrismTheme.dp(4)
                color: ColorUtils.applyAlpha(PrismTheme.paper, 0.22) // iris-literal: the lock's own glass, drawn small over its picture
            }
            PrismText {
                anchors.left: art.right
                anchors.leftMargin: PrismTheme.dp(6)
                anchors.right: parent.right
                anchors.rightMargin: PrismTheme.dp(6)
                anchors.verticalCenter: parent.verticalCenter
                text: String(MprisController.activePlayer?.trackTitle ?? "") || Translation.tr("Now playing")
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.dp(9)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
        // Signing in: the picture, the name and the field.
        Column {
            readonly property point at: root.placeOf(String(root.blocks?.session?.zone ?? ""), "bottom")
            readonly property real s: root.k * root.scaleOf("session")
            x: Math.round(mini.width * at.x - width / 2)
            y: Math.round(mini.height * at.y - height / 2)
            spacing: PrismTheme.dp(3)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: Boolean(root.blocks?.session?.avatar ?? true)
                width: Math.max(PrismTheme.dp(14), 56 * parent.s)
                height: width
                radius: width / 2
                color: ColorUtils.applyAlpha(PrismTheme.paper, 0.3) // iris-literal: the sign-in field's glass, drawn small
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(PrismTheme.dp(48), Number(root.blocks?.session?.width ?? 248) * parent.s)
                height: Math.max(PrismTheme.dp(10), 36 * parent.s)
                radius: height / 2
                color: PrismTheme.spot
            }
        }
        // Status, in small type at its corner.
        Row {
            visible: root.on("status", false)
            readonly property point at: root.placeOf(String(root.blocks?.status?.zone ?? ""), "topRight")
            x: Math.round(Math.min(mini.width - width - PrismTheme.dp(10), Math.max(PrismTheme.dp(10), mini.width * at.x - width / 2)))
            y: Math.round(Math.min(mini.height - height - PrismTheme.dp(8), Math.max(PrismTheme.dp(8), mini.height * at.y - height / 2)))
            spacing: PrismTheme.dp(3)
            Repeater {
                model: ["battery_5_bar", "wifi", "keyboard"]
                delegate: PrismGlyph {
                    required property string modelData
                    text: modelData
                    iconSize: PrismTheme.dp(10)
                    color: PrismTheme.paper
                    opacity: 0.86
                }
            }
        }

        // The way in: under the pointer the miniature says what a press does.
        Rectangle {
            anchors.fill: parent
            color: PrismTheme.night
            opacity: miniHit.containsMouse ? 0.32 : 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
        }
        PrismPill {
            anchors.centerIn: parent
            opacity: miniHit.containsMouse ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            tone: "art"
            glyph: "open_with"
            text: Translation.tr("Arrange it here")
            onClicked: root.action("lockEdit")
        }
        MouseArea {
            id: miniHit
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.action("lockEdit")
        }
    }

    Column {
        id: side
        x: root.narrow ? 0 : mini.width + root.gap
        y: root.narrow ? mini.height + root.gap : 0
        width: root.narrow ? root.width : root.width - x
        spacing: PrismTheme.dp(10)

        PrismPill {
            tone: "solid"
            glyph: "open_with"
            text: Translation.tr("Edit on the lock screen")
            onClicked: root.action("lockEdit")
        }
        PrismText {
            width: parent.width
            text: root.hyprlock ? Translation.tr("Hyprlock locks the screen now, not this one.")
                : Translation.tr("Drag the clock, the player and the field.")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
        }
        PrismPill {
            tone: "quiet"
            glyph: "lock"
            text: Translation.tr("Lock now")
            onClicked: root.action("lockNow")
        }
        Item { width: 1; height: PrismTheme.dp(8) }
        PrismText {
            text: Translation.tr("What it shows")
            font.pixelSize: PrismTheme.body
            font.weight: Font.DemiBold
        }
        Flow {
            width: parent.width
            spacing: PrismTheme.dp(6)
            Repeater {
                model: [
                    { label: "Clock", glyph: "schedule", path: "iris.lock.blocks.clock.enable" },
                    { label: "At a glance", glyph: "partly_cloudy_day", path: "iris.lock.blocks.glance.enable" },
                    { label: "Now playing", glyph: "music_note", path: "iris.lock.blocks.media.enable" },
                    { label: "Activity", glyph: "timer", path: "iris.lock.blocks.activity.enable" },
                    { label: "Status", glyph: "wifi", path: "iris.lock.blocks.status.enable" },
                    { label: "Avatar", glyph: "account_circle", path: "iris.lock.blocks.session.avatar" }
                ]
                delegate: Rectangle {
                    id: part
                    required property var modelData
                    readonly property var row: PrismModel.find(part.modelData.path)
                    readonly property bool shown: { const _ = PrismModel.revision; return part.row ? Boolean(PrismModel.read(part.row)) : false }
                    visible: part.row !== null
                    width: partRow.implicitWidth + PrismTheme.dp(24)
                    height: PrismTheme.dp(32)
                    radius: height / 2
                    color: part.shown ? PrismTheme.accentPlate : partHit.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                    Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
                    Row {
                        id: partRow
                        anchors.centerIn: parent
                        spacing: PrismTheme.dp(6)
                        PrismGlyph {
                            anchors.verticalCenter: parent.verticalCenter
                            text: part.shown ? "check" : part.modelData.glyph
                            iconSize: PrismTheme.dp(16)
                            color: part.shown ? PrismTheme.accentInk : PrismTheme.ink2
                        }
                        PrismText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Translation.tr(part.modelData.label)
                            color: part.shown ? PrismTheme.ink : PrismTheme.ink2
                            font.pixelSize: PrismTheme.body
                            font.weight: part.shown ? Font.DemiBold : Font.Normal
                        }
                    }
                    MouseArea {
                        id: partHit
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (part.row) PrismModel.write(part.row, !part.shown)
                    }
                    Accessible.role: Accessible.CheckBox
                    Accessible.checked: part.shown
                    Accessible.name: Translation.tr(part.modelData.label)
                }
            }
        }
    }
}
