pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.components
import qs.modules.iris.style
import qs.modules.iris.state
import "../state"

// The Corner's Settings › Accounts: AniList and MyAnimeList, each a row that says whether it is connected and the one
// thing to do next. AniList shows its token on a page of its own; it is pasted here, tried, and only then kept.
// MAL comes back to iNiR by itself once the person allows it in the browser.
ColumnLayout {
    id: root

    readonly property real d: IrisStyle.settingsDensity
    spacing: Math.round(6 * root.d)
    Component.onCompleted: { CornerWatch.loadKeys(); CornerAccounts.whoIsAnilist() }
    Connections { target: CornerWatch; function onKeysReadyChanged(): void { CornerAccounts.whoIsAnilist() } }

    component Account: RowLayout {
        id: account
        property string name
        property string mark
        property bool connected
        property string detail
        property bool canConnect
        signal connect()
        signal disconnect()
        Layout.fillWidth: true
        spacing: Math.round(10 * root.d)
        Rectangle {
            Layout.preferredWidth: Math.round(28 * root.d)
            Layout.preferredHeight: Layout.preferredWidth
            radius: IrisStyle.capsule(width)
            color: account.connected ? IrisStyle.tintFill(IrisStyle.accent) : IrisStyle.fill
            MaterialSymbol {
                anchors.centerIn: parent
                text: account.connected ? "check" : account.mark
                iconSize: Math.round(16 * root.d)
                color: account.connected ? IrisStyle.accent : IrisStyle.subtext
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.round(2 * root.d)
            IrisText {
                Layout.fillWidth: true
                text: account.name
                font.pixelSize: IrisStyle.typeLabel
                elide: Text.ElideRight
            }
            IrisText {
                Layout.fillWidth: true
                text: account.detail
                textFormat: Text.PlainText
                font.pixelSize: IrisStyle.typeFootnote
                color: IrisStyle.subtext
                elide: Text.ElideRight
            }
        }
        IrisButton {
            text: account.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")
            enabled: account.connected || account.canConnect
            colBackground: IrisStyle.fill
            colBackgroundHover: IrisStyle.fillHover
            onClicked: account.connected ? account.disconnect() : account.connect()
        }
    }

    Account {
        name: "AniList"
        mark: "person"
        connected: CornerAccounts.anilist
        canConnect: /^\d+$/.test(CornerAccounts.anilistClient) && !CornerAccounts.working
        detail: CornerAccounts.anilist ? (CornerAccounts.anilistName.length > 0 ? Translation.tr("Connected as %1").arg(CornerAccounts.anilistName) : Translation.tr("Connected"))
            : /^\d+$/.test(CornerAccounts.anilistClient) ? Translation.tr("Connect, allow iNiR, then paste the token it shows below")
            : Translation.tr("Paste your AniList client ID below first")
        onConnect: CornerAccounts.connectAnilist()
        onDisconnect: CornerAccounts.disconnect("anilist")
    }
    RowLayout {
        Layout.fillWidth: true
        visible: !CornerAccounts.anilist && /^\d+$/.test(CornerAccounts.anilistClient)
        spacing: Math.round(8 * root.d)
        IrisField {
            id: token
            Layout.fillWidth: true
            implicitHeight: Math.round(36 * root.d)
            font.pixelSize: IrisStyle.typeLabel
            echoMode: TextInput.Password
            placeholderText: Translation.tr("Paste the AniList token")
            onAccepted: { CornerAccounts.useAnilistToken(token.text); token.text = "" }
        }
        IrisButton {
            visible: token.text.trim().length > 0
            enabled: !CornerAccounts.working
            text: Translation.tr("Use it")
            colBackground: IrisStyle.tintFill(IrisStyle.accent)
            colBackgroundHover: IrisStyle.tintFillHover(IrisStyle.accent)
            foreground: IrisStyle.accent
            onClicked: { CornerAccounts.useAnilistToken(token.text); token.text = "" }
        }
    }
    Account {
        name: "MyAnimeList"
        mark: "person"
        connected: CornerAccounts.mal
        canConnect: CornerAccounts.malClient.length >= 8 && !CornerAccounts.working
        detail: CornerAccounts.mal ? Translation.tr("Connected")
            : CornerAccounts.malClient.length >= 8 ? Translation.tr("Connect, then allow iNiR in the browser")
            : Translation.tr("Paste your MyAnimeList client ID below first")
        onConnect: CornerAccounts.connectMal()
        onDisconnect: CornerAccounts.disconnect("mal")
    }
    IrisText {
        Layout.fillWidth: true
        visible: text.length > 0
        text: CornerAccounts.note
        textFormat: Text.PlainText
        wrapMode: Text.WordWrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.subtext
    }
    IrisText {
        Layout.fillWidth: true
        visible: !CornerAccounts.anilist && !CornerAccounts.mal
        text: Translation.tr("Tokens are kept in your system keyring (GNOME Keyring or KWallet).")
        wrapMode: Text.WordWrap
        font.pixelSize: IrisStyle.typeFootnote
        color: IrisStyle.textTertiary
    }
}
