pragma ComponentBehavior: Bound

// The Material face: a card on the desktop. The shape is the play button: it takes the shape the person picked while
// a station plays and rests as a circle otherwise. Beside it, the station, where it is, and what it plays now.
// When the person's widget design is iNstrument or Readout (or they pick Instrument here) it draws that grammar.
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
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 260
    resizeMinHeight: 100

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie12Sided")

    // ── What plays ───────────────────────────────────────────
    readonly property var station: Radio.current
    readonly property bool playing: Radio.phase === "playing"
    readonly property bool waiting: Radio.phase === "searching" || Radio.phase === "tuning"
    readonly property bool failed: Radio.phase === "failed"
    // In edit mode a click places the card; it never plays.
    readonly property bool steerable: !GlobalStates.widgetEditMode
    readonly property string playIcon: root.playing ? "pause" : root.waiting ? "more_horiz" : "play_arrow"
    readonly property string eyebrow: root.station ? Radio.tag : "Radio"
    readonly property string title: root.station?.name ?? "Tune in somewhere"
    readonly property string where: root.station ? `${Radio.flag} ${Radio.place}`.trim() : ""

    readonly property color shapeFill: root.playing ? root.widgetSemanticContainer(root.widgetPrimaryRole)
        : ColorUtils.applyAlpha(root.widgetInk, playButton.hovered ? 0.2 : 0.14)
    readonly property color shapeInk: root.playing ? root.widgetSemanticOnContainer(root.widgetPrimaryRole) : root.widgetInk

    readonly property int pad: Math.round(16 * root.scaleFactor)
    readonly property int shapeSize: Math.round(88 * root.scaleFactor)
    readonly property int infoWidth: Math.round(204 * root.scaleFactor)
    readonly property int instrumentMargin: Math.round(14 * root.scaleFactor)
    implicitWidth: root.instrument ? Math.round(300 * root.scaleFactor)
        : root.pad * 2 + root.shapeSize + Math.round(16 * root.scaleFactor) + root.infoWidth
    implicitHeight: root.instrument ? instrumentBody.implicitHeight + root.instrumentMargin * 2
        : Math.max(root.shapeSize, info.implicitHeight) + root.pad * 2

    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    // ── Shape look ───────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: root.instrument ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            enabled: root.animationsActive
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        RippleButton {
            id: playButton
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            width: root.shapeSize
            height: root.shapeSize
            enabled: root.steerable
            buttonRadius: root.shapeSize / 2
            colBackground: "transparent"
            colBackgroundHover: "transparent"
            colRipple: ColorUtils.applyAlpha(root.shapeInk, 0.18)
            onClicked: Radio.playPause()
            Accessible.name: root.playing ? "Stop" : "Play"

            contentItem: Item {
                MaterialShape {
                    anchors.fill: parent
                    implicitSize: root.shapeSize
                    shape: DesktopWidgetShapes.shapeForName(root.playing ? root.shapeName : "Circle")
                    color: root.shapeFill
                }
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.playIcon
                    fill: 1
                    iconSize: Math.round(root.shapeSize * 0.42)
                    color: root.shapeInk
                }
            }
        }

        ColumnLayout {
            id: info
            x: playButton.x + playButton.width + Math.round(16 * root.scaleFactor)
            width: root.infoWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.scaleFactor)

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.scaleFactor)
                MaterialSymbol {
                    text: "radio"
                    fill: 1
                    iconSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                    color: root.widgetAccent3Visible
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.eyebrow
                    elide: Text.ElideRight
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    font.capitalization: root.widgetCapitalization
                    font.letterSpacing: Math.round(1 * root.scaleFactor)
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
                }
                RippleButton {
                    id: nextButton
                    implicitWidth: Math.round(28 * root.scaleFactor)
                    implicitHeight: implicitWidth
                    buttonRadius: implicitWidth / 2
                    enabled: root.steerable && !root.waiting
                    opacity: enabled ? 1 : 0.4
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(root.widgetInk, 0.12)
                    colRipple: ColorUtils.applyAlpha(root.widgetInk, 0.2)
                    onClicked: Radio.next()
                    Accessible.name: "Next station"
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        fill: 1
                        iconSize: Math.round(20 * root.scaleFactor)
                        color: root.widgetInk
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: root.widgetTitleFamily
                font.pixelSize: Math.round(Appearance.font.pixelSize.larger * root.widgetTitleScale * root.scaleFactor)
                font.weight: root.widgetTitleWeight
                font.letterSpacing: root.widgetTitleTracking
                color: root.widgetInk
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.where.length > 0
                text: root.where
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                font.weight: Font.Medium
                color: ColorUtils.applyAlpha(root.widgetInk, 0.78)
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(2 * root.scaleFactor)
                text: Radio.line
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: root.failed ? root.widgetAccentVisible : ColorUtils.applyAlpha(root.widgetInk, 0.58)
            }
        }
    }

    // ── Instrument look ──────────────────────────────────────
    ColumnLayout {
        id: instrumentBody
        anchors.fill: parent
        anchors.margins: root.instrumentMargin
        opacity: root.instrument ? 1 : 0
        visible: opacity > 0
        spacing: Math.round(6 * root.scaleFactor)
        Behavior on opacity {
            enabled: root.animationsActive
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        InstrumentLabel {
            Layout.fillWidth: true
            text: "Radio / " + (root.station ? Radio.tag : "Anywhere")
            color: root.widgetAccentVisible
            scaleFactor: root.scaleFactor
            strong: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.scaleFactor)
            StyledText {
                Layout.fillWidth: true
                text: root.title
                elide: Text.ElideRight
                font.family: root.widgetNumbersFamily
                font.pixelSize: Math.round(24 * root.scaleFactor)
                font.weight: root.widgetEditorial ? Appearance.editorial.titleWeight : Font.Bold
                font.letterSpacing: -0.5
                color: root.widgetInk
            }
            Repeater {
                model: [
                    { icon: root.playIcon, enabled: true, action: () => Radio.playPause(), name: root.playing ? "Stop" : "Play" },
                    { icon: "skip_next", enabled: !root.waiting, action: () => Radio.next(), name: "Next station" }
                ]
                RippleButton {
                    required property var modelData
                    implicitWidth: Math.round(28 * root.scaleFactor)
                    implicitHeight: implicitWidth
                    buttonRadius: Math.round(6 * root.scaleFactor)
                    enabled: root.steerable && modelData.enabled
                    opacity: enabled ? 1 : 0.4
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.applyAlpha(root.widgetAccentVisible, 0.14)
                    colRipple: ColorUtils.applyAlpha(root.widgetAccentVisible, 0.22)
                    onClicked: modelData.action()
                    Accessible.name: modelData.name
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: modelData.icon
                        fill: 1
                        iconSize: Math.round(18 * root.scaleFactor)
                        color: root.widgetInk
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(14 * root.scaleFactor)
            InstrumentField {
                Layout.preferredWidth: Math.round(100 * root.scaleFactor)
                label: "From"
                value: root.station ? Radio.place : "--"
                ink: root.widgetInk
                muted: root.widgetInkMuted
                family: root.widgetNumbersFamily
                scaleFactor: root.scaleFactor
            }
            InstrumentField {
                Layout.fillWidth: true
                label: root.playing ? "On air" : "Status"
                value: Radio.line
                ink: root.failed ? root.widgetAccentVisible : root.widgetInk
                muted: root.widgetInkMuted
                family: root.widgetNumbersFamily
                scaleFactor: root.scaleFactor
            }
        }
    }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                title: "Style"
                WidgetQuickChoices {
                    current: root.instrument ? "instrument" : "shape"
                    model: [
                        { label: "Shape", icon: "interests", value: "shape" },
                        { label: "Instrument", icon: "avg_pace", value: "instrument" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                visible: !root.instrument
                title: "Shape while playing"
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
