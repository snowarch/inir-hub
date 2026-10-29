pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks

// The taskbar as the switches below leave it, over the person's own wallpaper: edge, alignment, tinted icons and
// tray, seconds and the unread badge change here as they are flipped, before anyone looks down at the real one.
Rectangle {
    id: root

    readonly property var bar: Config.options?.waffles?.bar ?? ({})
    readonly property bool atBottom: root.bar.bottom ?? true
    readonly property bool leftAlign: root.bar.leftAlignApps ?? false
    readonly property bool tintApps: root.bar.monochromeIcons ?? false
    readonly property bool tintTray: root.bar.tintTrayIcons ?? false
    readonly property bool seconds: Config.options?.time?.secondPrecision ?? false
    readonly property bool unread: root.bar?.notifications?.showUnreadCount ?? true

    Layout.fillWidth: true
    implicitHeight: Looks.dp(164)
    radius: Looks.settings.radiusSmall
    color: Looks.settings.card
    border.width: 1
    border.color: Looks.settings.cardStroke
    clip: true

    Rectangle {
        id: shot
        anchors.fill: parent
        anchors.margins: 1
        radius: Looks.settings.radiusSmall
        clip: true
        color: Looks.colors.bg0

        StyledImage {
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: Wallpapers.effectiveWallpaperUrl
            sourceSize.width: 1000
            asynchronous: true
            cache: false
        }

        // the bar, 48 px like Windows', drawn at three quarters
        Rectangle {
            id: strip
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.atBottom ? parent.height - height : 0
            height: Looks.dp(36)
            color: Qt.alpha(Looks.colors.bg1Base, Looks.dark ? 0.86 : 0.9)
            Behavior on y {
                animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                y: root.atBottom ? 0 : parent.height - 1
                height: 1
                color: Qt.alpha(Looks.colors.fg, 0.08)
            }

            Row {
                id: apps
                anchors.verticalCenter: parent.verticalCenter
                x: root.leftAlign ? Looks.dp(10) : (strip.width - apps.width) / 2
                spacing: Looks.dp(6)
                Behavior on x {
                    animation: NumberAnimation { duration: Looks.transition.enabled ? Looks.transition.duration.medium : 0; easing.type: Easing.BezierSpline; easing.bezierCurve: Looks.transition.easing.bezierCurve.standard }
                }

                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "start-here"
                    implicitSize: Looks.dp(20)
                    isMask: false
                }
                FluentIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "search"
                    implicitSize: Looks.dp(16)
                    color: Looks.colors.fg
                }
                Repeater {
                    // five apps, the first two open
                    model: ["#F0883E", "#3B82F6", "#8B8B8B", "#22C55E", "#A855F7"]
                    delegate: Item {
                        id: app
                        required property string modelData
                        required property int index
                        width: Looks.dp(26)
                        height: Looks.dp(30)
                        Rectangle {
                            anchors.centerIn: parent
                            width: Looks.dp(18)
                            height: Looks.dp(18)
                            radius: Looks.dp(4)
                            color: root.tintApps ? Looks.colors.accent : app.modelData
                            Behavior on color {
                                animation: ColorAnimation { duration: Looks.transition.enabled ? 160 : 0 }
                            }
                        }
                        Rectangle {
                            visible: app.index < 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            width: app.index === 0 ? Looks.dp(12) : Looks.dp(5)
                            height: Looks.dp(3)
                            radius: height / 2
                            color: app.index === 0 ? Looks.colors.accent : Qt.alpha(Looks.colors.fg, 0.55)
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Looks.dp(10)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Looks.dp(8)

                Repeater {
                    model: ["wifi-4", "speaker", "battery-7"]
                    delegate: FluentIcon {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        icon: modelData
                        implicitSize: Looks.dp(14)
                        color: root.tintTray ? Looks.colors.accent : Looks.colors.fg
                    }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    WText {
                        anchors.right: parent.right
                        text: root.seconds ? Qt.formatTime(DateTime.clock.date, "hh:mm:ss") : DateTime.time
                        font.pixelSize: Looks.dp(10)
                        font.features: { "tnum": 1 }
                    }
                    WText {
                        anchors.right: parent.right
                        text: DateTime.shortDate
                        font.pixelSize: Looks.dp(10)
                    }
                }
                Rectangle {
                    visible: root.unread
                    anchors.verticalCenter: parent.verticalCenter
                    width: Looks.dp(16)
                    height: Looks.dp(16)
                    radius: width / 2
                    color: Looks.colors.accent
                    WText {
                        anchors.centerIn: parent
                        text: "2"
                        font.pixelSize: Looks.dp(9)
                        font.weight: Looks.font.weight.strong
                        color: Looks.colors.accentFg
                    }
                }
            }
        }

        // what the bar is set to, in words, on a chip at the open edge
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.atBottom ? Looks.dp(14) : parent.height - height - Looks.dp(14)
            width: chipText.implicitWidth + Looks.dp(20)
            height: Looks.dp(24)
            radius: Looks.settings.radiusSmall
            color: Qt.alpha(Looks.colors.bg1Base, 0.9)
            WText {
                id: chipText
                anchors.centerIn: parent
                text: [root.leftAlign ? Translation.tr("Apps on the left") : Translation.tr("Apps centered"),
                    root.atBottom ? Translation.tr("bottom edge") : Translation.tr("top edge"),
                    root.tintApps ? Translation.tr("tinted icons") : ""].filter(t => t.length > 0).join(" · ")
                font.pixelSize: Looks.settings.caption
            }
        }
    }
}
