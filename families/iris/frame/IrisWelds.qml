pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

// Every desktop widget joined to the frame (IrisWidgetWeld), by output. A weld reads its neighbours here so two bodies
// on one wall are one silhouette, and the frame's own window reads them all: it owns the line a weld crosses and
// holds the widgets on the frame while the compositor shows its overview (the desktop below zooms away with them).
Singleton {
    id: root

    property var list: []
    function add(weld: var): void {
        if (!root.list.includes(weld)) root.list = root.list.concat([weld])
    }
    function remove(weld: var): void {
        if (root.list.includes(weld)) root.list = root.list.filter(other => other !== weld)
    }
    function on(output: string): var {
        return root.list.filter(weld => weld.outputName === output && weld.melt > 0)
    }
    // The compositor zoomed the desktop out: the frame stays, so what is joined to it stays with it.
    readonly property bool overview: NiriService.inOverview
}
