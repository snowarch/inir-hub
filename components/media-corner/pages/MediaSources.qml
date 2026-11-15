pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../corner"
import "../state"
import "../state/streams.js" as Streams

// The person's sources. It ships none, and what is added here hasn't been read by anyone: the Corner only asks it.
// Then how the Corner looks (SourcesAppearance) and how subtitles are chosen (SourcesSubtitles), each a card.
MediaPage {
    id: root
    spacing: Math.round(14 * root.d)

    CornerHeading { page: true; eyebrow: Translation.tr("Library"); title: Translation.tr("Sources") }

    property string addonError: ""
    property string webError: ""
    property string confirmation: ""
    property var manifestPreview: null
    property var diagnostic: null
    property bool diagnosticLoading: false
    property var pendingEnable: null
    property int previewTicket: 0
    onVisibleChanged: if (!visible) {
        root.previewTicket++
        CornerSources.cancelPreview()
        root.manifestPreview = null
        root.diagnostic = null
        root.diagnosticLoading = false
        root.pendingEnable = null
    }
    function inspectManifest(address: string, refreshing: bool): void {
        root.manifestPreview = null
        root.diagnostic = null
        root.diagnosticLoading = false
        root.addonError = ""
        const ticket = ++root.previewTicket
        CornerSources.previewAddon(address, refreshing, (preview, error) => {
            if (ticket !== root.previewTicket) return
            root.addonError = error
            root.manifestPreview = preview
            root.contentY = 0
        })
    }
    function diagnose(source: var): void {
        root.manifestPreview = null
        root.diagnostic = null
        root.diagnosticLoading = true
        root.addonError = ""
        const ticket = ++root.previewTicket
        const name = CornerSources.displayName(source)
        CornerSources.previewAddon(source.url, true, (preview, error) => {
            if (ticket !== root.previewTicket) return
            root.diagnosticLoading = false
            root.diagnostic = { name, checkedAt: Date.now(), info: preview?.info ?? null, error }
            root.contentY = 0
        })
    }
    function confirmEnable(): void {
        if (!root.pendingEnable) return
        const pending = root.pendingEnable
        const index = CornerSources.list.findIndex(s => s.type === "stremio" && s.url === pending.url)
        if (index >= 0) {
            if (pending.capability) CornerSources.setCapability(index, pending.capability, true)
            else if (!CornerSources.list[index].on) CornerSources.toggle(index)
        }
        root.pendingEnable = null
    }
    function capabilities(source: var): string {
        if (!source) return ""
        const parts = []
        if (source.hasStreams !== false) parts.push(Translation.tr("Streams"))
        if (source.hasSubtitles !== false) parts.push(Translation.tr("Subtitles"))
        return parts.length ? parts.join(", ") : Translation.tr("None")
    }
    function resourceDetails(source: var): string {
        if (!source) return ""
        const details = []
        if (source.hasStreams !== false) details.push(Translation.tr("Streams") + ": " + (source.streamTypes ?? source.types ?? []).join(", ") + " / " + (source.streamPrefixes ?? source.prefixes ?? []).join(", "))
        if (source.hasSubtitles !== false) details.push(Translation.tr("Subtitles") + ": " + (source.subtitleTypes ?? source.types ?? []).join(", ") + " / " + (source.subtitlePrefixes ?? source.prefixes ?? []).join(", "))
        return details.join("; ")
    }
    component SourceNotice: ColumnLayout {
        id: sourceNotice
        signal accepted()
        spacing: Math.round(8 * root.d)
        IrisText {
            Layout.fillWidth: true
            text: Translation.tr("iNiR and the maintainer are not responsible for external sources you add.")
            wrapMode: Text.WordWrap
        }
        RowLayout {
            IrisButton { text: Translation.tr("Continue"); onClicked: sourceNotice.accepted() }
            IrisButton { text: Translation.tr("Close"); quiet: true; onClicked: root.confirmation = "" }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: intro.implicitHeight + Math.round(32 * root.d)
        radius: IrisStyle.radiusCard
        color: CornerSkin.card
        border.width: CornerSkin.edgeWidth
        border.color: CornerSkin.edge
        ColumnLayout {
            id: intro
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Math.round(16 * root.d); rightMargin: Math.round(16 * root.d) }
            spacing: Math.round(4 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("What Watch looks in. There are none until you add them, and nobody has checked what you add: you choose what to trust.")
                color: IrisStyle.textSecondary
                font.pixelSize: IrisStyle.typeMeta
                wrapMode: Text.WordWrap
            }
        }
    }

    IrisText {
        Layout.fillWidth: true
        visible: CornerState.migrationError.length > 0 || CornerSources.invalid > 0
        text: CornerState.migrationError.length > 0 ? CornerState.migrationError : Translation.tr("Some sources are invalid and were omitted")
        color: IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    IrisText {
        visible: CornerSources.list.length === 0
        text: Translation.tr("You have no sources yet")
        color: IrisStyle.muted
    }
    IrisText {
        Layout.fillWidth: true
        visible: root.addonError.length > 0
        text: root.addonError
        color: IrisStyle.danger
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        id: diagnosticPanel
        Layout.fillWidth: true
        visible: root.diagnostic !== null || root.diagnosticLoading
        IrisGroupTitle { text: Translation.tr("Source diagnostic") }
        IrisText { visible: root.diagnosticLoading; text: Translation.tr("Loading…") }
        IrisText {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: root.diagnostic ? Translation.tr("%1 — checked %2").arg(root.diagnostic.name).arg(new Date(root.diagnostic.checkedAt).toLocaleString()) : ""
            wrapMode: Text.WordWrap
        }
        IrisText {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: !root.diagnostic ? "" : root.diagnostic.error || Translation.tr("Manifest responds. Capabilities: %1").arg(root.capabilities(root.diagnostic.info))
            wrapMode: Text.WordWrap
        }
        IrisButton { text: Translation.tr("Close"); quiet: true; onClicked: root.diagnostic = null }
    }
    component DataNotice: IrisText {
        Layout.fillWidth: true
        text: Translation.tr("When you use Watch, enabled add-ons receive the title type and IMDb or Kitsu ID, plus season and episode where applicable. Media Corner does not send your profile, progress or watchlist.")
        wrapMode: Text.WordWrap
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.pendingEnable !== null
        IrisText { text: Translation.tr("Enable searches for %1?").arg(root.pendingEnable?.name ?? ""); textFormat: Text.PlainText; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        DataNotice {}
        RowLayout {
            IrisButton { text: Translation.tr("Confirm"); onClicked: root.confirmEnable() }
            IrisButton { text: Translation.tr("Cancel"); quiet: true; onClicked: root.pendingEnable = null }
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.manifestPreview !== null
        readonly property var previous: root.manifestPreview?.refreshing ? CornerSources.list.find(s => s.url === root.manifestPreview.url) : null
        IrisGroupTitle { text: Translation.tr("Manifest preview") }
        IrisText {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: root.manifestPreview ? Translation.tr("Declared name: %1").arg(String(root.manifestPreview.info.name || Streams.hostOf(root.manifestPreview.url))) : ""
            wrapMode: Text.WordWrap
        }
        DataNotice { visible: root.manifestPreview !== null && !root.manifestPreview.refreshing }
        IrisText {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: root.manifestPreview ? Translation.tr("Capabilities: %1").arg(root.capabilities(root.manifestPreview.info)) : ""
            wrapMode: Text.WordWrap
        }
        IrisText {
            Layout.fillWidth: true
            visible: root.manifestPreview !== null
            textFormat: Text.PlainText
            text: root.manifestPreview ? Translation.tr("Types / ID prefixes: %1").arg(root.resourceDetails(root.manifestPreview.info)) : ""
            wrapMode: Text.WordWrap
        }
        IrisText {
            Layout.fillWidth: true
            visible: parent.previous !== null && parent.previous !== undefined
            textFormat: Text.PlainText
            text: parent.previous ? Translation.tr("Previously: %1 — %2").arg(String(parent.previous.name)).arg(root.capabilities(parent.previous)) : ""
            wrapMode: Text.WordWrap
        }
        IrisText {
            Layout.fillWidth: true
            visible: parent.previous !== null && parent.previous !== undefined
            textFormat: Text.PlainText
            text: parent.previous ? Translation.tr("Previous types / ID prefixes: %1").arg(root.resourceDetails(parent.previous)) : ""
            wrapMode: Text.WordWrap
        }
        IrisText {
            Layout.fillWidth: true
            visible: root.manifestPreview?.refreshing ?? false
            text: Translation.tr("New capabilities stay disabled until you enable them.")
            wrapMode: Text.WordWrap
        }
        RowLayout {
            IrisButton {
                text: Translation.tr("Confirm")
                onClicked: {
                    if (!CornerSources.applyPreview(root.manifestPreview)) root.addonError = Translation.tr("Sources are not ready; try again")
                    else addonField.text = ""
                    root.manifestPreview = null
                }
            }
            IrisButton { text: Translation.tr("Cancel"); quiet: true; onClicked: { root.previewTicket++; root.manifestPreview = null } }
        }
    }
    DataNotice { visible: CornerSources.list.some(s => s.type === "stremio") }
    Repeater {
        model: CornerSources.list
        ColumnLayout {
            id: row
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: Math.round(12 * root.d)
            RowLayout {
            Layout.fillWidth: true
            IrisSwitch {
                on: row.modelData.on
                name: CornerSources.displayName(row.modelData)
                onToggled: {
                    if (row.modelData.type !== "stremio" || row.modelData.on) CornerSources.toggle(row.index)
                    else { root.pendingEnable = { url: row.modelData.url, name: CornerSources.displayName(row.modelData) }; root.contentY = 0 }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: CornerSources.displayName(row.modelData)
                    textFormat: Text.PlainText
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: Number(row.modelData.checkedAt ?? 0) > 0
                    text: visible ? Translation.tr("Manifest checked %1").arg(new Date(row.modelData.checkedAt).toLocaleString()) : ""
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                }
                IrisText {
                    Layout.fillWidth: true
                    text: (row.modelData.type === "web" ? Translation.tr("Web, opens in the browser") : Translation.tr("Stremio add-on"))
                        + " · " + Streams.hostOf(row.modelData.url ?? row.modelData.template)
                    textFormat: Text.PlainText
                    color: IrisStyle.muted
                    font.pixelSize: IrisStyle.typeFootnote
                    elide: Text.ElideRight
                }
                IrisText {
                    Layout.fillWidth: true
                    visible: String(CornerSources.refreshErrors[row.modelData.url] ?? "").length > 0
                    text: String(CornerSources.refreshErrors[row.modelData.url] ?? "")
                    color: IrisStyle.danger
                    font.pixelSize: IrisStyle.typeFootnote
                    wrapMode: Text.WordWrap
                }
            }
            IrisIconButton {
                materialIcon: "keyboard_arrow_up"
                enabled: row.index > 0
                Accessible.name: Translation.tr("Move %1 up").arg(CornerSources.displayName(row.modelData))
                onClicked: CornerSources.move(row.index, -1)
            }
            IrisIconButton {
                materialIcon: "keyboard_arrow_down"
                enabled: row.index < CornerSources.list.length - 1
                Accessible.name: Translation.tr("Move %1 down").arg(CornerSources.displayName(row.modelData))
                onClicked: CornerSources.move(row.index, 1)
            }
            IrisIconButton {
                visible: row.modelData.type === "stremio"
                materialIcon: "network_check"
                Accessible.name: Translation.tr("Check %1").arg(CornerSources.displayName(row.modelData))
                onClicked: root.diagnose(row.modelData)
            }
            IrisIconButton {
                visible: row.modelData.type === "stremio"
                materialIcon: "refresh"
                Accessible.name: Translation.tr("Refresh %1").arg(String(row.modelData.name))
                onClicked: {
                    const url = String(row.modelData.url)
                    root.inspectManifest(url, true)
                }
            }
            IrisIconButton {
                materialIcon: "delete"
                Accessible.name: Translation.tr("Remove %1").arg(String(row.modelData.name))
                onClicked: CornerSources.remove(row.index)
            }
            }
            RowLayout {
                Layout.fillWidth: true
                IrisField {
                    id: aliasField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Local alias (optional)")
                    text: String(row.modelData.alias ?? "")
                }
                IrisButton { text: Translation.tr("Save"); onClicked: CornerSources.setAlias(row.index, aliasField.text) }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: row.modelData.type === "stremio"
                IrisText { visible: row.modelData.hasStreams !== false; text: Translation.tr("Streams") }
                IrisSwitch {
                    visible: row.modelData.hasStreams !== false
                    name: Translation.tr("Streams")
                    on: row.modelData.streamsEnabled !== false
                    onToggled: {
                        if (on || !row.modelData.on) CornerSources.setCapability(row.index, "streams", !on)
                        else { root.pendingEnable = { url: row.modelData.url, name: CornerSources.displayName(row.modelData), capability: "streams" }; root.contentY = 0 }
                    }
                }
                IrisText { visible: row.modelData.hasSubtitles !== false; text: Translation.tr("Subtitles") }
                IrisSwitch {
                    visible: row.modelData.hasSubtitles !== false
                    name: Translation.tr("Subtitles")
                    on: row.modelData.subtitlesEnabled !== false
                    onToggled: {
                        if (on || !row.modelData.on) CornerSources.setCapability(row.index, "subtitles", !on)
                        else { root.pendingEnable = { url: row.modelData.url, name: CornerSources.displayName(row.modelData), capability: "subtitles" }; root.contentY = 0 }
                    }
                }
            }
        }
    }

    SourcesAppearance { Layout.fillWidth: true }
    SourcesSubtitles { Layout.fillWidth: true }

    SourcesCard {
        Layout.fillWidth: true
        eyebrow: Translation.tr("Add")
        title: Translation.tr("Add a Stremio add-on")
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(10 * root.d)
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)
                IrisField {
                    id: addonField
                    Layout.fillWidth: true
                    placeholderText: "https://example.com/manifest.json"
                }
                IrisButton {
                    text: Translation.tr("Add")
                    enabled: addonField.text.trim().length > 0
                    onClicked: root.confirmation = "addon"
                }
            }
            SourceNotice {
                Layout.fillWidth: true
                visible: root.confirmation === "addon"
                onAccepted: {
                    root.confirmation = ""
                    root.inspectManifest(addonField.text, false)
                }
            }
        }
    }

    SourcesCard {
        Layout.fillWidth: true
        eyebrow: Translation.tr("Add")
        title: Translation.tr("Add a web source")
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(10 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("A site's search address, with %s where the title goes. It opens in your browser.")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
                wrapMode: Text.WordWrap
            }
            GridLayout {
                Layout.fillWidth: true
                columns: root.width < Math.round(560 * root.d) ? 1 : 3
                columnSpacing: Math.round(8 * root.d)
                rowSpacing: Math.round(8 * root.d)
                IrisField {
                    id: webName
                    Layout.fillWidth: parent.columns === 1
                    Layout.preferredWidth: Math.round(180 * root.d)
                    placeholderText: Translation.tr("Name")
                }
                IrisField {
                    id: webTemplate
                    Layout.fillWidth: true
                    placeholderText: "https://example.com/search?q=%s"
                }
                IrisButton {
                    Layout.alignment: Qt.AlignRight
                    text: Translation.tr("Add")
                    enabled: webName.text.trim().length > 0 && webTemplate.text.trim().length > 0
                    onClicked: root.confirmation = "web"
                }
            }
            SourceNotice {
                Layout.fillWidth: true
                visible: root.confirmation === "web"
                onAccepted: {
                    root.confirmation = ""
                    root.webError = CornerSources.addWeb(webName.text, webTemplate.text)
                    if (root.webError.length > 0) return
                    webName.text = ""
                    webTemplate.text = ""
                }
            }
            IrisText {
                Layout.fillWidth: true
                visible: root.webError.length > 0
                text: root.webError
                color: IrisStyle.danger
                font.pixelSize: IrisStyle.typeFootnote
                wrapMode: Text.WordWrap
            }
        }
    }
}
