// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import "../state"

ColumnLayout {
    id: root
    required property EditorSession session
    required property PlaybackController playback
    readonly property int padX: Math.round(EditorSkin.small)
    readonly property int padY: Math.round(EditorSkin.small * 2 / 3)
    spacing: EditorSkin.cards ? EditorSkin.small : EditorSkin.gap

    component ToolCard: EditorSurface {
        id: card
        property bool divided: false
        property bool tail: false
        readonly property int topInset: EditorSkin.cards ? root.padY : (card.divided ? Math.round(EditorSkin.small) : root.padY)
        readonly property int bottomInset: EditorSkin.cards ? root.padY : (card.tail ? root.padY : 0)
        default property alias items: cardBody.data
        Layout.fillWidth: true
        section: true
        implicitHeight: cardBody.implicitHeight + card.topInset + card.bottomInset
        Rectangle {
            visible: card.divided && !EditorSkin.cards
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.padX
            anchors.rightMargin: root.padX
            height: 1
            color: EditorSkin.colors.edge
        }
        ColumnLayout {
            id: cardBody
            anchors.fill: parent
            anchors.leftMargin: root.padX
            anchors.rightMargin: root.padX
            anchors.topMargin: card.topInset
            anchors.bottomMargin: card.bottomInset
            spacing: EditorSkin.small
        }
    }

    ToolCard {
        Flow {
            Layout.fillWidth: true
            spacing: EditorSkin.small
            EditorAction { symbol: "skip_previous"; hint: Translation.tr("Go to start (Home)"); onClicked: root.playback.seek(root.session.startMs) }
            EditorAction { symbol: "navigate_before"; hint: Translation.tr("Previous frame (←)"); onClicked: root.playback.step(-1) }
            EditorAction { symbol: "navigate_next"; hint: Translation.tr("Next frame (→)"); onClicked: root.playback.step(1) }
            EditorAction { symbol: "skip_next"; hint: Translation.tr("Go to end (End)"); onClicked: { root.playback.pause(); root.playback.seek(root.session.effectiveEndMs); } }
            EditorAction { label: Translation.tr("In"); hint: Translation.tr("Set in point here (I)"); onClicked: root.session.setInPoint(root.playback.position) }
            EditorAction { label: Translation.tr("Out"); hint: Translation.tr("Set out point here (O)"); onClicked: root.session.setOutPoint(root.playback.position) }
            EditorText {
                height: EditorSkin.body + EditorSkin.small * 2
                verticalAlignment: Text.AlignVCenter
                text: root.session.timecode(root.playback.position) + " / " + root.session.timecode(root.session.durationMs)
                role: "mono"
            }
            Repeater {
                model: [0.25, 0.5, 1, 1.5, 2]
                EditorAction { required property real modelData; label: modelData + "×"; hint: Translation.tr("Playback speed (S to cycle)"); selected: root.session.playbackRate === modelData; onClicked: root.session.playbackRate = modelData }
            }
        }
    }

    ToolCard {
        visible: !root.session.compressOpen
        divided: true
        EditorChoices {
            Layout.fillWidth: true
            title: Translation.tr("Aspect Ratio")
            choices: [{ label: Translation.tr("Free"), value: -1 }, { label: "16:9", value: 16 / 9 }, { label: "9:16", value: 9 / 16 }, { label: "4:3", value: 4 / 3 }, { label: "1:1", value: 1 }]
            tolerance: 0.01
            selectedValue: !root.session.cropEnabled ? null : root.session.cropW === 1 && root.session.cropH === 1 ? -1 : root.session.cropW * root.session.metadata.video?.width / (root.session.cropH * root.session.metadata.video?.height)
            onChosen: value => root.session.applyPreset(value)
        }
        Flow {
            Layout.fillWidth: true
            spacing: EditorSkin.small
            EditorAction { symbol: "restart_alt"; hint: Translation.tr("Reset transformations"); onClicked: root.session.resetTransformations() }
            EditorAction { symbol: "rotate_right"; hint: Translation.tr("Rotate 90°"); selected: root.session.rotation !== 0; onClicked: root.session.rotation = (root.session.rotation + 90) % 360 }
            EditorAction { symbol: "flip"; hint: Translation.tr("Flip horizontal"); selected: root.session.flipHorizontal; onClicked: root.session.flipHorizontal = !root.session.flipHorizontal }
            EditorAction { symbol: "flip"; hint: Translation.tr("Flip vertical"); selected: root.session.flipVertical; onClicked: root.session.flipVertical = !root.session.flipVertical }
            EditorAction { symbol: root.session.mute ? "volume_off" : "volume_up"; hint: root.session.mute ? Translation.tr("Unmute preview") : Translation.tr("Mute preview"); selected: root.session.mute; onClicked: root.session.mute = !root.session.mute }
            EditorRange {
                width: Appearance.sizes.osdWidth
                value: root.session.mute ? 0 : root.session.volume
                enabled: !root.session.mute
                onMoved: next => root.session.volume = next
                Accessible.name: Translation.tr("Preview volume")
            }
        }
    }

    ToolCard {
        visible: root.session.compressOpen
        divided: true
        Flow {
            Layout.fillWidth: true
            spacing: EditorSkin.small
            EditorAction { label: Translation.tr("Video (MP4)"); symbol: "movie"; selected: root.session.compressFormat === "mp4"; onClicked: root.session.compressFormat = "mp4" }
            EditorAction { label: Translation.tr("GIF Animation"); symbol: "gif"; selected: root.session.compressFormat === "gif"; onClicked: root.session.compressFormat = "gif" }
            EditorAction { label: Translation.tr("Done"); symbol: "check"; onClicked: root.session.compressOpen = false }
        }
        EditorText {
            Layout.fillWidth: true
            text: root.session.estimateError || Translation.tr("Estimated Size: %1 → %2").arg(root.session.bytes(root.session.metadata.size)).arg(root.session.estimating ? Translation.tr("calculating…") : root.session.bytes(root.session.estimatedSize))
            color: root.session.estimateError ? EditorSkin.colors.error : EditorSkin.colors.muted
            wrapMode: Text.Wrap
            role: "meta"
        }
        ColumnLayout {
            visible: root.session.compressFormat === "mp4"
            Layout.fillWidth: true
            spacing: EditorSkin.small
            EditorText { text: Translation.tr("Compression Quality") + " · CRF " + root.session.crf }
            EditorRange { Layout.fillWidth: true; from: 10; to: 100; value: root.session.compressionPercent; onMoved: next => root.session.compressionPercent = next; Accessible.name: Translation.tr("Compression Quality") }
            EditorChoices {
                Layout.fillWidth: true
                title: Translation.tr("Output Resolution")
                choices: ["original", "1080p", "720p", "480p"].map(v => ({ value: v, label: v === "original" ? Translation.tr("Original") : v }))
                selectedValue: root.session.outputResolution
                onChosen: value => root.session.outputResolution = value
            }
        }

        Repeater {
            model: root.session.compressFormat === "gif" ? [
                { title: Translation.tr("Resolution"), key: "gifScale", choices: [1, 0.75, 0.5, 0.33, 0.25].map(v => ({ label: Math.round(v * 100) + "%", value: v })) },
                { title: Translation.tr("FPS"), key: "gifFps", choices: [10, 12, 15, 20, 24, 30].map(v => ({ label: String(v), value: v })) },
                { title: Translation.tr("Dither / Quality"), key: "gifDither", choices: [{ label: Translation.tr("Bayer"), value: "bayer" }, { label: "Floyd-Steinberg", value: "floyd_steinberg" }, { label: "Sierra", value: "sierra2_4a" }, { label: Translation.tr("None"), value: "none" }] },
                { title: Translation.tr("Colors"), key: "gifColors", choices: [256, 128, 64, 32].map(v => ({ label: String(v), value: v })) }
            ] : []
            EditorChoices {
                required property var modelData
                Layout.fillWidth: true
                title: modelData.title; choices: modelData.choices
                selectedValue: root.session[modelData.key]
                onChosen: value => root.session[modelData.key] = value
            }
        }

        EditorAction { visible: root.session.compressFormat === "gif"; label: Translation.tr("Export GIF"); symbol: "gif"; primary: true; onClicked: root.session.exportRequested(false, "gif") }
    }

    ToolCard {
        divided: true
        tail: true
        Flow {
            Layout.fillWidth: true
            spacing: EditorSkin.small
            EditorAction { label: Translation.tr("Compress"); symbol: "compress"; selected: root.session.compressOpen; onClicked: root.session.compressOpen = !root.session.compressOpen }
            EditorAction { label: Translation.tr("Save Copy"); symbol: "content_copy"; onClicked: root.session.exportRequested(false, "mp4") }
            EditorAction { label: Translation.tr("Audio (MP3)"); symbol: "music_note"; enabled: root.session.metadata.audio?.present === true; hint: Translation.tr("Extract audio track"); onClicked: root.session.exportRequested(false, "mp3") }
            EditorAction { label: Translation.tr("GIF Animation"); symbol: "gif"; onClicked: root.session.exportRequested(false, "gif") }
            EditorAction { label: Translation.tr("Save and Replace"); symbol: "check_circle"; primary: true; onClicked: root.session.exportRequested(true, "mp4") }
        }
    }
}
