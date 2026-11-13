pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The Island's designs as themselves: each one alive in a small Island hanging from a strip of the person's own
// wallpaper, its name and what it shows under it. The worn one's name sits in the solid pill Prism chooses with; a
// press wears it. The faces are the shell's own (bar/island/designs/<id>/Face.qml), never a drawing of them.
Item {
    id: root
    property var choices: []
    property var current
    signal picked(var value)

    readonly property real gap: PrismTheme.dp(10)
    readonly property int columns: root.width >= PrismTheme.dp(600) ? 3 : 2
    readonly property real cardWidth: Math.floor((root.width - (root.columns - 1) * root.gap) / root.columns)
    readonly property real cardHeight: PrismTheme.dp(150)
    readonly property url wallpaper: Wallpapers.stillUrlFor(String(Wallpapers.effectiveWallpaperPath ?? ""))
    implicitHeight: Math.ceil(root.choices.length / root.columns) * (root.cardHeight + root.gap) - root.gap

    // What a face reads of the Island, at a card's size.
    QtObject {
        id: sample
        readonly property real compactHeight: PrismTheme.dp(34)
        readonly property real faceRoom: Math.max(0, root.cardWidth - PrismTheme.dp(52))
        readonly property color clockAccent: IrisStyle.clockAccent
        readonly property real figureSize: IrisStyle.typeHeadline
        readonly property bool nothingLook: IrisStyle.nothingAt("island")
        readonly property bool zoned: false
        readonly property bool vertical: false
    }
    // Halo is the Island's own clock, drawn inline by the bar: here the same clock.
    Component {
        id: haloFace
        Item {
            readonly property real contentWidth: haloClock.implicitWidth + PrismTheme.dp(22)
            IrisClock {
                id: haloClock
                anchors.centerIn: parent
                family: IrisStyle.figureFace(pixelSize)
                minorFamily: family
                pixelSize: IrisStyle.typeHeadline
                separatorColor: IrisStyle.clockAccent
            }
        }
    }

    Repeater {
        model: root.choices
        delegate: Item {
            id: card
            required property var modelData
            required property int index
            readonly property bool chosen: PrismModel.same(card.modelData.value, root.current)
            x: (card.index % root.columns) * (root.cardWidth + root.gap)
            y: Math.floor(card.index / root.columns) * (root.cardHeight + root.gap)
            width: root.cardWidth
            height: root.cardHeight
            scale: press.pressed ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            Accessible.role: Accessible.RadioButton
            Accessible.name: Translation.tr(card.modelData.label)
            Accessible.checked: card.chosen

            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(20)
                color: card.chosen || press.containsMouse ? PrismTheme.fillHover : PrismTheme.fill
                Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
            }
            // A strip of the person's screen, the Island hanging from its top edge as it does on theirs.
            ClippingRectangle {
                id: screen
                x: PrismTheme.dp(6)
                y: PrismTheme.dp(6)
                width: parent.width - 2 * x
                height: PrismTheme.dp(78)
                radius: PrismTheme.dp(15)
                color: PrismTheme.night
                Image {
                    anchors.fill: parent
                    source: root.wallpaper
                    sourceSize.width: PrismTheme.dp(360)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                // The wallpaper settles under the Island so its face reads as it does on a bright desktop.
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.alpha(PrismTheme.night, 0.5) }
                        GradientStop { position: 1; color: Qt.alpha(PrismTheme.night, 0.15) }
                    }
                }
                Rectangle {
                    id: body
                    readonly property real want: (face.item?.contentWidth ?? PrismTheme.dp(110)) + PrismTheme.dp(24)
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: PrismTheme.dp(9)
                    width: Math.min(screen.width - PrismTheme.dp(16), body.want)
                    height: sample.compactHeight
                    radius: height / 2
                    color: IrisStyle.bodySurface
                    clip: true
                    Behavior on width { NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
                    Loader {
                        id: face
                        anchors.fill: parent
                        asynchronous: true
                        sourceComponent: card.modelData.value === "halo" ? haloFace : null
                        source: card.modelData.value === "halo" ? "" : Qt.resolvedUrl("../../bar/island/designs/" + card.modelData.value + "/Face.qml")
                        onLoaded: if (item && item.island !== undefined) item.island = sample
                        // A card torn down while its face still compiles keeps the Loader alive a moment in a dead
                        // context, and Qt creates the face there ("invalid context"): let go while it still lives.
                        Component.onDestruction: face.active = false
                    }
                }
            }
            // The name, in the solid pill once worn; what it shows under it.
            Item {
                id: nameRow
                anchors.top: screen.bottom
                anchors.topMargin: PrismTheme.dp(9)
                x: PrismTheme.dp(8)
                width: parent.width - 2 * x
                height: PrismTheme.dp(24)
                Rectangle {
                    width: label.implicitWidth + PrismTheme.dp(card.chosen ? 34 : 0)
                    height: parent.height
                    radius: height / 2
                    color: card.chosen ? PrismTheme.solid : "transparent"
                    Behavior on width { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
                }
                PrismGlyph {
                    id: tick
                    visible: card.chosen
                    x: PrismTheme.dp(7)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "check"
                    iconSize: PrismTheme.dp(14)
                    color: PrismTheme.inkSolid
                }
                PrismText {
                    id: label
                    x: card.chosen ? tick.x + tick.width + PrismTheme.dp(4) : PrismTheme.dp(2)
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr(card.modelData.label)
                    font.pixelSize: PrismTheme.body
                    font.weight: Font.DemiBold
                    color: card.chosen ? PrismTheme.inkSolid : PrismTheme.ink
                }
            }
            PrismText {
                anchors.top: nameRow.bottom
                anchors.topMargin: PrismTheme.dp(3)
                x: PrismTheme.dp(10)
                width: parent.width - 2 * x
                text: Translation.tr(String(card.modelData.detail ?? ""))
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.caption
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            MouseArea {
                id: press
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(card.modelData.value)
            }
        }
    }
}
