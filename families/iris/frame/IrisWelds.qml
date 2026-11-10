pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

// Every desktop widget joined to the frame (IrisWidgetWeld), by output. The frame's window reads them: each is a shape
// of its field, joined to the frame like any body that hangs from it, and the widget moves into the item that window
// lends here (`host`) so its content stands over its body.
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
        return root.list.filter(weld => weld.outputName === output && weld.melt > 0).slice(0, root.most)
    }
    // The frame's field holds twenty shapes for everything on it.
    readonly property int most: 8
    function shapesOn(output: string): var {
        return root.on(output).map((weld, index) => ({ id: "weld" + index, x: weld.box.x, y: weld.box.y,
            width: weld.box.width, height: weld.box.height, radius: weld.bodyRadius, corners: weld.corners,
            joins: "frame", fuse: weld.fuse * weld.melt }))
    }
    property var hosts: ({})
    function lend(output: string, item: var): void {
        const next = Object.assign({}, root.hosts)
        if (item) next[output] = item
        else delete next[output]
        root.hosts = next
    }
    function hostOn(output: string): var { return root.hosts[output] ?? null }
}
