pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../state"
import "../state/plan.js" as Plan

// The picker: the four modes, the second screen to use when several are connected, and a line that says what is going
// on. Keys and pointer share one place, a ring that glides between the tiles: arrows or Tab move it, the pointer
// brings it along, Enter or Space picks, 1 to 4 pick directly, I shows About, Escape closes.
Rectangle {
    id: card

    readonly property real d: FamilyStyle.density
    readonly property real pad: Math.round(20 * card.d)
    // The tile the keys or the pointer are on: the active mode until either moves.
    property int cursor: -1
    readonly property int shown: card.cursor >= 0 ? card.cursor : Math.max(0, Plan.MODES.indexOf(Projection.activeMode))
    property bool about: false

    function move(step: int): void {
        for (let i = 1; i <= Plan.MODES.length; i++) {
            const next = (card.shown + step * i + Plan.MODES.length * 4) % Plan.MODES.length
            if (Projection.canUse(Plan.MODES[next])) {
                card.cursor = next
                return
            }
        }
    }
    function pick(index: int): void {
        const mode = Plan.MODES[index]
        if (mode && Projection.canUse(mode)) {
            card.cursor = index
            Projection.apply(mode)
        }
    }

    readonly property string status: {
        if (!Projection.supported)
            return Translation.tr("Display Projection needs niri to switch displays")
        if (Projection.phase === "applying")
            return Translation.tr("Applying…")
        if (Projection.phase === "done")
            return Translation.tr("Done")
        if (Projection.phase === "failed")
            return Projection.failure
        if (!Projection.outputsRead && Projection.readError.length > 0)
            return Translation.tr("Couldn't read the displays: %1").arg(Projection.readError)
        if (!Projection.outputsRead)
            return Translation.tr("Reading displays…")
        if (!Projection.primary)
            return Translation.tr("No displays detected")
        if (!Projection.target)
            return Translation.tr("Connect a second screen to duplicate or extend")
        if (Projection.wlMirror === 0)
            return Translation.tr("wl-mirror is not installed: Duplicate won't work")
        const size = Plan.size(Projection.target)
        return Translation.tr("Second screen: %1").arg(Plan.label(Projection.target) + (size ? " · " + size : ""))
    }
    readonly property bool troubled: !Projection.supported || Projection.phase === "failed"
        || (!Projection.outputsRead && Projection.readError.length > 0)
    readonly property string glyph: card.troubled ? "error"
        : Projection.phase === "done" ? "check_circle"
        : Projection.phase === "applying" ? "sync"
        : Projection.wlMirror === 0 && Projection.target ? "warning"
        : "desktop_windows"

    implicitWidth: content.implicitWidth + card.pad * 2
    implicitHeight: content.implicitHeight + card.pad * 2
    radius: FamilyStyle.radiusSheet
    color: FamilyStyle.surface
    border.width: 1
    border.color: FamilyStyle.border
    focus: true

    Component.onCompleted: card.forceActiveFocus()

    // A round glyph button of the header: it answers on the way down, acts on release.
    component HeaderButton: Rectangle {
        id: button

        required property string glyph
        required property string label
        property bool on: false
        signal activated()

        implicitWidth: Math.round(30 * FamilyStyle.density)
        implicitHeight: button.implicitWidth
        radius: button.width / 2
        color: buttonArea.pressed ? FamilyStyle.fillActive
             : button.on ? FamilyStyle.tintFill(FamilyStyle.accent)
             : buttonArea.containsMouse ? FamilyStyle.fillHover
             : "transparent"
        scale: buttonArea.pressed ? FamilyStyle.pressScale(0.92) : 1
        Accessible.role: Accessible.Button
        Accessible.name: button.label

        Behavior on color {
            ColorAnimation { duration: FamilyStyle.feedbackDuration }
        }
        Behavior on scale {
            NumberAnimation { duration: FamilyStyle.feedbackDuration; easing.type: FamilyStyle.feedbackEasing }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: button.glyph
            iconSize: FamilyStyle.typeTitle
            color: button.on ? FamilyStyle.accent : FamilyStyle.subtext
        }
        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }

    Keys.onPressed: event => {
        const key = event.key
        if (key === Qt.Key_Escape)
            Projection.hide()
        else if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_Backtab)
            card.move(-1)
        else if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_Tab)
            card.move(1)
        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
            card.pick(card.shown)
        else if (key >= Qt.Key_1 && key <= Qt.Key_4)
            card.pick(key - Qt.Key_1)
        else if (key === Qt.Key_I)
            card.about = !card.about
        else
            return
        event.accepted = true
    }

    // Clicks on the card stay on the card; a click beside it closes it.
    MouseArea { anchors.fill: parent }

    ColumnLayout {
        id: content
        anchors.centerIn: parent
        spacing: Math.round(14 * card.d)

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * card.d)

            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Project")
                color: FamilyStyle.textStrong
                font.family: FamilyStyle.fontTitle
                font.pixelSize: FamilyStyle.typeTitle
                font.weight: FamilyStyle.weight(Font.DemiBold)
                font.letterSpacing: -FamilyStyle.typeTitle * 0.01
            }

            HeaderButton {
                glyph: "info"
                label: Translation.tr("About")
                on: card.about
                onActivated: card.about = !card.about
            }
            HeaderButton {
                glyph: "close"
                label: Translation.tr("Close")
                onActivated: Projection.hide()
            }
        }

        Item {
            id: tiles
            implicitWidth: row.implicitWidth
            implicitHeight: row.implicitHeight

            RowLayout {
                id: row
                anchors.fill: parent
                spacing: Math.round(10 * card.d)

                Repeater {
                    id: tileRepeater
                    model: Plan.MODES

                    ModeTile {
                        required property string modelData
                        mode: modelData
                        Layout.fillHeight: true
                        active: Projection.activeMode === modelData
                        focused: card.cursor >= 0 && card.shown === index
                        working: Projection.phase === "applying" && Projection.applyingMode === modelData
                        finished: Projection.phase === "done" && Projection.applyingMode === modelData
                        onPicked: card.pick(index)
                        onPointed: card.cursor = index
                    }
                }
            }

            // Where the keys and the pointer are: it glides from tile to tile, and turns around from wherever it is
            // when the next move comes before it lands.
            Rectangle {
                id: ring
                readonly property Item spot: {
                    row.width
                    tileRepeater.count
                    return tileRepeater.itemAt(card.shown)
                }
                readonly property real gap: Math.round(3 * card.d)
                x: (ring.spot ? ring.spot.x : 0) - ring.gap
                y: -ring.gap
                width: (ring.spot ? ring.spot.width : 0) + ring.gap * 2
                height: tiles.height + ring.gap * 2
                radius: FamilyStyle.radiusTile + ring.gap
                color: "transparent"
                border.width: Math.max(2, Math.round(2 * card.d))
                border.color: FamilyStyle.hairlineStrong
                opacity: card.cursor >= 0 ? 1 : 0

                Behavior on x {
                    NumberAnimation { duration: FamilyStyle.duration(240); easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: FamilyStyle.feedbackDuration }
                }
            }
        }

        // Only with more than one second screen: which one the modes use.
        Flow {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            visible: Projection.externals.length > 1
            spacing: Math.round(6 * card.d)

            StyledText {
                height: Math.round(28 * card.d)
                text: Translation.tr("Second screen:")
                color: FamilyStyle.subtext
                font.family: FamilyStyle.fontMain
                font.pixelSize: FamilyStyle.typeMeta
            }

            Repeater {
                model: Projection.externals

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool chosen: Projection.target !== null && Projection.target.name === chip.modelData.name
                    implicitWidth: chipText.implicitWidth + Math.round(20 * card.d)
                    implicitHeight: Math.round(28 * card.d)
                    radius: height / 2
                    color: chip.chosen ? FamilyStyle.tintFill(FamilyStyle.accent)
                         : chipArea.containsMouse ? FamilyStyle.fillHover : FamilyStyle.fill
                    border.width: chip.chosen ? 1 : 0
                    border.color: FamilyStyle.accent
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: chipText.text
                    Accessible.checked: chip.chosen

                    StyledText {
                        id: chipText
                        anchors.centerIn: parent
                        text: Plan.label(chip.modelData)
                        color: chip.chosen ? FamilyStyle.accent : FamilyStyle.text
                        font.family: FamilyStyle.fontMain
                        font.pixelSize: FamilyStyle.typeMeta
                    }
                    MouseArea {
                        id: chipArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: Projection.phase !== "applying"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Projection.requestedTarget = chip.modelData.name
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            spacing: Math.round(8 * card.d)

            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: card.glyph
                iconSize: FamilyStyle.typeLabel
                color: card.troubled ? FamilyStyle.danger
                     : Projection.phase === "done" ? FamilyStyle.success
                     : FamilyStyle.subtext
            }
            StyledText {
                Layout.fillWidth: true
                text: card.status
                wrapMode: Text.WordWrap
                color: card.troubled ? FamilyStyle.danger : FamilyStyle.subtext
                font.family: FamilyStyle.fontMain
                font.pixelSize: FamilyStyle.typeMeta
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            visible: card.about
            spacing: Math.round(4 * card.d)

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: FamilyStyle.border
            }
            Repeater {
                model: [
                    Translation.tr("Duplicate runs wl-mirror, by Ferdinand Bachmann (Ferdi265), GPL-3.0-or-later: it does the mirroring, this only starts it and switches the displays."),
                    Translation.tr("Turning a display off lasts until niri restarts; your niri config is never changed."),
                    Translation.tr("Keys: arrows or Tab to move, Enter to pick, 1 to 4 for a mode, Escape to close.")
                ]

                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(4 * card.d)
                    text: modelData
                    wrapMode: Text.WordWrap
                    color: FamilyStyle.textSecondary
                    font.family: FamilyStyle.fontMain
                    font.pixelSize: FamilyStyle.typeFootnote
                }
            }
        }
    }
}
