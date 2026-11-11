pragma ComponentBehavior: Bound

// The subject as glyphs: every face of the widget draws through this one item and only sizes and labels it.
//
// It chooses the subject (a cover, the wallpaper, a file, a word or a built-in one), reads every option the person
// set and hands both to the shell's GlyphArt, which draws on the GPU. It moves only with "Moves" on, while `live`;
// without it a picture is drawn once. A style's values are written by the option row itself (widget.json `sets`).
// The look, its options and the built-in subjects are those of winchxyz/afterglyph (MIT), ported in the base.

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "afterglyph.js" as Afterglyph
import "root:modules/common/widgets/GlyphArt.js" as Glyphs

Item {
    id: root

    // What the face sets.
    property bool plate: true
    property real radius: 0
    // The face's own inks for the "theme" palette: dark, middle, light, stroke.
    property var theme: ["#3b37d6", "#7f8cff", "#e8ebff", "#63e6b4"]
    // The face is on screen and may move.
    property bool live: true

    // The widget's stored options; the fallbacks are widget.json's.
    function read(key: string): var {
        return CustomWidgets.getConfigValue("afterglyph", key, undefined)
    }
    readonly property var own: ({ cell: 9 })
    readonly property var settings: Glyphs.settings(key => root.read(key) ?? root.own[key])
    readonly property string source: String(root.read("source") ?? "auto")
    readonly property string word: String(root.read("word") ?? "iNiR")
    readonly property string look: String(root.read("look") ?? "signal")


    // What the face reads.
    readonly property var demo: Glyphs.demo(root.source)
    readonly property var chosen: Afterglyph.resolve(root.source, root.cover, Wallpapers.effectiveWallpaperUrl,
        String(root.read("file") ?? ""), root.word, Directories.homePath, root.demo !== null)
    readonly property bool fromMusic: root.chosen.kind === "picture" && root.cover.length > 0 && root.chosen.url === root.cover
    readonly property string title: root.fromMusic ? MediaArtwork.title : ""
    readonly property string artist: root.fromMusic ? MediaArtwork.artist : ""
    readonly property bool pictured: root.chosen.kind === "picture"
    readonly property bool failed: root.pictured && root.shown.status === Image.Error
    readonly property bool loading: root.pictured && root.shown.status === Image.Loading
    readonly property bool drawn: root.chosen.kind === "word" || root.chosen.kind === "demo"
        || (root.pictured && root.shown.status === Image.Ready)
    // Width over height of the plate.
    readonly property real aspect: Afterglyph.aspect("auto", root.chosen.kind,
        root.drawn ? root.shown.implicitWidth : 0, root.drawn ? root.shown.implicitHeight : 0)
    readonly property int columns: art.columns
    readonly property int rows: art.rows
    // What a readout prints: the subject's name, and the look with the palette's name.
    readonly property string name: root.demo !== null ? root.demo.name + " · " + root.demo.seed
        : root.chosen.kind === "word" ? root.word.replace(/\|/g, " ").toUpperCase()
        : root.title.length > 0 ? (root.artist.length > 0 ? root.title + "  ·  " + root.artist : root.title) : ""
    readonly property string tag: (art.inks?.label ?? (root.demo !== null ? root.demo.tag : root.look.toUpperCase()))
        + "  " + art.columns + "×" + art.rows
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

    // A new subject comes in with the intro; while the face cannot move it is simply there.
    readonly property string subject: root.chosen.kind + ":" + root.source + root.word + root.chosen.url
    onSubjectChanged: {
        if (root.live && root.chosen.kind !== "none") art.appear()
        else art.settle()
    }
    onLiveChanged: if (!root.live) art.settle()

    // The picture GlyphArt reads, a few texels a cell; never painted itself.
    Item {
        id: stage
        width: art.columns * 3
        height: art.rows * 4

        Image {
            id: still
            anchors.fill: parent
            readonly property bool wanted: !root.moving && root.pictured
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
            readonly property bool wanted: root.moving && root.pictured
            visible: wanted
            source: wanted ? root.chosen.url : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            cache: false
            playing: root.live && root.visible
        }
    }

    GlyphArt {
        id: art
        anchors.fill: parent
        visible: root.chosen.kind !== "none"
        picture: stage
        hidePicture: true
        source: root.chosen.kind === "demo" ? root.source : root.chosen.kind === "word" ? "word" : "picture"
        word: root.word
        settings: root.settings
        theme: root.theme
        plate: root.plate
        radius: root.radius
        shown: root.drawn
        live: root.live
        animated: root.moving
        // The desktop under it redraws far more often than the glyphs change (a video, a clock): it blits its last frame.
        cached: true
        fontFamily: Appearance.font.family.monospace
    }
}
