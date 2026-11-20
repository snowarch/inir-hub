import QtQuick
import QtQuick.Shapes
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

/**
 * Edit marks of the bar, one file for both bars. Loaded over the modules only while the shell layout
 * edit mode is on for this screen. Every module gets a hairline outline and a name on hover. Press
 * and drag lifts it: a ghost follows the pointer, the modules after the caret ease aside, a caret
 * shows the landing slot across groups. Release drops it; far off the bar it removes it. A press
 * that does not move is not taken (pointer handlers only watch), so the module still opens.
 * Right click on a module or on the empty bar opens the edit sheets.
 *
 * zones: [{ name, repeater, rtl }]. The repeater's delegates are the modules in config order
 * (a Loader, or a BarGroup holding one); rtl is for a zone that lays out right to left.
 */
Item {
    id: root

    property var zones: []
    property var screenObject: null
    property bool barBottom: false

    // Module slots in this item's coordinates, refreshed by a timer while idle (never mid-drag).
    property var slots: []
    readonly property var holes: root.slots.map(s => ({ x: s.x, y: s.y, width: s.w, height: s.h }))
    readonly property bool dragging: root.drag !== null
    property var drag: null
    property real px: 0
    property real py: 0
    readonly property real removeReach: 40
    readonly property bool removing: root.drag !== null
        && (root.barBottom ? -root.py : root.py - root.height) > root.removeReach
    readonly property var landing: (root.drag !== null && !root.removing) ? root._landing(root.px) : null

    readonly property string screenName: root.screenObject?.name ?? ""
    readonly property int animMs: Appearance.animationsEnabled ? Appearance.animation.elementMoveFast.duration : 0

    function _collect() {
        const out = []
        for (let zi = 0; zi < root.zones.length; ++zi) {
            const z = root.zones[zi]
            const ids = BarModules.ids(z.name)
            const rep = z.repeater
            if (!rep) continue
            for (let i = 0; i < rep.count && i < ids.length; ++i) {
                const host = rep.itemAt(i)
                if (!host || !host.visible || !(host.width > 0)) continue
                const holder = (host.items && host.items.length > 0) ? host.items[0] : host
                const content = holder.item ?? null
                const p = host.mapToItem(root, 0, 0)
                out.push({
                    zone: z.name, index: i, id: ids[i], rtl: z.rtl === true, host: host,
                    standIn: !content || !(content.implicitWidth >= 1) || content.visible === false,
                    x: Math.round(p.x), y: Math.round(p.y), w: Math.round(host.width), h: Math.round(host.height)
                })
            }
        }
        return out
    }
    function refresh() {
        if (root.dragging) return
        const next = root._collect()
        const key = s => s.map(m => m.zone + m.index + m.id + m.x + "," + m.y + "," + m.w + "," + m.h + m.standIn).join("|")
        if (key(next) !== key(root.slots)) root.slots = next
    }
    Timer {
        interval: 140
        repeat: true
        running: !root.dragging
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Where a drop at pointer x would land: the zone nearest to it and the slot among its modules.
    function _landing(x) {
        const byZone = {}
        for (const s of root.slots) (byZone[s.zone] = byZone[s.zone] ?? []).push(s)
        let best = null, bestD = 1e9
        for (const name of Object.keys(byZone)) {
            const list = byZone[name]
            let lo = 1e9, hi = -1e9
            for (const s of list) { lo = Math.min(lo, s.x); hi = Math.max(hi, s.x + s.w) }
            const d = x < lo ? lo - x : x > hi ? x - hi : 0
            if (d < bestD) { bestD = d; best = { zone: name, list: list } }
        }
        if (!best) return null
        const list = best.list, rtl = list[0].rtl
        let idx = 0
        for (const s of list) if (rtl ? (s.x + s.w / 2 > x) : (s.x + s.w / 2 < x)) idx++
        const n = list.length
        let cx
        if (rtl) cx = idx < n ? list[idx].x + list[idx].w + 3 : list[n - 1].x - 3
        else cx = idx < n ? list[idx].x - 3 : list[n - 1].x + list[n - 1].w + 3
        return { zone: best.zone, index: idx, x: cx, rtl: rtl }
    }

    function beginDrag(slot) {
        root.drag = { zone: slot.zone, index: slot.index, id: slot.id }
    }
    function dragTo(x, y) { root.px = x; root.py = y }
    function endDrag() {
        const d = root.drag
        if (!d) return
        const land = root.landing
        const remove = root.removing
        root.drag = null
        if (remove) BarModules.remove(d.zone, d.index)
        else if (land) BarModules.move(d.zone, d.index, land.zone, land.index)
    }
    function cancelDrag() { root.drag = null }

    readonly property var dragInfo: root.drag ? BarModules.info(root.drag.id) : ({ name: "", icon: "widgets" })
    readonly property var dragSlot: {
        if (!root.drag) return null
        for (const s of root.slots) if (s.zone === root.drag.zone && s.index === root.drag.index) return s
        return null
    }

    DragEscape {
        active: root.dragging
        onCancel: root.cancelDrag()
    }

    // Right click on the empty bar: the bar's sheet. Sits under the module marks.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: ShellEditSession.openSheet("bar", "", root.screenName,
            BarModules.screenRect(root, root.Window.window, root.screenObject, root.barBottom))
    }

    Repeater {
        model: root.slots
        delegate: Item {
            id: mark
            required property var modelData
            readonly property bool lifted: root.drag !== null && root.drag.zone === modelData.zone
                && root.drag.index === modelData.index
            readonly property var meta: BarModules.info(modelData.id)
            // Modules after the caret in the landing zone step aside by the ghost's width.
            readonly property real shift: {
                const l = root.landing
                if (!l || lifted || l.zone !== modelData.zone) return 0
                const after = l.rtl ? modelData.index >= l.index : modelData.index >= l.index
                if (!after) return 0
                return (l.rtl ? -1 : 1) * (ghost.width + 6)
            }
            x: modelData.x; y: modelData.y; width: modelData.w; height: modelData.h

            Translate { id: slide; x: mark.shift
                Behavior on x { enabled: root.animMs > 0; NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } } }
            transform: slide
            readonly property Item host: modelData.host
            onHostChanged: if (host) host.transform = [hostSlide]
            Component.onCompleted: if (host) host.transform = [hostSlide]
            Component.onDestruction: if (host) host.transform = []
            Translate { id: hostSlide; x: slide.x }

            Rectangle {
                anchors.fill: parent
                visible: !modelData.standIn
                radius: Math.min(height / 2, Appearance.rounding.small)
                color: mark.lifted ? ColorUtils.applyAlpha(Appearance.colors.colLayer0, 0.7) : "transparent"
                border.width: 1
                border.color: mark.lifted ? Appearance.colors.colPrimary : Appearance.colors.colOutline
                opacity: hover.hovered || mark.lifted ? 1 : 0.7
            }

            // A module that shows nothing right now: a dashed stand-in so it can still be carried.
            Item {
                anchors.fill: parent
                visible: modelData.standIn
                opacity: mark.lifted ? 0.5 : 1
                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeColor: Appearance.colors.colOutline
                        strokeWidth: 1
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [3, 3]
                        fillColor: ColorUtils.applyAlpha(Appearance.colors.colLayer1, 0.6)
                        startX: 1; startY: 1
                        PathLine { x: mark.width - 1; y: 1 }
                        PathLine { x: mark.width - 1; y: mark.height - 1 }
                        PathLine { x: 1; y: mark.height - 1 }
                        PathLine { x: 1; y: 1 }
                    }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    width: Math.min(implicitWidth, mark.width - 6)
                    clip: true
                    MaterialSymbol { anchors.verticalCenter: parent.verticalCenter
                        text: mark.meta.icon; iconSize: Appearance.font.pixelSize.normal
                        color: Appearance.colors.colSubtext }
                    StyledText { anchors.verticalCenter: parent.verticalCenter
                        text: mark.meta.name; font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext }
                }
            }

            // Name on hover
            Rectangle {
                visible: hover.hovered && !root.dragging && !modelData.standIn
                anchors.centerIn: parent
                width: tagText.implicitWidth + 12
                height: tagText.implicitHeight + 6
                radius: height / 2
                color: Appearance.colors.colLayer2
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant
                StyledText { id: tagText; anchors.centerIn: parent; text: mark.meta.name
                    font.pixelSize: Appearance.font.pixelSize.smaller; color: Appearance.colors.colOnLayer2 }
            }

            HoverHandler { id: hover }
            // Watches only: a press that stays put is still the module's.
            DragHandler {
                target: null
                acceptedButtons: Qt.LeftButton
                dragThreshold: 6
                onActiveChanged: {
                    if (active) { root.beginDrag(mark.modelData); root.dragTo(root.mapFromItem(mark, centroid.position.x, centroid.position.y).x, root.mapFromItem(mark, centroid.position.x, centroid.position.y).y) }
                    else root.endDrag()
                }
                onCentroidChanged: if (active && root.dragging) {
                    const p = root.mapFromItem(mark, centroid.position.x, centroid.position.y)
                    root.dragTo(p.x, p.y)
                }
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onPressed: ShellEditSession.openSheet("module", mark.modelData.id, root.screenName,
                    BarModules.screenRect(mark, root.Window.window, root.screenObject, root.barBottom))
            }
        }
    }

    // Caret: where the module lands.
    Rectangle {
        visible: root.landing !== null
        x: (root.landing?.x ?? 0) - width / 2
        y: root.height * 0.15
        width: 3
        height: root.height * 0.7
        radius: 2
        color: Appearance.colors.colPrimary
        Behavior on x { enabled: root.animMs > 0; NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
    }

    // Ghost of the carried module; tints to the error colour and says Remove when it is off the bar.
    Rectangle {
        id: ghost
        visible: root.dragging
        z: 100
        width: ghostRow.implicitWidth + 20
        height: Math.min(root.height - 6, 34)
        x: root.px - width / 2
        y: Math.max(3, Math.min(root.height - height - 3, root.py - height / 2))
        radius: height / 2
        color: root.removing ? Appearance.colors.colError : Appearance.colors.colPrimaryContainer
        border.width: 1
        border.color: root.removing ? Appearance.colors.colOnError : Appearance.colors.colPrimary
        opacity: 0.94
        Row {
            id: ghostRow
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol { anchors.verticalCenter: parent.verticalCenter
                text: root.removing ? "delete" : root.dragInfo.icon
                iconSize: Appearance.font.pixelSize.normal
                color: root.removing ? Appearance.colors.colOnError : Appearance.colors.colOnPrimaryContainer }
            StyledText { anchors.verticalCenter: parent.verticalCenter
                text: root.removing ? Translation.tr("Remove") : root.dragInfo.name
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.removing ? Appearance.colors.colOnError : Appearance.colors.colOnPrimaryContainer }
        }
    }
}
