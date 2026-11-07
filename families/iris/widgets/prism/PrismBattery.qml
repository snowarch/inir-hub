pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.widgets

// Batteries in Prism: the first device on the tab, its state on the flap, its charge as the figure in the pane, the
// others as rows on the foot. Only what the machine reports is drawn: a desktop with nothing paired says so.
PrismFolder {
    id: root

    readonly property var glyphs: ({
        mouse: "mouse", keyboard: "keyboard", headset: "headset_mic", headphones: "headphones",
        phone: "smartphone", tablet: "tablet", gaminginput: "stadia_controller", pen: "stylus",
        touchpad: "touchpad_mouse", speakers: "speaker", wearable: "watch"
    })
    readonly property var devices: {
        const list = []
        if (Battery.available)
            list.push({ name: Translation.tr("This computer"), glyph: "laptop", level: Battery.percentage,
                charging: Battery.isCharging, low: Battery.isLow })
        for (const device of UPower.devices.values) {
            if (!device || device.isLaptopBattery || !device.isPresent || device.type === UPowerDeviceType.LinePower)
                continue
            const kind = UPowerDeviceType.toString(device.type).toLowerCase().replace(/\s/g, "")
            if (!root.glyphs[kind])
                continue
            list.push({ name: device.model || UPowerDeviceType.toString(device.type), glyph: root.glyphs[kind],
                level: device.percentage, charging: device.state === UPowerDeviceState.Charging, low: device.percentage <= 0.2 })
        }
        return list.slice(0, root.large ? 5 : 3)
    }
    readonly property var lead: root.devices[0] ?? null
    readonly property var others: root.devices.slice(1)
    function stateWord(device: var): string {
        return !device ? "" : device.charging ? Translation.tr("Charging")
            : device.level >= 0.995 ? Translation.tr("Fully charged") : device.low ? Translation.tr("Low") : ""
    }
    function tint(device: var): color {
        return root.nothing ? root.signal : device.low && !device.charging ? root.danger : device.charging ? root.warm : root.accent
    }

    shelf: root.lead ? root.tint(root.lead) : root.nothing ? root.signal : root.accent
    tabGlyph: root.lead ? root.lead.glyph : "battery_full"
    tabText: root.lead ? root.lead.name : Translation.tr("Batteries")
    flapGlyph: root.lead?.charging ? "bolt" : root.lead ? "" : "power"
    flapText: root.lead ? (root.stateWord(root.lead) || Math.round(root.lead.level * 100) + "%") : ""

    // ── the pane: the charge ──
    Row {
        visible: root.lead !== null
        x: root.inset
        y: Math.round(root.paneMiddle - height / 2)
        spacing: root.dp(2)
        FaceFigure {
            id: charge
            face: root
            text: root.lead ? String(Math.round(root.lead.level * 100)) : ""
            size: root.type(40, 52, 76)
        }
        FaceText {
            face: root
            y: Math.round(charge.height * 0.5)
            text: "%"
            color: root.inkSecondary
            size: root.type(14, 16, 22)
            weight: Font.Bold
        }
    }
    FaceText {
        visible: root.lead === null
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.paneMiddle - height / 2)
        text: Translation.tr("Devices you pair show up here")
        color: root.inkSecondary
        size: root.type(13, 15, 18)
        weight: Font.DemiBold
        wrapMode: Text.WordWrap
        maximumLineCount: 2
    }

    // ── the foot: the other devices ──
    Column {
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.large ? root.footTop + root.dp(22) : root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        spacing: root.pick(4, 6, 12)
        Repeater {
            model: root.small ? root.others.slice(0, 1) : root.medium ? root.others.slice(0, 2) : root.others
            Item {
                id: device
                required property var modelData
                width: root.innerWidth
                height: root.pick(18, 20, 26)
                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: device.modelData.glyph
                    fill: 1
                    iconSize: root.px(root.type(14, 15, 19))
                    color: root.inkSecondary
                }
                FaceText {
                    face: root
                    x: root.pick(22, 24, 30)
                    width: parent.width - x - level.implicitWidth - root.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: device.modelData.name
                    color: root.inkSecondary
                    size: root.type(12, 12.5, 14)
                    weight: Font.Medium
                    elide: Text.ElideRight
                }
                FaceText {
                    id: level
                    face: root
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(device.modelData.level * 100) + "%"
                    color: device.modelData.low && !device.modelData.charging ? root.danger : root.ink
                    size: root.type(12, 13, 15)
                    weight: Font.Bold
                    font.family: root.fontNumbers
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
    FaceText {
        visible: root.others.length === 0
        face: root
        x: root.inset
        width: root.innerWidth
        y: Math.round(root.footTop + (root.footHeight - height) / 2 - root.dp(2))
        text: root.lead ? (root.stateWord(root.lead) || Translation.tr("On power")) : Translation.tr("On power")
        color: root.inkTertiary
        size: root.type(12, 13, 14)
        weight: Font.Medium
    }
}
