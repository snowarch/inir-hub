pragma ComponentBehavior: Bound

// The glyph wallpaper's options (`background.effects.glyphs`) in Waffle's rows: what it shows, its look chosen from
// live samples, and behind "Adjust this look" every option of GlyphArt.js, drawn from that list.

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.settings
import "root:modules/common/widgets/GlyphArt.js" as Glyphs

Column {
    id: root

    readonly property string base: "background.effects.glyphs."
    readonly property var held: Config.options?.background?.effects?.glyphs ?? ({})
    readonly property var values: Glyphs.settings(key => root.held[key])
    readonly property string source: String(root.held.source ?? "wallpaper")
    property bool adjusting: false
    readonly property var icons: ({ "Characters": "text-font", "Colour": "color", "Screen": "desktop", "Subject": "cut", "Motion": "play" })

    function write(key: string, value: var): void {
        Config.setNestedValue(root.base + key, value)
    }

    WSettingsDropdown {
        width: root.width
        label: Translation.tr("Shows")
        icon: "image"
        currentValue: root.source
        options: [{ value: "wallpaper", displayName: Translation.tr("Your wallpaper") }]
            .concat(Glyphs.subjects().map(entry => ({ value: entry.value, displayName: Translation.tr(entry.label) })))
            .concat([{ value: "word", displayName: Translation.tr("A word") }])
        onSelected: value => root.write("source", value)
    }
    WSettingsTextField {
        width: root.width
        visible: root.source === "word"
        label: Translation.tr("Word")
        icon: "text-font"
        placeholderText: Translation.tr("A word, | for a new line")
        text: String(root.held.word ?? "")
        onEditingFinished: newText => root.write("word", newText)
    }

    Item {
        width: root.width
        height: looks.implicitHeight + Looks.dp(28)
        GlyphLookGrid {
            id: looks
            anchors.fill: parent
            anchors.margins: Looks.dp(14)
            current: String(root.held.look ?? "signal")
            sample: Wallpapers.effectiveWallpaperUrl
            theme: [Qt.darker(Looks.colors.accent, 2.2), Looks.colors.accent, Qt.lighter(Looks.colors.accent, 1.7),
                Appearance.colors.colTertiary]
            textColor: Looks.colors.fg
            ringColor: Looks.colors.accent
            chipRadius: Looks.dp(6)
            fontFamily: Looks.font.family.ui
            fontPixelSize: Looks.font.pixelSize.normal
            translate: text => Translation.tr(text)
            onPicked: look => Config.setNestedValues(Glyphs.lookWrites(root.base, look))
        }
    }

    WSettingsSwitch {
        width: root.width
        label: Translation.tr("Adjust this look")
        icon: "options"
        checked: root.adjusting
        onCheckedChanged: root.adjusting = checked
    }

    Repeater {
        model: root.adjusting ? Glyphs.OPTIONS : []
        delegate: Loader {
            id: row
            required property var modelData
            readonly property var spec: row.modelData
            readonly property var value: root.values[row.spec.key]
            width: root.width
            visible: Glyphs.shown(row.spec, key => root.values[key])
            active: visible
            sourceComponent: row.spec.kind === "switch" ? switchRow : row.spec.kind === "range" ? rangeRow
                : row.spec.kind === "choice" ? choiceRow : textRow

            Component {
                id: switchRow
                WSettingsSwitch {
                    width: row.width
                    label: Translation.tr(row.spec.label)
                    icon: root.icons[row.spec.group]
                    checked: row.value
                    onCheckedChanged: root.write(row.spec.key, checked)
                }
            }
            Component {
                id: rangeRow
                WSettingsSpinBox {
                    width: row.width
                    label: Translation.tr(row.spec.label)
                    icon: root.icons[row.spec.group]
                    suffix: row.spec.unit
                    from: row.spec.min
                    to: row.spec.max
                    stepSize: row.spec.step
                    value: row.value
                    onValueChanged: root.write(row.spec.key, value)
                }
            }
            Component {
                id: choiceRow
                WSettingsDropdown {
                    width: row.width
                    label: Translation.tr(row.spec.label)
                    icon: root.icons[row.spec.group]
                    currentValue: row.value
                    options: row.spec.choices.map(choice => ({ value: choice[0], displayName: Translation.tr(choice[1]) }))
                    onSelected: value => root.write(row.spec.key, value)
                }
            }
            Component {
                id: textRow
                // A colour is typed as #rrggbb here.
                WSettingsTextField {
                    width: row.width
                    label: Translation.tr(row.spec.label)
                    icon: root.icons[row.spec.group]
                    placeholderText: row.spec.fallback
                    text: String(row.value)
                    onEditingFinished: newText => {
                        if (row.spec.kind !== "colour" || /^#[0-9a-fA-F]{6}$/.test(newText.trim())) root.write(row.spec.key, newText.trim())
                    }
                }
            }
        }
    }
}
