pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.pieces

IrisWidgetFace {
    id: root
    readonly property bool ribbonStyle: String(root.widget.familyOption("face", "curve")) === "ribbon"
    designFace: root.ribbonStyle ? "" : IrisDesign.skin("widgetScreenTime")

    property int revision: 0
    readonly property bool on: ScreenTime.enabled
    readonly property var today: { void root.revision; return ScreenTime.getToday() }
    readonly property int total: Number(root.today?.totalSeconds ?? 0)
    readonly property var hourly: Array.from(root.today?.hourly ?? []).concat(new Array(24).fill(0)).slice(0, 24)
    readonly property real hourPeak: Math.max(900, ...root.hourly)
    readonly property int hourNow: { void root.revision; return new Date().getHours() }
    readonly property var apps: { void root.revision; return root.on ? ScreenTime.getAppList(1) : [] }
    readonly property int appCount: root.large ? 5 : root.medium ? 2 : 1
    readonly property var topApps: root.apps.slice(0, root.appCount)
    readonly property color tint: root.inked(IrisStyle.identity.indigo)
    // Under a minute counted: the day has not started, and "0m" over a row of empty stubs said nothing.
    readonly property bool idle: root.total < 60

    function duration(seconds: int): string {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor(seconds % 3600 / 60)
        return hours > 0 ? Translation.tr("%1 h %2 min").arg(hours).arg(minutes) : Translation.tr("%1 min").arg(minutes)
    }
    function shortDuration(seconds: int): string {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor(seconds % 3600 / 60)
        return hours > 0 ? hours + Translation.tr("h") + " " + minutes + Translation.tr("m") : minutes + Translation.tr("m")
    }

    // Ticks only while seen; uncovered, it catches up with what was counted behind the windows.
    Connections {
        target: ScreenTime
        enabled: root.moving
        function onDataChanged(): void { root.revision++ }
    }
    onMovingChanged: if (root.moving) root.revision++

    component AppIcon: SmartAppIcon {
        required property var app
        implicitSize: root.dp(root.small ? 22 : 20)
        icon: IrisPieces.appIcon(String(app?.originalId ?? app?.id ?? ""))
    }

    // The day's use drawn as the Day draws the sun: a smooth line through the hours with the fade under it, up to now,
    // the hours under it (a bar per hour read as a row of stubs).
    readonly property real nowAt: { void root.revision; const now = new Date(); return (now.getHours() * 60 + now.getMinutes()) / 1440 }
    readonly property var useLevels: root.hourly.map(seconds => seconds / root.hourPeak)
    component HourBars: ColumnLayout {
        id: bars
        property real barHeight: root.dp(56)
        spacing: root.dp(2)
        FaceArea {
            face: root
            Layout.fillWidth: true
            Layout.preferredHeight: bars.barHeight
            tint: root.tint
            to: root.nowAt
            curve: t => IrisFaceData.smooth(root.useLevels, t)
        }
        FaceHours { face: root; Layout.fillWidth: true }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: !root.on
        spacing: root.dp(8)

        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "hourglass_bottom"
            text: Translation.tr("Screen Time")
            tint: root.tint
        }
        Item { Layout.fillHeight: true }
        FaceText {
            face: root
            Layout.fillWidth: true
            text: IrisFaceData.unwidowed(Translation.tr("See where your day goes"))
            size: root.small ? 13 : 14
            weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        FaceChoice {
            icon: "toggle_on"
            label: Translation.tr("Turn on")
            onClicked: Config.setNestedValue("screenTime.enable", true)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: root.on && root.idle
        spacing: root.dp(8)

        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "hourglass_bottom"
            text: Translation.tr("Screen Time")
            trailing: root.small ? "" : Translation.tr("Today")
            tint: root.tint
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            FaceBlank {
                face: root
                // Large has room to lose it in: there it waits right under its head, where the first row would be.
                y: root.large ? root.dp(24) : Math.round((parent.height - height) / 2)
                width: parent.width
                glyph: "hourglass_empty"
                tint: root.tint
                title: Translation.tr("Nothing yet today")
                detail: Translation.tr("Your hours show up here as you use the computer")
            }
        }
    }

    // Ribbon: the day as one strip of 24 hours, each hour the colour of the app that held it, an unbroken run where one
    // app held on. It shows what the curve can't: which part of the day went where.
    readonly property var ribbonTints: [root.inked(IrisStyle.identity.indigo), root.inked(IrisStyle.identity.orange),
        root.inked(IrisStyle.identity.pink), root.inked(IrisStyle.identity.teal)]
    function ribbonTint(rank: int): color {
        return rank < root.ribbonTints.length ? root.ribbonTints[rank] : root.inkTertiary
    }
    readonly property var ribbonRuns: {
        if (!root.ribbonStyle)
            return []
        const data = root.today?.apps ?? {}
        const keys = root.apps.map(app => app.id)
        const runs = []
        for (let hour = 0; hour < 24; ++hour) {
            let rank = -1, most = 0
            for (let i = 0; i < keys.length; ++i) {
                const seconds = Number(data[keys[i]]?.hourly?.[hour] ?? 0)
                if (seconds > most) { most = seconds; rank = i }
            }
            if (rank < 0)
                continue
            rank = Math.min(rank, root.ribbonTints.length)
            const share = Math.min(1, Number(root.hourly[hour]) / 3600)
            const last = runs[runs.length - 1]
            if (last && last.rank === rank && last.to === hour) {
                last.to = hour + 1
                last.used += share
            } else {
                runs.push({ rank: rank, from: hour, to: hour + 1, used: share })
            }
        }
        return runs
    }

    Loader {
        anchors.fill: parent
        active: root.on && !root.idle && root.ribbonStyle
        sourceComponent: Component { RibbonView {} }
    }

    component RibbonView: ColumnLayout {
        spacing: root.dp(root.large ? 12 : 8)
        RowLayout {
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(10)
            FaceFigure {
                face: root
                Layout.alignment: Qt.AlignBaseline
                text: root.shortDuration(root.total)
                size: root.small ? 30 : root.large ? 52 : 38
            }
            FaceText {
                face: root
                visible: !root.small && ScreenTime.currentAppName.length > 0
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
                horizontalAlignment: Text.AlignRight
                text: Translation.tr("Now: %1").arg(ScreenTime.currentAppName)
                color: root.inkTertiary
                size: 12
            }
        }
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: root.dp(3)
            Item {
                id: ribbon
                Layout.fillWidth: true
                Layout.fillHeight: true
                Rectangle {
                    anchors.fill: parent
                    radius: root.dp(6)
                    color: root.fillQuiet
                }
                Repeater {
                    model: root.ribbonRuns
                    Rectangle {
                        required property var modelData
                        x: Math.round(ribbon.width * modelData.from / 24)
                        width: Math.round(ribbon.width * modelData.to / 24) - x - Math.max(1, root.dp(1))
                        height: ribbon.height
                        radius: root.dp(4)
                        color: root.ribbonTint(modelData.rank)
                        // An hour barely touched stays a shade of its app, not a full block.
                        opacity: 0.4 + 0.6 * modelData.used / (modelData.to - modelData.from)
                    }
                }
                // Now: what lies past it has not happened.
                Rectangle {
                    x: Math.round(ribbon.width * root.nowAt)
                    y: -root.dp(2)
                    width: Math.max(1, root.dp(1.5))
                    height: ribbon.height + root.dp(4)
                    color: root.ink
                }
            }
            FaceHours { face: root; visible: !root.small; Layout.fillWidth: true }
        }
        Repeater {
            model: root.small ? root.topApps.slice(0, 1) : []
            AppKey {
                required property var modelData
                required property int index
                app: modelData
                rank: index
            }
        }
        Flow {
            visible: root.medium
            Layout.fillWidth: true
            spacing: root.dp(12)
            Repeater {
                model: root.medium ? root.apps.slice(0, 3) : []
                AppKey {
                    required property var modelData
                    required property int index
                    app: modelData
                    rank: index
                }
            }
        }
        Column {
            visible: root.large
            Layout.fillHeight: false
            Layout.fillWidth: true
            spacing: root.dp(9)
            Repeater {
                model: root.large ? root.topApps : []
                RowLayout {
                    id: appRow
                    required property var modelData
                    required property int index
                    width: parent.width
                    spacing: root.dp(8)
                    AppIcon { app: appRow.modelData }
                    AppKey { app: appRow.modelData; rank: appRow.index; Layout.fillWidth: true }
                    FaceText {
                        face: root
                        text: root.shortDuration(appRow.modelData.seconds)
                        color: root.inkSecondary
                        size: 12.5
                        font.family: root.fontNumbers
                    }
                }
            }
        }
    }

    // An app's colour on the ribbon, beside its name.
    component AppKey: Row {
        id: key
        required property var app
        required property int rank
        spacing: root.dp(6)
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: root.dp(9)
            height: width
            radius: root.dp(3)
            color: root.ribbonTint(key.rank)
        }
        FaceText {
            face: root
            text: key.app?.name ?? ""
            color: root.inkSecondary
            size: 12.5
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: root.on && !root.idle && !root.ribbonStyle
        spacing: root.dp(root.small ? 2 : 6)

        FaceHeader {
            face: root
            Layout.fillWidth: true
            glyph: "hourglass_bottom"
            text: Translation.tr("Screen Time")
            trailing: root.small ? "" : Translation.tr("Today")
            tint: root.tint
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.dp(16)

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: root.small
                // As wide as today's total, so "13h 46m" is never cut; the bars take the rest.
                Layout.preferredWidth: root.medium ? Math.max(root.dp(96), totalFigure.implicitWidth) : -1
                visible: !root.large
                spacing: root.dp(2)

                Item { Layout.fillHeight: true }
                FaceFigure {
                    id: totalFigure
                    face: root
                    Layout.fillWidth: true
                    text: root.shortDuration(root.total)
                    size: root.small ? 32 : 30
                    elide: Text.ElideRight
                }
                RowLayout {
                    Layout.fillHeight: false
                    visible: root.small && root.topApps.length > 0
                    Layout.fillWidth: true
                    spacing: root.dp(6)
                    AppIcon { app: root.topApps[0] ?? null }
                    FaceText {
                        face: root
                        Layout.fillWidth: true
                        text: root.topApps[0]?.name ?? ""
                        color: root.inkSecondary
                        size: 12
                    }
                }
                FaceText {
                    face: root
                    visible: root.medium && ScreenTime.currentAppName.length > 0
                    Layout.fillWidth: true
                    text: Translation.tr("Now: %1").arg(ScreenTime.currentAppName)
                    color: root.inkTertiary
                    size: 11.5
                }
            }

            ColumnLayout {
                visible: root.medium
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.dp(10)

                Item { Layout.fillHeight: true }
                HourBars {
                    Layout.fillHeight: false
                    Layout.fillWidth: true
                    barHeight: root.dp(40)
                }
                RowLayout {
                    Layout.fillHeight: false
                    Layout.fillWidth: true
                    spacing: root.dp(10)
                    Repeater {
                        model: root.topApps
                        RowLayout {
                            id: chip
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: root.dp(4)
                            AppIcon { app: chip.modelData }
                            FaceText {
                                face: root
                                Layout.fillWidth: true
                                text: root.shortDuration(chip.modelData.seconds)
                                color: root.inkSecondary
                                font.family: root.fontNumbers
                                font.features: ({ "tnum": 1 })
                                size: 11.5
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.large
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.dp(8)

                RowLayout {
                    Layout.fillHeight: false
                    Layout.fillWidth: true
                    FaceFigure {
                        face: root
                        text: root.duration(root.total)
                        size: 34
                    }
                    Item { Layout.fillWidth: true }
                }
                HourBars {
                    Layout.fillHeight: false
                    Layout.fillWidth: true
                    barHeight: root.dp(64)
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: root.dp(4)
                    implicitHeight: 1
                    color: root.hairline
                }
                Repeater {
                    model: root.topApps
                    RowLayout {
                        id: appRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        spacing: root.dp(10)
                        AppIcon { app: appRow.modelData; implicitSize: root.dp(22) }
                        ColumnLayout {
                            Layout.fillHeight: false
                            Layout.fillWidth: true
                            spacing: root.dp(3)
                            RowLayout {
                                Layout.fillHeight: false
                                Layout.fillWidth: true
                                FaceText {
                                    face: root
                                    Layout.fillWidth: true
                                    text: appRow.modelData.name
                                    size: 12.5
                                    weight: Font.DemiBold
                                }
                                FaceText {
                                    face: root
                                    text: root.shortDuration(appRow.modelData.seconds)
                                    color: root.inkSecondary
                                    font.family: root.fontNumbers
                                    font.features: ({ "tnum": 1 })
                                    size: 11.5
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: root.dp(4)
                                radius: IrisStyle.capsule(height)
                                color: root.fill
                                Rectangle {
                                    width: parent.width * Math.min(1, appRow.modelData.seconds / Math.max(1, root.topApps[0]?.seconds ?? 1))
                                    height: parent.height
                                    radius: IrisStyle.capsule(height)
                                    color: root.accent
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
