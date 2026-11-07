import QtQuick
import QtQuick.Effects
import qs.services
import qs.modules.iris.prism.core

// A long page's groups as one line of words, the reference's "Songs  Albums  Artists": the open one on a solid pill,
// the rest in grey ink. More than the line holds slides sideways (wheel or drag) and fades at the edge it continues
// past; the open one is kept in view.
Item {
    id: root
    property var choices: []      // { label, value }
    property var current
    signal picked(var value)

    implicitHeight: PrismTheme.dp(34)

    // The open tab is brought into view once the line has its widths.
    property Item pending: null
    Timer { id: showLater; interval: 0; onTriggered: root.show(root.pending) }

    function show(item: Item): void {
        if (!item) return
        const pad = PrismTheme.dp(28)
        if (item.x - pad < strip.contentX) strip.contentX = Math.max(0, item.x - pad)
        else if (item.x + item.width + pad > strip.contentX + strip.width)
            strip.contentX = Math.min(strip.contentWidth - strip.width, item.x + item.width + pad - strip.width)
    }

    Flickable {
        id: strip
        anchors.fill: parent
        contentWidth: line.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        Behavior on contentX { enabled: !strip.dragging && !strip.flicking; NumberAnimation { duration: PrismTheme.ms(260); easing.type: Easing.OutCubic } }
        layer.enabled: strip.contentWidth > strip.width
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: fade
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Row {
            id: line
            height: strip.height
            spacing: PrismTheme.dp(4)
            Repeater {
                model: root.choices
                delegate: Item {
                    id: tab
                    required property var modelData
                    readonly property bool chosen: JSON.stringify(tab.modelData.value) === JSON.stringify(root.current)
                    width: words.implicitWidth + PrismTheme.dp(26)
                    height: line.height
                    onChosenChanged: if (tab.chosen) { root.pending = tab; showLater.restart() }
                    Component.onCompleted: if (tab.chosen) { root.pending = tab; showLater.restart() }
                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: tab.chosen ? PrismTheme.solid : area.pressed ? PrismTheme.fillPress : area.containsMouse ? PrismTheme.fill : "transparent"
                        Behavior on color { ColorAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
                    }
                    PrismText {
                        id: words
                        anchors.centerIn: parent
                        text: Translation.tr(String(tab.modelData.label))
                        font.pixelSize: PrismTheme.body
                        font.weight: tab.chosen ? Font.DemiBold : Font.Medium
                        color: tab.chosen ? PrismTheme.inkSolid : area.containsMouse ? PrismTheme.ink : PrismTheme.ink2
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.PageTab
                        Accessible.name: words.text
                        onClicked: root.picked(tab.modelData.value)
                    }
                }
            }
        }
        // The wheel slides the line sideways; a page scroll passes on when the line is whole.
        WheelHandler {
            enabled: strip.contentWidth > strip.width
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const delta = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y
                strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width, strip.contentX - delta))
                event.accepted = true
            }
        }
    }

    // The mask: whole in the middle, fading at an edge only where the line goes on past it.
    Item {
        id: fade
        anchors.fill: strip
        visible: false
        layer.enabled: true
        readonly property real reach: PrismTheme.dp(40)
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: strip.contentX > 1 ? "transparent" : "white" } // iris-literal: a mask, only its alpha counts
                GradientStop { position: fade.reach / Math.max(1, fade.width); color: "white" } // iris-literal: a mask
                GradientStop { position: 1 - fade.reach / Math.max(1, fade.width); color: "white" } // iris-literal: a mask
                GradientStop { position: 1; color: strip.contentX < strip.contentWidth - strip.width - 1 ? "transparent" : "white" } // iris-literal: a mask
            }
        }
    }
}
