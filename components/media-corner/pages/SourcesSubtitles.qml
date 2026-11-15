pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/subtitles.js" as Subtitles

// Sources › Subtitles: which language Watch preselects, the fallback, and an OpenSubtitles account of the person's own.
SourcesCard {
    id: sub
    eyebrow: Translation.tr("Watch")
    title: Translation.tr("Subtitles")
    readonly property var languages: [
        { value: "eng", label: "English (eng)" }, { value: "spa", label: "Español (spa)" },
        { value: "por", label: "Português (por)" }, { value: "fra", label: "Français (fra)" },
        { value: "deu", label: "Deutsch (deu)" }, { value: "ita", label: "Italiano (ita)" },
        { value: "jpn", label: "日本語 (jpn)" }, { value: "ko", label: "한국어 (ko)" },
        { value: "zh", label: "中文 (zh)" }, { value: "ar", label: "العربية (ar)" },
        { value: "ru", label: "Русский (ru)" }, { value: "uk", label: "Українська (uk)" },
        { value: "hi", label: "हिन्दी (hi)" }, { value: "id", label: "Bahasa Indonesia (id)" },
        { value: "tr", label: "Türkçe (tr)" }
    ]

    component LanguageChoice: ColumnLayout {
        id: languageChoice
        required property string optionName
        required property string heading
        property bool optional: false
        property bool editingCustom: false
        readonly property string value: String(CornerState.options[optionName] ?? "")
        readonly property string selectedValue: sub.languages.find(item => Subtitles.languageCode(item.value) === Subtitles.languageCode(value))?.value ?? value
        readonly property bool known: sub.languages.some(item => item.value === selectedValue)
        Layout.fillWidth: true
        RowLayout {
            Layout.fillWidth: true
            IrisText { Layout.fillWidth: true; text: languageChoice.heading; wrapMode: Text.WordWrap }
            IrisPopupButton {
                accessibleName: languageChoice.heading
                current: languageChoice.selectedValue
                otherText: Translation.tr("Custom: %1").arg(languageChoice.value)
                options: (languageChoice.optional ? [{ value: "", label: Translation.tr("None") }] : []).concat(sub.languages, [{ value: "custom", label: Translation.tr("Custom code") }])
                onPicked: value => {
                    if (value === "custom") languageChoice.editingCustom = true
                    else { languageChoice.editingCustom = false; CornerState.set(languageChoice.optionName, value) }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: languageChoice.editingCustom || (languageChoice.value.length > 0 && !languageChoice.known)
            IrisField {
                id: customLanguage
                Layout.fillWidth: true
                text: languageChoice.value
                placeholderText: Translation.tr("ISO language code")
                Accessible.name: languageChoice.heading + ": " + Translation.tr("ISO language code")
            }
            IrisButton {
                text: Translation.tr("Save")
                enabled: /^[a-zA-Z]{2,3}$/.test(customLanguage.text.trim())
                onClicked: { CornerState.set(languageChoice.optionName, customLanguage.text.trim().toLowerCase()); languageChoice.editingCustom = false }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        IrisText { Layout.fillWidth: true; text: Translation.tr("Subtitle selection"); wrapMode: Text.WordWrap }
        IrisPopupButton {
            accessibleName: Translation.tr("Subtitle selection")
            current: CornerState.options.subtitleAutoSelect
            options: [{ value: true, label: Translation.tr("Select preferred language") }, { value: false, label: Translation.tr("Leave it to me") }]
            onPicked: value => CornerState.set("subtitleAutoSelect", value)
        }
    }
    LanguageChoice { optionName: "subtitleLanguage"; heading: Translation.tr("Preferred subtitle language") }
    LanguageChoice { optionName: "subtitleFallbackLanguage"; heading: Translation.tr("Fallback subtitle language"); optional: true }

    RowLayout {
        Layout.fillWidth: true
        IrisField {
            id: subtitleKey
            Layout.fillWidth: true
            placeholderText: Translation.tr("OpenSubtitles API key (optional)")
            echoMode: TextInput.Password
            text: CornerState.options.subtitleApiKey
        }
        IrisButton {
            text: Translation.tr("Save")
            onClicked: CornerState.saveApiKey(subtitleKey.text.trim())
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: !CornerSubtitles.authenticated
        IrisField { id: subtitleUser; Layout.fillWidth: true; placeholderText: Translation.tr("OpenSubtitles username") }
        IrisField { id: subtitlePassword; Layout.fillWidth: true; placeholderText: Translation.tr("Password"); echoMode: TextInput.Password }
        IrisButton {
            text: Translation.tr("Sign in")
            enabled: subtitleUser.text.trim().length > 0 && subtitlePassword.text.length > 0 && CornerState.options.subtitleApiKey.length > 0
            onClicked: {
                CornerSubtitles.login(subtitleUser.text.trim(), subtitlePassword.text)
                subtitlePassword.text = ""
            }
        }
    }
    IrisText {
        Layout.fillWidth: true
        visible: CornerSubtitles.authenticated || CornerSubtitles.loginError.length > 0
        text: CornerSubtitles.authenticated ? Translation.tr("Signed in to OpenSubtitles") : CornerSubtitles.loginError
        color: CornerSubtitles.authenticated ? IrisStyle.textSecondary : IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    IrisButton {
        visible: CornerSubtitles.authenticated
        text: Translation.tr("Sign out")
        quiet: true
        onClicked: CornerSubtitles.signOut()
    }
}
