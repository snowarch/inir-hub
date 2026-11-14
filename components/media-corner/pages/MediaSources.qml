pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"
import "../state/streams.js" as Streams

// The person's sources. It ships none, and what is added here hasn't been read by anyone: the Corner only asks it.
MediaPage {
    id: root
    spacing: Math.round(14 * root.d)

    property string addonError: ""
    property string webError: ""
    property string confirmation: ""

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
        radius: IrisStyle.radiusTile
        color: IrisStyle.fillQuiet
        ColumnLayout {
            id: intro
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Math.round(16 * root.d); rightMargin: Math.round(16 * root.d) }
            spacing: Math.round(4 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: Translation.tr("What Watch looks in. There are none until you add them, and nobody has checked what you add: you choose what to trust.")
                color: IrisStyle.muted
                font.pixelSize: IrisStyle.typeFootnote
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
    Repeater {
        model: CornerSources.list
        RowLayout {
            id: row
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: Math.round(12 * root.d)
            IrisSwitch {
                on: row.modelData.on
                name: String(row.modelData.name)
                onToggled: CornerSources.toggle(row.index)
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                IrisText {
                    Layout.fillWidth: true
                    text: String(row.modelData.name)
                    textFormat: Text.PlainText
                    font.weight: IrisStyle.weight(Font.DemiBold)
                    elide: Text.ElideRight
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
                visible: row.modelData.type === "stremio"
                materialIcon: "refresh"
                Accessible.name: Translation.tr("Refresh %1").arg(String(row.modelData.name))
                onClicked: {
                    const url = String(row.modelData.url)
                    CornerSources.refreshAddon(url, error => { CornerSources.refreshErrors = Object.assign({}, CornerSources.refreshErrors, { [url]: error }) })
                }
            }
            IrisIconButton {
                materialIcon: "delete"
                Accessible.name: Translation.tr("Remove %1").arg(String(row.modelData.name))
                onClicked: CornerSources.remove(row.index)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        IrisText { text: Translation.tr("Subtitle language (ISO code)") }
        IrisField { id: subtitleLanguage; Layout.fillWidth: true; text: CornerState.options.subtitleLanguage }
        IrisButton {
            text: Translation.tr("Save")
            enabled: /^[a-zA-Z]{2,3}$/.test(subtitleLanguage.text.trim())
            onClicked: CornerState.set("subtitleLanguage", subtitleLanguage.text.trim().toLowerCase())
        }
    }

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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: addonSection.implicitHeight + Math.round(32 * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fillQuiet
        ColumnLayout {
            id: addonSection
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Math.round(16 * root.d); rightMargin: Math.round(16 * root.d) }
            spacing: Math.round(10 * root.d)
            IrisGroupTitle { text: Translation.tr("Add a Stremio add-on") }
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
                    CornerSources.addAddon(addonField.text, error => {
                        root.addonError = error
                        if (!error) addonField.text = ""
                    })
                }
            }
            IrisText {
                Layout.fillWidth: true
                visible: root.addonError.length > 0
                text: root.addonError
                color: IrisStyle.danger
                font.pixelSize: IrisStyle.typeFootnote
                wrapMode: Text.WordWrap
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: webSection.implicitHeight + Math.round(32 * root.d)
        radius: IrisStyle.radiusTile
        color: IrisStyle.fillQuiet
        ColumnLayout {
            id: webSection
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Math.round(16 * root.d); rightMargin: Math.round(16 * root.d) }
            spacing: Math.round(10 * root.d)
            IrisGroupTitle { text: Translation.tr("Add a web source") }
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
