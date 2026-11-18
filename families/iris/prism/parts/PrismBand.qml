import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// A page iRiS draws itself (the Hub, About, Shortcuts) wears the page card's head alone: the page's art as one band,
// the way back and forward, where the page lives and its name, so every page of Prism opens the same way.
Item {
    id: root
    property var page: null
    readonly property string pageId: String(root.page?.pageId ?? "")
    implicitHeight: PrismTheme.dp(96)

    PrismFlow {
        anchors.fill: parent
        tint: String(root.page?.tint ?? "grey")
        seed: 0.61 + PrismModel.index(root.pageId) * 0.137
        centre: Qt.point(0.5, 0.5)
        thickness: 0.9
        strength: PrismTheme.light ? 0.6 : 0.72
        mute: 0.5
        radius: PrismTheme.dp(26)
    }
    Row {
        x: PrismTheme.dp(22)
        anchors.verticalCenter: parent.verticalCenter
        spacing: PrismTheme.dp(8)
        PrismRound { overArt: true; smoked: true; glyph: "arrow_back"; enabled_: PrismState.canBack; onClicked: PrismState.goBack() }
        PrismRound { overArt: true; smoked: true; glyph: "arrow_forward"; enabled_: PrismState.canForward; onClicked: PrismState.goForward() }
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: PrismTheme.dp(8)
            mono: true
            text: [String(root.page?.group ?? ""), String(root.page?.name ?? "")].filter(part => part.length > 0).map(part => Translation.tr(part)).join("  /  ").toUpperCase()
            color: PrismTheme.light ? PrismTheme.ink2 : PrismTheme.spotInk2
            font.pixelSize: PrismTheme.dp(9.5)
            font.letterSpacing: PrismTheme.dp(9.5) * 0.1
        }
    }
    PrismText {
        anchors.right: parent.right
        anchors.rightMargin: PrismTheme.dp(28)
        anchors.verticalCenter: parent.verticalCenter
        text: Translation.tr(String(root.page?.name ?? ""))
        font.pixelSize: PrismTheme.display
        font.weight: Font.Bold
        font.letterSpacing: -PrismTheme.display * 0.035
    }
}
