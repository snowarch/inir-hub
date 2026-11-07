import QtQuick
import qs
import qs.services
import QtQuick.Effects
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The left column: the window's lights, iRiS's mark, the search and the pages by group, then what the person pinned.
Item {
    id: root
    signal closeRequested()
    signal growRequested()
    signal switchHost()
    // A pinned row opens its page with the row lit.
    signal reach(var row)
    property alias search: searchField
    // In a window the green light grows the window's column instead of the panel, and the host key reads "over the desktop".
    property bool windowed: false

    Rectangle {
        anchors.fill: parent
        color: PrismTheme.rail
    }
    // The haze the reference spills from its corner, in the person's accent.
    PrismGlow {
        x: -width * 0.45
        y: -height * 0.42
        width: root.width * 2.2
        height: root.width * 2.2
        colour: PrismTheme.accent
        strength: PrismTheme.light ? 0.22 : 0.36
    }
    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: PrismTheme.line
    }

    // Over the desktop or as a window: one key on the lights' line, the glyph says where it goes.
    PrismRound {
        id: hostKey
        z: 2
        x: root.width - width - PrismTheme.dp(14)
        y: PrismTheme.dp(18) + PrismTheme.dp(6) - height / 2
        implicitWidth: PrismTheme.dp(26)
        glyphSize: PrismTheme.dp(15)
        glyph: root.windowed ? "picture_in_picture_center" : "open_in_new"
        onClicked: root.switchHost()
        Accessible.name: root.windowed ? Translation.tr("Over the desktop") : Translation.tr("As a window")
        PrismText {
            visible: hostKey.hovered
            anchors.right: parent.left
            anchors.rightMargin: PrismTheme.dp(6)
            anchors.verticalCenter: parent.verticalCenter
            text: root.windowed ? Translation.tr("Over the desktop") : Translation.tr("As a window")
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.caption
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: column.implicitHeight + PrismTheme.dp(24)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        layer.enabled: sideEdge.active
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: sideEdge.mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Column {
            id: column
            x: PrismTheme.dp(20)
            width: root.width - x
            spacing: 0

            // The lights: red and yellow put Settings away, green gives it the whole room (a window: its column the screen).
            Row {
                topPadding: PrismTheme.dp(18)
                spacing: PrismTheme.dp(8)
                Repeater {
                    model: [{ c: "#ff5f57", g: "close" }, { c: "#febc2e", g: "remove" }, { c: "#28c840", g: root.windowed || !PrismState.wide ? "open_in_full" : "close_fullscreen" }] // iris-literal: macOS window lights
                    delegate: Rectangle {
                        id: light
                        required property var modelData
                        required property int index
                        width: PrismTheme.dp(12)
                        height: width
                        radius: width / 2
                        color: light.modelData.c
                        PrismGlyph {
                            anchors.centerIn: parent
                            visible: lightsHover.hovered
                            text: light.modelData.g
                            iconSize: PrismTheme.dp(9)
                            color: Qt.rgba(0, 0, 0, 0.6) // iris-literal: Prism's own fills and scrims, scheme-aware above
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -PrismTheme.dp(3)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: light.index !== 2 ? root.closeRequested()
                                : root.windowed ? root.growRequested() : (PrismState.wide = !PrismState.wide)
                        }
                    }
                }
                HoverHandler { id: lightsHover }
            }

            Row {
                topPadding: PrismTheme.dp(26)
                spacing: PrismTheme.dp(8)
                PrismGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "tune"
                    filled: true
                    iconSize: PrismTheme.dp(22)
                }
                PrismText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Translation.tr("Settings")
                    font.pixelSize: PrismTheme.head
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }
            }

            Item { width: 1; height: PrismTheme.dp(22) }
            PrismField {
                id: searchField
                width: column.width - PrismTheme.dp(20)
                height: PrismTheme.dp(34)
                glyph: "search"
                placeholder: Translation.tr("Search")
                text: PrismState.query
                onEdited: text => PrismState.query = text
                onCommitted: text => PrismState.query = text
            }

            Repeater {
                model: PrismModel.groups
                delegate: Column {
                    id: group
                    required property string modelData
                    width: column.width
                    PrismText {
                        topPadding: PrismTheme.dp(18)
                        bottomPadding: PrismTheme.dp(6)
                        text: Translation.tr(group.modelData).toUpperCase()
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.6
                    }
                    Repeater {
                        model: PrismModel.inGroup(group.modelData)
                        delegate: PrismNavItem {
                            required property var modelData
                            width: group.width
                            edge: group.width
                            glyph: modelData.glyph
                            text: Translation.tr(modelData.name)
                            current: !PrismState.searching && PrismState.page === modelData.pageId
                            onClicked: PrismState.go(modelData.pageId)
                        }
                    }
                }
            }

            // Pinned rows: the reference's playlists, each one a row the person keeps at hand.
            Column {
                id: pinned
                width: column.width
                readonly property var rows: PrismModel.pinnedRows()
                visible: pinned.rows.length > 0
                PrismText {
                    topPadding: PrismTheme.dp(18)
                    bottomPadding: PrismTheme.dp(6)
                    text: Translation.tr("Pinned").toUpperCase()
                    color: PrismTheme.ink3
                    font.pixelSize: PrismTheme.caption
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.6
                }
                Repeater {
                    model: pinned.rows
                    delegate: PrismNavItem {
                        required property var modelData
                        width: pinned.width
                        edge: pinned.width
                        glyph: modelData.glyph
                        text: Translation.tr(modelData.label)
                        trailing: "close"
                        onClicked: root.reach(modelData)
                        onTrailingClicked: PrismModel.togglePin(modelData)
                    }
                }
            }

        }
    }

    // The page list fades where it meets the panel's edge; a blurred band would be masked away with it.
    IrisScrollEdge {
        id: sideEdge
        flick: flick
        anchors.fill: flick
        blurs: false
        reach: PrismTheme.dp(28)
    }
}
