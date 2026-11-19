import QtQuick
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.controls

// A group's head, said once (his 11-18: "Signal" over "Signal" was a basic error of hierarchy). The group's name, and
// under it what the group is for, taken from its master row: the first row named as the group (Clock › Clock), or the
// group's only row. A master that is a switch stands at the head's end and turns the whole group on or off; any other
// master gives the head its words and keeps only its control below (PrismSection.headlessKey).
Item {
    id: root
    // { title, rows }
    property var entry: ({ title: "", rows: [] })
    // The page's own head is bigger than a group's.
    property real size: PrismTheme.head
    // The line under the name may run past the name's own width (a folder's tab holds the name; the line sits on the body).
    property real lineWidth: root.width

    readonly property string title: String(root.entry?.title ?? "")
    readonly property var rows: Array.from(root.entry?.rows ?? [])
    function same(a: string, b: string): bool { return String(a ?? "").trim().toLowerCase() === String(b ?? "").trim().toLowerCase() }
    readonly property var master: root.rows.length === 0 ? null
        : root.same(root.rows[0].label, root.title) || root.rows.length === 1 ? root.rows[0] : null
    readonly property bool masterSwitch: root.master !== null && String(root.master.kind) === "switch"
    // The rows under the head: a master switch lives in the head; another master stays, without its name.
    readonly property var bodyRows: root.masterSwitch ? root.rows.slice(1) : root.rows
    readonly property string headlessKey: root.master !== null && !root.masterSwitch ? String(root.master.key ?? "") : ""
    readonly property string line: {
        if (!root.master) return ""
        const about = String(root.master.spec?.description ?? root.master.detail ?? "")
        // A master named otherwise than its group says its own name first: Badges › "Unread counts: the colour of…".
        return root.same(root.master.label, root.title) || about.length === 0 ? Translation.tr(about)
            : Translation.tr(String(root.master.label)) + " · " + Translation.tr(about)
    }
    // A master switch the page's lead took (PrismLead) still dims the group it heads.
    readonly property var leadMaster: root.entry?.lead ?? null
    readonly property bool on: {
        const _ = PrismModel.revision
        return root.masterSwitch ? Boolean(PrismModel.read(root.master)) : root.leadMaster ? Boolean(PrismModel.read(root.leadMaster)) : true
    }

    implicitHeight: Math.max(words.implicitHeight, root.masterSwitch ? toggle.height : 0)

    Column {
        id: words
        width: parent.width - (root.masterSwitch ? toggle.width + PrismTheme.dp(16) : 0)
        spacing: PrismTheme.dp(3)
        PrismText {
            width: parent.width
            text: Translation.tr(root.title)
            font.pixelSize: root.size
            font.weight: Font.DemiBold
            font.letterSpacing: -root.size * 0.012
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        PrismText {
            visible: text.length > 0
            width: root.lineWidth
            text: root.line
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.small
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
    PrismSwitch {
        id: toggle
        visible: root.masterSwitch
        anchors.right: parent.right
        y: Math.max(0, Math.round((words.children[0].implicitHeight - height) / 2))
        checked: root.on
        enabled: root.masterSwitch && !PrismModel.locked(root.master)
        onToggled: value => PrismModel.write(root.master, value)
    }
}
