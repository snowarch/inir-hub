pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import "../state/NihilProfiles.js" as Profiles

// The four whole desktop layouts: wear one, keep the current desktop over it, or take it back to how it came. A profile
// holds the structure of the desktop and never its look.
NScroller {
    id: root

    readonly property var nihil: Config.options?.nihil
    readonly property string worn: root.nihil?.profile ?? "vertical"
    readonly property var saved: root.nihil?.savedProfiles ?? ({})
    readonly property real cardWidth: (root.innerWidth - NihilStyle.s(14)) / 2

    function valuesOf(id: string): var {
        return root.saved[id] ?? Profiles.list.find(profile => profile.id === id)?.values ?? null
    }

    function wear(id: string): void {
        const values = root.valuesOf(id)
        if (!values)
            return
        const updates = { "nihil.profile": id }
        for (const key in values)
            updates["nihil." + key] = values[key]
        Config.setNestedValues(updates)
    }

    function keep(id: string): void {
        const values = {}
        for (const key of Profiles.keys)
            values[key] = Config.getNestedValue("nihil." + key, undefined)
        const next = Object.assign({}, root.saved)
        next[id] = values
        Config.setNestedValues({ "nihil.savedProfiles": next, "nihil.profile": id })
    }

    function restore(id: string): void {
        const next = Object.assign({}, root.saved)
        delete next[id]
        Config.setNestedValue("nihil.savedProfiles", next)
        if (root.worn === id) {
            const updates = { "nihil.profile": id }
            const values = Profiles.list.find(profile => profile.id === id)?.values ?? {}
            for (const key in values)
                updates["nihil." + key] = values[key]
            Config.setNestedValues(updates)
        }
    }

    bottomPad: NihilStyle.s(32)

    // A profile drawn as a small screen: the panel, where the dash stands, how the workspaces line up.
    component Plan: Rectangle {
        id: plan
        property string profile: ""
        property bool worn: false
        readonly property bool dashLeft: plan.profile === "vertical"
        readonly property bool dashBottom: plan.profile === "horizontal" || plan.profile === "dock"
        readonly property bool rowOfWorkspaces: plan.profile === "horizontal"
        readonly property real u: plan.width / 100
        radius: NihilStyle.r(10)
        color: Qt.alpha("#000000", 0.28)
        border.width: 1
        border.color: plan.worn ? Qt.alpha(NihilStyle.accent, 0.5) : NihilStyle.hair
        clip: true

        // The panel.
        Rectangle {
            visible: plan.profile !== "corner"
            x: plan.u * 3; y: plan.u * 3; width: plan.width - plan.u * 6; height: plan.u * 3.2
            radius: height / 2; color: NihilStyle.pieceRaised
        }
        // The hot corner.
        Rectangle {
            visible: plan.profile === "corner"
            x: plan.u * 3; y: plan.u * 3; width: plan.u * 5; height: width
            radius: width / 2; color: NihilStyle.accent
        }
        // The dash.
        Rectangle {
            visible: plan.dashLeft
            x: plan.u * 3; y: plan.height * 0.3; width: plan.u * 3.4; height: plan.height * 0.44
            radius: width / 2; color: NihilStyle.pieceRaised
        }
        Rectangle {
            visible: plan.dashBottom
            x: plan.width * 0.32; y: plan.height - plan.u * 7; width: plan.width * 0.36; height: plan.u * 3.6
            radius: height / 2; color: NihilStyle.pieceRaised
        }
        // The workspaces.
        Repeater {
            model: plan.profile === "dock" ? 0 : 3
            delegate: Rectangle {
                required property int index
                x: plan.rowOfWorkspaces ? plan.width * 0.3 + index * plan.width * 0.14 : plan.width - plan.u * 13
                y: plan.rowOfWorkspaces ? plan.u * 9 : plan.height * 0.26 + index * plan.height * 0.17
                width: plan.rowOfWorkspaces ? plan.width * 0.12 : plan.u * 9
                height: plan.rowOfWorkspaces ? plan.u * 6 : plan.height * 0.13
                radius: plan.u * 1.2
                color: index === 0 ? Qt.alpha(NihilStyle.ink, 0.3) : NihilStyle.piece
            }
        }
        // The windows.
        Rectangle {
            x: plan.width * (plan.dashLeft ? 0.2 : 0.16)
            y: plan.height * (plan.rowOfWorkspaces ? 0.4 : 0.26)
            width: plan.width * (plan.rowOfWorkspaces || plan.profile === "dock" ? 0.68 : 0.56)
            height: plan.height * (plan.dashBottom ? 0.42 : 0.5)
            radius: plan.u * 1.6
            color: NihilStyle.piece
            border.width: 1
            border.color: NihilStyle.hair
        }
    }

    NText {
        x: NihilStyle.s(6)
        width: root.innerWidth - NihilStyle.s(12)
        bottomPadding: NihilStyle.s(12)
        text: root.worn === "custom" ? Translation.tr("You changed this desktop by hand. Keep it over a profile to have it back later.")
            : Translation.tr("Each profile is a whole desktop layout, and your colours stay as they are.")
        wrapMode: Text.Wrap
        color: NihilStyle.inkSoft
    }

    Flow {
        width: root.innerWidth
        spacing: NihilStyle.s(14)

        Repeater {
            model: Profiles.list

            delegate: NWell {
                id: card

                required property var modelData
                readonly property bool isWorn: root.worn === card.modelData.id
                readonly property bool isSaved: root.saved[card.modelData.id] !== undefined

                width: root.cardWidth
                height: NihilStyle.s(14) * 2 + plan.height + about.height + NihilStyle.s(70)
                radius: NihilStyle.r(22)
                lit: card.isWorn ? 0.8 : 0

                Plan {
                    id: plan
                    x: NihilStyle.s(14)
                    y: NihilStyle.s(14)
                    width: card.width - NihilStyle.s(28)
                    height: Math.round(width * 0.4)
                    profile: card.modelData.id
                    worn: card.isWorn
                }

                Column {
                    id: about
                    x: NihilStyle.s(18)
                    anchors.top: plan.bottom
                    anchors.topMargin: NihilStyle.s(14)
                    width: card.width - NihilStyle.s(36)
                    spacing: NihilStyle.s(3)

                    NText {
                        width: parent.width
                        text: Translation.tr(card.modelData.name)
                        font.pixelSize: NihilStyle.textLarge
                        font.weight: Font.DemiBold
                    }
                    NText {
                        width: parent.width
                        height: NihilStyle.s(34)
                        text: Translation.tr(card.modelData.description)
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignTop
                        color: NihilStyle.inkSoft
                    }
                }

                Row {
                    x: NihilStyle.s(14)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(12)
                    spacing: NihilStyle.s(4)

                    NButton {
                        icon: card.isWorn ? "check" : ""
                        label: card.isWorn ? Translation.tr("In use") : Translation.tr("Use")
                        lit: card.isWorn
                        onClicked: root.wear(card.modelData.id)
                    }
                    NButton {
                        label: Translation.tr("Keep current")
                        onClicked: root.keep(card.modelData.id)
                    }
                    NButton {
                        visible: card.isSaved
                        icon: "undo"
                        label: Translation.tr("Restore")
                        onClicked: root.restore(card.modelData.id)
                    }
                }
            }
        }
    }
}
