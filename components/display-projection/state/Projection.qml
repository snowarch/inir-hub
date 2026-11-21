pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import "plan.js" as Plan

// What Display Projection knows and does. It reads the displays only while its window is open, and once more when a
// mode is picked; it runs commands only for the mode the person picks. Turning a display off or on goes through
// `niri msg output`, which lasts until niri restarts and never touches the person's niri config.
Singleton {
    id: root

    property bool open: false
    // The window lives while open and for the moment after, while the card leaves the way it came; it goes at once
    // when its own screen is about to turn off.
    property bool alive: false
    // The screen the window opens on: the focused one when it opens (a live window never moves).
    property var screen: null
    readonly property bool supported: CompositorService.niriNative

    property var outputs: []
    property bool outputsRead: false
    property string readError: ""
    property var mirrors: []
    // Whether wl-mirror is on the PATH: -1 not asked yet, 0 missing, 1 there.
    property int wlMirror: -1
    // The second screen the person chose when several are connected ("" for the first one).
    property string requestedTarget: ""

    readonly property var primary: Plan.primary(root.outputs)
    readonly property var externals: Plan.externals(root.outputs)
    readonly property var target: Plan.resolveTarget(root.outputs, root.requestedTarget)
    readonly property string activeMode: root.outputsRead ? Plan.detectMode(root.outputs, root.mirrors.length > 0) : ""

    // idle, applying, done or failed, with the mode being put on and, when it failed, why.
    property string phase: "idle"
    property string applyingMode: ""
    property string failure: ""

    function show(): void {
        if (root.open)
            return
        // A window still leaving stays on its screen: a live window never moves.
        if (!root.alive)
            root.screen = GlobalStates.focusedScreen
        root.wlMirror = -1
        leaveLater.stop()
        root.alive = true
        root.open = true
        root.refresh()
    }
    // On the next turn: the click or key that asks for it belongs to the window being closed.
    function hide(): void { closeLater.restart() }
    function toggle(): void {
        if (root.open)
            root.hide()
        else
            root.show()
    }

    function modeName(mode: string): string {
        switch (mode) {
        case "pcOnly": return Translation.tr("PC screen only")
        case "duplicate": return Translation.tr("Duplicate")
        case "extend": return Translation.tr("Extend")
        case "secondOnly": return Translation.tr("Second screen only")
        }
        return mode
    }

    // Whether a mode can be picked now; the window says why when it can't.
    function canUse(mode: string): bool {
        if (!root.supported || !root.outputsRead || root.phase === "applying" || !root.primary)
            return false
        if (mode === "pcOnly")
            return true
        if (!root.target)
            return false
        return mode !== "duplicate" || root.wlMirror !== 0
    }

    // Put a mode on: read the displays again, then run its steps one after the other.
    function apply(mode: string): void {
        if (root.phase === "applying")
            return
        root.failure = ""
        root.applyingMode = mode
        if (!root.supported) {
            root._fail(Translation.tr("Display Projection needs niri to switch displays"))
            return
        }
        root.phase = "applying"
        root._applyAfterRead = true
        root.refresh()
    }

    function refresh(): void {
        if (!root.supported || outputsProbe.running || mirrorsProbe.running || toolProbe.running)
            return
        outputsProbe.running = true
    }

    property bool _applyAfterRead: false
    property var _steps: []
    property var _step: null
    property int _waitTries: 0

    onOpenChanged: {
        if (!root.open && root.phase !== "applying") {
            root.phase = "idle"
            root.failure = ""
        }
    }

    function _firstLine(text: string): string {
        return String(text ?? "").trim().split("\n")[0].trim()
    }

    function _readDone(): void {
        if (!root._applyAfterRead)
            return
        root._applyAfterRead = false
        if (root.readError.length > 0) {
            root._fail(Translation.tr("Couldn't read the displays: %1").arg(root.readError))
            return
        }
        const result = Plan.plan(root.applyingMode, root.outputs, root.requestedTarget, root.mirrors)
        const why = root._planError(result)
        if (why.length > 0) {
            root._fail(why)
            return
        }
        // The window goes with its screen: close it first, it comes back if something fails.
        if (root.open && root.screen && Plan.turnsOff(result.steps, String(root.screen.name)))
            root._close(true)
        root._steps = result.steps
        root._next()
    }

    function _planError(result: var): string {
        if (result.error === "noDisplays")
            return Translation.tr("No displays detected")
        if (result.error === "noSecond")
            return Translation.tr("No second screen connected")
        if (result.error)
            return Translation.tr("Unknown mode %1: use pcOnly, duplicate, extend or secondOnly").arg(root.applyingMode)
        if (root.wlMirror === 0 && result.steps.some(s => s.kind === "mirror"))
            return Translation.tr("wl-mirror is not installed: Duplicate won't work")
        return ""
    }

    function _next(): void {
        if (root._steps.length === 0) {
            root._finish()
            return
        }
        const step = root._steps[0]
        root._steps = root._steps.slice(1)
        root._step = step
        if (step.kind === "on" || step.kind === "off") {
            runner.command = ["niri", "msg", "output", step.name, step.kind]
            runner.running = true
        } else if (step.kind === "stop") {
            runner.command = ["kill"].concat(step.pids)
            runner.running = true
        } else if (step.kind === "wait") {
            root._waitTries = 0
            waitProbe.running = true
        } else if (step.kind === "mirror") {
            Quickshell.execDetached(["wl-mirror", "--fullscreen-output", step.target, step.source])
            mirrorSettle.restart()
        } else {
            root._later(0)
        }
    }

    function _later(ms: int): void {
        stepLater.interval = ms
        stepLater.restart()
    }

    function _finish(): void {
        root._step = null
        root.phase = "done"
        root.refresh()
        if (root.open)
            doneLater.restart()
        else
            root.phase = "idle"
    }

    function _fail(words: string): void {
        root._steps = []
        root._step = null
        root._applyAfterRead = false
        root.failure = words
        root.phase = "failed"
        if (!root.open)
            root.show()
    }

    function _close(atOnce: bool): void {
        root.open = false
        if (atOnce || FamilyStyle.recedeDuration <= 0) {
            leaveLater.stop()
            root.alive = false
        } else {
            leaveLater.restart()
        }
    }

    Timer { id: closeLater; interval: 0; onTriggered: root._close(false) }
    Timer { id: leaveLater; interval: FamilyStyle.recedeDuration; onTriggered: root.alive = false }
    Timer { id: doneLater; interval: 650; onTriggered: if (root.phase === "done") root.hide() }
    Timer { id: stepLater; interval: 0; onTriggered: root._next() }
    // Hot-plugging a display while the window is open shows up here.
    Timer {
        interval: 2000
        repeat: true
        running: root.open && root.supported && root.phase !== "applying"
        onTriggered: root.refresh()
    }

    Process {
        id: outputsProbe
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector { id: outputsText }
        stderr: StdioCollector { id: outputsErr }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.outputs = Plan.parseOutputs(outputsText.text)
                    root.outputsRead = true
                    root.readError = ""
                } catch (e) {
                    root.readError = String(e)
                }
            } else {
                root.readError = root._firstLine(outputsErr.text) || Translation.tr("niri msg exited with code %1").arg(exitCode)
            }
            mirrorsProbe.running = true
        }
    }

    // pgrep exits 1 when no wl-mirror runs: that is an answer, not a failure.
    Process {
        id: mirrorsProbe
        command: ["pgrep", "-a", "-x", "wl-mirror"]
        stdout: StdioCollector { id: mirrorsText }
        onExited: exitCode => {
            root.mirrors = exitCode === 0 ? Plan.parseMirrors(mirrorsText.text) : []
            if (root.wlMirror < 0)
                toolProbe.running = true
            else
                root._readDone()
        }
    }

    Process {
        id: toolProbe
        command: ["sh", "-c", "command -v wl-mirror"]
        onExited: exitCode => {
            root.wlMirror = exitCode === 0 ? 1 : 0
            root._readDone()
        }
    }

    Process {
        id: runner
        stdout: StdioCollector { id: runnerOut }
        stderr: StdioCollector { id: runnerErr }
        onExited: exitCode => {
            const step = root._step
            if (!step)
                return
            if (step.kind === "stop") {
                // Give the old mirror a moment to leave before a new one starts.
                root._later(200)
                return
            }
            if (exitCode !== 0) {
                const why = root._firstLine(runnerErr.text) || root._firstLine(runnerOut.text)
                    || Translation.tr("exit code %1").arg(exitCode)
                root._fail((step.kind === "on" ? Translation.tr("niri couldn't turn on %1: %2")
                                               : Translation.tr("niri couldn't turn off %1: %2")).arg(step.name).arg(why))
                return
            }
            root._later(0)
        }
    }

    // A display just turned on takes a moment to appear; wl-mirror needs it there. Waits up to about 1.5 s.
    Process {
        id: waitProbe
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector { id: waitText }
        onExited: exitCode => {
            const step = root._step
            if (!step)
                return
            let ready = false
            if (exitCode === 0) {
                try {
                    root.outputs = Plan.parseOutputs(waitText.text)
                    ready = root.outputs.some(o => o.name === step.name && o.enabled)
                } catch (e) {}
            }
            if (ready || ++root._waitTries >= 15)
                root._later(0)
            else
                waitAgain.restart()
        }
    }
    Timer { id: waitAgain; interval: 100; onTriggered: waitProbe.running = true }

    // wl-mirror runs on its own, so it keeps mirroring after the window closes. Look once that it stayed.
    Timer { id: mirrorSettle; interval: 600; onTriggered: mirrorCheck.running = true }
    Process {
        id: mirrorCheck
        command: ["pgrep", "-a", "-x", "wl-mirror"]
        stdout: StdioCollector { id: mirrorCheckText }
        onExited: exitCode => {
            const step = root._step
            if (!step)
                return
            const found = exitCode === 0 && Plan.parseMirrors(mirrorCheckText.text).some(m => m.target === step.target)
            if (found)
                root._later(0)
            else
                root._fail(Translation.tr("wl-mirror closed right after starting. Run it in a terminal to see why: %1")
                    .arg("wl-mirror --fullscreen-output " + step.target + " " + step.source))
        }
    }
}
