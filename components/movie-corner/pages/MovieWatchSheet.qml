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
import "../state"

// The Movie Corner's start of watching: over the page, the title's art behind, and one thing at a time — finding
// where it plays, the person's pick, opening the player. A failure stays on the sheet with what to try next.
Item {
    id: root
    signal dismissed()

    readonly property real d: IrisStyle.density
    readonly property var show: CornerWatch.item ?? ({})
    readonly property string title: String(root.show.title ?? "")
    readonly property string art: String(root.show.banner || root.show.imageLarge || root.show.image || "")
    readonly property string cover: String(root.show.imageLarge || root.show.image || "")
    readonly property bool failed: !CornerWatch.busy && CornerWatch.error.length > 0
    readonly property bool playing: CornerWatch.phase === "playing"
    readonly property bool choosing: CornerWatch.phase === "choosing"
    readonly property bool working: CornerWatch.phase === "finding" || CornerWatch.phase === "launching"
    // 0 finding sources, 1 your pick, 2 opening the player.
    readonly property int step: CornerWatch.phase === "launching" ? 2 : root.choosing ? 1 : 0
    readonly property var steps: [Translation.tr("Finding sources"), Translation.tr("Your pick"), Translation.tr("Opening the player")]

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
                        text: "movie"
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
                        visible: text.length > 0
                        text: root.show.kind === "series" ? [Translation.tr("Season %1, episode %2").arg(root.show.season).arg(root.show.episode), String(root.show.episodeTitle ?? "")]
                            .filter(x => x.length > 0).join(" · ") : String(root.show.year ?? "")
                        textFormat: Text.PlainText
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
                    text: root.step === 2 ? Translation.tr("Opening the player…") : Translation.tr("Looking for “%1” on every site").arg(root.title)
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    font.pixelSize: IrisStyle.typeHeadline
                    font.weight: IrisStyle.weight(Font.DemiBold)
                }
                IrisText {
                    Layout.fillWidth: true
                    text: root.step === 2 ? Translation.tr("mpv opens in its own window.")
                        : Translation.tr("Sites are asked together; it can take up to half a minute.")
                    wrapMode: Text.WordWrap
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeLabel
                }
            }

            // The pick: sources as cards, the best first.
            IrisText {
                Layout.fillWidth: true
                visible: root.choosing
                text: Translation.tr("Where to watch it?")
                font.pixelSize: IrisStyle.typeHeadline
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            // A source that would not open, or a pinned site without it: said above the others.
            IrisText {
                Layout.fillWidth: true
                visible: root.choosing && text.length > 0
                text: CornerWatch.error.length > 0 ? CornerWatch.error
                    : CornerWatch.fallbackFrom.length > 0 ? Translation.tr("%1 doesn't have it; these do").arg(CornerWatch.siteName(CornerWatch.fallbackFrom)) : ""
                wrapMode: Text.WordWrap
                color: IrisStyle.danger
                font.pixelSize: IrisStyle.typeLabel
            }
            GridLayout {
                Layout.fillWidth: true
                visible: root.choosing
                columns: body.width > Math.round(520 * root.d) ? 2 : 1
                columnSpacing: Math.round(10 * root.d)
                rowSpacing: Math.round(10 * root.d)
                Repeater {
                    model: root.choosing ? CornerWatch.sources : []
                    MouseArea {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property var s: card.modelData
                        readonly property int height_: Number(card.s.height ?? 0)
                        Layout.fillWidth: true
                        implicitHeight: cardColumn.implicitHeight + Math.round(24 * root.d)
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button
                        Accessible.name: String(card.s.title ?? "")
                        onClicked: { CornerWatch.error = ""; CornerWatch.play(card.s) }
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
                                    text: String(card.s.title ?? "")
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
                                    Accessible.name: Translation.tr("Always start from %1").arg(String(card.s.title ?? ""))
                                    onClicked: {
                                        CornerState.set("source", String(card.s.site ?? "ask"))
                                        CornerWatch.error = ""
                                        CornerWatch.play(card.s)
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
                                text: [card.s.burned ? Translation.tr("subtitles in the picture") : (card.s.subtitles ?? []).length > 0 ? Translation.tr("subtitles you can turn off") : "", String(card.s.name ?? "")]
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
                visible: root.choosing
                text: Translation.tr("The pin plays from that site from now on; the Corner's Settings › Source brings the question back.")
                wrapMode: Text.WordWrap
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
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
                RowLayout {
                    spacing: Math.round(8 * root.d)
                    IrisButton { text: Translation.tr("Back to the Corner"); onClicked: root.dismissed() }
                    IrisButton { text: Translation.tr("Stop"); onClicked: CornerWatch.stop() }
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
