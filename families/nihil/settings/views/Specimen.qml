pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// NiHiL as it stands right now, on the person's own wallpaper: every choice on this page shows here as it is made.
ClippingRectangle {
    id: root

    implicitHeight: NihilStyle.s(248)
    radius: NihilStyle.sectionRowRadius
    color: NihilStyle.well

    Image {
        anchors.fill: parent
        source: Wallpapers.effectiveWallpaperUrl
        sourceSize.width: 960
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: NihilStyle.scrim }

    DotText {
        x: NihilStyle.s(26)
        y: NihilStyle.s(24)
        text: DateTime.time.replace(/\s?[ap]m$/i, "")
        dot: NihilStyle.s(9)
        fuse: (Config.options?.nihil?.clock?.style ?? "dots") === "fused"
        color: NihilStyle.neutral(NihilStyle.m3.m3scrim, 0.97)
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: NihilStyle.s(22)
        y: NihilStyle.s(22)
        width: Math.min(NihilStyle.s(250), root.width * 0.42)
        height: NihilStyle.s(132)
        radius: NihilStyle.panelRadius
        color: NihilStyle.piece
        Column {
            anchors.fill: parent
            anchors.margins: NihilStyle.panelPad
            spacing: NihilStyle.cellGap
            NLevel {
                width: parent.width
                height: NihilStyle.s(44)
                vertical: false
                value: 0.64
                icon: "volume_up"
            }
            Row {
                spacing: NihilStyle.cellGap
                NButton { width: NihilStyle.s(52); height: NihilStyle.s(52); lit: true; icon: "wifi"; tone: NihilStyle.pieceRaised }
                NButton { width: NihilStyle.s(52); height: NihilStyle.s(52); icon: "bluetooth"; tone: NihilStyle.pieceRaised }
                DotGrid {
                    anchors.verticalCenter: parent.verticalCenter
                    width: NihilStyle.s(60)
                    height: NihilStyle.s(36)
                    columns: 7
                    rows: 4
                    level: 0.62
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: NihilStyle.s(14)
        spacing: NihilStyle.gap
        NButton { width: NihilStyle.s(46); height: NihilStyle.s(46); split: true; icon: "tune" }
        NButton { width: NihilStyle.s(46); height: NihilStyle.s(46); icon: "blur_circular" }
        NButton {
            width: Math.min(NihilStyle.s(220), root.width * 0.32)
            height: NihilStyle.s(46)
            NText {
                anchors.centerIn: parent
                serif: true
                text: Translation.tr("Search")
                font.pixelSize: NihilStyle.textLarge
                color: NihilStyle.inkSoft
            }
        }
        NButton { width: NihilStyle.s(46); height: NihilStyle.s(46); lit: true; icon: "bolt" }
    }
}
