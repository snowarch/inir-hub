pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import qs.modules.iris.preview
import qs.modules.iris.settings

// One area as Folio prints it, built once and kept by Folio's AreaPool: its title and sentence across, its live stage
// held still on the left with what it shows and the area's contents under it, its groups on a sheet to the right.
// The rows scroll as Classic's do (a wheel over them that glided head to head stuttered and kept the wheel from
// their sliders, 10-25); the stage follows the group being read.
Item {
    id: page
    required property string area
    property Item host
    // Classic names the area in its own head and holds the area's actions there.
    property bool titled: true
    property bool actions: true

    readonly property real d: Number(page.host?.d ?? IrisStyle.settingsDensity)
    function u(n: real): int { return Math.round(n * page.d) }
    readonly property var entry: IrisOptions.sectionById(page.area) ?? ({})
    // The page in front: only then do writes reach its rows and its stage plays.
    readonly property bool live: page.visible && page.area === String(page.host?.section ?? "")
    readonly property bool whole: rows.whole
    // Every page leads its sheet with the stage as a band across it, the way Apple's panes open on their picture: a stage
    // column beside the sheet squeezed every control into what was left (his 10-30, Classic first, then Folio too).

    Column {
        id: title
        visible: page.titled
        width: page.width - (titleActions.visible ? titleActions.width + page.u(16) : 0)
        spacing: page.u(4)
        IrisText {
            width: parent.width
            elide: Text.ElideRight
            text: Translation.tr(String(page.entry.title ?? ""))
            color: IrisStyle.text
            font.family: IrisStyle.fontTitle
            font.pixelSize: page.u(26)
            font.weight: IrisStyle.weight(Font.DemiBold)
            font.letterSpacing: -Math.round(page.u(26) * 0.01)
        }
        IrisText {
            width: parent.width
            elide: Text.ElideRight
            text: Translation.tr(String(page.entry.subtitle ?? ""))
            color: IrisStyle.muted
            font.pixelSize: IrisStyle.typeBody
        }
    }

    // What can be done to the area (customize, restore) on the title's line, as a pane's toolbar holds it.
    Row {
        id: titleActions
        visible: page.titled && page.actions && actionsRepeater.count > 0
        anchors.right: parent.right
        y: page.u(4)
        spacing: page.u(6)
        Repeater {
            id: actionsRepeater
            model: page.live && page.actions ? (page.host?.pageActions ?? []) : []
            MouseArea {
                id: titleAct
                required property var modelData
                width: titleActRow.implicitWidth + page.u(22)
                height: page.u(32)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: String(titleAct.modelData.label ?? "")
                onClicked: titleAct.modelData.clicked()
                Rectangle { anchors.fill: parent; radius: IrisStyle.capsule(height); color: titleAct.containsMouse ? IrisStyle.fillHover : IrisStyle.fillQuiet }
                Row {
                    id: titleActRow
                    anchors.centerIn: parent
                    spacing: page.u(6)
                    MaterialSymbol { anchors.verticalCenter: parent.verticalCenter; text: String(titleAct.modelData.glyph ?? ""); iconSize: page.u(16); color: IrisStyle.text }
                    IrisText { anchors.verticalCenter: parent.verticalCenter; text: String(titleAct.modelData.label ?? ""); color: IrisStyle.text; font.pixelSize: IrisStyle.typeMeta }
                }
            }
        }
    }

    Item {
        id: areaBox
        y: page.titled ? title.height + page.u(18) : 0
        width: page.width
        height: page.height - y
        readonly property bool staged: stage.available

        ClippingRectangle {
            id: plate
            parent: bannerSlot
            visible: areaBox.staged
            width: bannerSlot.width
            height: bannerSlot.height
            radius: IrisStyle.radiusSheet
            color: IrisStyle.readingCard
            border.width: 1
            border.color: IrisStyle.hairline
            IrisGroupPreview {
                id: stage
                anchors.fill: parent
                anchors.margins: page.u(12)
                radius: Math.max(IrisStyle.radiusRow, IrisStyle.radiusSheet - page.u(12))
                standIn: true
                captionOutside: false
                playing: page.live
                // Home leads with the welcome over its rows, so its rows get the width.
                section: page.area === "general" ? "" : page.area
                niriValue: (section, key) => IrisNiri.value(IrisOptions.settings.find(spec => spec.niri === section && spec.key === key) ?? { niri: section, key: key })
                niriRevision: IrisNiri.revision
                group: page.stageGroup
            }
        }

        // The groups' sheet: rows on the body in solid, on a reading fill over glass (never glass on glass).
        Rectangle {
            id: sheet
            x: 0
            width: areaBox.width - x
            height: areaBox.height
            radius: IrisStyle.radiusSheet
            color: IrisStyle.glassy ? IrisStyle.readingSidebar : "transparent"
            // Classic's stage stays over the sheet while its rows scroll under it: a change is seen where it happens
            // (his 10-30: the band scrolled away with the first rows).
            Item {
                id: bannerSlot
                x: flick.x
                y: IrisStyle.glassy ? page.u(6) : 0
                width: flick.width - page.u(8)
                height: areaBox.staged ? Math.round(Math.min(width * 0.3, page.u(260), sheet.height * 0.34)) : 0
            }
            Flickable {
                id: flick
                anchors.fill: parent
                anchors.leftMargin: IrisStyle.glassy ? page.u(6) : 0
                anchors.rightMargin: IrisStyle.glassy ? page.u(6) : 0
                anchors.topMargin: (IrisStyle.glassy ? page.u(6) : 0) + (bannerSlot.height > 0 ? bannerSlot.height + page.u(10) : 0)
                contentHeight: rows.y + rows.implicitHeight + page.u(24)
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                ScrollBar.vertical: IrisScrollBar {}
                onContentYChanged: spyPace.restart()
                // Rows soften into a blur and fade at the edge with more past it, cut by the sheet's own curve (his
                // 10-30: plates hit a square clip inside the round sheet, and the soft edge was gone).
                layer.enabled: flickEdge.active
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: flickEdge.mask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
                AreaRows {
                    id: rows
                    y: bannerSlot.height > 0 ? page.u(4) : 0
                    width: flick.width - page.u(8)
                    section: page.area
                    host: page.host
                    voice: "folio"
                    live: page.live
                    reach: flick.contentY + flick.height * 1.5
                    // grouped like a form: each group a plate, its rows a hairline apart (the rows floated on the
                    // body and a page read as loose text, 10-29)
                    groupFill: IrisStyle.formPlate
                    reading: page.reading
                    onReveal: row => page.reveal(row)
                    onBring: item => page.bring(item)
                }
            }
            IrisScrollEdge {
                id: flickEdge
                flick: flick
                anchors.fill: flick
                reach: page.u(28)
                radius: IrisStyle.glassy ? Math.max(0, sheet.radius - page.u(6)) : 0
            }
        }
    }

    // ── The group being read: the head that has reached the upper fifth (at the foot, the last one in view).
    property string reading: ""
    readonly property string stageGroup: page.reading.length > 0 && stage.sceneFor(page.area, page.reading).length > 0 ? page.reading : ""
    Timer { id: spyPace; interval: 90; onTriggered: page.spy() }
    function spy(): void {
        const targets = rows.targets()
        if (targets.length === 0) { page.reading = ""; return }
        let found = targets[0].key
        const atEnd = flick.contentY >= flick.contentHeight - flick.height - 2 && flick.contentY > 0
        if (flick.contentY >= 1) {
            for (const target of targets) {
                const top = target.item.mapToItem(flick.contentItem, 0, 0).y - flick.contentY
                if (top > flick.height * (atEnd ? 0.92 : 0.2)) break
                found = target.key
            }
        }
        page.reading = found
    }
    onLiveChanged: if (page.live) spyPace.restart()

    // Asked from outside (a link, the CLI): put a group's head at the top, or a row a third down, with one glide.
    function showGroup(wanted: string): void {
        const lower = wanted.toLowerCase()
        const target = rows.targets().find(entry => entry.key === wanted || entry.key.toLowerCase() === lower
            || Translation.tr(entry.key).toLowerCase() === lower)
        if (target) {
            page.waiting = ""
            page.glideTo(target.item.mapToItem(flick.contentItem, 0, 0).y - page.u(8))
        } else if (rows.openRest(wanted)) {
            // A group resting under a tile (or the area's Fine-tune) opens first, then shows.
            page.waiting = wanted
            rows.builtUpTo = rows.blocks.length
        } else if (rows.builtUpTo < rows.blocks.length) {
            // A group still waiting below the fold is built first (with the rest), then shown.
            page.waiting = wanted
            rows.builtUpTo = rows.blocks.length
        } else {
            page.waiting = ""
        }
    }
    property string waiting: ""
    onWholeChanged: if (page.whole && page.waiting.length > 0) showSoon.restart()
    Timer { id: showSoon; interval: 120; onTriggered: if (page.waiting.length > 0) page.showGroup(page.waiting) }
    // Scrolls only as far as the item needs to stand whole in view, its top kept in sight when it is taller than the page.
    function bring(item: Item): void {
        const top = item.mapToItem(flick.contentItem, 0, 0).y
        const air = page.u(24)
        const to = Math.min(top - air, top + item.height + air - flick.height)
        if (to > flick.contentY) page.glideTo(to)
    }
    function reveal(row: Item): void { page.glideTo(row.mapToItem(flick.contentItem, 0, 0).y - flick.height * 0.3) }
    function glideTo(y: real): void {
        const to = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), y))
        if (Math.abs(to - flick.contentY) < 1) return
        glider.from = flick.contentY
        glider.to = to
        glider.restart()
    }
    NumberAnimation { id: glider; target: flick; property: "contentY"; duration: IrisStyle.morphDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: IrisStyle.morphCurve }
}
