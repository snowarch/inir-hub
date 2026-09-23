pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.background.widgets
import qs.modules.background.widgets.clock
import qs.modules.background.widgets.mediaControls
import qs.modules.background.widgets.weather
import qs.modules.background.widgets.systemMonitor
import qs.modules.background.widgets.battery
import qs.modules.background.widgets.notes
import qs.modules.background.widgets.calendar
import qs.modules.background.widgets.todo
import qs.modules.background.widgets.timers
import qs.modules.background.widgets.dateBadge
import qs.modules.background.widgets.uptime
import qs.modules.background.widgets.controls
import qs.modules.background.widgets.screenTime
import qs.modules.background.widgets.dayProgress
import qs.modules.background.widgets.worldClock
import qs.modules.background.widgets.userCard
import qs.modules.background.widgets.newsTicker
import qs.modules.iris.widgets

Item {
    id: root

    property string screenName: ""
    readonly property string scope: DesktopWidgetLayout.lockScope(root.screenName)
    readonly property var shown: {
        Config.revision
        if (root.screenName.length === 0) return []
        return IrisFaceData.galleryEntries.map(entry => entry.key)
            .filter(key => DesktopWidgetLayout.enabled(root.scope, key, false))
    }

    Repeater {
        model: IrisFaceData.galleryEntries.map(entry => entry.key)
        delegate: Loader {
            id: slot
            required property string modelData
            active: root.shown.includes(slot.modelData)
            sourceComponent: ({
                clock: clockWidget, weather: weatherWidget, mediaControls: mediaWidget, controls: controlsWidget,
                monthCalendar: monthWidget, calendarUpcoming: upcomingWidget, todo: todoWidget, notes: notesWidget,
                timers: timersWidget, screenTime: screenTimeWidget, systemMonitor: vitalsWidget, battery: batteryWidget,
                worldClock: worldClockWidget, dayProgress: dayWidget, dateBadge: dateWidget, userCard: profileWidget,
                uptime: uptimeWidget, newsTicker: newsWidget
            })[slot.modelData] ?? null
        }
    }

    Component { id: clockWidget; ClockWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: weatherWidget; WeatherWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: mediaWidget; MediaControlsWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: controlsWidget; ControlsWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: monthWidget; MonthCalendarWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: upcomingWidget; CalendarUpcomingWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: todoWidget; TodoWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: notesWidget; NotesWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: timersWidget; TimerWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: screenTimeWidget; ScreenTimeWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: vitalsWidget; SystemMonitorWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: batteryWidget; BatteryWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: worldClockWidget; WorldClockWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: dayWidget; DayProgressWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: dateWidget; DateBadgeWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: profileWidget; UserCardWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: uptimeWidget; UptimeWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
    Component { id: newsWidget; NewsTickerWidget { visibleWhenLocked: true; outputName: root.scope; screenWidth: root.width; screenHeight: root.height; scaledScreenWidth: root.width; scaledScreenHeight: root.height; wallpaperScale: 1 } }
}
