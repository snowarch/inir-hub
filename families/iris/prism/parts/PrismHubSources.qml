pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// Where the hub's shelf comes from, in one card (`.claude/ref/language`): each source a line with its count in mono,
// a well to add another, the note on trust, and whether this computer counts its votes and installs.
Column {
    id: root
    spacing: PrismTheme.dp(12)

    PrismHeading {
        width: parent.width
        title: Translation.tr("Sources")
        titleSize: PrismTheme.head
    }
    Rectangle {
        width: parent.width
        height: lines.implicitHeight + PrismTheme.dp(12)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Column {
            id: lines
            x: PrismTheme.dp(6)
            y: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            Repeater {
                model: Hub.sources
                delegate: Item {
                    id: source
                    required property var modelData
                    required property int index
                    readonly property bool extra: Hub.extraSources.includes(source.modelData.source)
                    width: lines.width
                    height: PrismTheme.dp(58)
                    PrismGlyph {
                        id: mark
                        x: PrismTheme.dp(14)
                        anchors.verticalCenter: parent.verticalCenter
                        text: source.modelData.error ? "error" : source.extra ? "folder_special" : "verified"
                        filled: true
                        iconSize: PrismTheme.dp(18)
                        color: source.modelData.error ? PrismTheme.tint("red") : PrismTheme.ink2
                    }
                    Column {
                        anchors.left: mark.right
                        anchors.leftMargin: PrismTheme.dp(14)
                        anchors.right: drop.left
                        anchors.rightMargin: PrismTheme.dp(10)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(2)
                        PrismText {
                            width: parent.width
                            text: source.modelData.name || source.modelData.source
                            elide: Text.ElideRight
                            font.pixelSize: PrismTheme.row
                            font.weight: Font.DemiBold
                        }
                        PrismText {
                            width: parent.width
                            text: (source.modelData.error && source.modelData.count === 0 ? Translation.tr("Didn't answer")
                                : Translation.tr("%1 items · %2").arg(source.modelData.count).arg(source.modelData.source)).toUpperCase()
                            elide: Text.ElideMiddle
                            mono: true
                            color: source.modelData.error ? PrismTheme.tint("red") : PrismTheme.ink3
                            font.pixelSize: PrismTheme.caption - 1
                            font.letterSpacing: 0.6
                        }
                    }
                    PrismRound {
                        id: drop
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(8)
                        anchors.verticalCenter: parent.verticalCenter
                        width: source.extra ? PrismTheme.dp(32) : 0
                        visible: source.extra
                        implicitWidth: PrismTheme.dp(32)
                        glyph: "delete"
                        glyphSize: PrismTheme.dp(16)
                        Accessible.name: Translation.tr("Remove")
                        onClicked: Hub.removeSource(source.modelData.source)
                    }
                    Rectangle {
                        anchors.left: mark.right
                        anchors.leftMargin: PrismTheme.dp(14)
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(10)
                        anchors.bottom: parent.bottom
                        height: 1
                        color: PrismTheme.line
                    }
                }
            }
            // A new source: a well and its key on one line.
            Item {
                width: lines.width
                height: PrismTheme.dp(56)
                PrismField {
                    id: address
                    x: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - add.width - PrismTheme.dp(24)
                    height: PrismTheme.dp(36)
                    glyph: "add_link"
                    placeholder: Translation.tr("Address of an index.json, or a folder")
                    onEntered: text => root.add(text)
                }
                PrismPill {
                    id: add
                    anchors.right: parent.right
                    anchors.rightMargin: PrismTheme.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    tone: "quiet"
                    text: Translation.tr("Add")
                    enabled_: address.input.text.trim().length > 0
                    onClicked: root.add(address.input.text)
                }
            }
        }
    }
    PrismText {
        x: PrismTheme.dp(6)
        width: parent.width - PrismTheme.dp(12)
        wrapMode: Text.Wrap
        maximumLineCount: 40
        color: PrismTheme.ink3
        font.pixelSize: PrismTheme.caption
        text: Translation.tr("Everything in the official hub is reviewed before it is published. Other sources are not: add only the ones you trust.")
    }
    Rectangle {
        width: parent.width
        height: PrismTheme.dp(72)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        PrismGlyph {
            id: shareMark
            x: PrismTheme.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            text: "groups"
            filled: true
            iconSize: PrismTheme.dp(18)
            color: PrismTheme.ink2
        }
        Column {
            anchors.left: shareMark.right
            anchors.leftMargin: PrismTheme.dp(14)
            anchors.right: share.left
            anchors.rightMargin: PrismTheme.dp(14)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(2)
            PrismText {
                width: parent.width
                text: Translation.tr("Count my votes and installs")
                elide: Text.ElideRight
                font.pixelSize: PrismTheme.row
                font.weight: Font.DemiBold
            }
            PrismText {
                width: parent.width
                text: Translation.tr("Without your name, from a key kept on this computer")
                wrapMode: Text.Wrap
                maximumLineCount: 40
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.small
            }
        }
        PrismSwitch {
            id: share
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(18)
            anchors.verticalCenter: parent.verticalCenter
            checked: Hub.sharing
            onToggled: value => Hub.setSharing(value)
        }
    }

    function add(text: string): void {
        if (text.trim().length === 0) return
        Hub.addSource(text)
        address.input.text = ""
    }
}
