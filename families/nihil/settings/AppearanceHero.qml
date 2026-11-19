pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.nihil.style

// The head of Appearance: the wallpaper the glass stands on, and the accents to choose from over it.
ClippingRectangle {
    id: root

    required property var host

    readonly property string chosen: NihilStyle.paletteName
    readonly property var lights: [
        { id: "pearl", word: Translation.tr("Pearl") },
        { id: "glacier", word: Translation.tr("Glacier") },
        { id: "sage", word: Translation.tr("Sage") },
        { id: "coral", word: Translation.tr("Coral") },
        { id: "gold", word: Translation.tr("Gold") },
        { id: "wallpaper", word: Translation.tr("From the wallpaper") }
    ]

    height: NihilStyle.s(220)
    radius: NihilStyle.r(26)
    color: NihilStyle.well

    Image {
        anchors.fill: parent
        source: Wallpapers.effectiveWallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
    }
    // The words stay readable over any picture.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.alpha("#0B0C0F", 0.8) }
            GradientStop { position: 0.62; color: Qt.alpha("#0B0C0F", 0) }
        }
    }

    Column {
        x: NihilStyle.s(24)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(20)
        spacing: NihilStyle.s(12)

        NText {
            text: Translation.tr("Accent")
            font.pixelSize: NihilStyle.textBody
            font.weight: Font.Medium
            color: "#FFFFFF"
        }
        Row {
            spacing: NihilStyle.s(10)

            Repeater {
                model: root.lights

                MouseArea {
                    id: swatch
                    required property var modelData
                    readonly property bool here: root.chosen === swatch.modelData.id
                    readonly property var light: NihilStyle.palettes[swatch.modelData.id]

                    width: NihilStyle.s(34)
                    height: width
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: swatch.modelData.word
                    Accessible.checked: swatch.here
                    onClicked: root.host.write("look.palette", swatch.modelData.id)

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: swatch.here ? 2 : 0
                        border.color: "#FFFFFF"
                    }
                    // Pearl is the glass's own white; the wallpaper's accent shows the picture it comes from.
                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: swatch.here ? NihilStyle.s(4) : swatch.containsMouse ? NihilStyle.s(1) : NihilStyle.s(2)
                        radius: width / 2
                        color: swatch.modelData.id === "pearl" ? "#F5F6F8" : swatch.light.light || "#F5F6F8"
                        Behavior on anchors.margins { NumberAnimation { duration: NihilStyle.quick } }
                        Image {
                            anchors.fill: parent
                            visible: swatch.modelData.id === "wallpaper"
                            source: visible ? Wallpapers.effectiveWallpaperUrl : ""
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }
            }
        }
    }
}
