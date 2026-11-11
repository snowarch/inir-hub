pragma ComponentBehavior: Bound

// The glyph wallpaper's options (`background.effects.glyphs`): what it shows, its look chosen from live samples, and
// behind "Adjust this look" every option of GlyphArt.js, drawn from that list.

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.kit
import "root:modules/common/widgets/GlyphArt.js" as Glyphs

ColumnLayout {
    id: root

    readonly property string base: "background.effects.glyphs."
    readonly property var held: Config.options?.background?.effects?.glyphs ?? ({})
    readonly property var values: Glyphs.settings(key => root.held[key])
    readonly property string source: String(root.held.source ?? "wallpaper")
    property bool adjusting: false
    readonly property var icons: ({ "Characters": "text_fields", "Colour": "palette", "Screen": "tv", "Subject": "content_cut", "Motion": "animation" })

    function write(key: string, value: var): void {
        Config.setNestedValue(root.base + key, value)
    }

    spacing: 8

    ContentSubsection {
        title: Translation.tr("Shows")
        ConfigSelectionArray {
            currentValue: root.source
            options: [{ displayName: Translation.tr("Your wallpaper"), icon: "image", value: "wallpaper" }]
                .concat(Glyphs.subjects().map(entry => ({ displayName: Translation.tr(entry.label), value: entry.value })))
                .concat([{ displayName: Translation.tr("A word"), icon: "title", value: "word" }])
            onSelected: newValue => root.write("source", newValue)
        }
        MaterialTextField {
            Layout.fillWidth: true
            visible: root.source === "word"
            placeholderText: Translation.tr("A word, | for a new line")
            text: String(root.held.word ?? "")
            onEditingFinished: root.write("word", text)
        }
    }

    ContentSubsection {
        title: Translation.tr("Look")
        GlyphLookGrid {
            Layout.fillWidth: true
            current: String(root.held.look ?? "signal")
            sample: Wallpapers.effectiveWallpaperUrl
            theme: [Qt.darker(Appearance.colors.colPrimary, 2.2), Appearance.colors.colPrimary,
                Qt.lighter(Appearance.colors.colPrimary, 1.7), Appearance.colors.colTertiary]
            textColor: Appearance.colors.colOnLayer1
            ringColor: Appearance.colors.colPrimary
            chipRadius: Appearance.rounding.small
            fontFamily: Appearance.font.family.main
            fontPixelSize: Appearance.font.pixelSize.small
            translate: text => Translation.tr(text)
            onPicked: look => Config.setNestedValues(Glyphs.lookWrites(root.base, look))
        }
    }

    SettingsSwitch {
        buttonIcon: "tune"
        text: Translation.tr("Adjust this look")
        checked: root.adjusting
        onCheckedChanged: root.adjusting = checked
    }

    Repeater {
        model: root.adjusting ? Glyphs.GROUPS : []
        delegate: ContentSubsection {
            id: group
            required property string modelData
            title: Translation.tr(group.modelData)

            Repeater {
                model: Glyphs.OPTIONS.filter(spec => spec.group === group.modelData)
                delegate: Loader {
                    id: row
                    required property var modelData
                    readonly property var spec: row.modelData
                    readonly property var value: root.values[row.spec.key]
                    Layout.fillWidth: true
                    visible: Glyphs.shown(row.spec, key => root.values[key])
                    active: visible
                    sourceComponent: row.spec.kind === "switch" ? switchRow : row.spec.kind === "range" ? rangeRow
                        : row.spec.kind === "choice" ? choiceRow : row.spec.kind === "colour" ? colourRow : textRow

                    Component {
                        id: switchRow
                        SettingsSwitch {
                            width: row.width
                            buttonIcon: root.icons[row.spec.group]
                            text: Translation.tr(row.spec.label)
                            checked: row.value
                            onCheckedChanged: root.write(row.spec.key, checked)
                        }
                    }
                    Component {
                        id: rangeRow
                        ConfigSpinBox {
                            width: row.width
                            icon: root.icons[row.spec.group]
                            text: Translation.tr(row.spec.label)
                            unit: row.spec.unit
                            value: row.value
                            from: row.spec.min
                            to: row.spec.max
                            stepSize: row.spec.step
                            onValueModified: root.write(row.spec.key, value)
                        }
                    }
                    Component {
                        id: choiceRow
                        ColumnLayout {
                            width: row.width
                            spacing: 4
                            StyledText {
                                text: Translation.tr(row.spec.label)
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.small
                            }
                            ConfigSelectionArray {
                                currentValue: row.value
                                options: row.spec.choices.map(choice => ({ displayName: Translation.tr(choice[1]), value: choice[0] }))
                                onSelected: newValue => root.write(row.spec.key, newValue)
                            }
                        }
                    }
                    Component {
                        id: colourRow
                        ColorPickerRow {
                            width: row.width
                            label: Translation.tr(row.spec.label)
                            colorKey: row.spec.key
                            configPath: root.base + row.spec.key
                            currentColor: row.value
                        }
                    }
                    Component {
                        id: textRow
                        MaterialTextField {
                            width: row.width
                            placeholderText: Translation.tr(row.spec.label)
                            text: String(row.value)
                            onEditingFinished: root.write(row.spec.key, text)
                        }
                    }
                }
            }
        }
    }
}
