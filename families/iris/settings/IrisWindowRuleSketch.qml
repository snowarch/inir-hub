pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style

// Where and how an app's windows open, drawn: a screen wearing the wallpaper, the workspace they land on, and the
// window as it opens (a column of its width beside the next one, floating, maximized or the whole screen), as
// see-through as the rule says, marked when captures leave it out. It moves to each new value; the caption says it.
Column {
    id: root

    property var rule: null
    property string icon: ""
    property string screenName: ""
    property string workspaceName: ""
    property string caption: ""
    readonly property real d: IrisStyle.settingsDensity
    readonly property string open: String(root.rule?.open ?? "")
    readonly property real share: Number(root.rule?.width ?? 0) > 0 ? Number(root.rule.width) : 0.5
    readonly property bool named: String(root.rule?.workspace ?? "").length > 0

    spacing: Math.round(8 * root.d)

    Rectangle {
        id: bezel
        width: root.width
        height: Math.max(0, root.height - note.implicitHeight - root.spacing)
        radius: Math.round(8 * root.d) // iris-literal: a drawn monitor's bezel, as on Display's desk
        color: "#0b0b0c" // iris-literal: the bezel is the hardware's black, whatever the theme
        border.width: 1
        border.color: IrisStyle.hairline

        Item {
            id: glass
            anchors.fill: parent
            anchors.margins: Math.max(2, Math.round(3 * root.d))
            clip: true
            readonly property real gap: Math.round(6 * root.d)

            Image {
                anchors.fill: parent
                source: Wallpapers.effectiveWallpaperUrl
                sourceSize.width: Math.round(360 * root.d)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
            }

            // The workspace it lands on: a stack of them down the left, the one it opens on lit.
            Column {
                x: glass.gap
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(4 * root.d)
                visible: root.open !== "fullscreen"
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        readonly property bool here: typeof root.rule?.workspace === "number" ? root.rule.workspace - 1 === index : index === 0
                        width: Math.round(4 * root.d)
                        height: here ? Math.round(14 * root.d) : Math.round(6 * root.d)
                        radius: width / 2
                        color: "#ffffff" // iris-literal: marks over a wallpaper, never the theme's ink
                        opacity: here && root.named ? 1 : 0.45
                        Behavior on height { NumberAnimation { duration: IrisStyle.duration(220); easing.type: Easing.OutCubic } }
                    }
                }
            }

            // The column after it on the strip: the windows that were already there.
            Rectangle {
                visible: root.open === "" || root.open === "tiled"
                x: win.x + win.width + glass.gap
                y: glass.gap
                width: glass.width * 0.5
                height: glass.height - glass.gap * 2
                radius: Math.round(6 * root.d) // iris-literal: a window drawn at the sketch's scale
                color: IrisStyle.surfaceHighestOpaque
                opacity: 0.45
            }

            Rectangle {
                id: win
                readonly property real inset: Math.round(14 * root.d)
                x: root.open === "fullscreen" ? 0 : root.open === "floating" ? (glass.width - win.width) / 2 : inset
                y: root.open === "fullscreen" ? 0 : root.open === "floating" ? glass.height * 0.2 : glass.gap
                width: root.open === "fullscreen" ? glass.width : root.open === "maximized" ? glass.width - inset - glass.gap
                    : Math.max(Math.round(48 * root.d), (glass.width - inset) * root.share - glass.gap)
                height: root.open === "fullscreen" ? glass.height : root.open === "floating" ? glass.height * 0.6 : glass.height - glass.gap * 2
                radius: root.open === "fullscreen" ? 0 : Math.round(6 * root.d) // iris-literal: a window drawn at the sketch's scale
                color: IrisStyle.surfaceHighestOpaque
                opacity: Number(root.rule?.opacity ?? 1)
                Behavior on x { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                Behavior on height { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(180); easing.type: Easing.OutCubic } }

                // A window's face (its lines of text), so how see-through it is reads against the wallpaper.
                Column {
                    x: Math.round(10 * root.d)
                    y: Math.round(10 * root.d)
                    spacing: Math.round(6 * root.d)
                    visible: win.height > Math.round(56 * root.d)
                    Repeater {
                        model: [0.62, 0.44, 0.54]
                        Rectangle {
                            required property real modelData
                            width: Math.max(0, (win.width - Math.round(20 * root.d)) * modelData)
                            height: Math.round(4 * root.d)
                            radius: height / 2
                            color: IrisStyle.fillHover
                        }
                    }
                }
                Image {
                    id: appIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    // Under the face's lines on a short window, in the middle of a tall one.
                    y: Math.max(Math.round(40 * root.d), (win.height - appIcon.height) / 2)
                    width: Math.round(Math.min(32 * root.d, parent.height * 0.4))
                    height: width
                    sourceSize: Qt.size(64, 64)
                    source: root.icon
                    visible: root.icon.length > 0
                    asynchronous: true
                }
            }

            // Left out of screenshots and recordings: the window says so on its corner.
            Rectangle {
                visible: root.rule?.hidden === true
                x: win.x + win.width - width - Math.round(6 * root.d)
                y: win.y + Math.round(6 * root.d)
                width: Math.round(24 * root.d)
                height: width
                radius: width / 2
                color: IrisStyle.surface
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "visibility_off"
                    iconSize: Math.round(14 * root.d)
                    color: IrisStyle.text
                }
            }

            // Names only the drawing cannot show: a named workspace, a screen of its own.
            Row {
                x: glass.gap
                anchors.bottom: parent.bottom
                anchors.bottomMargin: glass.gap
                spacing: Math.round(4 * root.d)
                Repeater {
                    model: [root.named && typeof root.rule?.workspace !== "number" ? root.workspaceName : "", root.screenName].filter(text => text.length > 0)
                    Rectangle {
                        required property string modelData
                        width: tag.implicitWidth + Math.round(12 * root.d)
                        height: Math.round(20 * root.d)
                        radius: height / 2
                        color: IrisStyle.surface
                        IrisText {
                            id: tag
                            anchors.centerIn: parent
                            text: parent.modelData
                            font.pixelSize: IrisStyle.typeCaption
                            font.weight: IrisStyle.weight(Font.Medium)
                        }
                    }
                }
            }
        }
    }

    IrisText {
        id: note
        width: root.width
        text: root.caption
        wrapMode: Text.Wrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.subtext
    }
}
