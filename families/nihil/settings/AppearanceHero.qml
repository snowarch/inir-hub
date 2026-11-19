pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.nihil.style

// The head of Appearance: the wallpaper the glass is lit by, and the lights to choose from over it.
ClippingRectangle {
    id: root

    required property var host

    readonly property string chosen: NihilStyle.paletteName
    readonly property var lights: [
        { id: "filament", word: Translation.tr("Filament") },
        { id: "copper", word: Translation.tr("Copper") },
        { id: "signal", word: Translation.tr("Signal") },
        { id: "glacier", word: Translation.tr("Glacier") },
        { id: "sage", word: Translation.tr("Sage") },
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
            GradientStop { position: 0; color: Qt.alpha("#0C0A08", 0.78) }
            GradientStop { position: 0.62; color: Qt.alpha("#0C0A08", 0) }
        }
    }

    Column {
        x: NihilStyle.s(24)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(20)
        spacing: NihilStyle.s(12)

        NText {
            text: Translation.tr("Light")
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
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: swatch.here ? NihilStyle.s(4) : swatch.containsMouse ? NihilStyle.s(1) : NihilStyle.s(2)
                        radius: width / 2
                        color: swatch.modelData.id === "wallpaper" ? NihilStyle.pictureLight : swatch.light.light
                        Behavior on anchors.margins { NumberAnimation { duration: NihilStyle.quick } }
                    }
                }
            }
        }
    }
}
