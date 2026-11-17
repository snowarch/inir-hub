import QtQuick
import qs.services
import qs.modules.iris.settings
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// The Board's left column (his 11-17, design D3): the window's lights, then Home and every category as a round key with
// its name under it; the open category wears the accent. A key goes back to the page last read in its category.
Item {
    id: root
    property bool windowed: false
    signal closeRequested()
    signal minimizeRequested()
    signal growRequested()

    readonly property string here: PrismState.searching || PrismState.page === "changes" ? "-" : String(PrismModel.page(PrismState.page).group)
    property var lastOf: ({})
    Connections {
        target: PrismState
        function onPageChanged() {
            const page = PrismModel.page(PrismState.page)
            const next = Object.assign({}, root.lastOf)
            next[page.group] = page.pageId
            root.lastOf = next
        }
    }
    readonly property var keys: PrismModel.groups.filter(caption => PrismModel.inGroup(caption).length > 0).map(caption => {
        if (caption === "") return { caption: "", label: Translation.tr("Home"), glyph: "home" }
        const category = IrisOptions.categories.find(entry => PrismModel.captionOf(entry) === caption)
        return { caption: caption, label: caption === "iNiR" ? caption : Translation.tr(caption), glyph: String(category?.icon || "tune") }
    })
    function open(caption: string): void {
        const pages = PrismModel.inGroup(caption)
        const last = String(root.lastOf[caption] ?? "")
        PrismState.query = ""
        PrismState.go(pages.some(page => page.pageId === last) ? last : pages[0].pageId)
    }

    // The lights: red and yellow put Settings away, green gives it the whole room (a window: its column the screen).
    Row {
        id: lights
        y: PrismTheme.dp(20)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: PrismTheme.dp(8)
        Repeater {
            model: [{ c: "#ff5f57", g: "close" }, { c: "#febc2e", g: "remove" }, { c: "#28c840", g: root.windowed || !PrismState.wide ? "open_in_full" : "close_fullscreen" }] // iris-literal: macOS window lights
            delegate: Rectangle {
                id: light
                required property var modelData
                required property int index
                width: PrismTheme.dp(12)
                height: width
                radius: width / 2
                color: light.modelData.c
                PrismGlyph {
                    anchors.centerIn: parent
                    visible: lightsHover.hovered
                    text: light.modelData.g
                    iconSize: PrismTheme.dp(9)
                    color: Qt.rgba(0, 0, 0, 0.6) // iris-literal: Prism's own fills and scrims, scheme-aware above
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -PrismTheme.dp(3)
                    cursorShape: Qt.PointingHandCursor
                    onClicked: light.index === 0 ? root.closeRequested()
                        : light.index === 1 ? (root.windowed ? root.minimizeRequested() : root.closeRequested())
                        : root.windowed ? root.growRequested() : (PrismState.wide = !PrismState.wide)
                }
            }
        }
        HoverHandler { id: lightsHover }
    }

    Flickable {
        id: flick
        y: lights.y + lights.height + PrismTheme.dp(18)
        width: root.width
        height: root.height - y
        contentHeight: column.implicitHeight + PrismTheme.dp(16)
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        // The room left over is shared between the keys; a short window packs them and scrolls.
        readonly property real air: Math.max(PrismTheme.dp(6), Math.min(PrismTheme.dp(16), (flick.height - PrismTheme.dp(16) - column.bare) / Math.max(1, root.keys.length)))

        Column {
            id: column
            width: flick.width
            // The keys' own height, without the air between them.
            readonly property real bare: {
                let sum = 0
                for (let i = 0; i < keyRepeater.count; ++i) sum += keyRepeater.itemAt(i)?.need ?? 0
                return sum
            }
            Repeater {
                id: keyRepeater
                model: root.keys
                delegate: Item {
                    id: key
                    required property var modelData
                    readonly property bool on: root.here === key.modelData.caption
                    readonly property real need: cap.height + PrismTheme.dp(5) + label.implicitHeight
                    width: column.width
                    height: key.need + flick.air
                    PrismRound {
                        id: cap
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: PrismTheme.dp(38)
                        glyph: key.modelData.glyph
                        glyphSize: PrismTheme.dp(19)
                        lit: key.on
                        Accessible.role: Accessible.Button
                        Accessible.name: key.modelData.label
                        onClicked: root.open(key.modelData.caption)
                    }
                    PrismText {
                        id: label
                        y: cap.height + PrismTheme.dp(5)
                        x: PrismTheme.dp(4)
                        width: parent.width - PrismTheme.dp(8)
                        horizontalAlignment: Text.AlignHCenter
                        text: key.modelData.label
                        color: key.on ? PrismTheme.ink : PrismTheme.inkNav
                        font.pixelSize: PrismTheme.caption - 1
                        font.weight: key.on ? Font.Bold : Font.Medium
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        lineHeight: 0.95
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.open(key.modelData.caption)
                    }
                }
            }
        }
    }
}
