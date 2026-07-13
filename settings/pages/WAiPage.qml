pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.waffle.looks
import qs.modules.waffle.settings

/**
 * AI settings page (waffle family). ii mirror: modules/settings/AiConfig.qml —
 * keep both in sync; every control here writes the same config keys.
 *
 * Registered in waffleSettings.qml pages[] (index 15 — waffle indices are
 * positional, so new pages are appended at the END) and in
 * WSettingsContent.qml's searchIndex with pageIndex 15.
 *
 * Known difference from ii: the system prompt is a single-line field here.
 * waffle has no multi-line settings input, and inventing one for a single
 * consumer was not worth the shared-component risk.
 */
WSettingsPage {
    id: root
    settingsPageIndex: 15
    pageTitle: Translation.tr("AI")
    pageIcon: "wand"
    pageDescription: Translation.tr("Providers, models, behavior, voice input")

    Component.onCompleted: Ai.ensureInitialized()

    readonly property bool hasModel: (Ai.getModel() ?? null) !== null
    readonly property bool hasLocalModel: Ai.modelList.some(m => (Ai.models[m]?.endpoint ?? "").includes("localhost"))

    // ── Get started ──────────────────────────────────────────────────────
    WSettingsCard {
        title: Translation.tr("Get started")
        icon: "flash-on"

        WSettingsInfoBar {
            severity: root.hasModel ? WSettingsInfoBar.Severity.Success : WSettingsInfoBar.Severity.Warning
            message: root.hasModel
                ? Translation.tr("Active model: %1").arg(Ai.getModel().name)
                : Translation.tr("No model selected. Pick one from the model selector in the chat sidebar, or add a provider below.")
        }

        WSettingsInfoBar {
            severity: Ai.currentModelHasApiKey ? WSettingsInfoBar.Severity.Success : WSettingsInfoBar.Severity.Warning
            message: Ai.currentModelHasApiKey
                ? Translation.tr("API key ready for the active model")
                : Translation.tr("The active model needs an API key. Type /key YOUR_KEY in the chat, or re-add the provider below with its key.")
        }

        WSettingsInfoBar {
            severity: root.hasLocalModel ? WSettingsInfoBar.Severity.Success : WSettingsInfoBar.Severity.Info
            message: root.hasLocalModel
                ? Translation.tr("Local models detected (Ollama)")
                : Translation.tr("No local models. Install Ollama and pull a model to chat without any account or key.")
        }

        WText {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            wrapMode: Text.Wrap
            text: Translation.tr("Two ways to use the assistant: run models locally with Ollama (private, free, no key), or connect an online provider below — several have free tiers.")
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
        }
    }

    // ── Providers & models ───────────────────────────────────────────────
    WSettingsCard {
        id: providersCard
        title: Translation.tr("Providers & models")
        icon: "apps"

        readonly property var extraModels: Config.options?.ai?.extraModels ?? []
        readonly property var formatLabels: ({
            "openai": "OpenAI",
            "gemini": "Gemini",
            "mistral": "Mistral",
            "anthropic": "Anthropic",
            "openai-response": "Responses"
        })

        function openForm(preset, editIndex) {
            providerForm.editingIndex = editIndex ?? -1
            providerNameInput.text = preset?.name ?? ""
            providerEndpointInput.text = preset?.endpoint ?? ""
            providerModelInput.text = preset?.model ?? ""
            providerForm.selectedFormat = preset?.api_format ?? "openai"
            providerApiKeyInput.text = ""
            providerForm.expanded = true
        }

        function closeForm() {
            providerForm.expanded = false
            providerForm.editingIndex = -1
            providerNameInput.text = ""
            providerEndpointInput.text = ""
            providerModelInput.text = ""
            providerApiKeyInput.text = ""
            providerForm.selectedFormat = "openai"
        }

        WText {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            wrapMode: Text.Wrap
            text: Translation.tr("Quick add — popular providers (free tiers available)")
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
        }

        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 6

            Repeater {
                model: AiProviderPresets.presets

                delegate: WButton {
                    id: presetChip
                    required property var modelData
                    readonly property var preset: presetChip.modelData
                    readonly property bool alreadyAdded: providersCard.extraModels.some(m => (m?.endpoint ?? "") === preset.endpoint)

                    implicitWidth: presetChipRow.implicitWidth + 20
                    implicitHeight: 32
                    colBackground: preset.local
                        ? ColorUtils.transparentize(Looks.colors.accent, 0.88)
                        : Looks.colors.bg1
                    onClicked: providersCard.openForm(presetChip.preset, -1)

                    contentItem: RowLayout {
                        id: presetChipRow
                        anchors.centerIn: parent
                        spacing: 6

                        CustomIcon {
                            width: Looks.font.pixelSize.large
                            height: Looks.font.pixelSize.large
                            source: presetChip.preset.icon
                            colorize: true
                            color: presetChip.preset.local ? Looks.colors.accent : Looks.colors.fg
                        }
                        WText {
                            text: presetChip.preset.name
                            font.pixelSize: Looks.font.pixelSize.small
                            color: presetChip.preset.local ? Looks.colors.accent : Looks.colors.fg
                        }
                        FluentIcon {
                            visible: presetChip.alreadyAdded
                            icon: "checkmark"
                            implicitSize: Looks.font.pixelSize.normal
                            color: Looks.colors.accent
                        }
                    }

                    WToolTip {
                        visible: presetChip.hovered
                        text: presetChip.preset.description
                            + (presetChip.preset.requiresKey
                                ? "\n\n" + Translation.tr("Get a key: ") + presetChip.preset.keyGetLink
                                : "")
                    }
                }
            }
        }

        // ── Configured providers ─────────────────────────────────────────
        Repeater {
            model: providersCard.extraModels

            delegate: RowLayout {
                id: providerRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    WText {
                        Layout.fillWidth: true
                        text: providerRow.modelData?.name ?? providerRow.modelData?.model ?? Translation.tr("Unnamed")
                        font.pixelSize: Looks.font.pixelSize.normal
                        color: Looks.colors.fg
                        elide: Text.ElideRight
                    }
                    WText {
                        Layout.fillWidth: true
                        text: (providersCard.formatLabels[providerRow.modelData?.api_format] ?? "OpenAI")
                            + " · " + (providerRow.modelData?.model ?? "")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.subfg
                        elide: Text.ElideMiddle
                    }
                }

                WButton {
                    id: editProviderButton
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: providersCard.openForm(providerRow.modelData, providerRow.index)
                    contentItem: FluentIcon {
                        anchors.centerIn: parent
                        icon: "settings"
                        implicitSize: 16
                        color: Looks.colors.subfg
                    }
                    WToolTip {
                        visible: editProviderButton.hovered
                        text: Translation.tr("Edit")
                    }
                }

                WButton {
                    id: removeProviderButton
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: {
                        let models = [...providersCard.extraModels]
                        models.splice(providerRow.index, 1)
                        Config.setNestedValue("ai.extraModels", models)
                    }
                    contentItem: FluentIcon {
                        anchors.centerIn: parent
                        icon: "delete"
                        implicitSize: 16
                        color: Looks.colors.subfg
                    }
                    WToolTip {
                        visible: removeProviderButton.hovered
                        text: Translation.tr("Remove")
                    }
                }
            }
        }

        WText {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            visible: providersCard.extraModels.length === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: Translation.tr("No providers yet. Add one to use the chat sidebar — local models via Ollama and free OpenRouter models are loaded automatically.")
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
        }

        // ── Add / edit form ──────────────────────────────────────────────
        WSettingsButton {
            visible: !providerForm.expanded
            label: Translation.tr("Add AI provider")
            description: Translation.tr("Any OpenAI, Gemini or Anthropic compatible endpoint")
            icon: "add"
            buttonText: Translation.tr("Add")
            buttonIcon: "add"
            accent: true
            onButtonClicked: providersCard.openForm(null, -1)
        }

        ColumnLayout {
            id: providerForm
            Layout.fillWidth: true
            spacing: 4

            property bool expanded: false
            property int editingIndex: -1
            property string selectedFormat: "openai"

            visible: expanded

            WSettingsTextField {
                id: providerNameInput
                label: Translation.tr("Provider name")
                icon: "info"
                placeholderText: Translation.tr("e.g. My Claude Proxy")
                onTextEdited: newText => providerNameInput.text = newText
            }

            WSettingsTextField {
                id: providerEndpointInput
                label: Translation.tr("API endpoint URL")
                icon: "globe-search"
                placeholderText: "https://api.openai.com/v1/chat/completions"
                onTextEdited: newText => {
                    providerEndpointInput.text = newText
                    // Same auto-detection as the ii page: the format follows the
                    // endpoint unless the user picks one explicitly below.
                    const url = newText.toLowerCase()
                    if (url.includes("generativelanguage.googleapis.com"))
                        providerForm.selectedFormat = "gemini"
                    else if (url.includes("api.anthropic.com") || url.includes("/v1/messages"))
                        providerForm.selectedFormat = "anthropic"
                    else if (url.includes("api.openai.com") || url.includes("/v1/chat/completions"))
                        providerForm.selectedFormat = "openai"
                }
            }

            WSettingsTextField {
                id: providerModelInput
                label: Translation.tr("Model code")
                icon: "apps"
                placeholderText: "gpt-4.1"
                onTextEdited: newText => providerModelInput.text = newText
            }

            WSettingsTextField {
                id: providerApiKeyInput
                label: Translation.tr("API key (optional)")
                icon: "key"
                description: Translation.tr("Stored in the system keyring, never in config.json")
                placeholderText: "sk-..."
                onTextEdited: newText => providerApiKeyInput.text = newText
            }

            WSettingsChoiceGroup {
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                columns: 4
                currentValue: providerForm.selectedFormat
                onSelected: newValue => providerForm.selectedFormat = newValue
                options: [
                    { label: "OpenAI", value: "openai" },
                    { label: "Gemini", value: "gemini" },
                    { label: "Anthropic", value: "anthropic" },
                    { label: Translation.tr("Responses"), value: "openai-response" }
                ]
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 4
                spacing: 8

                Item { Layout.fillWidth: true }

                WButton {
                    implicitWidth: 90
                    implicitHeight: 32
                    onClicked: providersCard.closeForm()
                    contentItem: WText {
                        anchors.centerIn: parent
                        text: Translation.tr("Cancel")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.fg
                    }
                }

                WButton {
                    implicitWidth: 90
                    implicitHeight: 32
                    colBackground: Looks.colors.accent
                    colBackgroundHover: Looks.colors.accentHover
                    enabled: providerEndpointInput.text.trim() !== "" && providerModelInput.text.trim() !== ""
                    onClicked: {
                        const modelCode = providerModelInput.text.trim()
                        const apiKey = providerApiKeyInput.text.trim()
                        const keyId = modelCode.toLowerCase().replace(/[:\/ ]/g, "-")

                        const entry = {
                            name: providerNameInput.text.trim() || modelCode,
                            endpoint: providerEndpointInput.text.trim(),
                            model: modelCode,
                            api_format: providerForm.selectedFormat,
                            requires_key: apiKey.length > 0,
                            key_id: keyId,
                        }

                        let models = [...providersCard.extraModels]
                        if (providerForm.editingIndex >= 0) {
                            // Keep any field the form doesn't own (the ii page does
                            // the same) so editing never silently drops config.
                            const orig = models[providerForm.editingIndex]
                            if (orig) {
                                for (let k in orig) {
                                    if (!(k in entry) && k !== "index") entry[k] = orig[k]
                                }
                            }
                            models[providerForm.editingIndex] = entry
                        } else {
                            models.push(entry)
                        }
                        Config.setNestedValue("ai.extraModels", models)

                        if (apiKey.length > 0)
                            KeyringStorage.setNestedField(["apiKeys", keyId], apiKey)

                        providersCard.closeForm()
                    }
                    contentItem: WText {
                        anchors.centerIn: parent
                        text: providerForm.editingIndex >= 0 ? Translation.tr("Save") : Translation.tr("Add")
                        font.pixelSize: Looks.font.pixelSize.small
                        color: Looks.colors.accentFg
                    }
                }
            }
        }
    }

    // ── Assistant behavior ───────────────────────────────────────────────
    WSettingsCard {
        title: Translation.tr("Assistant behavior")
        icon: "wand"

        WSettingsTextField {
            id: systemPromptInput
            label: Translation.tr("AI system prompt")
            icon: "info"
            description: Translation.tr("Custom instructions the assistant always receives")
            placeholderText: Translation.tr("System prompt")
            text: Config.options?.ai?.systemPrompt ?? ""
            onTextEdited: newText => {
                systemPromptInput.text = newText
                Config.setNestedValue("ai.systemPrompt", newText)
            }
        }

        WSettingsRow {
            label: Translation.tr("AI tools")
            icon: "settings-cog-multiple"
            description: Translation.tr("What the assistant can do. Search is only available on Gemini models; Functions lets it read and edit the shell config")
        }

        WSettingsChoiceGroup {
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            columns: 3
            currentValue: Config.options?.ai?.tool ?? "search"
            onSelected: newValue => Config.setNestedValue("ai.tool", newValue)
            options: [
                { label: Translation.tr("Functions"), value: "functions" },
                { label: Translation.tr("Search"), value: "search" },
                { label: Translation.tr("None"), value: "none" }
            ]
        }

        WSettingsSlider {
            label: Translation.tr("Temperature")
            icon: "flash-on"
            description: Translation.tr("Higher is more creative, lower is more predictable. Default 0.5")
            from: 0
            to: 1
            stepSize: 0.05
            displayDecimals: 2
            value: Persistent.states?.ai?.temperature ?? 0.5
            onMoved: {
                if (Persistent.states?.ai)
                    Persistent.states.ai.temperature = Math.round(value * 100) / 100
            }
        }
    }

    // ── Privacy ──────────────────────────────────────────────────────────
    WSettingsCard {
        title: Translation.tr("Privacy & policy")
        icon: "shield"

        WSettingsRow {
            label: Translation.tr("Allow AI features")
            icon: "shield"
            description: Translation.tr("Local only restricts the assistant to models running on this machine (Ollama)")
        }

        WSettingsChoiceGroup {
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            columns: 3
            currentValue: Config.options?.policies?.ai ?? 0
            onSelected: newValue => Config.setNestedValue("policies.ai", newValue)
            options: [
                { label: Translation.tr("No"), value: 0 },
                { label: Translation.tr("Yes"), value: 1 },
                { label: Translation.tr("Local only"), value: 2 }
            ]
        }
    }

    // ── Voice input ──────────────────────────────────────────────────────
    WSettingsCard {
        title: Translation.tr("Voice input")
        icon: "mic"

        WSettingsSpinBox {
            id: voiceDurationSpin
            // Without the guard the spin box writes its own default over the
            // user's value while the page is still being created.
            property bool _ready: false
            Component.onCompleted: _ready = true

            label: Translation.tr("Voice input")
            icon: "timer"
            description: Translation.tr("Max recording length for the chat mic button and voice search")
            suffix: Translation.tr(" s")
            from: 3
            to: 60
            stepSize: 1
            value: Config.options?.voiceSearch?.duration ?? 8
            onValueChanged: {
                if (voiceDurationSpin._ready)
                    Config.setNestedValue("voiceSearch.duration", value)
            }
        }

        WText {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            wrapMode: Text.Wrap
            text: Translation.tr("Transcription uses Gemini, so a Gemini API key must be set — add the Gemini provider above with its key, or type /key in the chat with a Gemini model selected.")
            font.pixelSize: Looks.font.pixelSize.small
            color: Looks.colors.subfg
        }
    }
}
