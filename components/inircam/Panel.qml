import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import "Brands.js" as Brands

// The camera panel: the grid of cameras, the enlarged view, the wall, the
// camera list and the form to add one. It is a component of its own: it sits
// beside the family and never edits it.
Scope {
    id: root

    property bool open: false
    // grid · enlarged · wall · manage · form
    property string view: "grid"
    property string focusId: ""
    property var editing: null
    property string notice: ""

    readonly property var cameras: store.enabledCameras()

    function toggle() { root.open = !root.open }
    function close() {
        if (root.view === "form") {
            root.view = "manage"
            root.editing = null
            return
        }
        if (root.view === "grid") {
            root.open = false
            return
        }
        root.view = "grid"
    }

    function openCamera(id) {
        if (!id) return
        root.focusId = id
        root.view = "enlarged"
    }

    function stepCamera(delta) {
        const list = root.cameras
        if (list.length === 0) return
        let index = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === root.focusId) {
                index = i
                break
            }
        }
        root.focusId = list[(index + delta + list.length) % list.length].id
    }

    function openForm(camera) {
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

    function saveCamera(camera) {
        if (camera && camera.id) store.updateCamera(camera.id, camera)
        else store.addCamera(camera)
        root.editing = null
        root.view = "manage"
        root.notice = Translation.tr("Camera saved")
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
        if (root.view === "grid" && key >= "1" && key <= "9") {
            const index = parseInt(key) - 1
            if (index < root.cameras.length) {
                root.openCamera(root.cameras[index].id)
                event.accepted = true
            }
        }
    }

    CameraStore { id: store }
    PinStore { id: pins }

    Probe { id: cameraProbe }

    // RTSP feeds use external ffmpeg frame pullers (reliable across backends).
    // Sync pullers when cameras change and keep them alive while the component is active.
    readonly property string feedHelper: Qt.resolvedUrl("inircam-feeds").toString().replace(/^file:\/\//, "")
    Process {
        id: feedSync
        running: false
    }
    function syncFeeds() {
        if (!root.feedHelper || root.feedHelper.indexOf("inircam-feeds") === -1) return
        feedSync.command = ["sh", "-c", 'test -x "$1" && "$1" sync || true', "sh", root.feedHelper]
        feedSync.running = false
        feedSync.running = true
    }
    Timer {
        interval: 15000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.syncFeeds()
    }
    Connections {
        target: store
        function onCamerasChanged() { root.syncFeeds() }
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
        /// Pin a camera to the desktop, or unpin it when it is already pinned
        function pin(cameraId: string): string {
            const on = pins.toggle(cameraId)
            return on ? "pinned" : "unpinned"
        }
        /// Every pinned camera as JSON
        function pins(): string { return JSON.stringify(pins.pins) }
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

    // The panel itself: built only while it is open, so nothing runs while it is closed.
    LazyLoader {
        active: root.open
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
                            visible: root.view !== "grid"
                            text: ({
                                enlarged: Translation.tr("Enlarged"),
                                wall: Translation.tr("All cameras"),
                                manage: Translation.tr("Cameras"),
                                form: root.editing && root.editing.id ? Translation.tr("Edit camera") : Translation.tr("Add camera")
                            })[root.view] ?? ""
                            color: Appearance.colors.colOnSurfaceVariant
                            font.pixelSize: Appearance.font.pixelSize.small
                        }
                        Item { Layout.fillWidth: true }

                        RippleButton {
                            visible: root.view === "grid"
                            buttonText: Translation.tr("All cameras")
                            onClicked: root.view = "wall"
                        }
                        RippleButton {
                            visible: root.view === "grid" || root.view === "wall"
                            buttonText: Translation.tr("Cameras")
                            onClicked: root.view = "manage"
                        }
                        RippleButton {
                            visible: root.view === "manage"
                            buttonText: Translation.tr("Add camera")
                            onClicked: root.openForm(null)
                        }
                        RippleButton {
                            visible: root.view === "grid" || root.view === "enlarged" || root.view === "wall"
                            buttonText: Translation.tr("Grid")
                            onClicked: root.view = "grid"
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

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        CameraGrid {
                            anchors.fill: parent
                            visible: root.view === "grid"
                            cameras: root.cameras
                            pinnedIds: pins.pins.map(p => p.cameraId)
                            onCameraClicked: id => root.openCamera(id)
                        }

                        CameraWall {
                            anchors.fill: parent
                            visible: root.view === "wall"
                            cameras: root.cameras
                            onCameraClicked: id => root.openCamera(id)
                        }

                        CameraEnlarged {
                            anchors.fill: parent
                            visible: root.view === "enlarged"
                            camera: store.cameraById(root.focusId)
                            pinned: pins.pinFor(root.focusId) !== null
                            onPrevious: root.stepCamera(-1)
                            onNext: root.stepCamera(1)
                            onPinToggled: root.focusId ? pins.toggle(root.focusId) : false
                            onEdited: camera => root.openForm(camera)
                        }

                        CameraManage {
                            anchors.fill: parent
                            visible: root.view === "manage"
                            cameras: store.cameras
                            pinnedIds: pins.pins.map(p => p.cameraId)
                            onAdd: root.openForm(null)
                            onEdited: camera => root.openForm(camera)
                            onDeleted: camera => root.deleteCamera(camera)
                            onPinToggled: id => pins.toggle(id)
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