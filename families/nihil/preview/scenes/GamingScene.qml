pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.frame
import qs.modules.nihil.components
import qs.modules.nihil.preview.parts

// Gaming & Fullscreen: a game fills the screen. A notification arrives: it drops in, or waits behind a dot when
// game mode holds it; the volume pill shows, keeps quiet or stays away; what game mode stops is struck through.
PreviewScene {
    id: gameRoot
    readonly property real naturalWidth: Math.round(580 * gameRoot.d)
    readonly property real naturalHeight: Math.round(300 * gameRoot.d)
    narrowest: Math.round(400 * gameRoot.d)
    lowest: Math.round(230 * gameRoot.d)
    subject: Qt.rect(banner.x, banner.y, banner.width, banner.height)
    readonly property bool auto: gameRoot.opt("gameMode.autoDetect", true) === true
    readonly property bool holds: gameRoot.auto && gameRoot.opt("gameMode.suppressNotifications", true) === true
    readonly property bool banners: gameRoot.opt("nihil.notifications.fullscreen", true) === true && !gameRoot.holds
    readonly property string pill: String(gameRoot.opt("nihil.osd.fullscreen", "show"))
    readonly property var stops: [
        { glyph: "animation", name: Translation.tr("Animations"), on: gameRoot.auto && gameRoot.opt("gameMode.disableAnimations", true) === true },
        { glyph: "blur_on", name: Translation.tr("Glass"), on: gameRoot.auto && gameRoot.opt("gameMode.disableEffects", true) === true },
        { glyph: "motion_mode", name: Translation.tr("Niri motion"), on: gameRoot.auto && gameRoot.opt("gameMode.disableNiriAnimations", true) === true }
    ]
    property real t: 1
    Loop on t { running: gameRoot.playing; rest: 1400 }

    // The game: the screen gone dark and wide, a reticle in the middle.
    Rectangle { anchors.fill: parent; color: IrisStyle.veilHeavy }
    MaterialSymbol { anchors.centerIn: parent; anchors.verticalCenterOffset: -Math.round(14 * gameRoot.d); text: "sports_esports"; iconSize: Math.round(64 * gameRoot.d); color: IrisStyle.onMediaSecondary; opacity: 0.5 }

    // The notification: in from the top, or held behind a dot.
    Plate {
        id: banner
        surface: "cards"
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(280 * gameRoot.d)
        height: Math.round(56 * gameRoot.d)
        radius: IrisStyle.radiusPlate
        y: gameRoot.banners ? -height + (height + Math.round(18 * gameRoot.d)) * gameRoot.t : -height - 4
        RowLayout {
            anchors.fill: parent
            anchors.margins: Math.round(12 * gameRoot.d)
            spacing: Math.round(10 * gameRoot.d)
            IrisMark { implicitSize: Math.round(30 * gameRoot.d) }
            IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); Layout.fillWidth: true; elide: Text.ElideRight; text: Translation.tr("A message for you"); font.weight: IrisStyle.weight(Font.DemiBold) }
        }
    }
    Rectangle {
        visible: gameRoot.holds
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(16 * gameRoot.d)
        width: Math.round(34 * gameRoot.d)
        height: width
        radius: 0
        color: IrisStyle.bodySurface
        MaterialSymbol { anchors.centerIn: parent; text: "notifications_paused"; fill: 1; iconSize: Math.round(17 * gameRoot.d); color: IrisStyle.text }
        Rectangle {
            x: parent.width - width; y: 0
            width: Math.round(10 * gameRoot.d); height: width; radius: width / 2
            color: IrisStyle.accent
            scale: gameRoot.t
        }
    }
    // The volume pill over the game.
    Rectangle {
        id: osdPill
        visible: gameRoot.pill !== "hide"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(54 * gameRoot.d)
        width: Math.round((gameRoot.pill === "quiet" ? 120 : 220) * gameRoot.d)
        height: Math.round((gameRoot.pill === "quiet" ? 8 : 38) * gameRoot.d)
        radius: 0
        color: gameRoot.pill === "quiet" ? IrisStyle.fill : IrisStyle.bodySurface
        border.width: IrisStyle.edgeWidth
        border.color: IrisStyle.text
        opacity: gameRoot.t
        RowLayout {
            visible: gameRoot.pill !== "quiet"
            anchors.fill: parent
            anchors.leftMargin: Math.round(14 * gameRoot.d)
            anchors.rightMargin: Math.round(16 * gameRoot.d)
            spacing: Math.round(10 * gameRoot.d)
            MaterialSymbol { text: "volume_up"; fill: 1; iconSize: Math.round(17 * gameRoot.d); color: IrisStyle.text }
            Level { value: 0.55; tint: IrisStyle.text }
        }
        Rectangle { visible: gameRoot.pill === "quiet"; width: parent.width * 0.55; height: parent.height; radius: height / 2; color: IrisStyle.onMediaSecondary }
    }
    // What game mode stops.
    Column {
        id: stopped
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Math.round(14 * gameRoot.d)
        spacing: Math.round(6 * gameRoot.d)
        Repeater {
            model: gameRoot.stops
            Rectangle {
                id: stop
                required property var modelData
                width: stopRow.implicitWidth + Math.round(18 * gameRoot.d)
                height: Math.round(28 * gameRoot.d)
                radius: 0
                color: IrisStyle.veilHeavy
                opacity: stop.modelData.on ? 1 : 0.5
                RowLayout {
                    id: stopRow
                    anchors.centerIn: parent
                    spacing: Math.round(6 * gameRoot.d)
                    MaterialSymbol { text: stop.modelData.glyph; iconSize: Math.round(14 * gameRoot.d); color: IrisStyle.onMediaSecondary }
                    IrisText { text: stop.modelData.name; color: IrisStyle.onMedia; font.pixelSize: Math.round((IrisStyle.typeCaption) / Math.max(1, IrisStyle.typeScale)); font.strikeout: stop.modelData.on }
                }
            }
        }
    }
    // The page's parts: what shows over a fullscreen game (the banner, else the volume pill) and what game mode stops.
    spots: {
        const d = gameRoot.d
        const out = []
        const over = gameRoot.banners ? banner : osdPill.visible ? osdPill : null
        if (over)
            out.push({ group: "Fullscreen", x: over.x - 18 * d, y: over.y + over.height / 2, part: Qt.rect(over.x, over.y, over.width, over.height), radius: over.radius })
        out.push({ group: "Game mode", x: stopped.x - 18 * d, y: stopped.y + 14 * d,
            part: Qt.rect(stopped.x - 4 * d, stopped.y - 4 * d, stopped.width + 8 * d, stopped.height + 8 * d), radius: 18 * d })
        return out
    }
    Caption {
        glyph: gameRoot.auto ? "sports_esports" : "videogame_asset_off"
        text: gameRoot.auto ? (gameRoot.holds ? Translation.tr("Game mode holds notifications") : Translation.tr("Game mode on fullscreen")) : Translation.tr("Game mode stays off")
    }
}
