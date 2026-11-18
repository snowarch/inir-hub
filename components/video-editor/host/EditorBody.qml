// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.waffle.looks
import "../state"
import "../pages"
import "../controls"

Item {
    id: root
    property bool windowed: true
    property bool open: false
    property bool closing: false
    required property EditorSession session
    required property PlaybackController playback
    required property VideoBackend backend
    readonly property alias frame: frame
    readonly property alias dialogOpen: page.dialogOpen
    readonly property real d: EditorSkin.d
    signal closeRequested()

    readonly property var room: {
        const gap = Math.round(14 * root.d);
        if (EditorSkin.iris) {
            const side = edge => Math.max(0, IrisFrame.safeInset(edge) - IrisFrame.band) + gap;
            const x0 = side("left"), y0 = side("top");
            return { x: x0, y: y0, width: Math.max(0, root.width - x0 - side("right")), height: Math.max(0, root.height - y0 - side("bottom")) };
        }
        const bar = Appearance.sizes.barHeight + gap;
        const y0 = EditorSkin.waffle ? gap : bar;
        const b0 = EditorSkin.waffle ? bar : gap;
        return { x: gap, y: y0, width: Math.max(0, root.width - gap * 2), height: Math.max(0, root.height - y0 - b0) };
    }

    Timer {
        id: switchHostLater
        interval: 0
        onTriggered: EditorOptions.set("windowed", !root.windowed)
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.open && !root.windowed && !root.dialogOpen
        onClicked: root.closeRequested()
    }

    Item {
        id: frame
        readonly property real progress: irisFrame.item ? irisFrame.item.progress : (root.open ? 1 : 0)
        readonly property real radius: root.windowed ? 0 : (EditorSkin.iris ? IrisStyle.surfaceRadius("settings", IrisStyle.radiusPanel) : EditorSkin.cardRadius)
        width: root.windowed ? root.width : Math.round(Math.min(root.room.width, 1360 * root.d))
        height: root.windowed ? root.height : Math.round(Math.min(root.room.height, 860 * root.d))
        x: root.windowed ? 0 : Math.round(root.room.x + (root.room.width - width) / 2)
        y: root.windowed ? 0 : Math.round(root.room.y + (root.room.height - height) / 2)

        MouseArea { anchors.fill: parent; enabled: !root.windowed }

        Loader {
            id: irisFrame
            anchors.fill: parent
            active: EditorSkin.iris
            sourceComponent: IrisMorphSurface {
                open: root.windowed || root.open
                motionSurface: "settings"
                settles: true
                windowOffset: Qt.point(IrisFrame.band, IrisFrame.band)
                ownField: !root.windowed
                overlay: !root.windowed
                glass: !root.windowed && !EditorSkin.prism
                color: EditorSkin.page
                light: IrisStyle.surfaceLight("settings", IrisStyle.wallpaperLight)
                radius: frame.radius
            }
        }

        Loader {
            anchors.fill: parent
            active: !EditorSkin.iris
            sourceComponent: EditorSkin.waffle ? waffleFrame : materialFrame
        }
        Component {
            id: materialFrame
            PanelSurface {
                elevation: 2
                opaqueSurface: root.windowed || EditorSkin.prism
                wallpaperBackdrop: !root.windowed && !EditorSkin.prism
                cardStyle: !root.windowed
                radiusOverride: frame.radius
                borderWidthOverride: root.windowed ? 0 : EditorSkin.edgeWidth
            }
        }
        Component {
            id: waffleFrame
            Rectangle {
                id: wafflePaper
                color: EditorSkin.page
                radius: frame.radius
                border.width: root.windowed ? 0 : EditorSkin.edgeWidth
                border.color: EditorSkin.edge
                WRectangularShadow { target: wafflePaper; z: -1; visible: !root.windowed }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: EditorSkin.iris && !root.windowed && EditorSkin.edgeWidth > 0
            radius: frame.radius
            color: "transparent" // literal: hairline frame edge in Prism overlay
            border.width: EditorSkin.edgeWidth
            border.color: EditorSkin.edge
            opacity: frame.progress
        }

        Item {
            id: keyScope
            anchors.fill: parent
            anchors.margins: EditorSkin.pad
            focus: true
            enabled: !root.closing && (root.windowed || root.open)
            opacity: EditorSkin.iris && !root.windowed ? IrisStyle.contentAt(frame.progress) : 1
            Component.onCompleted: keyScope.forceActiveFocus()
            Keys.priority: Keys.AfterItem
            Keys.onPressed: event => {
                if (root.dialogOpen) return;
                if (event.key === Qt.Key_Escape) {
                    if (root.session.renderOpen) root.session.cancelRequested();
                    else root.closeRequested();
                } else if (!root.session.ready || root.session.renderOpen) return;
                else if (event.key === Qt.Key_Space) root.playback.toggle();
                else if (event.key === Qt.Key_Left) root.playback.step(-1);
                else if (event.key === Qt.Key_Right) root.playback.step(1);
                else if (event.key === Qt.Key_Home) root.playback.seek(root.session.startMs);
                else if (event.key === Qt.Key_End) { root.playback.pause(); root.playback.seek(root.session.effectiveEndMs); }
                else if (event.key === Qt.Key_I) root.session.setInPoint(root.playback.position);
                else if (event.key === Qt.Key_O) root.session.setOutPoint(root.playback.position);
                else if (event.key === Qt.Key_S) root.session.cycleSpeed();
                else if (event.key === Qt.Key_P) root.session.snapshotRequested();
                else return;
                event.accepted = true;
            }

            EditorPage {
                id: page
                anchors.fill: parent
                windowed: root.windowed
                session: root.session
                playback: root.playback
                backend: root.backend
                onSwitchHostRequested: switchHostLater.restart()
                onCloseRequested: root.closeRequested()
            }
        }
    }
}
