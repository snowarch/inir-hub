.pragma library

// Storage's reading: `df` for every mounted drive and `lsblk` for the names their owners gave them, turned into one
// line per drive (a btrfs subvolume mounted five times is one drive), the system first, then the biggest.

const skipTypes = ["tmpfs", "devtmpfs", "efivarfs", "squashfs", "overlay", "ramfs", "proc", "sysfs", "fuse.portal", "autofs"]
const skipMounts = /^\/(boot|efi|snap|var\/lib\/snapd|run\/credentials|var\/lib\/docker|nix\/store)(\/|$)/
const uuidLike = /^[0-9a-f]{8}-[0-9a-f]{4}-|^[0-9A-F]{4}-[0-9A-F]{4}$|^[0-9a-f]{16,}$/i

function unescape(text) {
    return String(text).replace(/\\x([0-9a-fA-F]{2})/g, (m, hex) => String.fromCharCode(parseInt(hex, 16)))
}

// "PATH LABEL" lines from `lsblk -rno PATH,LABEL` -> { "/dev/sda2": "Games" }
function labelsOf(text) {
    const labels = {}
    for (const line of String(text).split("\n")) {
        const at = line.indexOf(" ")
        if (at <= 0) continue
        const label = unescape(line.slice(at + 1)).trim()
        if (label.length > 0) labels[line.slice(0, at)] = label
    }
    return labels
}

function baseName(path) {
    const parts = String(path).split("/").filter(part => part.length > 0)
    return parts.length > 0 ? parts[parts.length - 1] : ""
}

// `df -B1 --output=source,fstype,size,used,avail,target` (header first) -> drives, deduplicated by device.
function drivesOf(text, labels) {
    const byDevice = {}
    const lines = String(text).split("\n").slice(1)
    for (const line of lines) {
        const cols = line.trim().split(/\s+/)
        if (cols.length < 6) continue
        const [source, type, sizeText, usedText, freeText] = cols
        const mount = cols.slice(5).join(" ")
        const size = Number(sizeText), used = Number(usedText), free = Number(freeText)
        if (!source.startsWith("/dev/") || source.startsWith("/dev/loop")) continue
        if (skipTypes.indexOf(type) >= 0 || skipMounts.test(mount)) continue
        if (!(size >= 1e9)) continue
        const known = byDevice[source]
        // The shortest mount names the drive: "/" over "/home" over "/var/log".
        if (known && known.mount.length <= mount.length) continue
        byDevice[source] = { device: source, mount: mount, size: size, used: used, free: free }
    }
    const drives = Object.values(byDevice).map(drive => {
        const label = labels[drive.device] ?? ""
        const tail = baseName(drive.mount)
        // Taken = what the drive holds over what it can hold (reserved blocks count as taken, as file managers show).
        const taken = drive.size > 0 ? Math.min(1, Math.max(0, 1 - drive.free / drive.size)) : 0
        return {
            device: drive.device,
            mount: drive.mount,
            system: drive.mount === "/",
            home: drive.mount === "/home",
            // The system and home drives without a label of their own are named by the face, in the person's language.
            label: label.length > 0 ? label : drive.mount === "/" || drive.mount === "/home" ? ""
                : tail.length > 0 && !uuidLike.test(tail) ? tail : baseName(drive.device),
            size: drive.size,
            free: drive.free,
            used: Math.max(0, drive.size - drive.free),
            taken: taken
        }
    })
    drives.sort((a, b) => (b.system - a.system) || (b.home - a.home) || (b.size - a.size))
    return drives
}

// Bytes as a person reads them (powers of 1000, like the drive's own box): "842 MB", "4.2 GB", "15 GB", "1.8 TB".
function sizeOf(bytes) {
    const units = ["B", "KB", "MB", "GB", "TB", "PB"]
    let value = Math.max(0, Number(bytes) || 0)
    let unit = 0
    while (value >= 1000 && unit < units.length - 1) {
        value /= 1000
        unit += 1
    }
    const shown = value < 10 && unit > 0 ? value.toFixed(1) : String(Math.round(value))
    return { value: shown, unit: units[unit], text: shown + " " + units[unit] }
}

// A short key that moves only when a figure a face shows would change (a drive's free space to 0.1 %).
function keyOf(drives) {
    return drives.map(drive => drive.device + ":" + Math.round(drive.taken * 1000) + ":" + drive.label).join("|")
}
