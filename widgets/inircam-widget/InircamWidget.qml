pragma ComponentBehavior: Bound

// The camera grid, on the desktop.
//
// The camera panel (the `inircam` component) owns the cameras, the credentials and the pullers.
// This card only shows what the panel already produces: it asks the panel for the camera list,
// asks it to keep the frames running while the card is on screen, and paints the JPEG frames the
// panel writes. Nothing is written here, and no password is read here.

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets

AbstractBackgroundWidget {
    id: root

    // Where this card's settings live, and the folder the hub installs it to.
    configEntryName: "custom.inircam-widget"
    defaultConfig: ({
        placementStrategy: "free",
        widgetScale: 100,
        widgetOpacity: 100,
        colorMode: "auto",
        dim: 0,
        showBackground: true,
        backgroundOpacity: 0.16,
        borderWidth: 1,
        borderOpacity: 0.2,
        cornerRadius: -1,
        useBlur: false,
        x: 320,
        y: 180,
        columns: 2,
        showCount: true,
        click: "pin"
    })
    // The ink is read from the wallpaper under the card, so it stays legible on any background.
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 200
    resizeMinHeight: 130

    // The card keeps its proportions when the user scales it.
    implicitWidth: Math.round(320 * root.scaleFactor)
    implicitHeight: Math.round(210 * root.scaleFactor)

    // ── Settings ─────────────────────────────────────────────
    readonly property int columns: Math.max(1, Math.min(4, Math.round(Number(root._readConfigKey("columns") ?? 2))))
    readonly property bool showCount: Boolean(root._readConfigKey("showCount") ?? true)
    readonly property string clickAction: String(root._readConfigKey("click") ?? "pin")

    // ── State ────────────────────────────────────────────────
    property var cameras: []
    property bool ready: false
    property int frameTick: 0

    readonly property int pad: Math.round(12 * root.scaleFactor)
    readonly property int gap: Math.round(8 * root.scaleFactor)
    readonly property int headerHeight: Math.round(20 * root.scaleFactor)
    readonly property int maxTiles: Math.max(root.columns, Math.min(root.columns * 3, 12))
    readonly property real tileWidth: Math.max(60, (root.width - root.pad * 2 - root.gap * (root.columns - 1)) / root.columns)
    readonly property real tileHeight: Math.max(38, Math.min(root.tileWidth * 0.66, (root.height - root.pad * 2 - root.headerHeight - root.gap) / Math.max(1, root.rows)))
    readonly property int rows: Math.max(1, Math.ceil(Math.min(root.cameras.length, root.maxTiles) / root.columns))
    readonly property string frameDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/inircam"
    readonly property string frameVersion: String(root.frameTick)

    // ── Talking to the panel ─────────────────────────────────
    // `inir inircam <fn>` reaches the panel on iNiR 3.1.0 and later.
    Process {
        id: teller
        running: false
    }

    function tell(verb, args) {
        teller.command = ["inir", "inircam", verb].concat(args ?? [])
        teller.running = false
        teller.running = true
    }

    // The camera list: ids and names, never a password.
    Process {
        id: listCall
        running: false
        stdout: StdioCollector {
            id: listOut
            waitForEnd: true
            onStreamFinished: root.takeList(listOut.text)
        }
        onExited: (code) => { if (code !== 0) root.readFallback() }
    }

    function refresh() {
        listCall.command = ["inir", "inircam", "cameras"]
        listCall.running = false
        listCall.running = true
    }

    function takeList(text) {
        const raw = String(text ?? "").trim()
        if (raw.length === 0) return root.readFallback()
        let list = null
        try {
            list = JSON.parse(raw)
        } catch (e) {
            list = null
        }
        if (!Array.isArray(list)) return root.readFallback()
        root.applyList(list)
    }

    function applyList(list) {
        const out = []
        for (let i = 0; i < list.length; i++) {
            const cam = list[i] || {}
            const id = String(cam.id ?? "")
            if (id.length === 0) continue
            out.push({ id: id, name: String(cam.name ?? id) })
            if (out.length >= 12) break
        }
        root.cameras = out
        root.ready = true
    }

    // Fallback for shells where `inir` does not reach the panel yet: the panel's own file,
    // read only. This is the only place that knows where the panel keeps its cameras.
    FileView {
        id: options
        path: Directories.pluginFile("inircam")
        printErrors: false
        onLoaded: root.readFallbackText(text())
        onLoadFailed: {
            root.cameras = []
            root.ready = true
        }
    }

    function readFallback() { options.reload() }

    function readFallbackText(text) {
        let doc = {}
        try {
            doc = JSON.parse(String(text ?? "{}"))
        } catch (e) {
            doc = {}
        }
        const list = Array.isArray(doc.cameras) ? doc.cameras : []
        const out = []
        for (let i = 0; i < list.length; i++) {
            const cam = list[i] || {}
            if (cam.enabled === false) continue
            const id = String(cam.id ?? "")
            if (id.length === 0) continue
            out.push({ id: id, name: String(cam.name ?? id) })
        }
        root.cameras = out
        root.ready = true
    }

    // Frames run only while this card is on screen. Hiding the card lets them go; the panel
    // stops the pullers when nothing holds them, the same rule it follows for itself.
    function holdFrames(on) {
        root.tell("feeds", ["inircam-widget", on ? "true" : "false"])
    }

    Component.onCompleted: {
        root.refresh()
        root.holdFrames(root.visible)
    }
    onVisibleChanged: {
        root.holdFrames(root.visible)
        if (root.visible) root.refresh()
    }

    // The list changes when a camera is added, edited or removed in the panel.
    Timer {
        interval: 30000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    // The panel writes frames several times a second; the card needs fewer than that.
    Timer {
        interval: 250
        repeat: true
        running: root.visible && root.cameras.length > 0
        onTriggered: root.frameTick++
    }

    function framePath(cameraId) {
        // The version keeps the Image from serving the previous frame: ffmpeg rewrites
        // the same path several times a second.
        return "file://" + root.frameDir + "/feed-" + Quickshell.processId + "-" + cameraId + "-sub.jpg?v=" + root.frameVersion
    }

    function openCamera(cameraId) {
        if (root.clickAction === "none") return
        if (root.clickAction === "toggle") return root.tell("toggle", [])
        root.tell("pin", [cameraId])
    }

    // ── Look ─────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : Appearance.rounding.normal
        color: ColorUtils.applyAlpha(root.colText, Math.max(root.backgroundOpacity, 0.06))
        border.width: root.borderWidth
        border.color: ColorUtils.applyAlpha(root.colText, Math.max(root.borderOpacity, 0.12))
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.pad

        // The name, how many, and the way into the panel.
        Row {
            id: header
            width: parent.width
            height: root.headerHeight
            spacing: Math.round(6 * root.scaleFactor)

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "videocam"
                iconSize: Math.round(16 * root.scaleFactor)
                color: root.widgetInk
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Math.round(60 * root.scaleFactor)
                text: Translation.tr("Cameras")
                color: root.widgetInk
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showCount && root.cameras.length > 0
                text: String(root.cameras.length)
                color: root.widgetInkMuted
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            }

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "tune"
                iconSize: Math.round(14 * root.scaleFactor)
                color: root.widgetInkMuted
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tell("manage", [])
                }
            }
        }

        // The grid.
        Grid {
            id: grid
            anchors.top: header.bottom
            anchors.topMargin: root.gap
            columns: root.columns
            spacing: root.gap
            visible: root.cameras.length > 0

            Repeater {
                model: root.cameras.slice(0, root.maxTiles)

                Rectangle {
                    id: tile
                    required property var modelData
                    width: root.tileWidth
                    height: root.tileHeight
                    radius: Appearance.rounding.small
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.10)
                    clip: true

                    Image {
                        id: shot
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.framePath(tile.modelData.id)
                        // Synchronous, like the panel's own feed: a local JPEG decode is cheap and
                        // an async load would still be in flight when the next frame replaces it.
                        asynchronous: false
                        cache: false
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }

                    // Every state has words: a camera that cannot be reached says so.
                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(2 * root.scaleFactor)
                        visible: shot.status !== Image.Ready

                        MaterialSymbol {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "videocam_off"
                            iconSize: Math.round(16 * root.scaleFactor)
                            color: root.widgetInkMuted
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Translation.tr("No signal")
                            color: root.widgetInkMuted
                            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Math.round(18 * root.scaleFactor)
                        color: ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.55)

                        StyledText {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(6 * root.scaleFactor)
                            anchors.rightMargin: Math.round(6 * root.scaleFactor)
                            verticalAlignment: Text.AlignVCenter
                            text: tile.modelData.name
                            color: root.widgetInk
                            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openCamera(tile.modelData.id)
                    }
                }
            }
        }

        // Nothing to show yet: say what to do about it.
        Column {
            anchors.centerIn: parent
            spacing: Math.round(2 * root.scaleFactor)
            visible: root.ready && root.cameras.length === 0

            MaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "videocam_off"
                iconSize: Math.round(20 * root.scaleFactor)
                color: root.widgetInkMuted
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr("No cameras yet")
                color: root.widgetInk
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.width - root.pad * 2
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Translation.tr("Add one in the camera panel")
                color: root.widgetInkMuted
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            }
        }
    }
}
