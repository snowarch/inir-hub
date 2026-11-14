import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import "Brands.js" as Brands
import qs.services

// Add a camera or change one: the name, the address, the login.
Item {
    id: root

    required property var camera
    required property Probe probe

    signal saved(var camera)
    signal cancelled()

    property bool editing: camera !== null && camera.id !== undefined && camera.id !== ""
    property string name: ""
    property string brand: "tapo"
    property string host: ""
    property string cameraId: ""
    property string username: ""
    property string password: ""
    property string urlMain: ""
    property string urlSub: ""
    property string error: ""

    function apply(camera) {
        if (!camera) {
            root.name = ""
            root.brand = "tapo"
            root.host = ""
            root.cameraId = ""
            root.username = ""
            root.password = ""
            root.urlMain = ""
            root.urlSub = ""
            root.error = ""
            return
        }
        root.name = camera.name || ""
        root.brand = camera.brand || "tapo"
        root.host = camera.host || ""
        root.cameraId = camera.cameraId || ""
        root.username = camera.username || ""
        root.password = camera.password || ""
        root.urlMain = camera.urlMain || ""
        root.urlSub = camera.urlSub || ""
        root.error = ""
    }

    function current() {
        return {
            id: root.editing ? root.camera.id : "",
            name: root.name,
            brand: root.brand,
            host: root.host,
            cameraId: root.cameraId,
            username: root.username,
            password: root.password,
            urlMain: root.urlMain,
            urlSub: root.urlSub,
            enabled: root.camera && root.camera.enabled !== false
        }
    }

    function test() {
        root.error = ""
        const cam = root.current()
        const url = Brands.streamUrl(cam, "main")
        if (!url) {
            root.error = Translation.tr("Enter the stream address first")
            return
        }
        root.probe.probe(url)
    }

    function save() {
        if (root.name.trim() === "") {
            root.error = Translation.tr("Give the camera a name")
            return
        }
        const cam = root.current()
        if (!Brands.streamUrl(cam, "main")) {
            root.error = Translation.tr("Enter the stream address")
            return
        }
        root.saved(cam)
    }

    onCameraChanged: root.apply(root.camera)

    Component.onCompleted: root.apply(root.camera)

    Connections {
        target: root.probe
        function onFinished(result) {
            if (!result) return
            root.error = result.ok ? "" : result.message
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        ColumnLayout {
            width: Math.min(parent.width, 640)
            spacing: 10

            StyledText {
                text: root.editing ? Translation.tr("Edit camera") : Translation.tr("Add camera")
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 8

                StyledText {
                    text: Translation.tr("Name")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: nameField
                    Layout.fillWidth: true
                    text: root.name
                    placeholderText: Translation.tr("Front door")
                    onTextChanged: root.name = text
                }

                StyledText {
                    text: Translation.tr("Brand")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                ComboBox {
                    id: brandBox
                    Layout.fillWidth: true
                    model: Brands.BRANDS.map(b => b.label)
                    onActivated: {
                        const b = Brands.BRANDS[currentIndex]
                        root.brand = b ? b.id : "custom"
                        if (!root.urlMain && b) root.urlMain = Brands.template(root.brand, "main")
                        if (!root.urlSub && b) root.urlSub = Brands.template(root.brand, "sub")
                    }
                    Component.onCompleted: {
                        const index = Brands.BRANDS.findIndex(b => b.id === root.brand)
                        currentIndex = index >= 0 ? index : 0
                    }
                }

                StyledText {
                    text: Translation.tr("Host or IP")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: hostField
                    Layout.fillWidth: true
                    text: root.host
                    placeholderText: "192.168.1.50"
                    onTextChanged: root.host = text
                }

                StyledText {
                    text: Translation.tr("Camera ID")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: cameraIdField
                    Layout.fillWidth: true
                    text: root.cameraId
                    placeholderText: Translation.tr("The stream key, for UniFi Protect")
                    onTextChanged: root.cameraId = text
                }

                StyledText {
                    text: Translation.tr("Username")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: userField
                    Layout.fillWidth: true
                    text: root.username
                    onTextChanged: root.username = text
                }

                StyledText {
                    text: Translation.tr("Password")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: passField
                    Layout.fillWidth: true
                    text: root.password
                    echoMode: TextInput.Password
                    onTextChanged: root.password = text
                }

                StyledText {
                    text: Translation.tr("Stream address")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: urlField
                    Layout.fillWidth: true
                    text: root.urlMain
                    placeholderText: "rtsp://user:pass@host/stream1"
                    onTextChanged: root.urlMain = text
                }

                StyledText {
                    text: Translation.tr("Low-resolution address")
                    color: Appearance.colors.colOnLayer2
                    font.pixelSize: Appearance.font.pixelSize.small
                }
                MaterialTextField {
                    id: urlSubField
                    Layout.fillWidth: true
                    text: root.urlSub
                    placeholderText: Translation.tr("Optional")
                    onTextChanged: root.urlSub = text
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.error !== ""
                text: root.error
                color: Appearance.colors.colError
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.probe.running || (root.probe.result && root.probe.result.ok)
                text: root.probe.result && root.probe.result.ok
                    ? Translation.tr("The camera answers: %1 %2").arg(root.probe.result.codec || "").arg(root.probe.result.width ? `${root.probe.result.width}×${root.probe.result.height}` : "")
                    : ""
                color: Appearance.colors.colPrimary
                font.pixelSize: Appearance.font.pixelSize.small
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RippleButton {
                    buttonText: Translation.tr("Test connection")
                    enabled: !root.probe.running
                    onClicked: root.test()
                }
                RippleButton {
                    buttonText: Translation.tr("Save")
                    onClicked: root.save()
                }
                RippleButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: root.cancelled()
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Translation.tr("The address and the login are kept in this component's own file")
                    color: Appearance.colors.colOnSurfaceVariant
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }
    }
}