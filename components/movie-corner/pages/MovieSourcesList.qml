pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import "../state"

// The Corner's Settings › Sources: each source the engine loaded (a file or a Stremio add-on) with the languages it
// plays, the files that failed and why, a field to add an add-on by its address and the folder for source files.
ColumnLayout {
    id: root

    readonly property real d: IrisStyle.settingsDensity
    spacing: Math.round(6 * root.d)
    Component.onCompleted: CornerWatch.loadSources()

    function languagesOf(source: var): string {
        return Array.from(source.audios ?? []).map(a => CornerWatch.languageName(String(a))).join(", ")
    }

    IrisText {
        Layout.fillWidth: true
        visible: CornerWatch.sourcesKnown && !CornerWatch.hasSources
        text: Translation.tr("No sources yet. Until you add one, a title's page shows where it streams officially (with your TMDB key).")
        wrapMode: Text.WordWrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.subtext
    }
    Repeater {
        model: CornerWatch.sources_
        RowLayout {
            id: line
            required property var modelData
            readonly property bool addon: line.modelData.kind === "stremio"
            Layout.fillWidth: true
            spacing: Math.round(10 * root.d)
            Rectangle {
                Layout.preferredWidth: Math.round(28 * root.d)
                Layout.preferredHeight: Layout.preferredWidth
                radius: IrisStyle.capsule(width)
                color: IrisStyle.fill
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: line.addon ? "extension" : "description"
                    iconSize: Math.round(16 * root.d)
                    color: IrisStyle.subtext
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * root.d)
                IrisText {
                    Layout.fillWidth: true
                    text: String(line.modelData.name || line.modelData.id)
                    textFormat: Text.PlainText
                    font.pixelSize: IrisStyle.typeLabel
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    text: (line.addon ? Translation.tr("Stremio add-on") : Translation.tr("Source file")) + " · " + root.languagesOf(line.modelData)
                    textFormat: Text.PlainText
                    font.pixelSize: IrisStyle.typeFootnote
                    color: IrisStyle.subtext
                    elide: Text.ElideRight
                }
            }
            IrisButton {
                visible: line.addon
                text: Translation.tr("Remove")
                colBackground: IrisStyle.fill
                colBackgroundHover: IrisStyle.fillHover
                onClicked: CornerWatch.removeAddon(String(line.modelData.site) + "/manifest.json")
            }
        }
    }
    Repeater {
        model: CornerWatch.sourceErrors
        IrisText {
            required property var modelData
            Layout.fillWidth: true
            text: Translation.tr("%1 did not load: %2").arg(String(modelData.file)).arg(String(modelData.error))
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            font.pixelSize: IrisStyle.typeFootnote
            color: IrisStyle.subtext
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Math.round(8 * root.d)
        IrisField {
            id: address
            Layout.fillWidth: true
            implicitHeight: Math.round(36 * root.d)
            font.pixelSize: IrisStyle.typeLabel
            placeholderText: Translation.tr("Stremio add-on address (…/manifest.json)")
            onAccepted: { CornerWatch.addAddon(address.text); address.text = "" }
        }
        IrisButton {
            visible: address.text.trim().length > 0
            enabled: !CornerWatch.addonChecking
            text: Translation.tr("Add")
            colBackground: IrisStyle.tintFill(IrisStyle.accent)
            colBackgroundHover: IrisStyle.tintFillHover(IrisStyle.accent)
            foreground: IrisStyle.accent
            onClicked: { CornerWatch.addAddon(address.text); address.text = "" }
        }
        IrisButton {
            text: Translation.tr("Open folder")
            enabled: CornerWatch.sourcesFolder.length > 0
            colBackground: IrisStyle.fill
            colBackgroundHover: IrisStyle.fillHover
            onClicked: CornerWatch.openSourcesFolder()
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: text.length > 0
        text: CornerWatch.addonChecking ? Translation.tr("Checking the add-on…") : CornerWatch.addonNote
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.subtext
    }
    IrisText {
        Layout.fillWidth: true
        text: Translation.tr("Add only sources you have the right to watch from. A source plays in the audio language set when you added it.")
        wrapMode: Text.WordWrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.textTertiary
    }
}
