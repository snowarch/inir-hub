// A page iRiS draws itself, hosted in Prism: Prism gives it the title and the room; the view scrolls on its own.
import QtQuick
import qs.modules.iris.prism.core

Item {
    id: root

    property var page: ({})
    property bool hosted: false
    property string eyebrow: ""
    property string title: ""
    property real keyRoom: 0

    PrismPoster {
        id: top
        x: PrismTheme.dp(32)
        width: parent.width - PrismTheme.dp(64)
        art: false
        pills: false
        page: root.page
        eyebrow: root.eyebrow
        title: root.title
        keyRoom: root.keyRoom
    }
    // iRiS's own pages keep 16 dp of air each side: given 16 more, their column stands on Prism's.
    Loader {
        id: view
        // Not named "air": the panel's PrismAura holds that id, and an id wins over a property (the page was 0 wide).
        readonly property real inset: String(root.page.view ?? "").includes("/prism/parts/") ? 0 : PrismTheme.dp(16)
        x: view.inset
        y: top.height
        width: parent.width - view.inset * 2
        height: parent.height - top.height
        active: root.hosted
        source: root.hosted ? root.page.view : ""
        // iRiS's own pages print their marks as Prism's covers, so a hosted list reads as the rail does.
        onLoaded: if (item && ("markDelegate" in item)) item.markDelegate = mark
        Component {
            id: mark
            PrismThumb {
                size: PrismTheme.dp(28)
                glyph: String(parent?.glyph ?? "circle")
                salt: String(parent?.name ?? "")
                tint: String(root.page?.tint ?? "grey")
            }
        }
    }
}
