pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks

// One shell event's sound as a Windows 11 settings row: hear it, then pick the pack's, a system theme sound or a file.
// Writes sounds.events.<eventId> as the Audio service reads it ("" = the pack's, a bare name, or an absolute path).
WSettingsRow {
    id: root

    property string eventId: ""

    readonly property string value: Config.options?.sounds?.events?.[root.eventId] ?? ""
    readonly property bool isFile: root.value.startsWith("/") || root.value.startsWith("file://")
    // The pack's sound, the theme's sounds, and last an entry that opens the file dialog. A file, or a name the
    // theme no longer has, stays listed after the default so the box always shows what plays.
    readonly property var options: {
        const list = [{ value: "", displayName: Audio.eventDefaultLabel(root.eventId) }]
        if (root.value !== "" && !Audio.themeSounds.includes(root.value))
            list.push({ value: root.value, displayName: root.isFile ? root.value.split("/").pop() : root.value })
        for (const name of Audio.themeSounds)
            list.push({ value: name, displayName: name })
        list.push({ value: "", displayName: Translation.tr("Choose a file") + "…" })
        return list
    }
    function indexOfValue(): int {
        return Math.max(0, root.options.findIndex(option => option.value === root.value))
    }
    function setValue(value: string): void {
        Config.setNestedValue("sounds.events." + root.eventId, value)
    }

    control: Component {
        RowLayout {
            spacing: Looks.dp(8)

            WButton {
                id: playButton
                implicitWidth: Looks.dp(36)
                implicitHeight: Looks.dp(32)
                colBackground: Looks.settings.tile
                colBackgroundHover: Looks.settings.tileHover
                colBackgroundActive: Looks.settings.tilePressed
                Accessible.name: Translation.tr("Preview")
                contentItem: FluentIcon {
                    anchors.centerIn: parent
                    icon: "play"
                    implicitSize: Looks.dp(16)
                    color: Looks.colors.fg
                }
                onClicked: Audio.previewEvent(root.eventId, "")
                WToolTip { text: Translation.tr("Preview") }
            }

            WComboBox {
                id: combo
                // one width down the whole list, so the boxes line up as a column
                implicitWidth: Looks.dp(260)
                model: root.options
                currentIndex: root.indexOfValue()
                onActivated: index => {
                    if (index === root.options.length - 1)
                        fileDialog.open()
                    else if (index >= 0 && index < root.options.length)
                        root.setValue(root.options[index].value)
                    // the box follows the config again, also when the dialog is cancelled
                    combo.currentIndex = Qt.binding(() => root.indexOfValue())
                }
            }
        }
    }

    FilePickerDialog {
        id: fileDialog
        title: Translation.tr("Choose a file")
        nameFilters: [
            Translation.tr("Sound files") + " (*.oga *.ogg *.wav *.flac *.mp3)",
            Translation.tr("All files") + " (*)"
        ]
        onAccepted: root.setValue(FileUtils.trimFileProtocol(String(selectedFile)))
    }
}
