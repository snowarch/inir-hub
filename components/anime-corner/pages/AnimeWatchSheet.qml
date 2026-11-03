pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.state
import "../state"

// The Anime Corner's own start of watching: over the page, the show's art behind, and one thing at a time — finding
// the show, finding where it plays, the person's pick, opening the player, playing. A failure stays on the sheet with
// what to try next instead of vanishing with the run.
Item {
    id: root
    signal dismissed()

    readonly property real d: IrisStyle.density
    readonly property var show: CornerWatch.watchShow ?? ({})
    readonly property string title: String(root.show.title ?? CornerWatch.session?.title ?? CornerWatch.query ?? "")
    readonly property string art: String(root.show.banner || root.show.imageLarge || root.show.image || CornerWatch.playingCover || "")
    readonly property string cover: String(root.show.imageLarge || root.show.image || CornerWatch.playingCover || "")
    readonly property bool failed: !CornerWatch.busy && CornerWatch.error.length > 0
    readonly property bool playing: CornerWatch.phase === "playing"
    readonly property bool working: CornerWatch.busy && !CornerWatch.choosing && !root.playing
    // 0 finding the show, 1 finding sources, 2 your pick, 3 opening the player, 4 playing.
    readonly property int step: root.playing ? 4
        : CornerWatch.pickingSource || CornerWatch.pickingEpisode || CornerWatch.pickingShow || CornerWatch.pickingQuality || CornerWatch.betweenEpisodes ? 2
        : CornerWatch.phase === "launching" && root.sourcePicked ? 3
        : CornerWatch.phase === "searching" ? 0 : 1
    // Once a source is picked, what is left is the player opening; a new question starts over.
    property bool sourcePicked: false
    property bool _askingSource: false
    Connections {
        target: CornerWatch
        function onPickChanged(): void {
            if (CornerWatch.pick !== null) {
                root.sourcePicked = false
                root._askingSource = String(CornerWatch.pick.prompt ?? "").indexOf("Select source") === 0
            } else if (root._askingSource) {
                root.sourcePicked = true
            }
        }
    }
    function pickSource(value: string): void { CornerWatch.choose(value) }
    readonly property var steps: [Translation.tr("Finding the show"), Translation.tr("Finding sources"), Translation.tr("Your pick"), Translation.tr("Opening the player")]

    // Everything under it waits: clicks never reach the page behind.
    MouseArea { anchors.fill: parent; hoverEnabled: true; onWheel: wheel => wheel.accepted = true }
    Rectangle { anchors.fill: parent; color: IrisStyle.surfaceOpaque; radius: IrisStyle.radiusTile }
    ClippingRectangle {
        anchors.fill: parent
        radius: IrisStyle.radiusTile
        color: "transparent"
        IrisImage {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.55
            source: /^https:\/\//.test(root.art) ? root.art : ""
            opacity: 0.32
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: IrisStyle.artVeil }
                GradientStop { position: 0.5; color: IrisStyle.surfaceOpaque }
            }
        }
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.margins: Math.round(28 * root.d)
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: body
            width: Math.min(scroller.width, Math.round(760 * root.d))
            x: Math.round((scroller.width - width) / 2)
            spacing: Math.round(20 * root.d)

            // The show: cover, name, the episode and the language it plays in.
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(18 * root.d)
                ClippingRectangle {
                    Layout.preferredWidth: Math.round(104 * root.d)
                    Layout.preferredHeight: Math.round(156 * root.d)
                    radius: IrisStyle.tileRadius(Math.round(52 * root.d))
                    color: IrisStyle.fillQuiet
                    IrisImage { anchors.fill: parent; source: /^https:\/\//.test(root.cover) ? root.cover : "" }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        visible: root.cover.length === 0
                        text: "live_tv"
                        iconSize: Math.round(36 * root.d)
                        color: IrisStyle.muted
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(6 * root.d)
                    IrisText {
                        Layout.fillWidth: true
                        text: root.title
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.pixelSize: IrisStyle.typeTitle
                        font.weight: IrisStyle.weight(Font.Bold)
                    }
                    IrisText {
                        Layout.fillWidth: true
                        readonly property string episode: CornerWatch.busyEpisode || CornerWatch.wantedEpisode
                        visible: text.length > 0
                        text: episode.length > 0 ? Translation.tr("Episode %1").arg(episode) : root.failed ? "" : Translation.tr("Pick an episode")
                        color: IrisStyle.textSecondary
                        font.pixelSize: IrisStyle.typeLabel
                    }
                    IrisChip {
                        glyph: "translate"
                        label: CornerWatch.watchLine
                        Accessible.description: Translation.tr("Change it in the Corner's Settings")
                        onClicked: CornerState.place = "settings"
                    }
                }
                IrisIconButton {
                    Layout.alignment: Qt.AlignTop
                    materialIcon: "close"
                    Accessible.name: CornerWatch.busy && !root.playing ? Translation.tr("Stop") : Translation.tr("Close")
                    onClicked: { if (CornerWatch.busy && !root.playing) CornerWatch.cancel(); root.dismissed() }
                }
            }

            // Where the start is: four steps, the current one lit.
            RowLayout {
                Layout.fillWidth: true
                visible: !root.failed && !root.playing
                spacing: Math.round(8 * root.d)
                Repeater {
                    model: root.steps
                    RowLayout {
                        id: stepRow
                        required property string modelData
                        required property int index
                        readonly property bool done: stepRow.index < root.step
                        readonly property bool here: stepRow.index === root.step
                        Layout.fillWidth: true
                        spacing: Math.round(6 * root.d)
                        Rectangle {
                            Layout.preferredWidth: Math.round(22 * root.d)
                            Layout.preferredHeight: Layout.preferredWidth
                            radius: width / 2
                            color: stepRow.done || stepRow.here ? IrisStyle.tintFill(IrisStyle.identity.pink) : IrisStyle.fillQuiet
                            border.width: stepRow.here ? 1 : 0
                            border.color: IrisStyle.identity.pink
                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: stepRow.done
                                text: "check"
                                iconSize: Math.round(14 * root.d)
                                color: IrisStyle.identity.pink
                            }
                            IrisText {
                                anchors.centerIn: parent
                                visible: !stepRow.done
                                text: String(stepRow.index + 1)
                                color: stepRow.here ? IrisStyle.identity.pink : IrisStyle.muted
                                font.pixelSize: IrisStyle.typeFootnote
                                font.weight: IrisStyle.weight(Font.DemiBold)
                            }
                            // The step at work breathes; nothing moves once it is someone's turn to pick.
                            SequentialAnimation on opacity {
                                running: stepRow.here && root.working && IrisStyle.motionEnabled
                                loops: Animation.Infinite
                                alwaysRunToEnd: true
                                NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                            }
                        }
                        IrisText {
                            Layout.fillWidth: true
                            text: stepRow.modelData
                            elide: Text.ElideRight
                            color: stepRow.here ? IrisStyle.text : IrisStyle.muted
                            font.pixelSize: IrisStyle.typeFootnote
                            font.weight: IrisStyle.weight(stepRow.here ? Font.DemiBold : Font.Normal)
                        }
                    }
                }
            }

            // Working: what it is doing and how long that takes.
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.working
                spacing: Math.round(4 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: root.step === 0 ? Translation.tr("Looking for “%1” on every site").arg(CornerWatch.query || root.title)
                        : root.step === 3 ? Translation.tr("Opening the player…")
                        : Translation.tr("Asking every site that has it")
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font.pixelSize: IrisStyle.typeHeadline
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: root.step === 3 ? Translation.tr("mpv opens in its own window.")
                        : Translation.tr("Sites are asked together; the first time can take up to half a minute.")
                    wrapMode: Text.WordWrap
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeLabel
                }
            }

            // The pick: sources as cards, the best first.
            IrisText {
                Layout.fillWidth: true
                visible: CornerWatch.choosing
                text: CornerWatch.betweenEpisodes ? Translation.tr("Episode finished")
                    : CornerWatch.pickingShow ? Translation.tr("Which one?")
                    : CornerWatch.pickingSource ? Translation.tr("Where to watch it?")
                    : CornerWatch.pickingQuality ? Translation.tr("Which quality?")
                    : Translation.tr("Which episode?")
                font.pixelSize: IrisStyle.typeHeadline
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            GridLayout {
                Layout.fillWidth: true
                visible: CornerWatch.pickingSource
                columns: body.width > Math.round(520 * root.d) ? 2 : 1
                columnSpacing: Math.round(10 * root.d)
                rowSpacing: Math.round(10 * root.d)
                Repeater {
                    model: CornerWatch.pickingSource ? CornerWatch.pickItems : []
                    MouseArea {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property var s: CornerWatch.sourceOf(card.modelData)
                        readonly property int height_: Number(card.s.height ?? 0)
                        Layout.fillWidth: true
                        implicitHeight: cardColumn.implicitHeight + Math.round(24 * root.d)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: String(card.s.provider ?? "")
                        onClicked: root.pickSource(CornerWatch.pickValue(card.modelData))
                        Rectangle {
                            anchors.fill: parent
                            radius: IrisStyle.radiusTile
                            color: card.containsMouse ? IrisStyle.fillHover : card.index === 0 ? IrisStyle.tintFill(IrisStyle.identity.pink) : IrisStyle.fillQuiet
                            border.width: 1
                            border.color: card.index === 0 ? IrisStyle.tintBorder(IrisStyle.identity.pink) : IrisStyle.hairline
                            Behavior on color { enabled: IrisStyle.motionEnabled; ColorAnimation { duration: IrisStyle.duration(120) } }
                        }
                        ColumnLayout {
                            id: cardColumn
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Math.round(14 * root.d) }
                            spacing: Math.round(4 * root.d)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Math.round(8 * root.d)
                                IrisText {
                                    Layout.fillWidth: true
                                    text: String(card.s.provider ?? "")
                                    textFormat: Text.PlainText
                                    elide: Text.ElideRight
                                    font.pixelSize: IrisStyle.typeLabel
                                    font.weight: IrisStyle.weight(Font.Bold)
                                }
                                // How sharp, as a badge.
                                Rectangle {
                                    implicitWidth: sharp.implicitWidth + Math.round(12 * root.d)
                                    implicitHeight: sharp.implicitHeight + Math.round(4 * root.d)
                                    radius: height / 2
                                    color: card.height_ >= 720 ? IrisStyle.tintFill(IrisStyle.identity.green) : IrisStyle.fill
                                    IrisText {
                                        id: sharp
                                        anchors.centerIn: parent
                                        text: card.height_ > 0 ? card.height_ + "p" : "SD?"
                                        color: card.height_ >= 720 ? IrisStyle.identity.green : IrisStyle.textSecondary
                                        font.family: IrisStyle.fontNumbers
                                        font.features: ({ "tnum": 1 })
                                        font.pixelSize: IrisStyle.typeFootnote
                                        font.weight: IrisStyle.weight(Font.DemiBold)
                                    }
                                }
                                IrisIconButton {
                                    materialIcon: "push_pin"
                                    Accessible.name: Translation.tr("Always start from %1").arg(String(card.s.provider ?? ""))
                                    onClicked: {
                                        CornerState.set("source", String(card.s.id ?? "ask"))
                                        root.pickSource(CornerWatch.pickValue(card.modelData))
                                    }
                                }
                            }
                            IrisText {
                                Layout.fillWidth: true
                                text: String(card.s.subs ?? "").length > 0
                                    ? Translation.tr("%1 audio · %2 subtitles").arg(CornerWatch.languageName(String(card.s.audio ?? ""))).arg(CornerWatch.languageName(String(card.s.subs)))
                                    : Translation.tr("%1 audio").arg(CornerWatch.languageName(String(card.s.audio ?? "")))
                                elide: Text.ElideRight
                                color: IrisStyle.textSecondary
                                font.pixelSize: IrisStyle.typeFootnote
                            }
                            IrisText {
                                Layout.fillWidth: true
                                text: [card.s.burned ? Translation.tr("subtitles in the picture") : "", String(card.s.server ?? "")]
                                    .filter(x => String(x).length > 0).join(" · ")
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: IrisStyle.muted
                                font.pixelSize: IrisStyle.typeFootnote
                            }
                        }
                    }
                }
            }
            IrisText {
                Layout.fillWidth: true
                visible: CornerWatch.pickingSource
                text: Translation.tr("The pin plays from that site from now on; the Corner's Settings › Source brings the question back.")
                wrapMode: Text.WordWrap
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
            }
            // Which show, when the sites name more than one.
            Repeater {
                model: CornerWatch.pickingShow ? CornerWatch.pickItems : []
                IrisButton {
                    id: showPick
                    required property var modelData
                    Layout.fillWidth: true
                    text: CornerWatch.pickLabel(showPick.modelData)
                    onClicked: CornerWatch.choose(CornerWatch.pickValue(showPick.modelData))
                }
            }
            // Episodes, qualities and what next after one ends: chips.
            Flow {
                Layout.fillWidth: true
                visible: CornerWatch.pickingEpisode || CornerWatch.pickingQuality || CornerWatch.betweenEpisodes
                spacing: Math.round(8 * root.d)
                Repeater {
                    model: CornerWatch.pickingEpisode || CornerWatch.pickingQuality || CornerWatch.betweenEpisodes ? CornerWatch.pickItems : []
                    IrisChip {
                        id: chip
                        required property var modelData
                        readonly property string value: CornerWatch.pickValue(chip.modelData)
                        label: CornerWatch.betweenEpisodes ? CornerWatch.actionLabel(chip.value)
                            : CornerWatch.pickingEpisode ? Translation.tr("Episode %1").arg(CornerWatch.pickLabel(chip.modelData))
                            : CornerWatch.pickLabel(chip.modelData)
                        onClicked: CornerWatch.choose(chip.value)
                    }
                }
            }

            // Playing: it is in mpv; subtitles can still be fetched from here.
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.playing
                spacing: Math.round(10 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Playing in mpv")
                    font.pixelSize: IrisStyle.typeHeadline
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                AnimeSubtitleFinder { Layout.fillWidth: true }
                RowLayout {
                    spacing: Math.round(8 * root.d)
                    IrisButton { text: Translation.tr("Back to the Corner"); onClicked: root.dismissed() }
                    IrisButton { text: Translation.tr("Next episode"); onClicked: CornerWatch.skip("next") }
                }
            }

            // Failed: why, in words, and what to try.
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.failed
                spacing: Math.round(10 * root.d)
                RowLayout {
                    spacing: Math.round(10 * root.d)
                    MaterialSymbol { text: "error"; iconSize: Math.round(26 * root.d); color: IrisStyle.danger }
                    IrisText {
                        Layout.fillWidth: true
                        text: CornerWatch.error
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        font.pixelSize: IrisStyle.typeHeadline
                        font.weight: IrisStyle.weight(Font.DemiBold)
                    }
                }
                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Another language or another site may have it: change them in the Corner's Settings, or try again.")
                    wrapMode: Text.WordWrap
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeLabel
                }
                RowLayout {
                    spacing: Math.round(8 * root.d)
                    IrisButton { emphasized: true; text: Translation.tr("Try again"); onClicked: CornerWatch.retry() }
                    IrisButton { text: Translation.tr("Settings"); onClicked: CornerState.place = "settings" }
                    IrisButton { text: Translation.tr("Close"); onClicked: { CornerWatch.error = ""; root.dismissed() } }
                }
            }
        }
    }
}
