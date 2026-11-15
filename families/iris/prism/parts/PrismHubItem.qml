pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// One hub item as its own page (`.claude/ref/language`, the record's sleeve and its liner notes): the picture whole
// with its name, credit and action on the frosted foot; what it does in a line; its figures over their names in mono;
// what people think and the person's own say; then the notes: what it is, what changed, what it reaches, where it
// comes from. The hub page (`PrismHub`) owns the action plan, the credits and the dates.
Column {
    id: page
    property var item: null
    property var hub: null
    signal back()

    readonly property var permissions: Array.from(page.item?.permissions ?? [])
    readonly property var hosts: Array.from(page.item?.hosts ?? [])
    readonly property var changes: Hub.changesOf(page.item)
    readonly property string pulledWhy: String(page.item?.installedBlocked || page.item?.blocked || "")
    readonly property string stage: Hub.stateOf(page.item)
    readonly property var authors: Array.from(page.item?.authors ?? [])
    readonly property bool hasChoices: Hub.choicesTitle(page.item).length > 0
    readonly property var choices: page.hasChoices ? (Hub.choices[page.item?.id ?? ""] ?? []) : []
    readonly property var permissionGlyphs: ({ process: "terminal", network: "public", files: "folder_open", inject: "code" })

    spacing: PrismTheme.dp(16)
    onItemChanged: if (page.hasChoices) Hub.readChoices(page.item.id)
    Component.onCompleted: if (page.hasChoices) Hub.readChoices(page.item.id)

    // ── Back to the shelf, the way here said in mono ────────────────
    Item {
        width: parent.width
        height: PrismTheme.dp(34)
        PrismRound {
            id: backKey
            implicitWidth: PrismTheme.dp(34)
            glyph: "arrow_back"
            glyphSize: PrismTheme.dp(17)
            Accessible.name: Translation.tr("Back")
            onClicked: page.back()
        }
        PrismText {
            anchors.left: backKey.right
            anchors.leftMargin: PrismTheme.dp(12)
            anchors.verticalCenter: parent.verticalCenter
            mono: true
            color: trailArea.containsMouse ? PrismTheme.ink : PrismTheme.ink3
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
            text: [Translation.tr("Hub"), Translation.tr(Hub.kindName(page.item?.kind ?? ""))].join("  /  ").toUpperCase()
            MouseArea {
                id: trailArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: page.back()
            }
        }
    }

    // ── The sleeve ──────────────────────────────────────────────────
    PrismHubArt {
        width: parent.width
        height: Math.round(Math.max(PrismTheme.dp(280), Math.min(width * 0.52, PrismTheme.dp(420))))
        radius: PrismTheme.dp(24)
        sheetHeight: PrismTheme.dp(108)
        item: page.item
        Column {
            x: PrismTheme.dp(24)
            width: parent.width - x - acts.width - PrismTheme.dp(44)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(3)
            PrismText {
                width: parent.width
                text: (page.pulledWhy.length > 0 ? Translation.tr("Pulled from the hub")
                    : [Translation.tr(Hub.kindName(page.item?.kind ?? "")), page.item?.version ? `v${page.item.version}` : ""]
                        .filter(part => part.length > 0).join("  ·  ")).toUpperCase()
                elide: Text.ElideRight
                mono: true
                color: page.pulledWhy.length > 0 ? PrismTheme.tint("red") : PrismTheme.spotInk2
                font.pixelSize: PrismTheme.caption - 1
                font.letterSpacing: 0.8
            }
            PrismText {
                width: parent.width
                text: String(page.item?.name ?? "")
                elide: Text.ElideRight
                color: PrismTheme.paper
                font.pixelSize: PrismTheme.title
                font.weight: Font.Bold
                font.letterSpacing: -PrismTheme.title * 0.025
            }
            PrismText {
                width: parent.width
                visible: page.authors.length > 0
                text: Translation.tr("By %1").arg(page.authors.join(", "))
                elide: Text.ElideRight
                color: PrismTheme.spotInk2
                font.pixelSize: PrismTheme.small
            }
        }
        Row {
            id: acts
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(20)
            anchors.verticalCenter: parent.verticalCenter
            spacing: PrismTheme.dp(8)
            PrismPill {
                visible: Boolean(page.item?.installed) && !["removing", "pulled"].includes(page.stage)
                tone: "dark"
                text: Translation.tr("Remove")
                onClicked: Hub.remove(page.item.id)
            }
            PrismHubAction {
                anchors.verticalCenter: parent.verticalCenter
                overArt: true
                plan: page.hub ? page.hub.actionOf(page.item) : ({ text: "" })
            }
        }
    }

    // ── Pulled: why, before anything else ───────────────────────────
    Rectangle {
        width: parent.width
        visible: page.pulledWhy.length > 0
        height: pulledLine.implicitHeight + PrismTheme.dp(28)
        radius: PrismTheme.dp(20)
        color: PrismTheme.card
        PrismGlyph {
            id: pulledMark
            x: PrismTheme.dp(18)
            y: PrismTheme.dp(14)
            text: "gpp_bad"
            filled: true
            iconSize: PrismTheme.dp(18)
            color: PrismTheme.tint("red")
        }
        PrismText {
            id: pulledLine
            anchors.left: pulledMark.right
            anchors.leftMargin: PrismTheme.dp(12)
            anchors.right: parent.right
            anchors.rightMargin: PrismTheme.dp(18)
            y: PrismTheme.dp(14)
            wrapMode: Text.Wrap
            maximumLineCount: 40
            font.pixelSize: PrismTheme.body
            text: Translation.tr("Pulled from the hub: %1").arg(page.pulledWhy)
        }
    }

    // ── What it does, in its own words ──────────────────────────────
    PrismText {
        x: PrismTheme.dp(4)
        width: parent.width - PrismTheme.dp(8)
        visible: text.length > 0
        text: String(page.item?.summary ?? "")
        wrapMode: Text.Wrap
        maximumLineCount: 40
        font.pixelSize: PrismTheme.head
        font.weight: Font.DemiBold
        font.letterSpacing: -PrismTheme.head * 0.01
        lineHeight: 1.15
    }

    // ── Its own choices: the whole plugin on or off, then each part ─
    Rectangle {
        width: parent.width
        visible: leads.count > 0
        height: leadColumn.implicitHeight + PrismTheme.dp(12)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Column {
            id: leadColumn
            x: PrismTheme.dp(6)
            y: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            Repeater {
                id: leads
                model: page.choices.filter(choice => choice.lead)
                delegate: Item {
                    id: lead
                    required property var modelData
                    width: leadColumn.width
                    height: Math.max(PrismTheme.dp(64), leadWords.implicitHeight + PrismTheme.dp(24))
                    Column {
                        id: leadWords
                        x: PrismTheme.dp(14)
                        anchors.right: leadSwitch.left
                        anchors.rightMargin: PrismTheme.dp(14)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: PrismTheme.dp(2)
                        PrismText {
                            width: parent.width
                            text: String(lead.modelData.label ?? "")
                            elide: Text.ElideRight
                            font.pixelSize: PrismTheme.row
                            font.weight: Font.DemiBold
                        }
                        PrismText {
                            width: parent.width
                            visible: text.length > 0
                            text: String(lead.modelData.note ?? "")
                            wrapMode: Text.Wrap
                            maximumLineCount: 40
                            color: PrismTheme.ink2
                            font.pixelSize: PrismTheme.small
                        }
                    }
                    PrismSwitch {
                        id: leadSwitch
                        anchors.right: parent.right
                        anchors.rightMargin: PrismTheme.dp(12)
                        anchors.verticalCenter: parent.verticalCenter
                        checked: Boolean(lead.modelData.on)
                        tint: "pink"
                        Accessible.name: String(lead.modelData.label ?? "")
                        onToggled: Hub.toggleChoice(page.item.id, lead.modelData.id)
                    }
                }
            }
        }
    }
    Column {
        width: parent.width
        visible: parts.count > 0
        spacing: PrismTheme.dp(10)
        PrismText {
            x: PrismTheme.dp(4)
            text: Hub.choicesTitle(page.item).toUpperCase()
            mono: true
            color: PrismTheme.ink3
            font.pixelSize: PrismTheme.caption - 1
            font.letterSpacing: 0.8
        }
        Flow {
            width: parent.width
            spacing: PrismTheme.dp(6)
            Repeater {
                id: parts
                model: page.choices.filter(choice => !choice.lead)
                delegate: PrismHubKey {
                    required property var modelData
                    glyph: modelData.on ? "check" : ""
                    label: String(modelData.label ?? "")
                    chosen: Boolean(modelData.on)
                    onPress: Hub.toggleChoice(page.item.id, modelData.id)
                }
            }
        }
    }

    // ── Its figures over their names, split by hairlines ────────────
    Rectangle {
        width: parent.width
        height: PrismTheme.dp(96)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Row {
            id: facts
            x: PrismTheme.dp(8)
            width: parent.width - PrismTheme.dp(16)
            height: parent.height
            readonly property var shown: [
                { figure: Hub.liked(page.item) >= 0 && page.hub ? page.hub.likedText(page.item) : "–", caption: Hub.votes(page.item) > 0
                    ? Translation.tr("%1 of %2 people liked it").arg(Hub.voteCount(page.item, "up")).arg(Hub.votes(page.item)) : Translation.tr("No votes yet") },
                { figure: Number(page.item?.installs ?? 0) > 0 ? Hub.countText(page.item.installs) : "", caption: Translation.tr("Have it") },
                { figure: page.item?.downloads !== undefined && !(Number(page.item?.installs ?? 0) > 0) ? Hub.countText(page.item.downloads) : "", caption: Translation.tr("Downloads") },
                { figure: String(page.item?.version ?? ""), caption: page.item?.installed && page.item.installed !== page.item.version
                    ? Translation.tr("You have %1").arg(page.item.installed) : Translation.tr("Version") },
                { figure: page.hub ? page.hub.dateText(page.item?.updated ?? "") : "", caption: Translation.tr("Updated") },
                { figure: page.item?.size ? Hub.sizeText(page.item.size) : "", caption: Translation.tr("Size") }
            ].filter(fact => fact.figure.length > 0)
            Repeater {
                model: facts.shown
                delegate: Item {
                    id: fact
                    required property var modelData
                    required property int index
                    width: facts.width / facts.shown.length
                    height: facts.height
                    Rectangle {
                        visible: fact.index > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: parent.height * 0.46
                        color: PrismTheme.line
                    }
                    Column {
                        anchors.centerIn: parent
                        width: parent.width - PrismTheme.dp(16)
                        spacing: PrismTheme.dp(4)
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: fact.modelData.figure
                            elide: Text.ElideRight
                            figures: true
                            font.pixelSize: PrismTheme.head
                            font.weight: Font.Bold
                            font.letterSpacing: -PrismTheme.head * 0.02
                        }
                        PrismText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: fact.modelData.caption.toUpperCase()
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            mono: true
                            color: PrismTheme.ink3
                            font.pixelSize: PrismTheme.caption - 2
                            font.letterSpacing: 0.6
                        }
                    }
                }
            }
        }
    }

    // ── What people think, and the person's own say ─────────────────
    Flow {
        width: parent.width
        spacing: PrismTheme.dp(6)
        Repeater {
            model: ["up", "down"]
            delegate: PrismHubKey {
                required property string modelData
                glyph: modelData === "up" ? "thumb_up" : "thumb_down"
                count: Hub.countText(Hub.voteCount(page.item, modelData))
                chosen: Hub.mine(page.item?.id ?? "").vote === modelData
                Accessible.name: modelData === "up" ? Translation.tr("I like it") : Translation.tr("Not for me")
                onPress: Hub.vote(page.item.id, modelData)
            }
        }
        Item { width: PrismTheme.dp(8); height: 1 }
        Repeater {
            model: Hub.reactionsOf(page.item)
            delegate: PrismHubKey {
                required property var modelData
                label: modelData.emoji
                count: Hub.countText(modelData.count)
                chosen: Boolean(modelData.mine)
                onPress: Hub.react(page.item.id, modelData.emoji)
            }
        }
        PrismHubKey {
            glyph: "add_reaction"
            label: Hub.reactionsOf(page.item).length === 0 ? Translation.tr("React") : ""
            chosen: picker.open
            enabled_: Hub.canReact(page.item?.id ?? "")
            Accessible.name: Translation.tr("Add a reaction")
            onPress: picker.open = !picker.open
        }
    }
    PrismHubReact {
        id: picker
        width: parent.width
        item: page.item
    }

    // ── The notes ───────────────────────────────────────────────────
    PrismText {
        x: PrismTheme.dp(4)
        width: parent.width - PrismTheme.dp(8)
        // Many listings repeat the summary as the description: say it once.
        visible: text.length > 0 && text.replace(/\.$/, "") !== String(page.item?.summary ?? "").replace(/\.$/, "")
        text: String(page.item?.description ?? "")
        wrapMode: Text.Wrap
        maximumLineCount: 40
        color: PrismTheme.ink2
        font.pixelSize: PrismTheme.body
        lineHeight: 1.25
    }
    PrismHeading {
        width: parent.width
        visible: page.changes.length > 0
        title: Hub.changesTitle(page.item)
        titleSize: PrismTheme.head
    }
    Rectangle {
        width: parent.width
        visible: page.changes.length > 0
        height: changeColumn.implicitHeight + PrismTheme.dp(36)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Column {
            id: changeColumn
            x: PrismTheme.dp(20)
            y: PrismTheme.dp(18)
            width: parent.width - PrismTheme.dp(40)
            spacing: PrismTheme.dp(16)
            Repeater {
                model: page.changes
                delegate: Column {
                    id: release
                    required property var modelData
                    width: changeColumn.width
                    spacing: PrismTheme.dp(6)
                    PrismText {
                        text: String(release.modelData.version ?? "").toUpperCase()
                        mono: true
                        color: PrismTheme.ink3
                        font.pixelSize: PrismTheme.caption - 1
                        font.letterSpacing: 0.8
                    }
                    Repeater {
                        model: release.modelData.notes
                        delegate: Item {
                            id: note
                            required property string modelData
                            width: release.width
                            height: noteText.implicitHeight
                            Rectangle {
                                y: Math.round(noteText.font.pixelSize * 0.55)
                                width: PrismTheme.dp(4)
                                height: width
                                radius: width / 2
                                color: PrismTheme.ink3
                            }
                            PrismText {
                                id: noteText
                                x: PrismTheme.dp(14)
                                width: parent.width - x
                                text: note.modelData
                                wrapMode: Text.Wrap
                                maximumLineCount: 40
                                font.pixelSize: PrismTheme.body
                            }
                        }
                    }
                }
            }
        }
    }
    PrismHeading {
        width: parent.width
        title: Hub.reachTitle(page.item)
        titleSize: PrismTheme.head
    }
    Rectangle {
        width: parent.width
        height: reachColumn.implicitHeight + PrismTheme.dp(12)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Column {
            id: reachColumn
            x: PrismTheme.dp(6)
            y: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            PrismText {
                x: PrismTheme.dp(14)
                width: parent.width - PrismTheme.dp(28)
                visible: page.permissions.length === 0
                topPadding: PrismTheme.dp(14)
                bottomPadding: PrismTheme.dp(14)
                wrapMode: Text.Wrap
                maximumLineCount: 40
                color: PrismTheme.ink2
                font.pixelSize: PrismTheme.body
                text: Hub.reachText(page.item)
            }
            Repeater {
                model: page.permissions
                delegate: Line {
                    required property string modelData
                    required property int index
                    glyph: page.permissionGlyphs[modelData] ?? "shield"
                    label: Translation.tr(Hub.permissionText[modelData] ?? modelData)
                    last: index === page.permissions.length - 1 && page.hosts.length === 0
                }
            }
            Line {
                visible: page.hosts.length > 0
                glyph: "dns"
                label: Translation.tr("Reaches")
                value: page.hosts.join(", ")
                last: true
            }
        }
    }
    PrismHeading {
        width: parent.width
        title: Translation.tr("About it")
        titleSize: PrismTheme.head
    }
    Rectangle {
        width: parent.width
        height: aboutColumn.implicitHeight + PrismTheme.dp(12)
        radius: PrismTheme.dp(24)
        color: PrismTheme.card
        Column {
            id: aboutColumn
            x: PrismTheme.dp(6)
            y: PrismTheme.dp(6)
            width: parent.width - PrismTheme.dp(12)
            readonly property var rows: [
                { label: Translation.tr("Where"), value: Hub.whereOf(page.item, "iris") },
                // Only a widget's place leaves its families unsaid; every other kind's place names them.
                { label: Translation.tr("Works in"), value: page.item?.kind === "widget" ? Hub.familyNames(page.item) : "" },
                { label: Translation.tr("Added"), value: page.hub ? page.hub.dateText(page.item?.added ?? "") : "" },
                { label: Translation.tr("License"), value: String(page.item?.license ?? "") },
                { label: Translation.tr("From"), value: String(page.item?.sourceName || page.item?.source || "") }
            ].filter(row => row.value.length > 0)
            Repeater {
                model: aboutColumn.rows
                delegate: Line {
                    required property var modelData
                    required property int index
                    label: modelData.label
                    value: modelData.value
                    last: index === aboutColumn.rows.length - 1
                }
            }
        }
    }
    Row {
        spacing: PrismTheme.dp(8)
        PrismPill {
            visible: String(page.item?.page ?? "").length > 0
            tone: "quiet"
            glyph: "folder_open"
            text: Translation.tr("See its files")
            onClicked: Qt.openUrlExternally(page.item.page)
        }
        PrismPill {
            visible: Hub.reportUrl(page.item).length > 0
            tone: "quiet"
            glyph: "flag"
            text: Translation.tr("Report")
            onClicked: Qt.openUrlExternally(Hub.reportUrl(page.item))
        }
    }

    // A line of a notes card: a mark, a name, and its value at the far end; a value too long for that end goes under
    // the name, whole (a list of hosts is read, never cut).
    component Line: Item {
        id: line
        property string glyph: ""
        property string label: ""
        property string value: ""
        property bool last: false
        readonly property real start: line.glyph.length > 0 ? PrismTheme.dp(43) : PrismTheme.dp(14)
        readonly property bool stacked: valueMeasure.implicitWidth > line.width - line.start - lineName.width - PrismTheme.dp(30)
        width: parent ? parent.width : 0
        height: line.stacked ? lineName.height + lineValue.implicitHeight + PrismTheme.dp(34) : PrismTheme.dp(48)
        PrismGlyph {
            x: PrismTheme.dp(14)
            y: line.stacked ? PrismTheme.dp(15) : (line.height - height) / 2
            visible: line.glyph.length > 0
            text: line.glyph
            filled: true
            iconSize: PrismTheme.dp(17)
            color: PrismTheme.ink2
        }
        PrismText {
            id: lineName
            x: line.start
            y: line.stacked ? PrismTheme.dp(14) : (line.height - height) / 2
            width: Math.min(implicitWidth, line.width * 0.5)
            text: line.label
            elide: Text.ElideRight
            font.pixelSize: PrismTheme.row
            font.weight: Font.DemiBold
        }
        PrismText {
            id: valueMeasure
            visible: false
            text: line.value
            font.pixelSize: PrismTheme.small
        }
        PrismText {
            id: lineValue
            x: line.stacked ? line.start : lineName.x + lineName.width + PrismTheme.dp(16)
            y: line.stacked ? lineName.y + lineName.height + PrismTheme.dp(4) : (line.height - height) / 2
            width: line.width - x - PrismTheme.dp(14)
            horizontalAlignment: line.stacked ? Text.AlignLeft : Text.AlignRight
            text: line.value
            wrapMode: line.stacked ? Text.Wrap : Text.NoWrap
            maximumLineCount: line.stacked ? 40 : 1
            elide: line.stacked ? Text.ElideNone : Text.ElideRight
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            lineHeight: 1.2
        }
        Rectangle {
            visible: !line.last
            x: line.start
            width: line.width - x - PrismTheme.dp(10)
            anchors.bottom: parent.bottom
            height: 1
            color: PrismTheme.line
        }
    }
}
