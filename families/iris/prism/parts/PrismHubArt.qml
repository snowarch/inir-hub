import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// A hub item's picture as art (`.claude/ref/language`): its preview edge to edge, or, with none yet, its kind's ribbon
// with the kind's mark printed white, so a catalogue of items without pictures still reads as a shelf of sleeves. With
// a sheet, the picture's foot turns to frosted glass (glass-card-pink-sky) that holds what the host puts in it.
Item {
    id: root
    property var item: null
    property real radius: PrismTheme.dp(16)
    // The frosted foot's height; 0 draws none.
    property real sheetHeight: 0
    default property alias sheet: sheetBox.data

    readonly property string kind: String(root.item?.kind ?? "")
    readonly property bool ready: picture.status === Image.Ready
    // Each kind its own ribbon, so a shelf of items without pictures still says what each one is.
    readonly property var tints: ({ widget: "amber", theme: "pink", "iris-theme": "violet", webapp: "teal", component: "blue", design: "orange", family: "indigo" })
    readonly property var glyphs: ({ widget: "widgets", theme: "palette", "iris-theme": "style", webapp: "language", component: "extension", design: "brush", family: "dashboard" })
    readonly property real seed: {
        const id = String(root.item?.id ?? "")
        let sum = 0
        for (let i = 0; i < id.length; i++) sum += id.charCodeAt(i) * (i + 1)
        return (sum % 97) / 9.7
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: PrismTheme.night

        Item {
            id: scene
            anchors.fill: parent
            PrismFlow {
                anchors.fill: parent
                visible: !root.ready
                dark: true
                tint: root.tints[root.kind] ?? "grey"
                seed: root.seed
                thickness: 0.5
            }
            PrismGlyph {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.sheetHeight / 2
                visible: !root.ready
                text: root.glyphs[root.kind] ?? "extension"
                filled: true
                iconSize: Math.round(Math.min(root.width, root.height - root.sheetHeight) * 0.24)
                color: PrismTheme.paper
            }
            IrisImage {
                id: picture
                anchors.fill: parent
                source: root.item?.previewUrl ?? ""
                opacity: root.ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(220); easing.type: Easing.OutCubic } }
            }
        }

        // The frosted foot: the picture under it, blurred and darkened, holds the words.
        ShaderEffectSource {
            id: under
            visible: false
            x: sheetBox.x; y: sheetBox.y; width: sheetBox.width; height: sheetBox.height
            sourceItem: root.sheetHeight > 0 ? scene : null
            sourceRect: Qt.rect(sheetBox.x, sheetBox.y, sheetBox.width, sheetBox.height)
        }
        MultiEffect {
            visible: root.sheetHeight > 0
            x: sheetBox.x; y: sheetBox.y; width: sheetBox.width; height: sheetBox.height
            source: under
            blurEnabled: true
            blur: 1
            blurMax: 48
            brightness: -0.12
        }
        Rectangle {
            id: sheetBox
            visible: root.sheetHeight > 0
            y: root.height - height
            width: root.width
            height: root.sheetHeight
            color: PrismTheme.glassSheet
            Rectangle { width: parent.width; height: 1; color: PrismTheme.spotEdge }
        }
    }
}
