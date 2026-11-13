pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import "Config.js" as Cfg
import "Brands.js" as Brands

Scope {
    id: root

    property bool open: false
    property string view: "grid" // grid | enlarged | wall | manage | form
    property string focusId: ""
    property var editingCamera: null
    property string formBrand: "tapo"
    property string notice: ""

    readonly property string cfgDir: (Quickshell.env("HOME") || "/tmp") + "/.config/inir/inircam"
    readonly property string cfgPath: cfgDir + "/config.json"

    property var settings: Cfg.clone(Cfg.DEFAULTS)

    function loadConfig(text) {
        try {
            var obj = JSON.parse(text || "{}")
            var m = Cfg.merge(obj)
            root.settings = m.config
        } catch (e) {
            root.settings = Cfg.clone(Cfg.DEFAULTS)
        }
    }

    function saveConfig() {
        cfgSave.command = ["bash", "-c",
            "set -e; dir=\"$1\"; file=\"$2\"; tmp=\"$file.tmp\"; mkdir -p \"$dir\"; cat > \"$tmp\"; chmod 600 \"$tmp\" 2>/dev/null || true; mv \"$tmp\" \"$file\"",
            "bash", root.cfgDir, root.cfgPath]
        cfgSave.running = false
        cfgSave.running = true
    }

    function showNotice(msg) {
        notice = msg || ""
        if (noticeTimer.running) noticeTimer.restart()
        else noticeTimer.start()
    }

    function enabledCameras() {
        var out = []
        var list = store.cameras || []
        for (var i = 0; i < list.length; i++) if (list[i].enabled !== false) out.push(list[i])
        return out
    }

    function cameraById(id) { return store.cameraById(id) }

    function openGrid() { view = "grid"; focusId = "" }
    function openManage() { view = "manage" }
    function openWall() { view = "wall" }
    function openEnlarged(id) { focusId = id || focusId; if (focusId) view = "enlarged" }
    function openForm(cam) {
        editingCamera = cam || null
        formBrand = (cam && cam.brand) ? cam.brand : "tapo"
        view = "form"
        // Populate form on next tick when loader/fields exist
        Qt.callLater(populateForm)
    }

    function populateForm() {
        // best-effort: fields are looked up by objectName not set; rely on bindings reset by recreating form state
        // (form visibility toggles keep state; we reset explicitly via formReset counter)
        formReset += 1
    }
    property int formReset: 0

    function nextCamera(delta) {
        var cams = enabledCameras()
        if (cams.length === 0) return
        var idx = 0
        for (var i = 0; i < cams.length; i++) if (cams[i].id === focusId) { idx = i; break }
        idx = (idx + delta + cams.length) % cams.length
        focusId = cams[idx].id
    }

    function handleKey(event) {
        var k = Cfg.keyPath(event)
        var acts = (settings.keys && settings.keys.actions) ? settings.keys.actions : {}
        if (k === acts.back || k === "Escape") {
            if (view === "form") { view = "manage"; event.accepted = true; return }
            if (view === "manage" || view === "enlarged" || view === "wall") { openGrid(); event.accepted = true; return }
            root.open = false; event.accepted = true; return
        }
        if (view === "grid") {
            if (k === acts.manage) { openManage(); event.accepted = true; return }
            if (k === acts.wall) { openWall(); event.accepted = true; return }
            if (settings.keys && settings.keys.cameraNumbers) {
                var idn = Cfg.keyId(event)
                if (idn > 0) {
                    var cams = enabledCameras()
                    if (idn <= cams.length) { openEnlarged(cams[idn - 1].id); event.accepted = true; return }
                }
            }
        } else if (view === "enlarged") {
            if (k === acts.next) { nextCamera(1); event.accepted = true; return }
            if (k === acts.previous) { nextCamera(-1); event.accepted = true; return }
            if (k === acts.fullscreen) { view = "wall"; event.accepted = true; return } // simple: wall as fullscreen-like
            if (k === acts.grid) { openGrid(); event.accepted = true; return }
            if (k === acts.refresh) { pool.revision += 1; event.accepted = true; return }
        } else if (view === "wall") {
            if (k === acts.grid) { openGrid(); event.accepted = true; return }
            if (k === acts.next) { nextCamera(1); event.accepted = true; return }
            if (k === acts.previous) { nextCamera(-1); event.accepted = true; return }
        }
    }

    function toggle() { root.open = !root.open }
    function close() { root.open = false }

    CameraStore { id: store }

    StreamPool {
        id: pool
        settings: root.settings
    }

    Probe { id: probe }

    FileView {
        id: cfgFile
        path: root.cfgPath
        printErrors: false
        onLoaded: root.loadConfig(text())
        onLoadFailed: root.loadConfig("{}")
    }

    Process {
        id: cfgSave
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(root.settings, null, 2))
            stdinEnabled = false
            closeStdin()
        }
        onExited: stdinEnabled = true
    }

    Timer {
        id: noticeTimer
        interval: 3500
        onTriggered: root.notice = ""
    }

    /// Live IP camera viewer panel.
    /// ```kdl
    /// Mod+Shift+I hotkey-overlay-title="Camera viewer" { spawn "inir" "inircam" "toggle"; }
    /// ```
    IpcHandler {
        target: "inircam"
        /// Show or hide the camera panel.
        function toggle(): void { root.toggle() }
        /// Open the camera panel.
        function open(): void { root.open = true }
        /// Close the camera panel.
        function close(): void { root.close() }
    }


    LazyLoader {
        active: root.open
        component: PanelWindow {
            id: win
            visible: root.open
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "inir:inircam"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            anchors { top: true; bottom: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: root.close()
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 1100)
                height: Math.min(parent.height - 80, 760)
                radius: 16
                color: "#1a1f24"
                border.color: "#334155"
                border.width: 1
                clip: true
                focus: true
                Keys.onPressed: (event) => root.handleKey(event)

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        StyledText {
                            text: "InirCam"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            color: "#e5e7eb"
                        }
                        StyledText {
                            visible: root.view !== "grid"
                            text: ({
                                enlarged: "Enlarged",
                                wall: "Wall",
                                manage: "Manage cameras",
                                form: root.editingCamera ? "Edit camera" : "Add camera"
                            })[root.view] || ""
                            color: "#94a3b8"
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Row {
                            spacing: 6
                            RippleButton {
                                visible: root.view !== "grid"
                                buttonText: "Back"
                                onClicked: root.openGrid()
                            }
                            RippleButton {
                                visible: root.view === "grid"
                                buttonText: "Wall"
                                onClicked: root.openWall()
                            }
                            RippleButton {
                                visible: root.view === "grid" || root.view === "manage"
                                buttonText: "Manage"
                                onClicked: root.openManage()
                            }
                            RippleButton {
                                visible: root.view === "manage"
                                buttonText: "Add camera"
                                onClicked: root.openForm(null)
                            }
                            RippleButton {
                                buttonText: "Close"
                                onClicked: root.close()
                            }
                        }
                    }

                    // Notice
                    Rectangle {
                        Layout.fillWidth: true
                        visible: root.notice !== ""
                        height: 30
                        radius: 8
                        color: "#243244"
                        StyledText {
                            anchors.centerIn: parent
                            text: root.notice
                            color: "#dbeafe"
                            font.pixelSize: 12
                        }
                    }

                    // Body
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // GRID
                        Flickable {
                            anchors.fill: parent
                            visible: root.view === "grid"
                            contentHeight: gridCol.implicitHeight
                            clip: true
                            ScrollBar.vertical: ScrollBar { }

                            Column {
                                id: gridCol
                                width: parent.width
                                spacing: 10

                                StyledText {
                                    visible: store.ready && enabledCameras().length === 0
                                    text: store.cameras.length === 0
                                        ? "No cameras yet. Open Manage to add one."
                                        : "All cameras are disabled. Open Manage to enable one."
                                    color: "#94a3b8"
                                    font.pixelSize: 14
                                }

                                Grid {
                                    id: camGrid
                                    width: parent.width
                                    columns: Math.max(1, Number(root.settings.grid?.columns || 2))
                                    spacing: 10
                                    Repeater {
                                        model: enabledCameras()
                                        delegate: Rectangle {
                                            required property var modelData
                                            required property int index
                                            width: (camGrid.width - camGrid.spacing * (camGrid.columns - 1)) / camGrid.columns
                                            height: Math.max(160, width * 0.56)
                                            radius: 12
                                            color: "#0f1720"
                                            border.color: "#334155"
                                            clip: true

                                            CameraFeed {
                                                anchors.fill: parent
                                                anchors.margins: 0
                                                pool: pool
                                                camera: modelData
                                                play: ({ on: root.open, quality: "sub" })
                                                capture: true
                                                muted: true
                                            }

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.bottom: parent.bottom
                                                height: 34
                                                color: "#66000000"
                                            }
                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.bottom: parent.bottom
                                                anchors.margins: 8
                                                text: (index + 1) + ". " + (modelData.name || "Camera")
                                                color: "white"
                                                font.pixelSize: 13
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.openEnlarged(modelData.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ENLARGED
                        Item {
                            anchors.fill: parent
                            visible: root.view === "enlarged"
                            property var cam: root.cameraById(root.focusId)
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 12
                                    color: "#0b1117"
                                    clip: true
                                    CameraFeed {
                                        id: enlargedFeed
                                        anchors.fill: parent
                                        visible: parent.parent.parent.cam !== null
                                        pool: pool
                                        camera: parent.parent.parent.cam || ({ id: "", name: "" })
                                        play: ({ on: root.open && root.view === "enlarged", quality: "main" })
                                        capture: true
                                        muted: false
                                        onSnapshotSaved: (path) => root.showNotice("Snapshot saved: " + path)
                                        onSnapshotFailed: (reason) => root.showNotice(reason)
                                    }
                                    StyledText {
                                        anchors.centerIn: parent
                                        visible: parent.parent.parent.cam === null
                                        text: "Camera not found"
                                        color: "#94a3b8"
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    StyledText {
                                        text: (parent.parent.cam ? parent.parent.cam.name : "")
                                        color: "#e5e7eb"
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                    }
                                    Item { Layout.fillWidth: true }
                                    RippleButton { buttonText: "Prev"; onClicked: root.nextCamera(-1) }
                                    RippleButton { buttonText: "Next"; onClicked: root.nextCamera(1) }
                                    RippleButton { buttonText: "Snapshot"; onClicked: enlargedFeed.takeSnapshot() }
                                    RippleButton { buttonText: "Mute/Unmute"; onClicked: enlargedFeed.muted = !enlargedFeed.muted }
                                    RippleButton { buttonText: "Edit"; onClicked: if (parent.parent.cam) root.openForm(parent.parent.cam) }
                                }
                            }
                        }

                        // WALL (simple all-cameras grid, main streams)
                        Flickable {
                            anchors.fill: parent
                            visible: root.view === "wall"
                            contentHeight: wallCol.implicitHeight
                            clip: true
                            ScrollBar.vertical: ScrollBar { }
                            Column {
                                id: wallCol
                                width: parent.width
                                spacing: 10
                                Grid {
                                    id: wallGrid
                                    width: parent.width
                                    columns: Math.max(1, Number(root.settings.wall?.columns || root.settings.grid?.columns || 2))
                                    spacing: 8
                                    Repeater {
                                        model: enabledCameras()
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: (wallGrid.width - wallGrid.spacing * (wallGrid.columns - 1)) / wallGrid.columns
                                            height: Math.max(180, width * 0.56)
                                            radius: 10
                                            color: "#0f1720"
                                            clip: true
                                            CameraFeed {
                                                anchors.fill: parent
                                                pool: pool
                                                camera: modelData
                                                play: ({ on: root.open && root.view === "wall", quality: "main" })
                                                capture: false
                                                muted: true
                                            }
                                            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 28; color: "#66000000" }
                                            StyledText { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 6; text: modelData.name || "Camera"; color: "white"; font.pixelSize: 12 }
                                            MouseArea { anchors.fill: parent; onClicked: root.openEnlarged(modelData.id) }
                                        }
                                    }
                                }
                            }
                        }

                        // MANAGE
                        Flickable {
                            anchors.fill: parent
                            visible: root.view === "manage"
                            contentHeight: manageCol.implicitHeight
                            clip: true
                            ScrollBar.vertical: ScrollBar { }
                            Column {
                                id: manageCol
                                width: parent.width
                                spacing: 8
                                StyledText {
                                    visible: (store.cameras || []).length === 0
                                    text: "No cameras configured."
                                    color: "#94a3b8"
                                }
                                Repeater {
                                    model: store.cameras || []
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: manageCol.width
                                        height: 64
                                        radius: 10
                                        color: "#111827"
                                        border.color: "#334155"
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                StyledText { text: modelData.name || "Camera"; color: "#e5e7eb"; font.pixelSize: 14 }
                                                StyledText {
                                                    text: (modelData.brand || "custom") + " • " + (Brands.redact ? Brands.redact(Brands.streamUrl(modelData, "main")) : (modelData.host || ""))
                                                    color: "#94a3b8"; font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }
                                            RippleButton { buttonText: modelData.enabled !== false ? "Disable" : "Enable"; onClicked: { var c = Object.assign({}, modelData); c.enabled = !(modelData.enabled !== false); store.updateCamera(modelData.id, c) } }
                                            RippleButton { buttonText: "Edit"; onClicked: root.openForm(modelData) }
                                            RippleButton { buttonText: "Delete"; onClicked: store.removeCamera(modelData.id) }
                                        }
                                    }
                                }
                            }
                        }

                        // FORM
                        Flickable {
                            anchors.fill: parent
                            visible: root.view === "form"
                            contentHeight: formCol.implicitHeight
                            clip: true
                            ScrollBar.vertical: ScrollBar { }

                            Column {
                                id: formCol
                                width: Math.min(parent.width, 640)
                                spacing: 10
                                property var cam: root.editingCamera || ({})
                                property string brandId: root.formBrand

                                function applyFromCamera() {
                                    var c = root.editingCamera || ({})
                                    fName.text = c.name || ""
                                    var bid = c.brand || "tapo"
                                    root.formBrand = bid
                                    var bi = Brands.BRANDS.findIndex(b => b.id === bid)
                                    fBrand.currentIndex = bi >= 0 ? bi : 0
                                    fHost.text = c.host || ""
                                    fCamId.text = c.cameraId || ""
                                    fUser.text = c.username || ""
                                    fPass.text = c.password || ""
                                    fMain.text = c.urlMain || c.url || Brands.template(bid, "main") || ""
                                    fSub.text = c.urlSub || Brands.template(bid, "sub") || ""
                                }
                                Connections {
                                    target: root
                                    function onFormResetChanged() { formCol.applyFromCamera() }
                                    function onViewChanged() { if (root.view === "form") formCol.applyFromCamera() }
                                }

                                StyledText { text: root.editingCamera ? "Edit camera" : "Add camera"; color: "#e5e7eb"; font.pixelSize: 16 }
                                GridLayout {
                                    columns: 2
                                    columnSpacing: 10
                                    rowSpacing: 8
                                    width: parent.width

                                    StyledText { text: "Name"; color: "#cbd5e1" }
                                    TextField { id: fName; Layout.fillWidth: true; placeholderText: "Front door" }

                                    StyledText { text: "Brand"; color: "#cbd5e1" }
                                    ComboBox {
                                        id: fBrand
                                        Layout.fillWidth: true
                                        model: Brands.BRANDS.map(b => b.label)
                                        onActivated: {
                                            var b = Brands.BRANDS[currentIndex]
                                            root.formBrand = b ? b.id : "custom"
                                            if (!fMain.text && b && b.main) fMain.text = b.main
                                            if (!fSub.text && b && b.sub) fSub.text = b.sub
                                        }
                                    }

                                    StyledText { text: "Host / IP"; color: "#cbd5e1" }
                                    TextField { id: fHost; Layout.fillWidth: true; placeholderText: "192.168.1.50" }

                                    StyledText { text: "Camera ID"; color: "#cbd5e1" }
                                    TextField { id: fCamId; Layout.fillWidth: true; placeholderText: "(for UniFi stream key, etc.)" }

                                    StyledText { text: "Username"; color: "#cbd5e1" }
                                    TextField { id: fUser; Layout.fillWidth: true }

                                    StyledText { text: "Password"; color: "#cbd5e1" }
                                    TextField { id: fPass; Layout.fillWidth: true; echoMode: TextInput.Password }

                                    StyledText { text: "Main URL"; color: "#cbd5e1" }
                                    TextField { id: fMain; Layout.fillWidth: true; placeholderText: "rtsp://user:pass@host/stream1" }

                                    StyledText { text: "Sub URL"; color: "#cbd5e1" }
                                    TextField { id: fSub; Layout.fillWidth: true; placeholderText: "(optional low-res stream)" }
                                }

                                Row {
                                    spacing: 8
                                    RippleButton {
                                        buttonText: "Test connection"
                                        onClicked: {
                                            var cam = {
                                                id: formCol.cam.id || "",
                                                name: fName.text || "Camera",
                                                brand: (Brands.BRANDS[fBrand.currentIndex] || {}).id || "custom",
                                                host: fHost.text, cameraId: fCamId.text,
                                                username: fUser.text, password: fPass.text,
                                                urlMain: fMain.text, urlSub: fSub.text
                                            }
                                            probe.test(Brands.streamUrl(cam, "main"), cam)
                                        }
                                    }
                                    RippleButton {
                                        buttonText: "Save"
                                        onClicked: {
                                            var cam = {
                                                id: formCol.cam.id,
                                                name: fName.text || "Camera",
                                                brand: (Brands.BRANDS[fBrand.currentIndex] || {}).id || "custom",
                                                host: fHost.text, cameraId: fCamId.text,
                                                username: fUser.text, password: fPass.text,
                                                urlMain: fMain.text, urlSub: fSub.text,
                                                enabled: formCol.cam.enabled !== false
                                            }
                                            if (root.editingCamera && root.editingCamera.id) store.updateCamera(root.editingCamera.id, cam)
                                            else store.addCamera(cam)
                                            root.showNotice("Camera saved")
                                            root.openManage()
                                        }
                                    }
                                    RippleButton { buttonText: "Cancel"; onClicked: root.openManage() }
                                }

                                Rectangle {
                                    width: parent.width
                                    visible: probe.running || (probe.result && probe.result.done)
                                    height: probeCol.implicitHeight + 16
                                    radius: 8
                                    color: "#111827"
                                    border.color: "#334155"
                                    Column {
                                        id: probeCol
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 4
                                        StyledText { text: probe.running ? "Testing connection…" : "Connection test"; color: "#e5e7eb"; font.pixelSize: 13 }
                                        StyledText {
                                            visible: !probe.running && probe.result
                                            text: probe.result ? (probe.result.ok ? ("OK" + (probe.result.codec ? " • " + probe.result.codec : "") + (probe.result.size ? " • " + probe.result.size : "")) : ("Failed: " + (probe.result.error || "unknown error"))) : ""
                                            color: (probe.result && probe.result.ok) ? "#86efac" : "#fca5a5"
                                            font.pixelSize: 12
                                            wrapMode: Text.Wrap
                                            width: parent.width
                                        }
                                        StyledText {
                                            visible: !probe.running && probe.result && probe.result.hint
                                            text: probe.result ? (probe.result.hint || "") : ""
                                            color: "#94a3b8"; font.pixelSize: 11; wrapMode: Text.Wrap; width: parent.width
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        cfgFile.reload()
    }
}
