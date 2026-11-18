import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Add a whole NVR or DVR at once. An NVR hides several cameras behind one address, one
// login and a channel number: this form asks for the address, the login and a channel
// range, probes each channel with ffprobe, and keeps the ones that answer as cameras.
//
// The channel that answers and the channel that does not are told apart by ffprobe alone,
// so a wrong password is reported once (not eight times), and a range that runs past the
// NVR's real channel count stops after a few empty channels instead of probing to the end.
Item {
    id: root

    component Field: Item {
        id: field
        required property string value
        property string placeholder: ""
        property bool secret: false
        signal edited(string text)

        Layout.fillWidth: true
        Layout.preferredHeight: input.implicitHeight

        MaterialTextField {
            id: input
            anchors.left: parent.left
            anchors.right: parent.right
            text: field.value
            placeholderText: field.placeholder
            echoMode: field.secret ? TextInput.Password : TextInput.Normal
            onTextChanged: field.edited(text)
        }
    }

    required property Probe probe

    signal added(var cameras)
    signal cancelled()

    // ── What the NVR is ──────────────────────────────────────
    property string brand: "dahua"
    property string host: ""
    property string port: "554"
    property string username: ""
    property string password: ""
    property int fromChannel: 1
    property int toChannel: 8

    // Stops a range that runs past the NVR's channels: three empty ones in a row is enough.
    readonly property int emptyInARow: 3

    readonly property var brandList: [
        { id: "dahua", label: Translation.tr("Dahua / Imou / Amcrest"), path: "cam/realmonitor?channel=%1&subtype=%2" },
        { id: "hikvision", label: Translation.tr("Hikvision / HiLook"), path: "Streaming/Channels/%1%2" },
        { id: "reolink", label: Translation.tr("Reolink"), path: "h264Preview_%1_%2" }
    ]

    // ── What the scan found ──────────────────────────────────
    property bool scanning: false
    property int channel: 1
    property int checked: 0
    property int misses: 0
    property var found: []
    property string message: ""
    property var currentUrls: ({ main: "", sub: "" })

    // ── Addresses ────────────────────────────────────────────
    function addressBase() {
        const host = String(root.host ?? "").trim()
        if (host.length === 0) return ""
        const port = String(root.port ?? "").trim()
        return port.length > 0 ? `${host}:${port}` : host
    }

    function channelUrls(channel) {
        const base = root.addressBase()
        if (base.length === 0) return { main: "", sub: "" }
        const entry = root.brandList.find(b => b.id === root.brand) ?? root.brandList[0]
        // Hikvision counts 101, 102, ... per channel; the others take the number as-is.
        const narrow = root.brand === "hikvision" ? (channel < 10 ? `0${channel}` : String(channel)) : String(channel)
        const main = `rtsp://${base}/${entry.path}`.replace("%1", narrow).replace("%2", root.brand === "hikvision" ? "01" : "0")
        const sub = `rtsp://${base}/${entry.path}`.replace("%1", narrow).replace("%2", "1")
        return { main: main, sub: sub }
    }

    // The login rides inside the URL; Probe hands it to ffprobe through stdin so it never
    // reaches a command line.
    function withAuth(url) {
        const user = String(root.username ?? "").trim()
        const pass = String(root.password ?? "")
        if (url.length === 0 || (user.length === 0 && pass.length === 0)) return url
        const scheme = url.indexOf("://")
        if (scheme < 0) return url
        const auth = encodeURIComponent(user) + (pass.length > 0 ? ":" + encodeURIComponent(pass) : "") + "@"
        return url.slice(0, scheme + 3) + auth + url.slice(scheme + 3)
    }

    // ── The scan ─────────────────────────────────────────────
    function start() {
        if (root.scanning) return
        root.scanning = true
        root.found = []
        root.message = ""
        root.misses = 0
        root.checked = 0
        root.channel = Math.max(1, Math.min(root.fromChannel, root.toChannel))
        root.scanNext()
    }

    function stop(reason) {
        root.scanning = false
        root.probe.cancel()
        if (reason && itemCount() === 0 && root.message.length === 0) root.message = reason
        if (!reason && itemCount() === 0 && root.message.length === 0)
            root.message = Translation.tr("No channel answered in that range.")
    }

    function scanNext() {
        if (!root.scanning) return
        if (root.channel > Math.max(root.fromChannel, root.toChannel)) return root.stop("")
        if (root.misses >= root.emptyInARow) return root.stop("")
        root.currentUrls = root.channelUrls(root.channel)
        root.probe.probe(root.withAuth(root.currentUrls.main))
    }

    function onProbed(result) {
        if (!root.scanning) return
        if (!result) return root.stop("")

        root.checked += 1
        if (result.ok) {
            root.misses = 0
            const list = root.found.slice()
            list.push({
                channel: root.channel,
                main: root.currentUrls.main,
                sub: root.currentUrls.sub,
                detail: result.width > 0 ? `${result.width}×${result.height} ${result.codec || ""}`.trim() : "",
                selected: true
            })
            root.found = list
        } else {
            root.misses += 1
            // A login that fails on the very first channel is a login problem. On a later one it
            // is usually a channel that is not there: Dahua and Imou answer 401 for those, so the
            // scan counts it as empty and keeps looking.
            if (result.kind === "auth" && root.found.length === 0)
                return root.stop(Translation.tr("The NVR refused that login. Check the username and password."))
            if (result.kind === "offline" && root.checked === 1)
                return root.stop(Translation.tr("Nothing answered at that address. Check the host and the port."))
        }
        root.channel += 1
        root.scanNext()
    }

    function itemCount() { return root.found.length }

    function selectedCount() {
        let n = 0
        for (let i = 0; i < root.found.length; i++) if (root.found[i].selected) n++
        return n
    }

    function toggle(index) {
        const list = root.found.slice()
        if (!list[index]) return
        list[index] = Object.assign({}, list[index], { selected: !list[index].selected })
        root.found = list
    }

    function add() {
        const out = []
        const host = String(root.host ?? "").trim()
        for (let i = 0; i < root.found.length; i++) {
            const f = root.found[i]
            if (!f.selected) continue
            out.push({
                id: "",
                name: `${Translation.tr("NVR")} ${host} - ${Translation.tr("Channel")} ${f.channel}`,
                brand: root.brand,
                host: host,
                cameraId: "",
                username: root.username,
                password: root.password,
                urlMain: f.main,
                urlSub: f.sub,
                enabled: true
            })
        }
        root.added(out)
    }

    Connections {
        target: root.probe
        function onFinished(result) { root.onProbed(result) }
    }

    // ── Look ─────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        StyledText {
            text: Translation.tr("Add from an NVR or DVR")
            color: Appearance.colors.colOnLayer1
            font.pixelSize: Appearance.font.pixelSize.large
            font.weight: Font.DemiBold
        }
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("One address hides several cameras behind a channel number. Scan the channels, then keep the ones that answer.")
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.smaller
            wrapMode: Text.Wrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 8

            StyledText {
                text: Translation.tr("Brand")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            ComboBox {
                id: brandBox
                Layout.fillWidth: true
                model: root.brandList.map(b => b.label)
                onActivated: root.brand = root.brandList[currentIndex].id
                Component.onCompleted: currentIndex = Math.max(0, root.brandList.findIndex(b => b.id === root.brand))
            }

            StyledText {
                text: Translation.tr("Host or IP")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            Field {
                value: root.host
                placeholder: "192.168.1.50"
                onEdited: text => root.host = text
            }

            StyledText {
                text: Translation.tr("RTSP port")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            Field {
                value: root.port
                placeholder: "554"
                onEdited: text => root.port = text
            }

            StyledText {
                text: Translation.tr("Username")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            Field {
                value: root.username
                onEdited: text => root.username = text
            }

            StyledText {
                text: Translation.tr("Password")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            Field {
                value: root.password
                secret: true
                onEdited: text => root.password = text
            }

            StyledText {
                text: Translation.tr("Channels")
                color: Appearance.colors.colOnLayer2
                font.pixelSize: Appearance.font.pixelSize.small
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MaterialTextField {
                    Layout.preferredWidth: 70
                    text: String(root.fromChannel)
                    onTextChanged: root.fromChannel = Math.max(1, Number(text) || 1)
                }
                StyledText {
                    text: "–"
                    color: Appearance.colors.colOnLayer2
                }
                MaterialTextField {
                    Layout.preferredWidth: 70
                    text: String(root.toChannel)
                    onTextChanged: root.toChannel = Math.max(1, Number(text) || 1)
                }
                Item { Layout.fillWidth: true }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButton {
                buttonText: root.scanning ? Translation.tr("Stop") : Translation.tr("Scan channels")
                onClicked: root.scanning ? root.stop("") : root.start()
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.scanning
                text: Translation.tr("Checking channel %1…").replace("%1", String(root.channel))
                color: Appearance.colors.colOnSurfaceVariant
                font.pixelSize: Appearance.font.pixelSize.small
                elide: Text.ElideRight
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.message.length > 0
            text: root.message
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.Wrap
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: root.found
            visible: root.found.length > 0

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                width: ListView.view.width
                height: 44
                radius: Appearance.rounding.normal
                color: Appearance.colors.colLayer2

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    MaterialSymbol {
                        text: row.modelData.selected ? "check_box" : "check_box_outline_blank"
                        iconSize: 18
                        color: row.modelData.selected ? Appearance.colors.colPrimary : Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        text: `${Translation.tr("Channel")} ${row.modelData.channel}`
                        color: Appearance.colors.colOnLayer2
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: row.modelData.detail
                        color: Appearance.colors.colOnSurfaceVariant
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggle(row.index)
                }
            }
        }

        Item { Layout.fillHeight: true; visible: root.found.length === 0 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RippleButton {
                buttonText: Translation.tr("Cancel")
                onClicked: root.cancelled()
            }
            Item { Layout.fillWidth: true }
            RippleButton {
                buttonText: root.selectedCount() > 0
                    ? Translation.tr("Add %1 cameras").replace("%1", String(root.selectedCount()))
                    : Translation.tr("Add cameras")
                enabled: root.selectedCount() > 0 && !root.scanning
                onClicked: root.add()
            }
        }
    }
}
