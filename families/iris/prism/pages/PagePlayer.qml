import QtQuick

// Generated from Prism's page plan; labels and details are the catalogued strings of iRiS Settings.
PrismPage {
    pageId: "player"
    name: "Player"
    group: "Desktop"
    glyph: "music_note"
    tint: "red"
    lead: ["iris.player.visualizer.style", "iris.player.bubbleOpens"]
    sections: [
        { title: "Player", rows: [
            {"path": "iris.player.roundCover", "label": "Round album cover", "kind": "switch", "def": false, "glyph": "album"},
            {"path": "iris.player.artworkBackground", "label": "Blurred album background", "kind": "switch", "def": true, "glyph": "blur_on", "detail": "Tints the expanded Island and media cards with the cover."},
            {"path": "iris.player.bubbleOpens", "label": "Media bubble opens", "kind": "choice", "def": "card", "glyph": "open_in_new", "detail": "A card that floats out of the bubble, or the Island's player page.", "choices": [{"label": "Card", "value": "card"}, {"label": "Island", "value": "island"}]}
        ] },
        { title: "Visualizer", rows: [
            {"path": "iris.player.visualizer.style", "label": "Visualizer", "kind": "choice", "def": "capsules", "glyph": "graphic_eq", "detail": "How what plays is drawn on the resting Island, its player page and the Visualizer bubble.", "choices": [{"label": "Capsules", "value": "capsules"}, {"label": "Equalizer", "value": "rise"}, {"label": "Dots", "value": "dots"}, {"label": "Wave", "value": "wave"}, {"label": "Ring", "value": "ring"}]},
            {"path": "iris.player.visualizer.bars", "label": "Bands", "kind": "range", "def": 5, "glyph": "equalizer", "detail": "How many parts of the sound it follows.", "min": 3, "max": 9, "step": 1}
        ] }
    ]
}
