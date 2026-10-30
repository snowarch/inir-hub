pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.settings
import qs.modules.iris.settings.layouts.drawer as Skins // so Quickshell mirrors the skins IrisSkin loads by url

// Drawer: Settings pulled out from the foot of the screen like a desk's drawer, the desktop above it left in view. Its
// head is a row of keys, the way the Dock holds apps: one per kind of area (Appearance, Island & Dock...), and the kind
// you are in opens into its areas by name, the open one inverted; a key you rest on says its name. An area is its title and live stage on the left and its groups flowing across columns; the grip raises
// the drawer to the top of the room for a long area.
Item {
    id: root
    property Item host
    readonly property real d: Number(root.host?.d ?? 1)
    function u(n: real): int { return Math.round(n * root.d) }

    readonly property alias searchSlot: searchSlot
    readonly property alias rowsSlot: rowsSlot
    readonly property real pageWidth: body.width
    readonly property real need: 0
    readonly property string voice: "drawer"
    readonly property bool ownsStage: true
    readonly property bool drawsRows: true
    // The head already says where it searches, and the field narrows on a small screen: one word fits any language.
    readonly property string searchHint: Translation.tr("Search")
    // Raised to the room's top; the engine reads it for the body's height.
    property bool tall: false

    readonly property bool windowed: root.host?.windowed ?? false
    readonly property var sections: root.host?.sections ?? []
    readonly property string section: String(root.host?.section ?? "")
    readonly property bool searching: root.host?.searching ?? false
    readonly property bool paged: Number(root.host?.advancedPage ?? -1) >= 0
    readonly property var noteCounts: root.host?.noteCounts ?? ({})
    readonly property color signal: IrisStyle["signal"] ?? IrisStyle.danger
    readonly property real pad: root.u(20)
    // Home, then each kind of area; a kind holding the open area spells its areas out, the rest stay one glyph.
    readonly property var shelves: {
        const out = root.sections.filter(entry => entry.id === "general").map(entry => ({ entry: entry, areas: [entry], cluster: -1 }))
        for (const category of IrisOptions.categories) {
            const areas = category.sections.map(id => root.sections.find(entry => entry.id === id)).filter(entry => !!entry)
            if (category.foot) areas.forEach(entry => out.push({ entry: entry, areas: [entry], cluster: category.cluster }))
            else if (areas.length > 0) out.push({ entry: category, areas: areas, cluster: category.cluster })
        }
        return out
    }

    // ── The grip: a click raises or lowers the drawer, a pull up or down says which.
    MouseArea {
        id: grip
        objectName: "drawerGrip"
        visible: !root.windowed
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.u(120)
        height: root.u(20)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: root.tall ? Translation.tr("Lower settings") : Translation.tr("Raise settings")
        property real from: 0
        property bool pulled: false
        onPressed: mouse => { grip.from = mouse.y; grip.pulled = false }
        onPositionChanged: mouse => {
            if (!grip.pressed || grip.pulled || Math.abs(mouse.y - grip.from) < root.u(12)) return
            grip.pulled = true
            root.tall = mouse.y < grip.from
        }
        onClicked: if (!grip.pulled) root.tall = !root.tall
        Rectangle {
            anchors.centerIn: parent
            width: root.u(grip.containsMouse ? 52 : 44)
            height: root.u(5)
            radius: height / 2
            color: grip.containsMouse ? IrisStyle.textTertiary : IrisStyle.hairlineStrong
            Behavior on width { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
        }
    }

    // ── The head: the search, the keys, the switch and the way out.
    RowLayout {
        id: head
        x: root.pad
        y: root.u(root.windowed ? 14 : 22)
        width: root.width - 2 * root.pad
        height: root.u(40)
        spacing: root.u(10)
        Item { id: searchSlot; Layout.preferredWidth: root.searchWidth; Layout.preferredHeight: root.u(36) }
        Item { id: keyGap; Layout.fillWidth: true; Layout.preferredHeight: root.u(40) }
        LayoutSwitch { id: switcher; host: root.host; voice: "drawer"; compact: true }
        HeadKey {
            glyph: root.windowed ? "layers" : "web_asset"
            name: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open as a window")
            onClicked: root.host.switchHost()
        }
        HeadKey { glyph: "close"; name: Translation.tr("Close settings"); onClicked: root.host.close() }
    }

    // The keys fit their room, never cut (a 1366 px laptop hid Lock & Login, Sources and the Hub past the edge): the
    // open kind names all its areas while they fit beside the search, then only the open one keeps its name and the
    // search narrows, and a narrow window gives the keys a row of their own. The room a rested name takes is kept, and
    // the widths come from the names, so laying the row out never feeds back into choosing it.
    IrisText { id: nameProbe; visible: false; font.pixelSize: IrisStyle.typeMeta; font.weight: IrisStyle.weight(Font.DemiBold) }
    FontMetrics { id: nameMetrics; font: nameProbe.font }
    function rowNeed(spellAll: bool, section: string): real {
        nameMetrics.font
        const named = entry => Math.ceil(nameMetrics.advanceWidth(Translation.tr(String(entry.title ?? "")))) + root.u(48)
        let width = 0, keys = 0, rest = 0
        root.shelves.forEach((shelf, i) => {
            if (i > 0 && root.shelves[i - 1].cluster !== shelf.cluster) { width += root.u(15); keys++ }
            const spelled = shelf.areas.length > 1 && shelf.areas.some(entry => entry.id === section)
            for (const entry of spelled ? shelf.areas : [shelf.entry]) {
                const on = (spelled || shelf.areas.length === 1) && String(entry.id) === section
                if (spellAll && (on || spelled)) width += named(entry)
                else { width += root.u(38); rest = Math.max(rest, named(entry) - root.u(38)) }
                keys++
            }
        })
        return width + Math.max(0, keys - 1) * root.u(2) + rest
    }
    readonly property real headFree: head.width - switcher.implicitWidth - 2 * root.u(36) - 4 * head.spacing
    // Measured for the widest area, so the search and the row's place hold still from one area to the next.
    readonly property real needSpelled: root.sections.reduce((most, entry) => Math.max(most, root.rowNeed(true, String(entry.id))), 0)
    readonly property real needTight: root.sections.reduce((most, entry) => Math.max(most, root.rowNeed(false, String(entry.id))), 0)
    // 0: one row, the open kind's areas by name; 1: one row of glyphs and one name at a time, the open area's until
    // another key is rested on; 2: the keys on a row of their own, by name if they fit there.
    readonly property int headFit: root.needSpelled + root.u(180) <= root.headFree ? 0
        : root.needTight + root.u(180) <= root.headFree ? 1 : 2
    readonly property bool spellAll: root.headFit === 0 || (root.headFit === 2 && root.needSpelled <= head.width)
    readonly property real searchWidth: root.headFit === 2 ? root.u(250)
        : Math.max(root.u(180), Math.min(root.u(250), root.headFree - (root.headFit === 0 ? root.needSpelled : root.needTight)))

    Flickable {
        id: keyFlick
        x: root.headFit < 2 ? head.x + keyGap.x : head.x
        y: root.headFit < 2 ? head.y : head.y + head.height + root.u(8)
        width: root.headFit < 2 ? keyGap.width : head.width
        height: root.u(40)
        contentWidth: keyRow.width
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: keyRow.width > keyFlick.width
        clip: true
        Row {
            id: keyRow
            x: Math.max(0, Math.round((keyFlick.width - width) / 2))
            height: keyFlick.height
            spacing: root.u(2)
            Repeater {
                model: root.shelves
                Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property bool starts: slot.index > 0 && root.shelves[slot.index - 1]?.cluster !== slot.modelData.cluster
                    readonly property bool spelled: slot.modelData.areas.length > 1 && !root.searching && !root.paged
                        && slot.modelData.areas.some(entry => entry.id === root.section)
                    width: slotRow.width
                    height: keyRow.height
                    // The open kind holds its areas in one tray, so a glyph beside the open area reads as its sibling.
                    Rectangle {
                        visible: slot.spelled
                        x: slot.starts ? root.u(17) : 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: slotRow.width - x
                        height: root.u(38)
                        radius: IrisStyle.capsule(height)
                        color: IrisStyle.fillQuiet
                    }
                    Row {
                        id: slotRow
                        height: parent.height
                        spacing: root.u(2)
                        Item {
                            visible: slot.starts
                            width: root.u(15)
                            height: parent.height
                            Rectangle { anchors.centerIn: parent; width: 1; height: root.u(20); color: IrisStyle.hairline }
                        }
                        AreaKey { visible: !slot.spelled; entry: slot.modelData.entry; areas: slot.modelData.areas; anchors.verticalCenter: parent.verticalCenter }
                        Repeater {
                            model: slot.spelled ? slot.modelData.areas : []
                            AreaKey {
                                required property var modelData
                                entry: modelData
                                areas: [modelData]
                                spelled: true
                                // A Repeater's key is made before it has a parent and keeps none on the way out.
                                anchors.verticalCenter: parent?.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }

    // ── The body: an area of the pool, or a search's results and a shared page on their own sheet.
    Item {
        id: body
        x: root.pad
        y: keyFlick.y + keyFlick.height + root.u(16)
        width: root.width - 2 * root.pad
        height: root.height - y - root.u(14)

        AreaPool {
            id: pool
            anchors.fill: parent
            current: root.searching ? pool.shown : root.section
            hidden: root.searching || root.paged
            settled: Boolean(root.host?.bodySettled ?? true)
            urlFor: id => Qt.resolvedUrl("DrawerPage.qml")
            propsFor: id => ({ host: root.host })
            onArrived: id => {
                if (root.wantedGroup.length > 0 && id === root.section) {
                    pool.shownItem?.showGroup?.(root.wantedGroup)
                    root.wantedGroup = ""
                }
            }
        }
        Rectangle {
            visible: root.searching || root.paged
            anchors.fill: parent
            radius: IrisStyle.radiusSheet
            color: IrisStyle.glassy ? IrisStyle.readingSidebar : "transparent"
            Item {
                id: rowsSlot
                anchors.fill: parent
                anchors.margins: IrisStyle.glassy ? root.u(6) : 0
            }
        }
    }

    // A group asked for by name lands once its area's page stands.
    property string wantedGroup: ""
    function showGroup(key: string): void {
        if (pool.shown === root.section && pool.shownItem?.showGroup) pool.shownItem.showGroup(key)
        else root.wantedGroup = key
    }

    // The key the pointer rests on names itself after a beat; sweeping on along the row, each names itself at once.
    property string resting: ""
    property string named: ""
    Timer { id: nameSoon; interval: 260; onTriggered: root.named = root.resting }

    // A key: its glyph; open, an inverted capsule with its name; spelled out or rested on, its name beside it. A kind's
    // key opens its first area.
    component AreaKey: MouseArea {
        id: key
        property var entry: ({})
        property var areas: [key.entry]
        property bool spelled: false
        readonly property string areaId: String(key.areas[0]?.id ?? "")
        readonly property bool on: key.areas.length === 1 && key.areaId === root.section && !root.searching && !root.paged
        readonly property bool found: !root.searching || key.areas.some(area => root.host?.matchedSections?.has(area.id) ?? false)
        readonly property bool open: (key.on && (root.spellAll || root.named.length === 0)) || (key.spelled && root.spellAll)
            || root.named === String(key.entry.id ?? "")
        readonly property int noted: key.areas.reduce((sum, area) => sum + Number(root.noteCounts[area.id] ?? 0), 0)
        width: key.open ? keyName.implicitWidth + root.u(48) : root.u(38)
        height: root.u(38)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        opacity: key.found ? 1 : 0.35
        Accessible.role: Accessible.PageTab
        Accessible.name: Translation.tr(String(key.entry.title ?? ""))
        Accessible.checked: key.on
        Behavior on width { enabled: IrisStyle.motionEnabled; NumberAnimation { duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve } }
        onContainsMouseChanged: {
            if (key.containsMouse) {
                root.resting = String(key.entry.id ?? "")
                if (root.named.length > 0) root.named = root.resting
                else nameSoon.restart()
            } else if (root.resting === String(key.entry.id ?? "")) {
                root.resting = ""
                Qt.callLater(() => { if (root.resting.length === 0) { nameSoon.stop(); root.named = "" } })
            }
        }
        onClicked: root.host.selectSection(key.areaId)
        Rectangle {
            anchors.fill: parent
            radius: IrisStyle.capsule(height)
            color: key.on ? IrisStyle.text : key.containsMouse || (key.open && !key.spelled) ? IrisStyle.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
        }
        MaterialSymbol {
            id: keyGlyph
            x: (root.u(38) - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            text: String(key.entry.icon ?? "settings")
            iconSize: root.u(19)
            fill: key.on ? 1 : 0
            color: key.on ? IrisStyle.surfaceOpaque : key.open ? IrisStyle.text : IrisStyle.subtext
        }
        IrisText {
            id: keyName
            x: root.u(36)
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - x - root.u(12))
            clip: true
            opacity: key.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: IrisStyle.duration(160); easing.type: IrisStyle.feedbackEasing } }
            text: Translation.tr(String(key.entry.title ?? ""))
            color: key.on ? IrisStyle.surfaceOpaque : key.spelled && !key.containsMouse ? IrisStyle.subtext : IrisStyle.text
            font.pixelSize: IrisStyle.typeMeta
            font.weight: IrisStyle.weight(Font.DemiBold)
        }
        Rectangle {
            visible: key.noted > 0
            x: root.u(26)
            y: root.u(7)
            width: root.u(7)
            height: width
            radius: width / 2
            color: root.signal
        }
    }

    component HeadKey: MouseArea {
        id: key
        property string glyph
        property string name
        Layout.preferredWidth: root.u(36)
        Layout.preferredHeight: root.u(36)
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: key.name
        Rectangle { anchors.fill: parent; radius: IrisStyle.capsule(height); color: key.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet }
        MaterialSymbol { anchors.centerIn: parent; text: key.glyph; iconSize: root.u(18); color: IrisStyle.text }
    }
}
