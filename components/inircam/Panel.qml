import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Brands.js" as Brands

// The camera panel: the list of cameras down the side, the one you picked large
// beside it, the whole grid, the form to add one. It is a component of its own:
// it sits beside the family and never edits it.
Scope {
    id: root

    property bool open: false
    // single · grid · manage · form · nvr
    property string view: "single"
    property string focusId: ""
    property var editing: null
    property string notice: ""

    readonly property var cameras: store.enabledCameras()
    readonly property var pinnedIds: pins.pins.map(p => p.cameraId)
    // The camera in front of you: the one that was picked, or the first one if nothing was
    // picked yet (and the old pick is gone, because it was deleted).
    readonly property string shownId: {
        const list = root.cameras
        if (list.length === 0) return ""
        for (let i = 0; i < list.length; i++) if (list[i].id === root.focusId) return root.focusId
        return list[0].id
    }

    function toggle() { root.open = !root.open }
    function close() {
        if (root.view === "form") {
            root.view = "manage"
            root.editing = null
            return
        }
        if (root.view === "single" || root.view === "grid") {
            root.open = false
            return
        }
        root.view = "single"
    }

    function openCamera(id) {
        if (!id) return
        root.focusId = id
        root.view = "single"
    }

    function stepCamera(delta) {
        const list = root.cameras
        if (list.length === 0) return
        let index = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === root.shownId) {
                index = i
                break
            }
        }
        root.focusId = list[(index + delta + list.length) % list.length].id
    }

    function openForm(camera, mode) {
        root.formInitialMode = mode || "manual"
        // Adding a whole NVR is its own surface: no single camera to edit, channels instead.
        if (!camera && root.formInitialMode === "nvr") {
            root.editing = null
            root.view = "nvr"
            return
        }
        root.editing = camera ? Object.assign({}, camera) : {
            id: "",
            name: "",
            brand: "tapo",
            host: "",
            cameraId: "",
            username: "",
            password: "",
            urlMain: "",
            urlSub: ""
        }
        root.view = "form"
    }
    property string formInitialMode: "manual"

    function saveCamera(camera) {
        if (camera && camera.id) store.updateCamera(camera.id, camera)
        else store.addCamera(camera)
        root.editing = null
        root.view = "manage"
        root.notice = Translation.tr("Camera saved")
    }

    // Every channel the scan kept becomes one camera, named after the NVR and its number.
    function addCameras(cameras) {
        if (!cameras || cameras.length === 0) return
        // A batch is created in one go: the number keeps the ids apart when two channels land
        // in the same millisecond.
        const stamp = String(Date.now())
        for (let i = 0; i < cameras.length; i++) {
            const camera = Object.assign({}, cameras[i])
            if (!camera.id) camera.id = `${stamp}-${i + 1}`
            store.addCamera(camera)
        }
        root.view = "manage"
        root.notice = cameras.length === 1
            ? Translation.tr("Camera added")
            : Translation.tr("Cameras added: %1").replace("%1", String(cameras.length))
    }

    function deleteCamera(camera) {
        pins.remove(pins.pinFor(camera.id)?.id ?? "")
        store.removeCamera(camera.id)
    }

    function handleKey(event) {
        const key = event.text || ""
        if (event.key === Qt.Key_Escape) {
            root.close()
            event.accepted = true
            return
        }
        if ((root.view === "grid" || root.view === "single") && key >= "1" && key <= "9") {
            const index = parseInt(key) - 1
            if (index < root.cameras.length) {
                root.openCamera(root.cameras[index].id)
                event.accepted = true
            }
            return
        }
        // Left/right walks the side list without going back to it.
        if (root.view === "single") {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.stepCamera(1)
                event.accepted = true
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.stepCamera(-1)
                event.accepted = true
            }
        }
    }

    CameraStore { id: store }
    PinStore { id: pins }

    Probe { id: cameraProbe }

    // RTSP feeds use external ffmpeg frame pullers (reliable across backends).
    // Pullers run only while the panel or a pinned camera is on screen; at rest
    // the shell keeps no stream open.
    readonly property string feedHelper: Qt.resolvedUrl("inircam-feeds").toString().replace(/^file:\/\//, "")
    // Who is showing the frames right now: the panel, a pin, or another item that
    // asked through `feeds`. Nothing runs while nobody holds one.
    property var feedHolders: ({})
    readonly property bool feedsNeeded: root.open || pins.pins.length > 0 || Object.keys(root.feedHolders).length > 0
    // Who needs the main stream: the camera shown large, and any pinned to the desktop. Everything
    // else — grid, side list, another item's card — is drawn from the substream, so a wall of ten
    // cameras does not open twenty streams at an NVR that only has a handful.
    readonly property var mainIds: {
        const ids = []
        if (root.open && root.view === "single" && root.shownId) ids.push(root.shownId)
        for (let i = 0; i < pins.pins.length; i++) {
            const id = pins.pins[i].cameraId
            if (id && ids.indexOf(id) === -1) ids.push(id)
        }
        return ids
    }

    Process {
        id: feedSync
        running: false
    }

    function runFeedHelper(verb) {
        if (!root.feedHelper || root.feedHelper.indexOf("inircam-feeds") === -1) return
        const script = verb === "sync"
            ? 'test -x "$1" && exec "$1" sync "$2" "$3"'
            : 'test -x "$1" && exec "$1" stop'
        feedSync.command = ["sh", "-c", script, "sh", root.feedHelper, String(Quickshell.processId), root.mainIds.join(",")]
        feedSync.running = false
        feedSync.running = true
    }

    function syncFeeds() { root.runFeedHelper("sync") }
    onMainIdsChanged: if (root.feedsNeeded) root.syncFeeds()
    function stopFeeds() { root.runFeedHelper("stop") }

    onFeedsNeededChanged: {
        if (root.feedsNeeded) root.syncFeeds()
        else root.stopFeeds()
    }

    // Keeps a puller alive after an RTSP drop, and only while something shows it.
    Timer {
        interval: 15000
        repeat: true
        running: root.feedsNeeded
        onTriggered: root.syncFeeds()
    }
    Connections {
        target: store
        function onCamerasChanged() { if (root.feedsNeeded) root.syncFeeds() }
    }

    /// The camera panel: open or close it, open a camera, pin it to the desktop.
    ///
    /// ```kdl
    /// Mod+Shift+C { spawn "inir" "inircam" "toggle"; }
    /// ```
    IpcHandler {
        target: "inircam"
        /// Open or close the camera panel
        function toggle(): void { root.toggle() }
        /// Close the camera panel
        function close(): void { root.open = false }
        /// Open the camera panel
        function open(): void { root.open = true }
        /// Open the camera list/management view
        function manage(): void { root.open = true; root.view = "manage" }
        /// Open the add-camera form
        function add(): void { root.open = true; root.openForm(null, "manual") }
        /// Open the NVR/DVR scan form
        function addNvr(): void { root.open = true; root.openForm(null, "nvr") }
        /// Open network discovery
        function discover(): void { root.open = true; root.openForm(null, "discover") }
        /// Pin a camera to the desktop, or unpin it when it is already pinned
        function pin(cameraId: string): string {
            const on = pins.toggle(cameraId)
            return on ? "pinned" : "unpinned"
        }
        /// Every pinned camera as JSON
        function pins(): string { return JSON.stringify(pins.pins) }
        /// The cameras this panel can show, without their passwords, as JSON
        function cameras(): string {
            return JSON.stringify(store.enabledCameras().map(camera => ({
                id: String(camera.id ?? ""),
                name: String(camera.name ?? camera.id ?? "")
            })))
        }
        /// Keep the frames running for another item that shows them, or let them go
        function feeds(holder: string, active: bool): string {
            const name = String(holder ?? "")
            if (name.length === 0) return JSON.stringify({ error: "a holder is required" })
            const next = Object.assign({}, root.feedHolders)
            if (active) next[name] = true
            else delete next[name]
            root.feedHolders = next
            return JSON.stringify({ holders: Object.keys(next) })
        }
    }

    // The pinned cameras: their own windows, up while the panel is closed.
    Variants {
        model: pins.pins.map(pin => pin.id)

        PanelWindow {
            id: pinWindow
            required property string modelData
            readonly property var pin: pins.pins.find(p => p.id === pinWindow.modelData) ?? null
            readonly property var camera: pinWindow.pin ? store.cameraById(pinWindow.pin.cameraId) : null
            readonly property int pad: 14

            screen: {
                const wanted = pinWindow.pin ? pinWindow.pin.output : ""
                if (wanted.length > 0) {
                    const found = Quickshell.screens.find(s => s.name === wanted)
                    if (found) return found
                }
                return Quickshell.screens[0] ?? null
            }
            visible: pinWindow.pin !== null
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:inircam-pin"
            WlrLayershell.layer: pinWindow.pin && pinWindow.pin.onTop === false ? WlrLayer.Bottom : WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; left: true }
            margins {
                left: Math.round(pinWindow.pin ? pinWindow.pin.x : 0) - pinWindow.pad
                top: Math.round(pinWindow.pin ? pinWindow.pin.y : 0) - pinWindow.pad
            }
            implicitWidth: pinCard.width + pinWindow.pad * 2
            implicitHeight: pinCard.height + pinWindow.pad * 2
            mask: Region { item: pinCard }

            PinnedCamera {
                id: pinCard
                x: pinWindow.pad
                y: pinWindow.pad
                pin: pinWindow.pin
                camera: pinWindow.camera
                bounds: Qt.size(pinWindow.screen?.width ?? 1920, pinWindow.screen?.height ?? 1080)
                onMoved: (id, x, y) => pins.update(id, { x: x, y: y, output: pinWindow.screen?.name ?? "" })
                onResized: (id, width) => pins.update(id, { width: width })
                onClosed: id => pins.remove(id)
                onOpened: cameraId => { root.open = true; root.openCamera(cameraId) }
                onTopToggled: (id, onTop) => pins.update(id, { onTop: onTop })
            }
        }
    }

    // The panel itself. It stays built and hidden while closed: destroying the layer surface on
    // every close leaks one surface per open (Quickshell 0.3.x), and the leftovers come back later
    // with whatever they were showing. Nothing runs anyway — feeds and timers follow `visible`.
    PanelWindow {
        id: window
        visible: root.open
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:inircam"
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
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1
            clip: true
            focus: true
            Keys.onPressed: event => root.handleKey(event)

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // The header: where you are and what you can do from here.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledText {
                        text: Translation.tr("Cameras")
                        font.pixelSize: Appearance.font.pixelSize.title
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        text: ({
                            single: Translation.tr("One camera"),
                            grid: Translation.tr("All cameras"),
                            manage: Translation.tr("Cameras"),
                            nvr: Translation.tr("Add from an NVR"),
                            form: root.editing && root.editing.id ? Translation.tr("Edit camera") : Translation.tr("Add camera")
                        })[root.view] ?? ""
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Item { Layout.fillWidth: true }

                    // The two ways to watch the list.
                    RippleButton {
                        visible: root.view === "single" || root.view === "grid"
                        buttonText: Translation.tr("Single")
                        toggled: root.view === "single"
                        onClicked: root.view = "single"
                    }
                    RippleButton {
                        visible: root.view === "single" || root.view === "grid"
                        buttonText: Translation.tr("Grid")
                        toggled: root.view === "grid"
                        onClicked: root.view = "grid"
                    }
                    RippleButton {
                        visible: root.view === "manage" || root.view === "nvr"
                        buttonText: Translation.tr("Back")
                        onClicked: root.view = root.cameras.length > 0 ? "single" : "grid"
                    }
                    RippleButton {
                        visible: root.view === "manage"
                        buttonText: Translation.tr("Add camera")
                        onClicked: root.openForm(null)
                    }
                    RippleButton {
                        buttonText: Translation.tr("Close")
                        onClicked: root.close()
                    }
                }

                // The notice line: what just happened.
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.notice !== ""
                    implicitHeight: 32
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colLayer2

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.notice
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    // The list down the side: pick one, and it takes the room.
                    CameraSidebar {
                        Layout.fillHeight: true
                        visible: root.view === "single" || root.view === "grid"
                        cameras: root.cameras
                        selectedId: root.shownId
                        pinnedIds: root.pinnedIds
                        onCameraSelected: id => root.openCamera(id)
                        onManageRequested: root.view = "manage"
                        onAddRequested: root.openForm(null)
                    }

                    Item {
                        id: gridArea

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        CameraGrid {
                            anchors.fill: parent
                            visible: root.view === "grid"
                            // As many across as the room allows: ten cameras in two columns are
                            // five rows tall, and five rows do not fit.
                            columns: Math.max(2, Math.min(4, Math.floor(gridArea.width / 260)))
                            cameras: root.cameras
                            pinnedIds: root.pinnedIds
                            onCameraClicked: id => root.openCamera(id)
                        }

                        CameraEnlarged {
                            anchors.fill: parent
                            visible: root.view === "single"
                            camera: store.cameraById(root.shownId)
                            pinned: pins.pinFor(root.shownId) !== null
                            onPrevious: root.stepCamera(-1)
                            onNext: root.stepCamera(1)
                            onPinToggled: root.shownId ? pins.toggle(root.shownId) : false
                            onEdited: camera => root.openForm(camera)
                        }

                        CameraManage {
                            anchors.fill: parent
                            visible: root.view === "manage"
                            cameras: store.cameras
                            pinnedIds: pins.pins.map(p => p.cameraId)
                            onAdd: root.openForm(null)
                            onAddNvr: root.openForm(null, "nvr")
                            onEdited: camera => root.openForm(camera)
                            onDeleted: camera => root.deleteCamera(camera)
                            onPinToggled: id => pins.toggle(id)
                        }

                        NvrForm {
                            anchors.fill: parent
                            visible: root.view === "nvr"
                            probe: cameraProbe
                            onAdded: cameras => root.addCameras(cameras)
                            onCancelled: root.view = "manage"
                        }

                        CameraForm {
                            anchors.fill: parent
                            visible: root.view === "form"
                            camera: root.editing
                            probe: cameraProbe
                            onSaved: camera => root.saveCamera(camera)
                            onCancelled: { root.editing = null; root.view = "manage" }
                        }
                    }
                }
            }
        }
    }
}
