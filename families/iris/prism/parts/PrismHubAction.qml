import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The one thing an item asks for now (`PrismHub.actionOf`): a white key when it gets or updates something, a quiet key
// for the rest that acts, and the state printed plainly, in mono, when there is nothing to press.
Item {
    id: root
    property var plan: ({ text: "" })
    // Over a picture's frosted foot: the white key and the smoke's ink.
    property bool overArt: false
    readonly property bool acts: typeof root.plan.run === "function"
    implicitWidth: root.acts ? pill.implicitWidth : said.implicitWidth
    implicitHeight: PrismTheme.dp(34)

    PrismPill {
        id: pill
        visible: root.acts
        anchors.fill: parent
        text: String(root.plan.text ?? "")
        tone: root.overArt ? (root.plan.strong ? "art" : "dark") : root.plan.strong ? "solid" : "quiet"
        onClicked: root.plan.run()
    }
    PrismText {
        id: said
        visible: !root.acts
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: String(root.plan.text ?? "").toUpperCase()
        mono: true
        color: root.plan.danger ? PrismTheme.tint("red") : root.overArt ? PrismTheme.spotInk2 : PrismTheme.ink3
        font.pixelSize: PrismTheme.caption - 1
        font.letterSpacing: 0.8
        // A word that only says what is happening breathes while it lasts.
        SequentialAnimation on opacity {
            running: Boolean(root.plan.busy) && PrismTheme.motion
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.45; duration: PrismTheme.ms(620); easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: PrismTheme.ms(620); easing.type: Easing.InOutSine }
        }
    }
}
