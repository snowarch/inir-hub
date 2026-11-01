pragma Singleton
import QtQuick
import Quickshell
import qs.modules.iris.style

// Every section a side panel can carry: what the panel builds, its editor lists and the Settings stage draws.
Singleton {
    // Getters: a list that feeds Settings holds no live colour.
    readonly property var catalog: [
        { id: "media", label: "Now playing", icon: "music_note", get tint() { return IrisStyle.identity.pink } },
        { id: "tasks", label: "Tasks", icon: "check_circle", get tint() { return IrisStyle.identity.green } },
        { id: "notes", label: "Notes", icon: "edit_note", get tint() { return IrisStyle.identity.yellow } },
        { id: "calendar", label: "Calendar", icon: "calendar_month", get tint() { return IrisStyle.identity.red } },
        { id: "weather", label: "Weather", icon: "partly_cloudy_day", get tint() { return IrisStyle.identity.sky } },
        { id: "notifications", label: "Notifications", icon: "notifications", get tint() { return IrisStyle.identity.orange } },
        { id: "focus", label: "Focus timer", icon: "timer", get tint() { return IrisStyle.identity.indigo } },
        { id: "mixer", label: "Sound mixer", icon: "graphic_eq", get tint() { return IrisStyle.identity.purple } },
        { id: "system", label: "System", icon: "monitor_heart", get tint() { return IrisStyle.identity.teal } }
    ]
}
