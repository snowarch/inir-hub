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

    topPad: NihilStyle.s(8)
    bottomPad: NihilStyle.s(32)
    sidePad: NihilStyle.s(14)

    // A profile drawn as a plan of the screen: the panel, where the dash stands, how the workspaces line up.
    component Plan: Rectangle {
        id: plan
        property string profile: ""
        readonly property bool dashLeft: plan.profile === "vertical"
        readonly property bool dashBottom: plan.profile === "horizontal" || plan.profile === "dock"
        readonly property bool rowOfWorkspaces: plan.profile === "horizontal"
        width: NihilStyle.s(112)
        height: NihilStyle.s(70)
        radius: NihilStyle.r(4)
        color: "transparent"
        border.width: 1
        border.color: NihilStyle.hair

        Rectangle { visible: plan.profile !== "corner"; x: 4; y: 4; width: parent.width - 8; height: 2; color: NihilStyle.inkSoft }
        Rectangle {
            visible: plan.dashLeft
            x: 5; y: parent.height * 0.3; width: 4; height: parent.height * 0.45; radius: 2; color: NihilStyle.ink
        }
        Rectangle {
            visible: plan.dashBottom
            x: parent.width * 0.3; y: parent.height - 9; width: parent.width * 0.4; height: 4; radius: 2; color: NihilStyle.ink
        }
        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                x: plan.rowOfWorkspaces ? plan.width * 0.24 + index * plan.width * 0.18 : plan.width - 16
                y: plan.rowOfWorkspaces ? 11 : plan.height * 0.24 + index * plan.height * 0.18
                width: plan.rowOfWorkspaces ? plan.width * 0.15 : 9
                height: plan.rowOfWorkspaces ? 7 : plan.height * 0.14
                radius: 1
                visible: plan.profile !== "dock"
                color: index === 0 ? NihilStyle.ink : NihilStyle.inkFaint
            }
        }
        Rectangle {
            x: parent.width * 0.3; y: parent.height * 0.3
            width: parent.width * (plan.dashLeft || plan.profile === "corner" ? 0.44 : 0.4); height: parent.height * 0.36
            radius: 2; color: "transparent"; border.width: 1; border.color: NihilStyle.inkSoft
        }
        NSpark {
            visible: plan.profile === "corner"
            x: -size * 0.3; y: -size * 0.3; size: NihilStyle.s(18)
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

            delegate: NGlass {
                id: card

                required property var modelData
                readonly property bool isWorn: root.worn === card.modelData.id
                readonly property bool isSaved: root.saved[card.modelData.id] !== undefined

                width: root.cardWidth
                height: NihilStyle.s(164)
                radius: NihilStyle.rCard
                ignite: card.isWorn ? 0.6 : 0
                spark: card.isWorn ? 1 : 0

                Plan {
                    anchors.right: parent.right
                    anchors.rightMargin: NihilStyle.s(16)
                    y: NihilStyle.s(18)
                    profile: card.modelData.id
                }

                Column {
                    x: NihilStyle.s(18)
                    y: NihilStyle.s(16)
                    width: card.width - NihilStyle.s(36) - NihilStyle.s(124)
                    spacing: NihilStyle.s(4)

                    NLabel {
                        text: card.isWorn ? Translation.tr("In use") : Translation.tr("Profile")
                        strong: card.isWorn
                    }
                    NDisplay {
                        width: parent.width
                        text: Translation.tr(card.modelData.name)
                        elide: Text.ElideRight
                        size: NihilStyle.s(30)
                        bloom: card.isWorn ? 0.7 : 0
                    }
                    NText {
                        width: parent.width
                        text: Translation.tr(card.modelData.description)
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
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
