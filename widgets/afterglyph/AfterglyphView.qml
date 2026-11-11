pragma ComponentBehavior: Bound

// The picture as glyphs: every face of the widget draws through this one item and only sizes and labels it.
//
// It chooses the picture (a cover, the wallpaper, a file or a word) and hands it to the shell's GlyphArt, which
// draws it on the GPU. At rest nothing runs: the only animation is the grow-in when the picture changes, and a GIF
// plays only while `live`.

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "afterglyph.js" as Afterglyph

Item {
    id: root

    // What the face sets.
    property string source: "auto"      // auto | music | wallpaper | file | word
    property string file: ""
    property string word: ""
    property string lookName: "signal"
    property int glyphPixel: 1          // screen px per glyph pixel
    property real glowAmount: 1
    property bool growIn: true
    property bool plate: true
    property real radius: 0
    property color accent: "white"      // literal: replaced by the face's accent
    // The face is on screen and may move.
    property bool live: true

    // What the face reads.
    readonly property var chosen: Afterglyph.resolve(root.source, root.cover, Wallpapers.effectiveWallpaperUrl,
        root.file, root.word, Directories.homePath)
    readonly property bool fromMusic: root.chosen.kind === "picture" && root.cover.length > 0 && root.chosen.url === root.cover
    readonly property string title: root.fromMusic ? MediaArtwork.title : ""
    readonly property string artist: root.fromMusic ? MediaArtwork.artist : ""
    readonly property bool failed: root.chosen.kind === "picture" && root.shown.status === Image.Error
    readonly property bool loading: root.chosen.kind === "picture" && root.shown.status === Image.Loading
    readonly property bool drawn: root.chosen.kind === "word" || (root.chosen.kind === "picture" && root.shown.status === Image.Ready)
    // Width over height of what is drawn, for a face that sizes itself to the picture.
    readonly property real aspect: {
        if (root.chosen.kind === "word") return 2.4
        const w = root.shown.implicitWidth, h = root.shown.implicitHeight
        return root.drawn && w > 0 && h > 0 ? Math.max(0.6, Math.min(2.4, w / h)) : 2.4
    }
    readonly property int columns: art.columns
    readonly property int rows: art.rows
    // In words, why there is nothing to draw ("" when there is).
    readonly property string message: {
        if (root.failed) return Translation.tr("This picture could not be opened")
        if (root.loading) return Translation.tr("Reading the picture")
        switch (root.chosen.why) {
        case "music": return Translation.tr("Nothing is playing")
        case "file": return Translation.tr("Choose a picture in this widget's options")
        case "word": return Translation.tr("Write a word in this widget's options")
        case "wallpaper": return Translation.tr("No wallpaper to read")
        default: return ""
        }
    }

    readonly property string cover: MediaArtwork.ready ? MediaArtwork.displaySource : ""
    readonly property bool moving: Afterglyph.animated(root.chosen.url)
    readonly property Image shown: root.moving ? clip : still

    // A new picture grows in from its foot; with motion off it is simply there.
    readonly property string subject: root.chosen.kind === "word" ? "word:" + root.word : root.chosen.url
    onSubjectChanged: {
        if (root.growIn && root.live && root.subject.length > 0) art.appear()
        else art.settle()
    }
    onLiveChanged: if (!root.live) art.settle()

    // The picture GlyphArt reads, four texels a cell; never painted itself.
    Item {
        id: stage
        width: art.columns * 4
        height: art.rows * 4

        Rectangle {
            anchors.fill: parent
            color: "black"      // literal: no light where the picture has none
        }
        Image {
            id: still
            anchors.fill: parent
            readonly property bool wanted: !root.moving && root.chosen.kind === "picture"
            visible: wanted
            source: wanted ? root.chosen.url : ""
            // Decoded small once: a cell reads a few texels, never the 4K original.
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            cache: false
        }
        AnimatedImage {
            id: clip
            anchors.fill: parent
            readonly property bool wanted: root.moving && root.chosen.kind === "picture"
            visible: wanted
            source: wanted ? root.chosen.url : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            cache: false
            playing: root.live && root.visible
        }
        Text {
            anchors.fill: parent
            anchors.margins: Math.round(stage.height * 0.12)
            visible: root.chosen.kind === "word"
            text: root.word
            color: "white"      // literal: the word is the light the glyphs read
            font.family: Appearance.font.family.title
            font.weight: Font.Black
            font.pixelSize: Math.max(8, stage.height)
            fontSizeMode: Text.Fit
            minimumPixelSize: 6
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    GlyphArt {
        id: art
        anchors.fill: parent
        visible: root.chosen.kind !== "none"
        picture: stage
        hidePicture: true
        lookName: root.lookName
        glyphPixel: root.glyphPixel
        glowAmount: root.glowAmount
        plate: root.plate
        radius: root.radius
        accent: root.accent
        shown: root.drawn
    }
}
