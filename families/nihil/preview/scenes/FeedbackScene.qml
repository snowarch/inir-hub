pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.nihil.style
import qs.modules.nihil.frame
import qs.modules.nihil.components
import qs.modules.nihil.preview.parts

PreviewScene {
    id: feedRoot
    subject: Qt.rect(bannerPlate.x, bannerPlate.y, bannerPlate.width, bannerPlate.height)
    // Its parts: the banner, the app's mark on it (which apps notify), the Island that keeps quiet (Do Not Disturb).
    spots: {
        const d = feedRoot.d, b = bannerPlate, i = feedIsland
        const mark = Math.round(38 * d), inset = Math.round(14 * d)
        return [
            { group: "Banners", x: b.x + b.width, y: b.y, part: Qt.rect(b.x, b.y, b.width, b.height), radius: b.radius },
            { group: "Apps", x: b.x + inset + mark / 2, y: b.y + b.height,
                part: Qt.rect(b.x + inset - 4 * d, b.y + (b.height - mark) / 2 - 4 * d, mark + 8 * d, mark + 8 * d), radius: 12 * d },
            { group: "Do Not Disturb", x: i.x + i.width + Math.round(18 * d), y: i.y + i.height / 2,
                part: Qt.rect(i.x, i.y, i.width, i.height), radius: i.height / 2 }
        ]
    }
    readonly property bool banners: feedRoot.opt("nihil.modules.notificationPopup", true)
    readonly property bool osd: feedRoot.opt("nihil.modules.osd", true)
    readonly property real bannerWidth: Math.max(340, Math.min(560, Number(feedRoot.opt("nihil.notifications.width", 380)))) * feedRoot.d
    readonly property real osdWidth: Math.max(260, Math.min(520, Number(feedRoot.opt("nihil.osd.width", 320)))) * feedRoot.d
    readonly property int duration: Math.max(2000, Math.min(12000, Number(feedRoot.opt("nihil.notifications.duration", 4000))))
    // In the person's figures and without a dead ".0": "4 s", "4,5 s" in German.
    readonly property string seconds: (feedRoot.duration / 1000).toLocaleString(Translation.locale, "f", feedRoot.duration % 1000 === 0 ? 0 : 1)
    // `nihil.notifications.position`: from the Island, or placed on a corner or an edge's middle of a wider stand-in screen.
    readonly property string position: {
        const value = String(feedRoot.opt("nihil.notifications.position", "island"))
        return ["topLeft", "topCenter", "topRight", "bottomLeft", "bottomCenter", "bottomRight"].includes(value) ? value : "island"
    }
    readonly property bool placed: feedRoot.position !== "island"
    readonly property bool placedTop: feedRoot.position.startsWith("top")
    readonly property int placedSide: feedRoot.position.endsWith("Left") ? -1 : feedRoot.position.endsWith("Right") ? 1 : 0
    readonly property real gap: Math.round(16 * feedRoot.d)
    readonly property string bannerBody: feedRoot.placed ? Translation.tr("Stays %1 s, then slides away.").arg(feedRoot.seconds)
        : Translation.tr("Stays %1 s, then folds back into the Island.").arg(feedRoot.seconds)
    readonly property real naturalWidth: Math.max(feedRoot.bannerWidth, feedRoot.osdWidth)
        + Math.round((feedRoot.placedSide !== 0 ? 300 : 120) * feedRoot.d)
    readonly property real naturalHeight: Math.round(300 * feedRoot.d)
    IslandPill { id: feedIsland; anchors.horizontalCenter: parent.horizontalCenter; y: IrisFrame.band }
    Plate {
        id: bannerPlate
        surface: "cards"
        own: IrisStyle.identity.orange
        opacity: feedRoot.banners ? 1 : 0.3
        x: Math.round(feedRoot.placedSide < 0 ? feedRoot.gap
            : feedRoot.placedSide > 0 ? parent.width - width - feedRoot.gap : (parent.width - width) / 2)
        y: Math.round(!feedRoot.placed ? feedIsland.y + feedIsland.height + IrisStyle.weld
            : !feedRoot.placedTop ? parent.height - height - Math.round(52 * feedRoot.d)
            : feedRoot.placedSide === 0 ? feedIsland.y + feedIsland.height + feedRoot.gap : IrisFrame.band + feedRoot.gap)
        width: feedRoot.bannerWidth
        height: bannerSkin.item ? bannerSkin.item.implicitHeight : Math.round(76 * feedRoot.d)
        radius: IrisStyle.radiusPlate
        // A Design that draws banners shows its own here, on a stand-in notice that starts over each time it runs out.
        Loader {
            id: bannerSkin
            anchors.fill: parent
            active: IrisDesign.skin("banner").length > 0
            source: IrisDesign.skin("banner")
            onLoaded: feedRoot.resetNotice()
        }
        RowLayout {
            visible: !bannerSkin.item
            anchors.fill: parent
            anchors.margins: Math.round(14 * feedRoot.d)
            spacing: Math.round(12 * feedRoot.d)
            IrisMark { implicitSize: Math.round(38 * feedRoot.d) }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * feedRoot.d)
                IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); text: Translation.tr("A notification"); font.weight: IrisStyle.weight(Font.DemiBold) }
                IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); Layout.fillWidth: true; text: feedRoot.bannerBody; color: IrisStyle.textSecondary; elide: Text.ElideRight }
            }
        }
        Rectangle {
            id: drain
            visible: !bannerSkin.item
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Math.round(6 * feedRoot.d)
            x: Math.round(18 * feedRoot.d)
            height: 2
            radius: 0
            color: IrisStyle.secondaryAccent
            readonly property real full: parent.width - 2 * x
            width: drain.full
            NumberAnimation on width {
                running: feedRoot.playing && feedRoot.banners
                loops: Animation.Infinite
                from: drain.full; to: 0
                duration: feedRoot.duration
            }
        }
    }
    function resetNotice(): void {
        if (!bannerSkin.item) return
        bannerSkin.item.notification = ({ notificationId: -1, appName: "iNiR", appIcon: "", image: "", urgency: "1",
            summary: Translation.tr("A notification"), time: Date.now(), timer: ({ interval: feedRoot.duration }), actions: [],
            body: feedRoot.bannerBody })
    }
    Timer { interval: feedRoot.duration + 600; running: feedRoot.playing && bannerSkin.item !== null; repeat: true; onTriggered: feedRoot.resetNotice() }
    Rectangle {
        id: osdPlate
        anchors.horizontalCenter: parent.horizontalCenter
        y: feedRoot.placed && !feedRoot.placedTop ? feedIsland.y + feedIsland.height + Math.round(40 * feedRoot.d)
            : bannerPlate.y + bannerPlate.height + Math.round(40 * feedRoot.d)
        opacity: feedRoot.osd ? 1 : 0.3
        width: osdSkin.item ? osdSkin.item.implicitWidth : feedRoot.osdWidth
        height: osdSkin.item ? osdSkin.item.implicitHeight : Math.round(44 * feedRoot.d)
        radius: 0
        color: IrisStyle.bodySurface
        // A Design's OSD stands in for the stand-in level.
        Loader {
            id: osdSkin
            anchors.fill: parent
            active: IrisDesign.skin("osd").length > 0
            source: IrisDesign.skin("osd")
            onLoaded: item.osd = Qt.binding(() => ({ kind: "volume", level: true, value: Math.min(1, Audio.value ?? 0.7), icon: "volume_up",
                levelFigure: true, open: true, levelStyle: String(feedRoot.opt("nihil.osd.style", "capsule")) }))
        }
        border.width: IrisStyle.rim.a > 0 ? 1 : 0
        border.color: IrisStyle.rim
        IrisGlassEdge { anchors.fill: parent; z: 10; visible: IrisStyle.edgeLit && shown; radius: parent.radius }
        RowLayout {
            visible: !osdSkin.item
            anchors.fill: parent
            anchors.leftMargin: Math.round(14 * feedRoot.d)
            anchors.rightMargin: Math.round(16 * feedRoot.d)
            spacing: Math.round(10 * feedRoot.d)
            MaterialSymbol { text: "volume_up"; fill: 1; iconSize: Math.round(18 * feedRoot.d); color: IrisStyle.text }
            Level { value: Math.min(1, Audio.value ?? 0.7); tint: IrisStyle.text }
            IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale)); text: Math.round(Math.min(1, Audio.value ?? 0.7) * 100); font.family: IrisStyle.fontNumbers; font.weight: IrisStyle.weight(Font.DemiBold) }
        }
    }
    Caption {
        glyph: "campaign"
        text: [feedRoot.banners ? Translation.tr("Banners on") : Translation.tr("Banners off"), feedRoot.osd ? Translation.tr("level feedback on") : Translation.tr("level feedback off")].join(" · ")
    }
}
