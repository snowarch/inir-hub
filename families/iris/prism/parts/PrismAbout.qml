pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.iris.components
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls
import qs.modules.iris.prism.fx

// About, as the shell's colophon (`.claude/ref/language`, letter-holo): the iNiR mark lit like a holographic letter on
// black, a hairline where its edges bend the light and the ribbon crossing its strokes, a few glints at its corners;
// what this desktop is printed small in mono along the foot, the way the poster prints its day and letter. One press
// copies those facts for an issue. Under it, where to read, ask and look, as keys.
Flickable {
    id: root
    IrisScrollFeel {}
    clip: true
    contentHeight: column.implicitHeight + PrismTheme.dp(40)
    boundsBehavior: Flickable.StopAtBounds

    readonly property string version: versionFile.text().trim()
    readonly property string irisVersion: irisVersionFile.text().trim()
    readonly property string compositor: CompositorService.isUmbriel ? "Umbriel" : CompositorService.niriNative ? "Niri" : SystemInfo.desktopEnvironment
    // The poster's foot, three columns as the poster's credits; a fact the system does not give is left out.
    readonly property var credits: [
        [{ label: Translation.tr("Version"), value: root.version }, { label: "iRiS", value: root.irisVersion },
         { label: Translation.tr("Branch"), value: ShellUpdates.localCommit.length > 0 ? ShellUpdates.currentBranch : "", lit: ShellUpdates.isNonMainBranch }],
        [{ label: Translation.tr("Commit"), value: ShellUpdates.localCommit }, { label: Translation.tr("Compositor"), value: root.compositor }],
        [{ label: Translation.tr("System"), value: SystemInfo.distroName }, { label: Translation.tr("Computer"), value: SystemInfo.hostname }]
    ].map(lines => lines.filter(line => String(line.value ?? "").length > 0 && line.value !== "Unknown"))

    // What an issue asks for, in English whatever the language, so whoever reads the report reads the same words.
    function report(): string {
        return [["iNiR", root.version], ["iRiS", root.irisVersion],
            ["Branch", ShellUpdates.localCommit.length > 0 ? ShellUpdates.currentBranch + " @ " + ShellUpdates.localCommit : ""],
            ["System", SystemInfo.distroName], ["Compositor", root.compositor]]
            .filter(line => String(line[1] ?? "").length > 0).map(line => line.join(" ")).join("\n")
    }

    FileView { id: versionFile; path: Quickshell.shellPath("VERSION") }
    FileView { id: irisVersionFile; path: Quickshell.shellPath("modules/iris/VERSION") }

    Column {
        id: column
        x: PrismTheme.dp(32)
        width: root.width - PrismTheme.dp(64)
        spacing: PrismTheme.dp(28)

        Item {
            id: poster
            width: parent.width
            height: Math.round(Math.max(PrismTheme.dp(320), Math.min(PrismTheme.dp(440), width * 0.48)))

            Rectangle {
                anchors.fill: parent
                radius: PrismTheme.dp(24)
                color: PrismTheme.night
            }

            // The letter: its strokes as a mask, the ribbon through them, and their edges as a hairline the light runs on.
            Item {
                id: letter
                readonly property real size: Math.round(poster.height * 0.54)
                readonly property real u: size / 320
                width: size
                height: size
                x: Math.round((poster.width - size) / 2)
                y: Math.round((poster.height - size) / 2 - PrismTheme.dp(16))

                MarkShape { id: body; anchors.fill: parent; visible: false; layer.enabled: true }
                MarkShape { id: edge; anchors.fill: parent; outline: true; visible: false; layer.enabled: true }
                MarkShape { anchors.fill: parent; outline: true; ink: Qt.rgba(1, 1, 1, 0.16) } // iris-literal: the letter's unlit hairline, on art that is always night

                PrismFlow {
                    id: through
                    anchors.fill: parent
                    tint: "holo"
                    dark: true
                    seed: 4.2
                    centre: Qt.point(0.42, 0.5)
                    thickness: 0.62
                    visible: false
                    layer.enabled: true
                }
                PrismFlow {
                    id: along
                    anchors.fill: parent
                    tint: "holo"
                    dark: true
                    seed: 1.3
                    centre: Qt.point(0.55, 0.45)
                    thickness: 1.5
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: through
                    maskEnabled: true
                    maskSource: body
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                MultiEffect {
                    anchors.fill: parent
                    source: along
                    maskEnabled: true
                    maskSource: edge
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                // Where the light catches: the leg's shoulder, the i's top, the fold's foot.
                Glint { x: 80 * letter.u; y: 0; span: PrismTheme.dp(20) }
                Glint { x: 320 * letter.u; y: 118 * letter.u; span: PrismTheme.dp(13) }
                Glint { x: 240 * letter.u; y: 320 * letter.u; span: PrismTheme.dp(16) }
            }

            PrismRound {
                anchors.right: parent.right
                anchors.rightMargin: PrismTheme.dp(14)
                y: PrismTheme.dp(14)
                implicitWidth: PrismTheme.dp(34)
                overArt: true
                smoked: true
                glyph: copied.running ? "check" : "content_copy"
                glyphSize: PrismTheme.dp(16)
                Accessible.name: Translation.tr("Copy")
                onClicked: {
                    Quickshell.clipboardText = root.report()
                    copied.restart()
                }
            }
            PrismText {
                anchors.right: parent.right
                anchors.rightMargin: PrismTheme.dp(56)
                y: PrismTheme.dp(14) + (PrismTheme.dp(34) - height) / 2
                text: Translation.tr("Copied")
                mono: true
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.caption
                opacity: copied.running ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(160); easing.type: Easing.OutCubic } }
            }
            Timer { id: copied; interval: 1600 }

            // The foot: three columns of credits, the last set to the right edge.
            Repeater {
                model: root.credits
                delegate: Column {
                    id: credit
                    required property var modelData
                    required property int index
                    readonly property bool last: credit.index === root.credits.length - 1
                    x: credit.last ? poster.width - PrismTheme.dp(24) - width : credit.index === 0 ? PrismTheme.dp(24) : Math.round(poster.width * 0.34)
                    y: poster.height - PrismTheme.dp(22) - height
                    spacing: PrismTheme.dp(3)
                    Repeater {
                        model: credit.modelData
                        delegate: Row {
                            required property var modelData
                            anchors.right: credit?.last ? parent.right : undefined
                            spacing: PrismTheme.dp(8)
                            PrismText {
                                text: parent.modelData.label
                                mono: true
                                color: PrismTheme.spotInk2
                                font.pixelSize: PrismTheme.caption
                            }
                            PrismText {
                                text: parent.modelData.value
                                mono: true
                                color: parent.modelData.lit ? PrismTheme.palette("holo")[2] : PrismTheme.paper
                                font.pixelSize: PrismTheme.caption
                            }
                        }
                    }
                }
            }
        }

        LinkGroup {
            eyebrow: Translation.tr("Shell")
            title: "iNiR"
            links: [
                { label: Translation.tr("Documentation"), glyph: "menu_book", url: "https://inir.space/docs/" },
                { label: Translation.tr("Report an issue"), glyph: "bug_report", url: "https://github.com/snowarch/inir/issues", shown: "snowarch/inir/issues" },
                { label: Translation.tr("Source code"), glyph: "code", url: "https://github.com/snowarch/inir" }
            ]
        }
        LinkGroup {
            eyebrow: Translation.tr("System")
            title: SystemInfo.distroName
            links: [
                SystemInfo.homeUrl ? { label: Translation.tr("Website"), glyph: "language", url: SystemInfo.homeUrl } : null,
                SystemInfo.documentationUrl ? { label: Translation.tr("Documentation"), glyph: "auto_stories", url: SystemInfo.documentationUrl } : null,
                SystemInfo.supportUrl ? { label: Translation.tr("Help & Support"), glyph: "support", url: SystemInfo.supportUrl } : null,
                SystemInfo.bugReportUrl ? { label: Translation.tr("Report a Bug"), glyph: "bug_report", url: SystemInfo.bugReportUrl } : null
            ].filter(link => link !== null)
        }
    }

    // The mark on its 320 box (InirMark's strokes): filled, it is the mask the ribbon shows through; outlined, the edge.
    component MarkShape: Shape {
        id: mark
        property bool outline: false
        property color ink: "white" // iris-literal: a mask's opaque ink, never seen
        readonly property real u: width / 320
        readonly property real line: PrismTheme.dp(1.5)
        preferredRendererType: Shape.CurveRenderer
        Stroke { mark: mark; at: [[0, 0], [80, 0], [80, 320], [0, 320]] }
        Stroke { mark: mark; at: [[0, 0], [80, 0], [320, 320], [240, 320]] }
        Stroke { mark: mark; at: [[240, 118], [320, 118], [320, 320], [240, 320]] }
        Stroke { mark: mark; at: [[240, 0], [320, 0], [320, 80], [240, 80]] }
    }
    component Stroke: ShapePath {
        id: stroke
        // The MarkShape it draws in (a ShapePath has no parent to ask).
        property var mark: null
        property var at: []
        readonly property real u: (stroke.mark?.width ?? 0) / 320
        readonly property bool outline: Boolean(stroke.mark?.outline)
        fillColor: stroke.outline ? "transparent" : stroke.mark.ink
        strokeColor: stroke.outline ? stroke.mark.ink : "transparent"
        strokeWidth: stroke.outline ? stroke.mark.line : -1
        joinStyle: ShapePath.MiterJoin
        PathPolyline { path: stroke.at.concat([stroke.at[0]]).map(point => Qt.point(point[0] * stroke.u, point[1] * stroke.u)) }
    }

    // A four-pointed glint centred on its point, a soft halo under it.
    component Glint: Item {
        id: glint
        property real span: PrismTheme.dp(16)
        width: 0
        height: 0
        Rectangle {
            x: -width / 2
            y: -height / 2
            width: glint.span * 0.5
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.22) // iris-literal: the glint's halo on art that is always night
        }
        Shape {
            x: -glint.span / 2
            y: -glint.span / 2
            width: glint.span
            height: glint.span
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: PrismTheme.paper
                strokeWidth: -1
                PathPolyline {
                    path: {
                        const h = glint.span / 2, w = glint.span * 0.07
                        return [Qt.point(h, 0), Qt.point(h + w, h - w), Qt.point(glint.span, h), Qt.point(h + w, h + w),
                            Qt.point(h, glint.span), Qt.point(h - w, h + w), Qt.point(0, h), Qt.point(h - w, h - w), Qt.point(h, 0)]
                    }
                }
            }
        }
    }

    // Where to go next for one maker, as keys: the place's mark, its name, the address it opens.
    component LinkGroup: Column {
        id: group
        property string eyebrow: ""
        property string title: ""
        property var links: []
        width: column.width
        visible: group.links.length > 0
        spacing: PrismTheme.dp(12)
        PrismHeading {
            width: parent.width
            eyebrow: group.eyebrow
            title: group.title
            titleSize: PrismTheme.head
        }
        Flow {
            id: keys
            width: parent.width
            spacing: PrismTheme.dp(8)
            // All on one line when they fit; else in even rows, never one key left alone under the others.
            readonly property int fits: Math.max(2, Math.floor((width + spacing) / (PrismTheme.dp(150) + spacing)))
            readonly property int columns: group.links.length <= keys.fits ? group.links.length : group.links.length % 2 === 0 ? 2 : keys.fits
            readonly property real keyWidth: Math.floor((width - (columns - 1) * spacing) / columns)
            Repeater {
                model: group.links
                delegate: Item {
                    id: link
                    required property var modelData
                    readonly property string host: link.modelData.shown ?? String(link.modelData.url).replace(/^https?:\/\//, "").replace(/\/$/, "")
                    width: keys.keyWidth
                    height: PrismTheme.dp(84)
                    PrismKey {
                        anchors.fill: parent
                        radius: PrismTheme.dp(16)
                        face: PrismTheme.keyQuiet
                        hovered: press.containsMouse
                        down: press.pressed
                        PrismGlyph {
                            x: PrismTheme.dp(14)
                            y: PrismTheme.dp(12)
                            text: link.modelData.glyph
                            iconSize: PrismTheme.dp(20)
                            color: PrismTheme.ink
                        }
                        PrismGlyph {
                            x: parent.width - PrismTheme.dp(12) - width
                            y: PrismTheme.dp(12)
                            text: "north_east"
                            iconSize: PrismTheme.dp(16)
                            color: press.containsMouse ? PrismTheme.ink : PrismTheme.ink3
                        }
                        Column {
                            x: PrismTheme.dp(14)
                            width: parent.width - PrismTheme.dp(28)
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: PrismTheme.dp(11)
                            PrismText {
                                width: parent.width
                                text: link.modelData.label
                                elide: Text.ElideRight
                                font.pixelSize: PrismTheme.small
                                font.weight: Font.Bold
                            }
                            PrismText {
                                width: parent.width
                                text: link.host
                                elide: Text.ElideMiddle
                                mono: true
                                color: PrismTheme.ink3
                                font.pixelSize: PrismTheme.caption - 1
                            }
                        }
                    }
                    MouseArea {
                        id: press
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Link
                        Accessible.name: link.modelData.label
                        onClicked: Qt.openUrlExternally(link.modelData.url)
                    }
                }
            }
        }
    }
}
