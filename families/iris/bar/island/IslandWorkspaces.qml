pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.pieces

// Workspaces (his 11-06 reference): this screen's workspaces as a row of cards, each its windows' icons, its name and
// what holds it; the one you are on stands on the stronger fill with its name in the accent. A tap goes there, a card's
// key brings the focused window to it, the round key at the end opens Niri's overview. Cards past the edge scroll
// sideways (wheel or drag) and fade as they leave, by their own opacity: no layer inside the chassis.
Item {
    id: strip
    required property var workspaces
    property real plateRadius: IrisStyle.radiusRow

    readonly property real d: IrisStyle.density
    readonly property var windows: NiriService.windows ?? []
    readonly property var focused: strip.windows.find(w => w.is_focused) ?? null
    // Workspaces that hold something, and the one you are on even when empty (Niri always keeps an empty one last).
    readonly property var cards: strip.workspaces.filter(ws => ws.is_active || strip.windows.some(w => w.workspace_id === ws.id))
    readonly property real cardWidth: Math.round(164 * strip.d)

    implicitHeight: Math.round(86 * strip.d)

    function nameOf(ws: var): string {
        return String(ws.name ?? "").length > 0 ? ws.name : Translation.tr("Workspace %1").arg(ws.idx)
    }

    Flickable {
        id: flick
        anchors.left: parent.left
        anchors.right: overview.left
        anchors.rightMargin: Math.round(10 * strip.d)
        height: parent.height
        contentWidth: row.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        clip: true
        WheelHandler {
            enabled: flick.interactive
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                const step = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? event.angleDelta.x : event.angleDelta.y
                flick.contentX = Math.max(0, Math.min(flick.contentWidth - flick.width, flick.contentX - step))
            }
        }

        Row {
            id: row
            height: flick.height
            spacing: Math.round(8 * strip.d)
            Repeater {
                model: strip.cards
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var held: strip.windows.filter(w => w.workspace_id === card.modelData.id)
                    readonly property var apps: Array.from(new Set(card.held.map(w => String(w.app_id ?? "")))).slice(0, 4)
                    readonly property var lead: card.held.find(w => w.id === card.modelData.active_window_id) ?? card.held[0] ?? null
                    readonly property bool here: card.modelData.is_active
                    readonly property bool canBring: strip.focused !== null && strip.focused.workspace_id !== card.modelData.id
                    // How much of the card the strip shows: it fades as it leaves by the right edge.
                    readonly property real seen: Math.max(0, Math.min(1, (flick.width - (card.x - flick.contentX)) / card.width))
                    width: strip.cardWidth
                    height: row.height
                    radius: strip.plateRadius
                    color: card.here ? IrisStyle.fill : hover.hovered ? IrisStyle.fillHover : IrisStyle.fillQuiet
                    opacity: Math.max(0.12, card.seen * card.seen)
                    scale: tap.pressed ? IrisStyle.pressScale(0.97) : 1
                    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: tap; gesturePolicy: TapHandler.WithinBounds; onTapped: NiriService.switchToWorkspaceById(card.modelData.id) }
                    Accessible.role: Accessible.Button
                    Accessible.name: strip.nameOf(card.modelData)

                    // One window: its icon; more: up to four in a square.
                    Item {
                        id: icons
                        x: Math.round(12 * strip.d)
                        y: Math.round(11 * strip.d)
                        width: Math.round(30 * strip.d)
                        height: width
                        Glyph {
                            visible: card.apps.length === 0
                            anchors.centerIn: parent
                            text: "add"
                            iconSize: 22 * strip.d
                            color: IrisStyle.textTertiary
                        }
                        SmartAppIcon {
                            visible: card.apps.length === 1
                            anchors.centerIn: parent
                            icon: IrisPieces.appIcon(card.apps[0] ?? "")
                            fallback: "application-x-executable"
                            iconSize: icons.width
                        }
                        Grid {
                            visible: card.apps.length > 1
                            anchors.fill: parent
                            columns: 2
                            spacing: Math.round(2 * strip.d)
                            Repeater {
                                model: card.apps.length > 1 ? card.apps : []
                                SmartAppIcon {
                                    required property var modelData
                                    icon: IrisPieces.appIcon(modelData)
                                    fallback: "application-x-executable"
                                    iconSize: Math.floor((icons.width - 2 * strip.d) / 2)
                                }
                            }
                        }
                    }
                    GlyphButton {
                        visible: card.canBring
                        x: card.width - width - Math.round(9 * strip.d)
                        y: Math.round(9 * strip.d)
                        implicitWidth: Math.round(28 * strip.d)
                        glyph: "move_down"
                        glyphSize: 16 * strip.d
                        Accessible.name: Translation.tr("Bring the window here")
                        onClicked: NiriService.moveWindowToWorkspaceById(strip.focused.id, card.modelData.id, false)
                    }
                    ColumnLayout {
                        x: Math.round(12 * strip.d)
                        width: card.width - Math.round(24 * strip.d)
                        y: card.height - height - Math.round(10 * strip.d)
                        spacing: 0
                        IrisText {
                            Layout.fillWidth: true
                            text: strip.nameOf(card.modelData)
                            color: card.here ? IrisStyle.accent : IrisStyle.text
                            font.pixelSize: IrisStyle.typeLabel
                            font.weight: IrisStyle.weight(Font.DemiBold)
                            elide: Text.ElideRight
                        }
                        IrisText {
                            Layout.fillWidth: true
                            readonly property string app: card.lead
                                ? (AppSearch.lookupDesktopEntry(card.lead.app_id ?? "")?.name ?? String(card.lead.app_id ?? "")) : ""
                            text: card.held.length === 0 ? Translation.tr("Empty")
                                : (card.held.length === 1 ? Translation.tr("1 window") : Translation.tr("%1 windows").arg(card.held.length))
                                    + (app.length > 0 ? " · " + app : "")
                            color: IrisStyle.textSecondary
                            font.pixelSize: IrisStyle.typeMeta
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    GlyphButton {
        id: overview
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.round(58 * strip.d)
        glyph: "crop_free"
        glyphSize: 26 * strip.d
        Accessible.name: Translation.tr("Overview")
        onClicked: NiriService.toggleOverview()
    }
}
