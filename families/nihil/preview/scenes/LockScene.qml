pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.nihil.lock
import qs.modules.nihil.style
import qs.modules.nihil.components
import qs.modules.nihil.preview.parts

PreviewScene {
    id: lockPreview
    readonly property real naturalWidth: Math.round(540 * lockPreview.d)
    readonly property real naturalHeight: Math.round(300 * lockPreview.d)
    readonly property string source: String(lockPreview.opt("nihil.lock.scene.source", "desktop"))
    readonly property real blur: Number(lockPreview.opt("nihil.lock.scene.blur", 100)) / 100
    readonly property real dim: Number(lockPreview.opt("nihil.lock.scene.dim", 0)) / 100
    readonly property string clockFormat: String(lockPreview.opt("nihil.lock.type.clockFormat", "auto"))
    readonly property string format: lockPreview.clockFormat === "24h" ? "HH:mm" : lockPreview.clockFormat === "12h" ? "h:mm AP" : String(Config.options?.time?.format ?? "hh:mm")
    Rectangle { anchors.fill: parent; color: IrisStyle.surface }
    IrisWallpaperView {
        id: lockWall
        anchors.fill: parent
        active: lockPreview.preview.visible && lockPreview.source !== "colour"
        live: false
        screen: GlobalStates.focusedScreen
        path: lockPreview.source === "custom" ? String(lockPreview.opt("nihil.lock.scene.path", "")) : configuredPath
        provideTexture: true
        decodeSize: Qt.size(Math.round(lockPreview.width), 0)
        opacity: 0
    }
    MultiEffect {
        anchors.fill: parent
        visible: lockPreview.source !== "colour"
        source: lockWall.textureItem
        blurEnabled: lockPreview.blur > 0
        blur: lockPreview.blur
        blurMax: IrisStyle.glassBlurMax
        saturation: Number(lockPreview.opt("nihil.lock.scene.saturation", 15)) / 100 - 1
        autoPaddingEnabled: false
    }
    Rectangle { anchors.fill: parent; color: IrisStyle.surface; opacity: lockPreview.dim }
    // A Design that draws the lock its own way is shown as itself: the real lock surface, scaled to the preview, on a
    // context that never asks PAM and takes no keys (the preview has none to give).
    readonly property bool drawn: IrisDesign.has("lockClock")
    QtObject {
        id: standIn
        signal shouldReFocus()
        signal unlocked(targetAction: var)
        signal failed()
        property string currentText: ""
        property bool unlockInProgress: false
        property bool showFailure: false
        property bool fingerprintsConfigured: false
        function clearText(): void { standIn.currentText = "" }
        function resetClearTimer(): void {}
        function tryUnlock(): void {}
    }
    Item {
        anchors.fill: parent
        visible: lockPreview.drawn
        clip: true
        readonly property size screen: Qt.size(GlobalStates.focusedScreen?.width ?? 1920, GlobalStates.focusedScreen?.height ?? 1080)
        Loader {
            active: lockPreview.drawn && lockPreview.preview.visible
            sourceComponent: IrisLockSurface {
                width: parent.parent.screen.width
                height: parent.parent.screen.height
                scale: Math.min(lockPreview.width / width, lockPreview.height / height)
                transformOrigin: Item.TopLeft
                x: (lockPreview.width - width * scale) / 2
                y: (lockPreview.height - height * scale) / 2
                context: standIn
                editing: true
            }
        }
    }
    ColumnLayout {
        id: blocks
        visible: !lockPreview.drawn
        anchors.centerIn: parent
        width: parent.width - Math.round(64 * lockPreview.d)
        spacing: Math.round(10 * lockPreview.d)
        IrisText {
            id: clockText
            visible: lockPreview.opt("nihil.lock.blocks.clock.enable", true)
            Layout.alignment: Qt.AlignHCenter
            text: Translation.locale.toString(DateTime.clock.date, lockPreview.format + (lockPreview.opt("nihil.lock.type.seconds", false) ? ":ss" : ""))
            font.family: IrisLockOptions.clockFamily
            font.pixelSize: Number(lockPreview.opt("nihil.lock.type.clockSize", 112)) * 0.6 * IrisLockOptions.typeScale
            font.weight: Number(lockPreview.opt("nihil.lock.type.clockWeight", 700))
            font.letterSpacing: Number(lockPreview.opt("nihil.lock.type.clockTracking", -4))
            color: IrisLockOptions.accentColour
        }
        IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale));
            id: dateLine
            visible: lockPreview.opt("nihil.lock.blocks.clock.enable", true) && String(lockPreview.opt("nihil.lock.type.dateFormat", "long")) !== "none"
            Layout.alignment: Qt.AlignHCenter
            text: Translation.locale.toString(DateTime.clock.date, String(lockPreview.opt("nihil.lock.type.dateFormat", "long")) === "short" ? "ddd d MMM" : "dddd d MMMM")
            color: IrisStyle.onMediaSecondary
        }
        RowLayout {
            id: glance
            visible: lockPreview.opt("nihil.lock.blocks.glance.enable", true)
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.round(16 * lockPreview.d)
            MaterialSymbol { visible: lockPreview.opt("nihil.lock.blocks.glance.weather", true); text: "partly_cloudy_day"; color: IrisStyle.onMedia; iconSize: Math.round(22 * lockPreview.d) }
            MaterialSymbol { visible: lockPreview.opt("nihil.lock.blocks.glance.events", true); text: "event"; color: IrisStyle.onMedia; iconSize: Math.round(22 * lockPreview.d) }
            IrisBatteryMark { visible: lockPreview.opt("nihil.lock.blocks.glance.battery", true); Layout.alignment: Qt.AlignVCenter; markHeight: Math.round(11 * lockPreview.d); level: 0.8; tint: IrisStyle.onMedia; frame: IrisStyle.onMediaTertiary }
        }
        Rectangle {
            id: session
            visible: lockPreview.opt("nihil.lock.blocks.session.enable", true)
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Number(lockPreview.opt("nihil.lock.blocks.session.width", 248)) * 0.65
            Layout.preferredHeight: Math.round(32 * lockPreview.d)
            radius: 0
            color: IrisStyle.onMediaFill
            MaterialSymbol { anchors.centerIn: parent; text: "lock"; color: IrisStyle.onMedia; iconSize: Math.round(18 * lockPreview.d) }
        }
        IrisText { font.pixelSize: Math.round((voiceSize) / Math.max(1, IrisStyle.typeScale));
            id: media
            visible: lockPreview.opt("nihil.lock.blocks.media.enable", true)
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            text: MprisController.titleOf(MprisController.activePlayer) || Translation.tr("Now playing")
            color: IrisStyle.onMediaSecondary
            elide: Text.ElideRight
        }
    }
    // The page's parts as the lock shows them: what lies behind, the clock and its type, the glance, the sign-in field
    // and what plays. A Design that draws its own lock is pointed at only through the legend.
    function partOf(item: Item, pad: real): rect {
        return Qt.rect(blocks.x + item.x - pad, blocks.y + item.y - pad, item.width + 2 * pad, item.height + 2 * pad)
    }
    spots: {
        if (lockPreview.drawn) return []
        const d = lockPreview.d, gap = 18 * d
        const out = [{ group: "Scene", x: 22 * d, y: 22 * d, part: Qt.rect(0, 0, lockPreview.width, lockPreview.height), radius: 0 }]
        const beside = (group, item, pad) => {
            if (!item.visible || item.width <= 0) return
            const r = lockPreview.partOf(item, pad)
            out.push({ group: group, x: r.x + r.width + gap, y: r.y + r.height / 2, part: r, radius: Math.min(r.height / 2, 12 * d) })
        }
        beside("Clock", clockText, 4 * d)
        beside("Type", dateLine, 3 * d)
        beside("At a glance", glance, 6 * d)
        beside("Sign in", session, 0)
        beside("Now playing", media, 3 * d)
        return out
    }

    Caption { glyph: "lock"; text: Translation.tr("Your lock screen, without locking") }
}
