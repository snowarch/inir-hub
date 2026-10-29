pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

// The head of Settings' first page (Home): what people change most, each one look away. The wallpaper as it is now, the
// mode, the colour it makes and the style that wears it, side by side as one segmented card; then the four switches
// of every day. Everything else is a tab below or a page in the list.
ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 24

    readonly property int outer: Math.round(28 * Appearance.rounding.scale)
    readonly property int inner: SettingsMaterialPreset.tileInnerRadius
    readonly property bool wide: root.width >= 640

    // pictures from the web, for people whose policy asks for them (policies.weeb)
    Process {
        id: webWall
        property string script: ""
        command: ["/usr/bin/bash", "-c", FileUtils.trimFileProtocol(webWall.script)]
    }

    // ── Wallpaper | mode, colour, style ──
    GridLayout {
        Layout.fillWidth: true
        columns: root.wide ? 2 : 1
        columnSpacing: SettingsMaterialPreset.tileGap
        rowSpacing: SettingsMaterialPreset.tileGap

        Item {
            id: wallTile
            Layout.fillWidth: !root.wide
            Layout.preferredWidth: root.wide ? Math.round(root.width * 0.42) : -1
            Layout.fillHeight: root.wide
            Layout.preferredHeight: root.wide ? -1 : Math.round(root.width * 9 / 16)
            Layout.minimumHeight: 220

            Rectangle {
                id: wallMask
                anchors.fill: parent
                visible: false
                topLeftRadius: root.outer
                bottomLeftRadius: root.wide ? root.outer : root.inner
                topRightRadius: root.wide ? root.inner : root.outer
                bottomRightRadius: root.inner
            }
            Rectangle {
                anchors.fill: parent
                color: SettingsMaterialPreset.tileColor
                topLeftRadius: wallMask.topLeftRadius
                bottomLeftRadius: wallMask.bottomLeftRadius
                topRightRadius: wallMask.topRightRadius
                bottomRightRadius: wallMask.bottomRightRadius
            }
            StyledImage {
                id: wallImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: Wallpapers.effectiveWallpaperUrl
                sourceSize.width: 900
                cache: false
                asynchronous: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: wallMask
                }
            }
            // the buttons sit on the picture: a soft fade under them keeps them readable on any wallpaper
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 88
                bottomLeftRadius: wallMask.bottomLeftRadius
                bottomRightRadius: wallMask.bottomRightRadius
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: ColorUtils.transparentize("#000000", 0.55) }
                }
            }
            RowLayout {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 16
                spacing: 8
                RippleButton {
                    implicitHeight: 40
                    implicitWidth: changeRow.implicitWidth + 32
                    buttonRadius: 20
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colOnPrimaryContainer, 0.92)
                    colRipple: ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colOnPrimaryContainer, 0.88)
                    onClicked: Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "wallpaperSelector", "toggle"])
                    contentItem: RowLayout {
                        id: changeRow
                        spacing: 8
                        MaterialSymbol {
                            Layout.leftMargin: 16
                            text: "wallpaper"
                            iconSize: 20
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            Layout.rightMargin: 16
                            text: Translation.tr("Change wallpaper")
                            font.pixelSize: Math.round(14 * Appearance.fontSizeScale)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }
                component PictureAction: RippleButton {
                    id: action
                    property string symbol: ""
                    property string label: ""
                    property string tip: ""
                    implicitHeight: 40
                    implicitWidth: action.label.length > 0 ? actionRow.implicitWidth + 28 : 40
                    buttonRadius: 20
                    colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.15)
                    colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                    contentItem: RowLayout {
                        id: actionRow
                        spacing: 6
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignCenter
                            Layout.leftMargin: action.label.length > 0 ? 14 : 0
                            text: action.symbol
                            iconSize: 20
                            color: Appearance.colors.colOnSurface
                        }
                        StyledText {
                            visible: action.label.length > 0
                            Layout.rightMargin: 14
                            text: action.label
                            font.pixelSize: Math.round(14 * Appearance.fontSizeScale)
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnSurface
                        }
                    }
                    StyledToolTip {
                        text: action.tip
                        extraVisibleCondition: action.tip.length > 0
                    }
                }
                PictureAction {
                    symbol: "shuffle"
                    tip: Translation.tr("Another one from the same folder")
                    onClicked: Wallpapers.randomFromCurrentFolder()
                }
                PictureAction {
                    symbol: "folder_open"
                    tip: Translation.tr("Pick an image file")
                    onClicked: Quickshell.execDetached([Directories.wallpaperSwitchScriptPath])
                }
                PictureAction {
                    visible: (Config.options?.policies?.weeb ?? 0) === 1 && wallTile.width > 520
                    enabled: !webWall.running
                    symbol: "ifl"
                    label: webWall.running ? Translation.tr("...") : Translation.tr("Konachan")
                    tip: Translation.tr("Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers").replace("~/Pictures/Wallpapers", Directories.shortHomePath(Directories.wallpapersPath))
                    onClicked: {
                        webWall.script = `${Directories.scriptsPath}/colors/random/random_konachan_wall.sh`
                        webWall.running = true
                    }
                }
                PictureAction {
                    visible: (Config.options?.policies?.weeb ?? 0) === 1 && wallTile.width > 520
                    enabled: !webWall.running
                    symbol: "ifl"
                    label: webWall.running ? Translation.tr("...") : Translation.tr("osu!")
                    tip: Translation.tr("Random osu! seasonal background\nImage is saved to ~/Pictures/Wallpapers").replace("~/Pictures/Wallpapers", Directories.shortHomePath(Directories.wallpapersPath))
                    onClicked: {
                        webWall.script = `${Directories.scriptsPath}/colors/random/random_osu_wall.sh`
                        webWall.running = true
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: SettingsMaterialPreset.tileGap

            component HeroTile: Rectangle {
                id: heroTile
                property bool first: false
                property bool last: false
                default property alias tileData: tileColumn.data
                Layout.fillWidth: true
                implicitHeight: tileColumn.implicitHeight + 32
                color: SettingsMaterialPreset.tileColor
                topLeftRadius: root.wide ? root.inner : (heroTile.first ? root.inner : root.inner)
                topRightRadius: heroTile.first ? (root.wide ? root.outer : root.inner) : root.inner
                bottomLeftRadius: heroTile.last && !root.wide ? root.outer : root.inner
                bottomRightRadius: heroTile.last ? root.outer : root.inner
                ColumnLayout {
                    id: tileColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 10
                }
            }

            // the three read as one column: a name, then its choices under it, left aligned, never wrapped beside it
            HeroTile {
                first: true
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Mode")
                    font.pixelSize: SettingsMaterialPreset.labelSize
                    color: SettingsMaterialPreset.labelColor
                }
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    enableSettingsSearch: false
                    currentValue: Appearance.m3colors.darkmode ? "dark" : "light"
                    onSelected: value => MaterialThemeLoader.setDarkMode(value === "dark")
                    options: [
                        { displayName: Translation.tr("Light"), icon: "light_mode", value: "light" },
                        { displayName: Translation.tr("Dark"), icon: "dark_mode", value: "dark" }
                    ]
                }
            }

            HeroTile {
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Color")
                    font.pixelSize: SettingsMaterialPreset.labelSize
                    color: SettingsMaterialPreset.labelColor
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: -8
                    text: ThemeService.isAutoTheme ? Translation.tr("Made from your wallpaper") : Translation.tr("From the color theme you picked")
                    font.pixelSize: SettingsMaterialPreset.supportingSize
                    color: SettingsMaterialPreset.supportingColor
                }
                // the scheme's own roles, so each choice is seen before it is read
                RowLayout {
                    spacing: 6
                    Repeater {
                        model: [Appearance.colors.colPrimary, Appearance.colors.colSecondary, Appearance.colors.colTertiary,
                            Appearance.colors.colPrimaryContainer, Appearance.colors.colSecondaryContainer]
                        delegate: Rectangle {
                            required property color modelData
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: 14
                            color: modelData
                            border.width: 1
                            border.color: ColorUtils.transparentize(Appearance.colors.colOnSurface, 0.85)
                        }
                    }
                }
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    enableSettingsSearch: false
                    currentValue: Config.options?.appearance?.palette?.type ?? "auto"
                    onSelected: value => {
                        Config.setNestedValue("appearance.palette.type", value)
                        if (!ThemeService.isAutoTheme)
                            MaterialThemeLoader.applySchemeVariant(MaterialThemeLoader.colorToHex(Appearance.m3colors.m3primary),
                                value, Appearance.m3colors.darkmode ? "dark" : "light")
                    }
                    options: [
                        { displayName: Translation.tr("Auto"), value: "auto" },
                        { displayName: Translation.tr("Tonal"), value: "scheme-tonal-spot" },
                        { displayName: Translation.tr("Vibrant"), value: "scheme-vibrant" },
                        { displayName: Translation.tr("Expressive"), value: "scheme-expressive" },
                        { displayName: Translation.tr("Neutral"), value: "scheme-neutral" },
                        { displayName: Translation.tr("Mono"), value: "scheme-monochrome" }
                    ]
                }
            }

            HeroTile {
                last: true
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Style")
                    font.pixelSize: SettingsMaterialPreset.labelSize
                    color: SettingsMaterialPreset.labelColor
                }
                ConfigSelectionArray {
                    Layout.fillWidth: true
                    enableSettingsSearch: false
                    currentValue: Config.options?.appearance?.globalStyle ?? "material"
                    onSelected: value => ThemeService.setGlobalStyle(value)
                    options: [
                        { displayName: Translation.tr("Material"), value: "material" },
                        { displayName: Translation.tr("Cards"), value: "cards" },
                        { displayName: Translation.tr("Aurora"), value: "aurora" },
                        { displayName: Translation.tr("Inir"), value: "inir" },
                        { displayName: Translation.tr("Angel"), value: "angel" },
                        { displayName: Translation.tr("Regalia"), value: "regalia" },
                        { displayName: Translation.tr("ZZZ"), value: "zzz" },
                        { displayName: Translation.tr("Cookie"), value: "cookie" },
                        { displayName: Translation.tr("Editorial"), value: "editorial" }
                    ]
                }
            }
        }
    }

    // ── Every day ──
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        StyledText {
            Layout.leftMargin: SettingsMaterialPreset.tilePaddingX
            text: Translation.tr("Every day")
            font.pixelSize: SettingsMaterialPreset.subheaderSize
            font.weight: Font.Medium
            color: SettingsMaterialPreset.subheaderColor
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.width >= 760 ? 4 : 2
            columnSpacing: 8
            rowSpacing: 8

            component DayTile: RippleButton {
                id: day
                property string symbol: ""
                property string label: ""
                property string stateText: ""
                property bool on: false
                Layout.fillWidth: true
                implicitHeight: 72
                pressScaleEnabled: false
                // M3 Expressive: on, the tile and its icon square off a little, filled with the accent's container
                buttonRadius: day.on ? 20 : 36
                toggled: day.on
                colBackground: SettingsMaterialPreset.tileColor
                colBackgroundHover: SettingsMaterialPreset.tileHoverColor
                colBackgroundToggled: Appearance.colors.colPrimaryContainer
                colBackgroundToggledHover: ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colOnPrimaryContainer, 0.92)
                colRipple: SettingsMaterialPreset.tilePressColor
                colRippleToggled: ColorUtils.mix(Appearance.colors.colPrimaryContainer, Appearance.colors.colOnPrimaryContainer, 0.88)
                Accessible.role: Accessible.CheckBox
                Accessible.checked: day.on
                Accessible.name: day.label
                Behavior on buttonRadius {
                    enabled: Appearance.animationsEnabled
                    NumberAnimation { duration: Appearance.animationCurves.expressiveFastSpatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                }

                contentItem: RowLayout {
                    spacing: 12
                    Rectangle {
                        Layout.leftMargin: 8
                        implicitWidth: 56
                        implicitHeight: 56
                        radius: day.on ? 16 : 28
                        color: day.on ? Appearance.colors.colPrimary : SettingsMaterialPreset.controlColor
                        Behavior on radius {
                            enabled: Appearance.animationsEnabled
                            NumberAnimation { duration: Appearance.animationCurves.expressiveFastSpatialDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial }
                        }
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: day.symbol
                            iconSize: 24
                            fill: day.on ? 1 : 0
                            color: day.on ? Appearance.colors.colOnPrimary : SettingsMaterialPreset.labelColor
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: day.label
                            font.pixelSize: Math.round(15 * Appearance.fontSizeScale)
                            font.weight: Font.Medium
                            color: day.on ? Appearance.colors.colOnPrimaryContainer : SettingsMaterialPreset.labelColor
                            elide: Text.ElideRight
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: day.stateText
                            font.pixelSize: Math.round(13 * Appearance.fontSizeScale)
                            color: day.on ? Appearance.colors.colOnPrimaryContainer : SettingsMaterialPreset.supportingColor
                            opacity: day.on ? 0.8 : 1
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            DayTile {
                symbol: "do_not_disturb_on"
                label: Translation.tr("Do not disturb")
                on: Notifications.silent
                stateText: on ? Translation.tr("Popups are quiet") : Translation.tr("Off")
                onClicked: Notifications.toggleSilent()
            }
            DayTile {
                symbol: "nightlight"
                label: Translation.tr("Night light")
                on: Hyprsunset.active
                stateText: on ? Translation.tr("Warmer screen") : Translation.tr("Off")
                onClicked: Hyprsunset.toggle()
            }
            DayTile {
                symbol: "sports_esports"
                label: Translation.tr("Game mode")
                on: GameMode.active
                stateText: on ? Translation.tr("Effects paused") : Translation.tr("Off")
                onClicked: GameMode.toggle()
            }
            DayTile {
                symbol: "coffee"
                label: Translation.tr("Keep awake")
                on: Idle.inhibit
                stateText: on ? Translation.tr("Screen stays on") : Translation.tr("Off")
                onClicked: Idle.toggleInhibit()
            }
        }
    }
}
