import QtQuick

// One page of Prism: what it is called, where it sits in the sidebar and its rows. Data only; the panel draws it.
// A row: path, label, detail, kind (switch | choice | range | swatch | text), def (its factory value), glyph, and as its
// kind needs: choices, min, max, step, unit, scale, invert; `when` hides it unless another key reads true ("path"),
// false ("!path") or differs from a value ("path!=value").
QtObject {
    property string pageId: ""
    property string name: ""
    property string group: ""
    property string glyph: "circle"
    property string tint: "grey"
    // The hero's first action: run something the page is about ({ label, target, fn } for `inir target fn`).
    property var show: null
    // A page only some machines have ("battery").
    property string needs: ""
    // The rows whose values the hero says in big type.
    property var lead: []
    property var sections: []
}
