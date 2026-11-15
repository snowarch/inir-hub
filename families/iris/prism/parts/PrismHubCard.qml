pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One item of the hub's shelf in three forms (`.claude/ref/language`): a `card` of the grid (its sleeve over its name,
// credits in mono, its figures and the one action), a `row` of the list (a small sleeve beside the same words), and a
// `poster` of the featured band (the picture whole, the words on its frosted foot). A press anywhere but the action
// opens the item.
Item {
    id: root
    property var item: null
    // The hub page: its action plan, credits and whether figures are shown at all.
    property var hub: null
    property string form: "card" // card | row | poster
    property bool last: false
    signal open()

    readonly property var plan: root.hub ? root.hub.actionOf(root.item) : ({ text: "" })
    readonly property string stage: Hub.stateOf(root.item)
    readonly property bool pulled: root.stage === "pulled" || root.stage === "blocked"
    readonly property string credit: root.pulled ? Translation.tr("Pulled from the hub") : root.hub ? root.hub.bylineOf(root.item) : ""

    implicitHeight: root.form === "row" ? PrismTheme.dp(76) : root.form === "poster" ? PrismTheme.dp(220) : cardColumn.implicitHeight + PrismTheme.dp(16)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: String(root.item?.name ?? "")
        onClicked: root.open()
    }

    // ── card ─────────────────────────────────────────────────────────
    Rectangle {
        visible: root.form === "card"
        anchors.fill: parent
        radius: PrismTheme.dp(20)
        color: area.containsMouse ? PrismTheme.raised : PrismTheme.card
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }
    }
    Column {
        id: cardColumn
        visible: root.form === "card"
        x: PrismTheme.dp(8)
        y: PrismTheme.dp(8)
        width: root.width - PrismTheme.dp(16)
        spacing: PrismTheme.dp(10)
        PrismHubArt {
            width: parent.width
            height: Math.round(width * 10 / 16)
            radius: PrismTheme.dp(14)
            item: root.form === "card" ? root.item : null
        }
        Column {
            x: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            spacing: PrismTheme.dp(2)
            PrismText {
                width: parent.width
                text: String(root.item?.name ?? "")
                elide: Text.ElideRight
                font.pixelSize: PrismTheme.row
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.row * 0.02
            }
            Credit { width: parent.width }
        }
        Item {
            x: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            height: cardAction.implicitHeight
            // A long state ("Needs iNiR 2.40.0") takes the line; the figures step aside, never under it.
            Figures {
                anchors.verticalCenter: parent.verticalCenter
                visible: Boolean(root.hub?.hasStats) && width + cardAction.implicitWidth + PrismTheme.dp(8) <= parent.width
                brief: true
            }
            PrismHubAction {
                id: cardAction
                anchors.right: parent.right
                width: Math.min(implicitWidth, parent.width)
                plan: root.plan
            }
        }
    }

    // ── row ──────────────────────────────────────────────────────────
    Rectangle {
        visible: root.form === "row"
        anchors.fill: parent
        radius: PrismTheme.dp(14)
        color: area.containsMouse ? PrismTheme.fill : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    PrismHubArt {
        id: rowArt
        visible: root.form === "row"
        x: PrismTheme.dp(10)
        anchors.verticalCenter: parent.verticalCenter
        width: PrismTheme.dp(88)
        height: PrismTheme.dp(55)
        radius: PrismTheme.dp(10)
        item: root.form === "row" ? root.item : null
    }
    Column {
        visible: root.form === "row"
        anchors.left: rowArt.right
        anchors.leftMargin: PrismTheme.dp(14)
        anchors.right: rowEnd.left
        anchors.rightMargin: PrismTheme.dp(14)
        anchors.verticalCenter: parent.verticalCenter
        spacing: PrismTheme.dp(1)
        PrismText {
            width: parent.width
            text: String(root.item?.name ?? "")
            elide: Text.ElideRight
            font.pixelSize: PrismTheme.row
            font.weight: Font.Bold
        }
        PrismText {
            width: parent.width
            visible: text.length > 0
            text: String(root.item?.summary ?? "")
            elide: Text.ElideRight
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
        }
        Row {
            width: parent.width
            spacing: PrismTheme.dp(12)
            Credit { id: rowCredit; width: Math.min(implicitWidth, parent.width - (rowFigures.visible ? rowFigures.width + parent.spacing : 0)) }
            Figures { id: rowFigures; anchors.verticalCenter: parent.verticalCenter; visible: Boolean(root.hub?.hasStats) }
        }
    }
    Row {
        id: rowEnd
        visible: root.form === "row"
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: PrismTheme.dp(12)
        PrismGlyph {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.width >= PrismTheme.dp(560)
            opacity: Array.from(root.item?.permissions ?? []).length > 0 ? 1 : 0
            text: "shield"
            filled: true
            iconSize: PrismTheme.dp(15)
            color: PrismTheme.ink3
        }
        // Every row's action in a slot of one width, so names, figures and keys line up down the list.
        Item {
            width: Math.max(PrismTheme.dp(88), rowAction.implicitWidth)
            height: rowAction.implicitHeight
            PrismHubAction { id: rowAction; anchors.right: parent.right; plan: root.plan }
        }
    }
    Rectangle {
        visible: root.form === "row" && !root.last && !area.containsMouse
        anchors.left: rowArt.right
        anchors.leftMargin: PrismTheme.dp(14)
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(10)
        anchors.bottom: parent.bottom
        height: 1
        color: PrismTheme.line
    }

    // ── poster ───────────────────────────────────────────────────────
    PrismHubArt {
        visible: root.form === "poster"
        anchors.fill: parent
        radius: PrismTheme.dp(20)
        sheetHeight: PrismTheme.dp(78)
        item: root.form === "poster" ? root.item : null
        Column {
            x: PrismTheme.dp(18)
            width: parent.width - x - posterAction.width - PrismTheme.dp(30)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            PrismText {
                width: parent.width
                text: Translation.tr(Hub.kindName(root.item?.kind ?? "")).toUpperCase()
                elide: Text.ElideRight
                mono: true
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.caption - 1
                font.letterSpacing: 0.8
            }
            PrismText {
                width: parent.width
                text: String(root.item?.name ?? "")
                elide: Text.ElideRight
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.head
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.head * 0.02
            }
            PrismText {
                width: parent.width
                visible: text.length > 0
                text: String(root.item?.summary ?? "")
                elide: Text.ElideRight
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.small
            }
        }
        PrismHubAction {
            id: posterAction
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(16)
            anchors.verticalCenter: parent.verticalCenter
            overArt: true
            plan: root.plan
        }
    }

    // Kind and authors, in the collection's mono credit.
    component Credit: PrismText {
        text: root.credit.toUpperCase()
        elide: Text.ElideRight
        mono: true
        color: root.pulled ? PrismTheme.tint("red") : PrismTheme.ink3
        font.pixelSize: PrismTheme.caption - 1
        font.letterSpacing: 0.6
    }

    // Liked share, downloads and (unless brief) the last update, as small tabular figures.
    component Figures: Row {
        id: figures
        property bool brief: false
        spacing: PrismTheme.dp(10)
        Repeater {
            model: [
                { glyph: "thumb_up", text: Hub.liked(root.item) >= 0 ? root.hub.likedText(root.item) : "" },
                { glyph: "download", text: root.item?.downloads !== undefined ? Hub.countText(root.item.downloads) : "" },
                { glyph: "update", text: figures.brief ? "" : root.hub.dateText(root.item?.updated ?? "") }
            ].filter(figure => figure.text.length > 0)
            delegate: Row {
                id: figure
                required property var modelData
                spacing: PrismTheme.dp(3)
                PrismGlyph {
                    anchors.verticalCenter: parent.verticalCenter
                    text: figure.modelData.glyph
                    filled: true
                    iconSize: PrismTheme.dp(12)
                    color: PrismTheme.ink3
                }
                PrismText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: figure.modelData.text
                    figures: true
                    color: PrismTheme.ink2
                    font.pixelSize: PrismTheme.caption
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
