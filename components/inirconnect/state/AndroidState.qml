pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common

Singleton {
    id: root

    property bool open: false
    property alias windowed: adapter.windowed
    property alias verticalLayout: adapter.verticalLayout
    property alias pinned: adapter.pinned
    property alias mediaVisible: adapter.mediaVisible
    property bool wirelessOpen: false
    property bool devicesOpen: false
    property bool shareOpen: false
    property bool notificationsOpen: false
    property bool moreOpen: false
    property bool audioEnabled: false
    property bool keepAwake: false
    property bool recording: false
    property bool mirrorRunning: scrcpyProc.running
    property bool mediaPlaying: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string mediaArtUrl: ""
    property var phoneNotifications: []

    readonly property bool isLightTheme: !ConnectStyle.dark
    readonly property string iconInk: Qt.color(ConnectStyle.text).toString()

    Component.onCompleted: iconWriter.syncIcon()
    onIconInkChanged: iconWriter.syncIcon()
    onIsLightThemeChanged: iconWriter.syncIcon()
    Connections {
        target: AppSearch
        function on_StartupClassMapChanged(): void { iconWriter.registerAppEntry() }
    }

    FileView {
        id: iconWriter
        path: Plugins.path("inirconnect", "icon.svg")
        printErrors: false
        property bool _updatingMap: false
        function registerAppEntry(): void {
            if (iconWriter._updatingMap) return
            const variantFile = Plugins.path("inirconnect", root.isLightTheme ? "assets/icon-light.svg" : "assets/icon-dark.svg")
            const cur = AppSearch._startupClassMap?.["inirconnect"]
            if (cur && cur.icon === variantFile) return
            iconWriter._updatingMap = true
            const nextMap = Object.assign({}, AppSearch._startupClassMap ?? {})
            nextMap["inirconnect"] = {
                id: "",
                name: "iNiRConnect",
                icon: variantFile,
                command: [],
                execute: () => {
                    root.open = !root.open
                }
            }
            AppSearch._startupClassMap = nextMap
            iconWriter._updatingMap = false
        }
        function syncIcon(): void {
            if (!iconWriter.path || iconWriter.path.length === 0) return
            const c = root.isLightTheme ? "#221F1B" : "#F5F2EB" // literal: adaptive light/dark SVG stroke
            iconWriter.setText(`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 24 24" fill="none">\n  <rect x="5.5" y="2.5" width="13" height="19" rx="3" stroke="${c}" stroke-width="2"/>\n  <line x1="10" y1="5.5" x2="14" y2="5.5" stroke="${c}" stroke-width="1.8" stroke-linecap="round"/>\n  <circle cx="12" cy="18.3" r="1.15" fill="${c}"/>\n</svg>\n`)
            iconWriter.registerAppEntry()
        }
    }

    FileView {
        id: optionsFile
        path: Directories.pluginFile("inirconnect")
        watchChanges: true
        atomicWrites: false
        onFileChanged: optionsFile.reload()
        onAdapterUpdated: optionsFile.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) optionsFile.writeAdapter() }
        JsonAdapter {
            id: adapter
            property bool windowed: false
            property bool verticalLayout: false
            property bool mediaVisible: true
            property bool pinned: false
            property string preferredDeviceId: ""
        }
    }

    property var devices: []
    property var recentFiles: []
    property string selectedDeviceId: adapter.preferredDeviceId
    property string selectedSerial: ""
    property string selectedKdeId: ""
    property string deviceIp: ""
    property string deviceName: "Android Device"
    property string deviceBrand: "android"
    property string connectionType: "none"
    property int batteryLevel: -1
    property bool isCharging: false
    property string networkType: "—"
    property string signalQuality: "Offline"
    property string statusMessage: ""

    property string qrImagePath: "/tmp/inir_adb_qr.png"
    property string qrStatus: "idle"
    property string qrMessage: ""
    property string qrCode: ""
    property string qrService: ""
    property real qrUpdated: 0

    onWirelessOpenChanged: {
        if (root.wirelessOpen)
            root.startQrPairing()
        else
            root.stopQrPairing()
    }

    readonly property bool connected: root.selectedSerial.length > 0 || root.selectedKdeId.length > 0
    readonly property bool hasAdb: root.selectedSerial.length > 0
    readonly property bool hasKde: root.selectedKdeId.length > 0

    function toggleSheet(sheet: string): void {
        root.devicesOpen = (sheet === "devices") ? !root.devicesOpen : false
        root.shareOpen = (sheet === "share") ? !root.shareOpen : false
        root.notificationsOpen = (sheet === "notifications") ? !root.notificationsOpen : false
        root.wirelessOpen = (sheet === "wireless") ? !root.wirelessOpen : false
    }

    function detectBrand(modelStr: string): string {
        const lower = modelStr.toLowerCase()
        if (lower.includes("xiaomi") || lower.includes("redmi") || lower.includes("poco") || lower.startsWith("2"))
            return "xiaomi"
        if (lower.includes("pixel") || lower.includes("google"))
            return "google"
        if (lower.includes("moto") || lower.includes("motorola"))
            return "motorola"
        if (lower.includes("oppo") || lower.includes("cph") || lower.includes("realme") || lower.includes("oneplus"))
            return "oppo"
        return "android"
    }

    function applySelectedDevice(): void {
        const onlineList = root.devices.filter(d => d.online)
        let chosen = root.devices.find(d => d.id === root.selectedDeviceId && d.online)
            ?? onlineList[0]
            ?? root.devices.find(d => d.id === root.selectedDeviceId)
            ?? null

        if (!chosen) {
            root.selectedSerial = ""
            root.selectedKdeId = ""
            root.deviceIp = ""
            root.connectionType = "none"
            root.batteryLevel = -1
            root.networkType = "—"
            root.signalQuality = "Offline"
            root.mediaPlaying = false
            root.mediaTitle = ""
            root.mediaArtist = ""
            root.mediaArtUrl = ""
            root.phoneNotifications = []
            return
        }

        root.selectedDeviceId = chosen.id
        root.selectedSerial = chosen.online ? (chosen.serial ?? "") : ""
        root.selectedKdeId = chosen.online ? (chosen.kdeId ?? "") : ""
        root.deviceIp = chosen.ip ?? ""
        root.deviceName = chosen.name || chosen.serial || "Android"
        root.deviceBrand = root.detectBrand(root.deviceName)
        if (root.selectedSerial.length > 0)
            root.connectionType = root.selectedSerial.includes(":") ? "wireless" : "adb"
        else if (root.selectedKdeId.length > 0)
            root.connectionType = "kdeconnect"
        else
            root.connectionType = "none"
        root.batteryLevel = chosen.batteryLevel ?? -1
        root.isCharging = Boolean(chosen.isCharging)
        root.networkType = chosen.networkType || "Wi-Fi"
        root.signalQuality = chosen.online ? (chosen.signalQuality || "Good") : "Offline"
        root.mediaPlaying = Boolean(chosen.mediaPlaying)
        root.mediaTitle = chosen.mediaTitle ?? ""
        root.mediaArtist = chosen.mediaArtist ?? ""
        root.mediaArtUrl = chosen.mediaArtUrl ?? ""
        root.phoneNotifications = chosen.notifications ?? []
    }

    function selectDevice(id: string): void {
        root.selectedDeviceId = id
        adapter.preferredDeviceId = id
        root.applySelectedDevice()
        root.devicesOpen = false
    }

    function rescanNetwork(): void {
        Quickshell.execDetached(["sh", "-c", "kdeconnect-cli --refresh >/dev/null 2>&1 || true"])
        Qt.callLater(root.refresh)
    }

    function refresh(): void {
        if (!adbProbeProc.running)
            adbProbeProc.running = true
    }

    onOpenChanged: {
        if (root.open) {
            root.refresh()
            pollTimer.start()
        } else {
            pollTimer.stop()
            root.wirelessOpen = false
            root.devicesOpen = false
            root.shareOpen = false
            root.notificationsOpen = false
            root.moreOpen = false
        }
    }

    Timer {
        id: pollTimer
        interval: 2500
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: adbProbeProc
        command: ["python3", Plugins.path("inirconnect", "scripts/probe.py")]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (!line.startsWith("JSON|")) return
                try {
                    const parsed = JSON.parse(line.slice(5))
                    root.devices = parsed.devices ?? []
                    root.recentFiles = parsed.recent ?? []
                    root.applySelectedDevice()
                } catch (e) {}
            }
        }
    }

    Process {
        id: actionProc
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line.length > 0)
                    root.statusMessage = line
            }
        }
        onExited: root.refresh()
    }

    Process {
        id: qrProc
        command: ["python3", Plugins.path("inirconnect", "scripts/adb_qr_service.py")]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim()
                if (line.startsWith("JSON:")) {
                    try {
                        const parsed = JSON.parse(line.slice(5))
                        root.qrStatus = parsed.status ?? "waiting"
                        root.qrMessage = parsed.message ?? ""
                        root.qrCode = parsed.password ?? ""
                        root.qrService = parsed.service ?? ""
                        root.qrUpdated = Date.now()
                        if (parsed.status === "connected") {
                            root.refresh()
                            Quickshell.execDetached([
                                "notify-send", "-a", "AndroidConnect",
                                "ADB Inalámbrico Conectado",
                                parsed.message
                            ])
                        }
                    } catch (e) {}
                }
            }
        }
        onExited: {
            if (root.qrStatus !== "connected")
                root.qrStatus = "idle"
        }
    }

    Process {
        id: scrcpyProc
    }

    function requireAdbOrGuide(featureName: string): bool {
        if (root.selectedSerial.length > 0)
            return true
        root.toggleSheet("wireless")
        root.wirelessOpen = true
        const ipHint = root.deviceIp.length > 0 ? `${root.deviceIp}:puerto` : "IP:puerto"
        root.statusMessage = `${featureName} requiere Depuración inalámbrica (ADB). Actívala en Opciones de desarrollador y conecta en ${ipHint}.`
        Quickshell.execDetached([
            "notify-send", "-a", "AndroidConnect",
            featureName,
            `Activa Depuración inalámbrica (ADB) en tu teléfono y conecta en ${ipHint}`
        ])
        return false
    }

    function runAdb(args: var): void {
        if (root.selectedSerial.length === 0) return
        actionProc.command = ["adb", "-s", root.selectedSerial].concat(args)
        actionProc.running = true
    }

    function wakeAndUnlock(): void {
        if (root.selectedSerial.length > 0) {
            root.runAdb(["shell", "input keyevent KEYCODE_WAKEUP && wm dismiss-keyguard"])
            return
        }
        if (root.selectedKdeId.length > 0) {
            Quickshell.execDetached([
                "sh", "-c",
                `kdeconnect-cli -d "${root.selectedKdeId}" --unlock >/dev/null 2>&1; kdeconnect-cli -d "${root.selectedKdeId}" --ping-msg "AndroidConnect" >/dev/null 2>&1`
            ])
            return
        }
        root.requireAdbOrGuide("Desbloquear pantalla")
    }

    function sendKeyEvent(key: string): void {
        if (!root.requireAdbOrGuide("Botones de navegación")) return
        root.runAdb(["shell", "input", "keyevent", key])
    }

    function openScrcpyWindow(): void {
        if (scrcpyProc.running) {
            scrcpyProc.running = false
            return
        }
        if (!root.requireAdbOrGuide("Espejo de pantalla (scrcpy)")) return
        let cmd = `command -v scrcpy >/dev/null 2>&1 && exec scrcpy -s "${root.selectedSerial}" --window-title="${root.deviceName}" --window-height=820 --max-fps=60 --video-bit-rate=12M`
        if (!root.audioEnabled)
            cmd += " --no-audio"
        if (root.keepAwake)
            cmd += " --stay-awake"
        if (!root.windowed && !root.pinned)
            root.open = false
        scrcpyProc.command = ["sh", "-c", cmd]
        scrcpyProc.running = true
    }

    function turnScreenOff(): void {
        if (!root.requireAdbOrGuide("Pantalla apagada")) return
        if (!root.windowed && !root.pinned)
            root.open = false
        scrcpyProc.command = [
            "sh", "-c",
            `command -v scrcpy >/dev/null 2>&1 && exec scrcpy -s "${root.selectedSerial}" --turn-screen-off --stay-awake --window-title="${root.deviceName}" --window-height=820 --max-fps=60 --video-bit-rate=12M`
        ]
        scrcpyProc.running = true
    }

    function takeScreenshot(): void {
        if (!root.requireAdbOrGuide("Captura de pantalla")) return
        Quickshell.execDetached([
            "sh", "-c",
            `dir="\${XDG_PICTURES_DIR:-$HOME/Pictures}"; mkdir -p "$dir"; out="$dir/android-$(date +%Y%m%d-%H%M%S).png"; if adb -s "${root.selectedSerial}" exec-out screencap -p > "$out" && [ -s "$out" ]; then wl-copy < "$out" 2>/dev/null || true; notify-send -a "AndroidConnect" "Captura guardada y copiada" "$out"; else rm -f "$out"; notify-send -a "AndroidConnect" "Error al capturar pantalla" "Verifica la conexión ADB"; fi`
        ])
    }

    function toggleRecording(): void {
        if (!root.requireAdbOrGuide("Grabar pantalla")) return
        if (!root.recording) {
            root.recording = true
            Quickshell.execDetached([
                "sh", "-c",
                `notify-send -a "AndroidConnect" "Grabando pantalla" "Pulsa Detener cuando termines"; adb -s "${root.selectedSerial}" shell screenrecord /sdcard/inir_rec.mp4`
            ])
        } else {
            root.recording = false
            Quickshell.execDetached([
                "sh", "-c",
                `adb -s "${root.selectedSerial}" shell pkill -INT screenrecord; sleep 1; dir="\${XDG_VIDEOS_DIR:-$HOME/Videos}"; mkdir -p "$dir"; out="$dir/android-$(date +%Y%m%d-%H%M%S).mp4"; if adb -s "${root.selectedSerial}" pull /sdcard/inir_rec.mp4 "$out" >/dev/null 2>&1; then adb -s "${root.selectedSerial}" shell rm -f /sdcard/inir_rec.mp4; notify-send -a "AndroidConnect" "Grabación guardada" "$out"; fi`
            ])
        }
    }

    function toggleKeepAwake(): void {
        if (!root.requireAdbOrGuide("Mantener activo")) return
        root.keepAwake = !root.keepAwake
        root.runAdb(["shell", "svc", "power", "stayon", root.keepAwake ? "true" : "false"])
        Quickshell.execDetached([
            "notify-send", "-a", "AndroidConnect",
            root.keepAwake ? "Mantener activo: Activado" : "Mantener activo: Desactivado",
            root.deviceName
        ])
    }

    function findPhone(): void {
        Quickshell.execDetached([
            "sh", "-c",
            `id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); if [ -n "$id" ]; then kdeconnect-cli -d "$id" --ring; notify-send -a "AndroidConnect" "Haciendo sonar teléfono" "${root.deviceName}"; elif [ -n "${root.selectedSerial}" ]; then adb -s "${root.selectedSerial}" shell cmd notification post -S bigtext -t "AndroidConnect" "ring" "¡Aquí está tu teléfono!" >/dev/null 2>&1; fi`
        ])
    }

    function browseFiles(): void {
        if (!root.windowed && !root.pinned)
            root.open = false
        Quickshell.execDetached([
            "sh", "-c",
            `id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); if [ -n "$id" ]; then qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/sftp" org.kde.kdeconnect.device.sftp.mountAndWait >/dev/null 2>&1 || kdeconnect-cli -d "$id" --mount >/dev/null 2>&1; mp="/run/user/$(id -u)/$id/storage/emulated/0"; [ ! -d "$mp" ] && mp="/run/user/$(id -u)/$id"; if [ -d "$mp" ]; then exec xdg-open "$mp"; else notify-send -a "AndroidConnect" "No se pudo montar el almacenamiento" "Activa el permiso de Archivos en la app KDE Connect de tu teléfono"; fi; else notify-send -a "AndroidConnect" "Sin conexión KDE Connect" "Vincula tu teléfono con KDE Connect para explorar sus carpetas"; fi`
        ])
    }

    function shareFile(): void {
        root.toggleSheet("share")
    }

    function shareFileDialog(): void {
        if (!root.windowed && !root.pinned)
            root.open = false
        Quickshell.execDetached([
            "sh", "-c",
            `files=$(kdialog --title "Enviar archivo a ${root.deviceName}" --multiple --separate-output --getopenfilename "$HOME" 2>/dev/null); [ -z "$files" ] && exit 0; id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); serial="${root.selectedSerial}"; count=0; IFS='
'; for f in $files; do [ -e "$f" ] || continue; if [ -n "$id" ]; then kdeconnect-cli -d "$id" --share "$f"; count=$((count + 1)); elif [ -n "$serial" ]; then adb -s "$serial" push "$f" /sdcard/Download/ >/dev/null 2>&1 && count=$((count + 1)); fi; done; if [ "$count" -gt 0 ]; then notify-send -a "AndroidConnect" "Archivo enviado" "Se enviaron $count archivo(s) a ${root.deviceName}"; else notify-send -a "AndroidConnect" "Error al enviar" "No hay dispositivo conectado"; fi`
        ])
    }

    function sendFilePath(filePath: string): void {
        if (filePath.length === 0) return
        Quickshell.execDetached([
            "sh", "-c",
            `f="$1"; id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); serial="${root.selectedSerial}"; if [ -n "$id" ]; then kdeconnect-cli -d "$id" --share "$f" && notify-send -a "AndroidConnect" "Archivo enviado" "$(basename "$f") enviado a ${root.deviceName}"; elif [ -n "$serial" ]; then adb -s "$serial" push "$f" /sdcard/Download/ >/dev/null 2>&1 && notify-send -a "AndroidConnect" "Archivo enviado por ADB" "$(basename "$f") guardado en /sdcard/Download/"; else notify-send -a "AndroidConnect" "Sin conexión" "Conecta tu teléfono primero"; fi`,
            "sh", filePath
        ])
    }

    function sendTextOrPath(val: string): void {
        if (val.length === 0) return
        Quickshell.execDetached([
            "sh", "-c",
            `v="$1"; id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); serial="${root.selectedSerial}"; if [ -e "$v" ]; then if [ -n "$id" ]; then kdeconnect-cli -d "$id" --share "$v" && notify-send -a "AndroidConnect" "Archivo enviado" "$(basename "$v") enviado a ${root.deviceName}"; elif [ -n "$serial" ]; then adb -s "$serial" push "$v" /sdcard/Download/ >/dev/null 2>&1 && notify-send -a "AndroidConnect" "Archivo enviado" "$(basename "$v") en /sdcard/Download/"; fi; else if [ -n "$id" ]; then kdeconnect-cli -d "$id" --share-text "$v" && notify-send -a "AndroidConnect" "Texto/URL enviado" "Enviado a ${root.deviceName}"; elif [ -n "$serial" ]; then escaped=$(printf '%s' "$v" | sed 's/ /%s/g'); adb -s "$serial" shell input text "$escaped" >/dev/null 2>&1 && notify-send -a "AndroidConnect" "Texto enviado por ADB" "${root.deviceName}"; fi; fi`,
            "sh", val
        ])
    }

    function pingDevice(customMsg: string): void {
        const msg = (customMsg && customMsg.length > 0) ? customMsg : "¡Hola desde AndroidConnect!"
        Quickshell.execDetached([
            "sh", "-c",
            `id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1);
            if [ -n "$id" ]; then
                kdeconnect-cli -d "$id" --ping-msg "$1"
                notify-send -a "AndroidConnect" "Notificación enviada al teléfono" "$1"
            elif [ -n "${root.selectedSerial}" ]; then
                adb -s "${root.selectedSerial}" shell cmd notification post -S bigtext -t "AndroidConnect" "ping" "$1" >/dev/null 2>&1
                notify-send -a "AndroidConnect" "Notificación enviada por ADB" "$1"
            else
                notify-send -a "AndroidConnect" "Sin conexión" "Conecta tu teléfono primero"
            fi`,
            "sh", msg
        ])
    }

    function dismissNotification(publicId: string): void {
        if (!publicId || publicId.length === 0) return
        Quickshell.execDetached([
            "sh", "-c",
            `id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1);
            if [ -n "$id" ]; then
                qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/notifications/$1" org.kde.kdeconnect.device.notifications.notification.dismiss >/dev/null 2>&1
            fi`,
            "sh", publicId
        ])
        Qt.callLater(root.refresh)
    }

    function sendClipboard(): void {
        Quickshell.execDetached([
            "sh", "-c",
            `clip=$(wl-paste -n 2>/dev/null); if [ -z "$clip" ]; then notify-send -a "AndroidConnect" "Portapapeles vacío" "Copia un texto o enlace primero"; exit 0; fi; id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); if [ -n "$id" ]; then kdeconnect-cli -d "$id" --send-clipboard >/dev/null 2>&1; kdeconnect-cli -d "$id" --share-text "$clip" >/dev/null 2>&1; notify-send -a "AndroidConnect" "Portapapeles enviado" "Texto enviado a ${root.deviceName}"; elif [ -n "${root.selectedSerial}" ]; then escaped=$(printf '%s' "$clip" | sed 's/ /%s/g'); adb -s "${root.selectedSerial}" shell input text "$escaped" >/dev/null 2>&1; notify-send -a "AndroidConnect" "Texto enviado por ADB" "${root.deviceName}"; else notify-send -a "AndroidConnect" "Sin conexión" "Conecta tu teléfono primero"; fi`
        ])
    }

    function mediaAction(cmd: string): void {
        if (cmd === "playpause") root.mediaPlaying = !root.mediaPlaying
        Quickshell.execDetached([
            "sh", "-c",
            `cmd="$1"; id="${root.selectedKdeId}"; [ -z "$id" ] && id=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1); serial="${root.selectedSerial}";
            if [ -n "$id" ]; then
                case "$cmd" in
                    playpause) qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.kde.kdeconnect.device.mprisremote.sendAction "PlayPause" >/dev/null 2>&1 ;;
                    next) qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.kde.kdeconnect.device.mprisremote.sendAction "Next" >/dev/null 2>&1 ;;
                    prev) qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.kde.kdeconnect.device.mprisremote.sendAction "Previous" >/dev/null 2>&1 ;;
                    volup) cur=$(qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.kde.kdeconnect.device.mprisremote.volume 2>/dev/null || echo 50); nxt=$((cur + 10)); [ "$nxt" -gt 100 ] && nxt=100; qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.freedesktop.DBus.Properties.Set org.kde.kdeconnect.device.mprisremote volume "$nxt" >/dev/null 2>&1 ;;
                    voldown) cur=$(qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.kde.kdeconnect.device.mprisremote.volume 2>/dev/null || echo 50); nxt=$((cur - 10)); [ "$nxt" -lt 0 ] && nxt=0; qdbus6 org.kde.kdeconnect "/modules/kdeconnect/devices/$id/mprisremote" org.freedesktop.DBus.Properties.Set org.kde.kdeconnect.device.mprisremote volume "$nxt" >/dev/null 2>&1 ;;
                esac
            fi
            if [ -n "$serial" ]; then
                case "$cmd" in
                    playpause) [ -z "$id" ] && adb -s "$serial" shell input keyevent KEYCODE_MEDIA_PLAY_PAUSE >/dev/null 2>&1 ;;
                    next) [ -z "$id" ] && adb -s "$serial" shell input keyevent KEYCODE_MEDIA_NEXT >/dev/null 2>&1 ;;
                    prev) [ -z "$id" ] && adb -s "$serial" shell input keyevent KEYCODE_MEDIA_PREVIOUS >/dev/null 2>&1 ;;
                    volup) adb -s "$serial" shell input keyevent KEYCODE_VOLUME_UP >/dev/null 2>&1 ;;
                    voldown) adb -s "$serial" shell input keyevent KEYCODE_VOLUME_DOWN >/dev/null 2>&1 ;;
                esac
            fi`,
            "sh", cmd
        ])
        Qt.callLater(root.refresh)
    }

    function startQrPairing(): void {
        qrProc.running = false
        root.qrStatus = "starting"
        root.qrMessage = "Generando código QR..."
        qrProc.running = true
    }

    function stopQrPairing(): void {
        qrProc.running = false
        root.qrStatus = "idle"
        root.qrMessage = ""
    }

    function pairAndConnect(ip: string, pairPort: string, code: string, connectPort: string): void {
        if (ip.length === 0 || pairPort.length === 0 || code.length === 0) {
            root.statusMessage = "Faltan datos de vinculación (IP, puerto o código)"
            return
        }
        const cPort = connectPort.length > 0 ? connectPort : pairPort
        root.statusMessage = `Vinculando con ${ip}:${pairPort}...`
        actionProc.command = [
            "sh", "-c",
            `out=$(adb pair "${ip}:${pairPort}" "${code}" 2>&1); echo "$out"; if echo "$out" | grep -qi "success"; then echo "Conectando a ${ip}:${cPort}..."; adb connect "${ip}:${cPort}"; fi`
        ]
        actionProc.running = true
    }

    function enableUsbTcpip(): void {
        root.statusMessage = "Cambiando ADB de USB a Wi-Fi (puerto 5555)..."
        const ip = root.deviceIp.length > 0 ? root.deviceIp : ""
        actionProc.command = [
            "sh", "-c",
            `adb tcpip 5555 2>&1; sleep 1; if [ -n "${ip}" ]; then adb connect "${ip}:5555" 2>&1; fi`
        ]
        actionProc.running = true
    }

    function pairWireless(hostPort: string, code: string): void {
        if (hostPort.length === 0 || code.length === 0) return
        root.statusMessage = "Vinculando con " + hostPort + "..."
        actionProc.command = ["adb", "pair", hostPort, code]
        actionProc.running = true
    }

    function connectWireless(hostPort: string): void {
        if (hostPort.length === 0) return
        root.statusMessage = "Conectando a " + hostPort + "..."
        actionProc.command = ["sh", "-c", "adb connect \"" + hostPort + "\" 2>&1"]
        actionProc.running = true
    }
}
