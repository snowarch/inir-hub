.pragma library

// What each kind of notice says when Settings asks to see one: the Island and Settings' preview show the same.
// `tr` is the Translation service and `style` IrisStyle (a library sees no QML context); `picture` is the screen's
// own wallpaper, standing in for a screenshot.
function of(kind, tr, style, nothingLook, picture) {
    const soon = new Date(Date.now() + 3600000)
    const samples = {
        accessory: ["headphones", style.identity.blue, tr.tr("Headset"), tr.tr("Connected"), 0.8, "accessory"],
        battery: ["battery_alert", style.danger, tr.tr("Low battery"), tr.tr("Plug in soon"), 0.12, ""],
        charge: ["battery_charging_full", style.success, tr.tr("Charging"), tr.tr("Full in %1").arg(tr.tr("%1 min").arg(40)), 0.64, "charge"],
        focus: ["do_not_disturb_on", style.identity.indigo, tr.tr("Do not disturb"), tr.tr("On"), -1, "status"],
        silent: ["notifications_off", style.danger, tr.tr("Silent"), "", -1, "silent"],
        unlock: ["face", style.identity.green, tr.tr("Unlocked"), "", -1, "unlock"],
        upcoming: ["event", style.danger, tr.tr("Calendar"), tr.tr("In %1 min").arg(5), 0.5, "soon"],
        rain: ["rainy", style.identity.sky, tr.tr("Rain soon"), tr.tr("Around %1").arg(Qt.formatTime(soon, "HH:00")), -1, ""],
        timers: ["alarm", style.identity.orange, tr.tr("Time's up"), tr.tr("%1 timer").arg(tr.tr("%1 min").arg(10)), -1, ""],
        recording: ["stop_circle", style.danger, tr.tr("Recording saved"), "1:23", -1, ""],
        shelf: ["check", style.accent, tr.tr("On the Shelf"), tr.tr("%1 files").arg(3), 1, "kept"],
        jobs: ["check", nothingLook ? style.text : style.success, tr.tr("Download"), tr.tr("Done"), 1, "done"],
        screenshot: ["screenshot_region", style.identity.blue, tr.tr("Screenshot saved"),
            Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png", -1, "shot"],
        gameMode: ["sports_esports", style.identity.green, tr.tr("Game mode on"), tr.tr("Effects and notifications held back"), -1, ""],
        niri: ["error", style.danger, tr.tr("Niri config has an error"), tr.tr("The previous config is still in use"), -1, ""],
        soundGuard: ["volume_off", style.danger, tr.tr("Volume held back"), tr.tr("It rose more than %1% at once").arg(10), -1, ""]
    }
    const s = samples[kind] ?? samples.accessory
    return { icon: s[0], tint: s[1], title: s[2], detail: s[3], value: s[4], kind: s[5], failed: false,
        image: s[5] === "shot" ? String(picture ?? "") : "" }
}
