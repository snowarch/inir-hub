pragma ComponentBehavior: Bound

// The Material face: a card on the desktop in three sizes (small, medium, large). The shape is the play button: it takes the shape the person picked while
// a station plays and rests as a circle otherwise. Beside it, the station, where it is, and what it plays now; its
// star, the tuner (search, countries, genres, favourites) and next. The wheel over the card sets the volume.
// When the person's widget design is iNstrument or Readout (or they pick Instrument here) it draws that grammar.
// Under iRiS the family's widget designs draw it instead: IrisRadioFace (iRiS) and PrismRadio (Prism), named by
// `iris.desktop` in widget.json; this drawing is then its Material design.
// Every screen's card steers the one Radio, so two cards never play two streams.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.instrument

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.radio"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie12Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 420 })
    needsColText: true
    resizeMinWidth: 150
    resizeMinHeight: 150
    resizeMaxWidth: 760
    resizeMaxHeight: 760

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie12Sided")

    // ── What plays ───────────────────────────────────────────
    readonly property var station: Radio.current
    readonly property bool playing: Radio.playing
    readonly property bool waiting: Radio.waiting
    readonly property bool failed: Radio.phase === "failed"
    // In edit mode a click places the card; it never plays.
    readonly property bool steerable: !GlobalStates.widgetEditMode
    readonly property string playIcon: root.playing ? "stop" : root.waiting ? "more_horiz" : "play_arrow"
    readonly property string eyebrow: root.station && Radio.tag.length > 0 ? Radio.tag : Translation.tr("Radio")
    readonly property string title: root.station?.name ?? Translation.tr("Tune in somewhere")
    readonly property string where: root.station ? `${Radio.flag} ${Radio.place}`.trim() : ""
    // The wheel's volume is said for a moment where the song goes.
    property bool turning: false
    Timer { id: turned; interval: 1400; onTriggered: root.turning = false }
    readonly property string statusLine: root.turning
        ? (Radio.muted ? Translation.tr("Muted") : Translation.tr("Volume %1 %").arg(Math.round(Radio.liveVolume)))
        : Radio.skipped.length > 0 && !root.playing ? Translation.tr("%1 didn't answer, moved on").arg(Radio.skipped)
        : Radio.line
    WheelHandler {
        enabled: root.steerable
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            Radio.nudgeVolume(event.angleDelta.y > 0 ? 1 : event.angleDelta.y < 0 ? -1 : 0)
            root.turning = true
            turned.restart()
        }
    }
    // The card sits on the desktop of every family; its tuner wears the family worn: iRiS and Waffle draw theirs,
    // loaded only while that family is the one in use.
    readonly property string family: Config.options?.panelFamily ?? "ii"
    Loader {
        id: familyLook
        active: root.family === "iris" || root.family === "waffle"
        source: root.family === "iris" ? "IrisLook.qml" : root.family === "waffle" ? "WaffleLook.qml" : ""
    }
    readonly property var wornLook: familyLook.item?.look ?? root.tunerLook
    onWornLookChanged: Radio.offerLook(familyLook.item ? root.family : "ii", root.wornLook)
    Component.onCompleted: Radio.offerLook("ii", root.tunerLook)
    function openTuner(): void { Radio.openTuner(root.desktop?.screen ?? null, root.wornLook) }

    // The tuner wears Material's panel colours, not the card's wallpaper ink: it is a window, not a widget.
    readonly property var tunerLook: ({
        d: 1,
        font: Appearance.font.family.main,
        small: Appearance.font.pixelSize.smaller,
        meta: Appearance.font.pixelSize.smallie,
        body: Appearance.font.pixelSize.small,
        title: Appearance.font.pixelSize.larger,
        bg: Appearance.colors.colLayer0Base,
        raised: Appearance.colors.colLayer1Base,
        hover: Appearance.colors.colLayer1Hover,
        press: Appearance.colors.colLayer1Active,
        selected: Appearance.colors.colSecondaryContainer,
        ink: Appearance.colors.colOnLayer0,
        muted: Appearance.colors.colSubtext,
        faint: ColorUtils.applyAlpha(Appearance.colors.colOnLayer0, 0.46),
        line: Appearance.colors.colOutlineVariant,
        accent: Appearance.colors.colPrimary,
        onAccent: Appearance.colors.colOnPrimary,
        danger: Appearance.colors.colError,
        scrim: ColorUtils.applyAlpha(Appearance.colors.colScrim, 0.32),
        radius: Appearance.rounding.windowRounding,
        radiusSmall: Appearance.rounding.small,
        glyph: materialGlyph
    })
    Component {
        id: materialGlyph
        MaterialSymbol {
            property string name: ""
            property real size: 20
            property bool filled: false
            text: name
            iconSize: size
            fill: filled ? 1 : 0
        }
    }

    // ── Size ─────────────────────────────────────────────────
    // Small is one square of the desktop's grid, medium two side by side, large two by two; every measure follows
    // the box the card gets, so a dragged size draws the same card bigger.
    readonly property real k: Math.max(0.4, Math.min(root.width / (root.isSmall ? 176 : 368), root.height / (root.isLarge ? 368 : 176)))
    function px(v: real): int { return Math.round(v * root.k) }
    readonly property int pad: root.px(root.isSmall ? 14 : 16)

    // The card's own parts (volume, keys, station rows) wear the widget's ink over the wallpaper.
    readonly property var cardLook: ({
        d: root.k,
        font: Appearance.font.family.main,
        small: root.px(Appearance.font.pixelSize.smaller),
        meta: root.px(Appearance.font.pixelSize.smallie),
        body: root.px(Appearance.font.pixelSize.small),
        raised: ColorUtils.applyAlpha(root.widgetInk, 0.1),
        hover: ColorUtils.applyAlpha(root.widgetInk, 0.12),
        press: ColorUtils.applyAlpha(root.widgetInk, 0.2),
        ink: root.widgetInk,
        muted: ColorUtils.applyAlpha(root.widgetInk, 0.72),
        faint: ColorUtils.applyAlpha(root.widgetInk, 0.5),
        line: ColorUtils.applyAlpha(root.widgetInk, 0.2),
        track: ColorUtils.applyAlpha(root.widgetInk, 0.2),
        accent: root.widgetAccentVisible,
        onAccent: root.widgetInk,
        radiusSmall: root.px(8),
        glyph: materialGlyph
    })

    readonly property color shapeFill: root.playing ? root.widgetSemanticContainer(root.widgetPrimaryRole)
        : ColorUtils.applyAlpha(root.widgetInk, 0.14)
    readonly property color shapeInk: root.playing ? root.widgetSemanticOnContainer(root.widgetPrimaryRole) : root.widgetInk

    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && !root.familyFaced && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    // The play key: the picked shape while a station plays, a circle at rest.
    component PlayShape: RippleButton {
        id: key
        property int size: 88
        implicitWidth: key.size
        implicitHeight: key.size
        enabled: root.steerable
        buttonRadius: key.size / 2
        colBackground: "transparent"
        colBackgroundHover: "transparent"
        colRipple: ColorUtils.applyAlpha(root.shapeInk, 0.18)
        onClicked: Radio.playPause()
        Accessible.name: root.playing ? Translation.tr("Stop") : Translation.tr("Play")
        contentItem: Item {
            MaterialShape {
                anchors.fill: parent
                implicitSize: key.size
                shape: DesktopWidgetShapes.shapeForName(root.playing ? root.shapeName : "Circle")
                color: root.shapeFill
                scale: key.hovered && !key.down ? 1.04 : 1
                Behavior on scale {
                    enabled: root.animationsActive
                    NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic }
                }
            }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.playIcon
                fill: 1
                iconSize: Math.round(key.size * 0.44)
                color: root.shapeInk
            }
        }
    }
    component Eyebrow: RowLayout {
        spacing: root.px(6)
        MaterialSymbol {
            text: "radio"
            fill: 1
            iconSize: root.px(Appearance.font.pixelSize.small)
            color: root.widgetAccent3Visible
        }
        StyledText {
            Layout.fillWidth: true
            text: root.eyebrow
            elide: Text.ElideRight
            font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
            font.weight: Font.DemiBold
            font.capitalization: root.widgetCapitalization
            font.letterSpacing: root.px(1)
            color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
        }
    }
    component Title: StyledText {
        text: root.title
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 0.95
        font.family: root.widgetTitleFamily
        font.weight: root.widgetTitleWeight
        font.letterSpacing: root.widgetTitleTracking
        color: root.widgetInk
        MouseArea {
            anchors.fill: parent
            enabled: root.steerable
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openTuner()
        }
    }
    component Keys: Row {
        property bool star: true
        spacing: root.px(2)
        enabled: root.steerable
        RadioButton {
            visible: parent.star && root.station !== null
            look: root.cardLook
            glyph: "star"
            on: Radio.kept
            label: Radio.kept ? Translation.tr("Remove from favourites") : Translation.tr("Add to favourites")
            size: root.px(32)
            onClicked: Radio.toggleFavourite(root.station)
        }
        RadioButton {
            look: root.cardLook
            glyph: "explore"
            filled: true
            on: Radio.tunerOpen
            label: Translation.tr("Find a station")
            size: root.px(32)
            onClicked: root.openTuner()
        }
        RadioButton {
            look: root.cardLook
            glyph: "skip_next"
            filled: true
            enabled: !root.waiting
            label: Translation.tr("Next station")
            size: root.px(32)
            onClicked: Radio.next()
        }
    }
    component Line: StyledText {
        elide: Text.ElideRight
        font.pixelSize: root.px(Appearance.font.pixelSize.small)
    }

    // ── Shape look ───────────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.pad
        active: !root.instrument && !root.familyFaced
        sourceComponent: root.isSmall ? smallFace : root.isLarge ? largeFace : mediumFace
    }

    // Small: the key, the tuner and next; under them the station and where it is.
    Component {
        id: smallFace
        ColumnLayout {
            spacing: root.px(2)
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                PlayShape { size: root.px(84) }
                Item { Layout.fillWidth: true }
                Column {
                    Layout.alignment: Qt.AlignTop
                    spacing: root.px(2)
                    enabled: root.steerable
                    RadioButton {
                        look: root.cardLook
                        glyph: "explore"
                        filled: true
                        label: Translation.tr("Find a station")
                        size: root.px(32)
                        onClicked: root.openTuner()
                    }
                    RadioButton {
                        look: root.cardLook
                        glyph: "skip_next"
                        filled: true
                        enabled: !root.waiting
                        label: Translation.tr("Next station")
                        size: root.px(32)
                        onClicked: Radio.next()
                    }
                }
            }
            Item { Layout.fillHeight: true }
            Title {
                Layout.fillWidth: true
                maximumLineCount: 1
                font.pixelSize: root.px(Appearance.font.pixelSize.normal * root.widgetTitleScale)
            }
            Line {
                Layout.fillWidth: true
                text: root.turning || root.failed || root.waiting || root.where.length === 0 ? root.statusLine : root.where
                font.weight: Font.Medium
                color: root.failed ? root.widgetAccentVisible : ColorUtils.applyAlpha(root.widgetInk, 0.7)
            }
        }
    }

    // Medium: the key beside the station, where it is and what it plays; keys and volume along the bottom.
    Component {
        id: mediumFace
        RowLayout {
            spacing: root.px(16)
            PlayShape {
                Layout.alignment: Qt.AlignVCenter
                size: root.px(112)
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.px(2)
                Eyebrow { Layout.fillWidth: true }
                Title {
                    Layout.fillWidth: true
                    font.pixelSize: root.px(Appearance.font.pixelSize.larger * root.widgetTitleScale)
                }
                Line {
                    Layout.fillWidth: true
                    visible: root.where.length > 0
                    text: root.where
                    font.weight: Font.Medium
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.78)
                }
                Line {
                    Layout.fillWidth: true
                    text: root.statusLine
                    color: root.failed ? root.widgetAccentVisible : ColorUtils.applyAlpha(root.widgetInk, 0.58)
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: -root.px(6)
                    spacing: 0
                    Keys {}
                    Item { Layout.fillWidth: true }
                    RadioVolume {
                        look: root.cardLook
                        barWidth: root.px(56)
                    }
                }
            }
        }
    }

    // Large: the same head, the song in full, volume, and the stations kept one click away.
    Component {
        id: largeFace
        ColumnLayout {
            spacing: root.px(8)
            RowLayout {
                Layout.fillWidth: true
                spacing: root.px(16)
                PlayShape { size: root.px(96) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: root.px(2)
                    Eyebrow { Layout.fillWidth: true }
                    Title {
                        Layout.fillWidth: true
                        font.pixelSize: root.px(Appearance.font.pixelSize.larger * 1.1 * root.widgetTitleScale)
                    }
                    Line {
                        Layout.fillWidth: true
                        visible: root.where.length > 0
                        text: root.where
                        font.weight: Font.Medium
                        color: ColorUtils.applyAlpha(root.widgetInk, 0.78)
                    }
                }
            }
            Line {
                Layout.fillWidth: true
                Layout.topMargin: root.px(2)
                text: root.statusLine
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                font.pixelSize: root.px(Appearance.font.pixelSize.normal)
                color: root.failed ? root.widgetAccentVisible : ColorUtils.applyAlpha(root.widgetInk, 0.82)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: -root.px(6)
                spacing: 0
                Keys {}
                Item { Layout.fillWidth: true }
                RadioVolume {
                    look: root.cardLook
                    barWidth: root.px(132)
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.cardLook.line
            }
            RadioCardStations {
                Layout.fillWidth: true
                card: root
                rows: 3
            }
            Item { Layout.fillHeight: true }
        }
    }

    // ── Instrument look ──────────────────────────────────────
    Loader {
        anchors.fill: parent
        anchors.margins: root.px(14)
        active: root.instrument && !root.familyFaced
        sourceComponent: RadioCardInstrument { card: root }
    }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                visible: !root.familyFaced
                title: Translation.tr("Style")
                WidgetQuickChoices {
                    current: root.instrument ? "instrument" : "shape"
                    model: [
                        { label: Translation.tr("Shape"), icon: "interests", value: "shape" },
                        { label: Translation.tr("Instrument"), icon: "avg_pace", value: "instrument" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                visible: !root.instrument && !root.familyFaced
                title: Translation.tr("Shape while playing")
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
