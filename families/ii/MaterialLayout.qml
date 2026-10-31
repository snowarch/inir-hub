import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.services

// Material's persistent surfaces for ShellLayoutController: the bar, the dock and the two sidebars, where each sits,
// what can change about it, and the room they take on the desktop. Everything here reads Material's own section.
QtObject {
    id: root

    readonly property var surfaces: [
        {
            id: "featureSidebar",
            families: ["ii"],
            kind: "edge",
            labelKey: "Feature sidebar",
            icon: "left_panel_open",
            layoutScope: "global",
            slots: ["left", "right"],
            editableProperties: ["sizeMode", "height", "thickness"],
            collisionPolicy: "swap-sidebar",
            resetScopes: ["surface", "family"]
        },
        {
            id: "systemSidebar",
            families: ["ii"],
            kind: "edge",
            labelKey: "System sidebar",
            icon: "right_panel_open",
            layoutScope: "global",
            slots: ["left", "right"],
            editableProperties: ["sizeMode", "height", "thickness"],
            collisionPolicy: "swap-sidebar",
            resetScopes: ["surface", "family"]
        },
        {
            id: "iiBar",
            families: ["ii"],
            kind: "edge",
            labelKey: "Bar",
            icon: "toolbar",
            layoutScope: "enabledOutputs",
            slots: ["top", "right", "bottom", "left"],
            editableProperties: [],
            collisionPolicy: "swap-edge",
            resetScopes: ["surface", "family"]
        },
        {
            id: "iiDock",
            families: ["ii"],
            kind: "edge",
            labelKey: "Dock",
            icon: "dock_to_bottom",
            layoutScope: "enabledOutputs",
            slots: ["top", "right", "bottom", "left"],
            editableProperties: ["thickness"],
            collisionPolicy: "swap-edge",
            resetScopes: ["surface", "family"]
        }
    ]
    readonly property var rebuilds: ["featureSidebar", "systemSidebar", "iiBar", "iiDock"]

    function _roleKey(surfaceId: string): string {
        return surfaceId === "featureSidebar" ? "feature" : surfaceId === "systemSidebar" ? "system" : ""
    }

    function _validSlot(value: var, fallback: string): string {
        const slot = String(value ?? "")
        return slot === "left" || slot === "right" ? slot : fallback
    }

    function sidebarAssignments(): var {
        const feature = root._validSlot(Config.options?.material?.sidebar?.shellLayout?.feature?.slot, "left")
        const system = root._validSlot(Config.options?.material?.sidebar?.shellLayout?.system?.slot, "right")
        if (feature !== system)
            return { featureSidebar: feature, systemSidebar: system, sanitized: false }
        return { featureSidebar: feature, systemSidebar: feature === "left" ? "right" : "left", sanitized: true }
    }

    function _sidebarSize(surfaceId: string): var {
        const role = Config.options?.material?.sidebar?.shellLayout?.[root._roleKey(surfaceId)]
        const mode = String(role?.sizeMode ?? "full")
        return {
            sizeMode: ["full", "fit", "custom"].includes(mode) ? mode : "full",
            customHeight: Math.round(Math.max(320, Math.min(2160, Number(role?.customHeight ?? 720)))),
            width: Math.round(Math.max(320, Math.min(900, Number(role?.width ?? 460)))),
            legacyFitEnabled: surfaceId === "featureSidebar"
                ? (Config.options?.material?.sidebar?.collapseWidgetsTab ?? false)
                : (Config.options?.material?.sidebar?.collapseEmptyNotifications ?? false)
        }
    }

    function surfaceState(surfaceId: string, desc: var, outputName: string): var {
        switch (surfaceId) {
        case "featureSidebar":
        case "systemSidebar": {
            const assignments = root.sidebarAssignments()
            const size = root._sidebarSize(surfaceId)
            return {
                ok: true,
                id: surfaceId,
                slot: assignments[surfaceId],
                scope: desc.layoutScope,
                outputName: outputName,
                sizeMode: size.sizeMode,
                customHeight: size.customHeight,
                width: size.width,
                legacyFitEnabled: size.legacyFitEnabled,
                sanitizedAssignment: assignments.sanitized,
                source: "material.sidebar.shellLayout"
            }
        }
        case "iiBar": {
            const vertical = Config.options?.material?.bar?.vertical ?? false
            const alternateEdge = Config.options?.material?.bar?.bottom ?? false
            return {
                ok: true,
                id: surfaceId,
                slot: vertical ? (alternateEdge ? "right" : "left") : (alternateEdge ? "bottom" : "top"),
                scope: desc.layoutScope,
                outputName: outputName,
                enabledOutputs: Config.options?.material?.bar?.screenList ?? [],
                source: "material.bar.vertical+material.bar.bottom"
            }
        }
        case "iiDock":
            return {
                ok: true,
                id: surfaceId,
                slot: Config.options?.material?.dock?.position ?? "bottom",
                enabled: Config.options?.material?.dock?.enable ?? true,
                thickness: Math.round(Config.options?.material?.dock?.height ?? 60),
                scope: desc.layoutScope,
                outputName: outputName,
                enabledOutputs: Config.options?.material?.dock?.screenList ?? [],
                source: "material.dock.position"
            }
        }
        return null
    }

    function _state(surfaceId: string, outputName: string): var {
        return ShellLayoutController.currentState(surfaceId, outputName)
    }

    // The surface already on `slot` that a move would swap with: the other sidebar, or the bar and the dock.
    function occupant(surfaceId: string, slot: string, outputName: string): string {
        const other = { featureSidebar: "systemSidebar", systemSidebar: "featureSidebar", iiBar: "iiDock", iiDock: "iiBar" }[surfaceId]
        if (!other)
            return ""
        const state = root._state(other, outputName)
        if (!state.ok || state.slot !== slot)
            return ""
        return other !== "iiDock" || state.enabled ? other : ""
    }

    function _barUpdates(slot: string): var {
        return {
            "material.bar.vertical": slot === "left" || slot === "right",
            "material.bar.bottom": slot === "bottom" || slot === "right"
        }
    }

    function moveSurface(surfaceId: string, slot: string, outputName: string, swapWith: string): bool {
        switch (surfaceId) {
        case "featureSidebar":
        case "systemSidebar": {
            const role = root._roleKey(surfaceId)
            const updates = {}
            updates["material.sidebar.shellLayout." + role + ".slot"] = slot
            updates["material.sidebar.shellLayout." + (role === "feature" ? "system" : "feature") + ".slot"] = slot === "left" ? "right" : "left"
            Config.setNestedValues(updates)
            return true
        }
        case "iiBar": {
            const updates = root._barUpdates(slot)
            if (swapWith === "iiDock") {
                const bar = root._state("iiBar", outputName)
                updates["material.dock.position"] = bar.ok ? bar.slot : "bottom"
            }
            Config.setNestedValues(updates)
            return true
        }
        case "iiDock": {
            if (swapWith === "iiBar") {
                const dock = root._state("iiDock", outputName)
                const updates = root._barUpdates(dock.ok ? dock.slot : "top")
                updates["material.dock.position"] = slot
                Config.setNestedValues(updates)
            } else {
                Config.setNestedValue("material.dock.position", slot)
            }
            return true
        }
        }
        return false
    }

    function setProperty(surfaceId: string, key: string, value: var, outputName: string): var {
        const numeric = Number(value)
        if (surfaceId === "iiDock" && key === "thickness") {
            if (!Number.isFinite(numeric))
                return { ok: false, code: "invalid-value", message: "Invalid dock size" }
            const clamped = Math.round(Math.max(40, Math.min(200, numeric)))
            Config.setNestedValue("material.dock.height", clamped)
            return { ok: true, effectiveValue: clamped }
        }
        const role = root._roleKey(surfaceId)
        if (role.length === 0)
            return { ok: false, code: "mutation-not-ready", message: "Property mutation is not available for this surface yet" }
        const base = "material.sidebar.shellLayout." + role
        if (key === "sizeMode") {
            const mode = String(value ?? "")
            if (!["full", "fit", "custom"].includes(mode))
                return { ok: false, code: "invalid-value", message: "Invalid sidebar size mode" }
            Config.setNestedValue(base + ".sizeMode", mode)
            return { ok: true, effectiveValue: mode }
        }
        if (key === "height" || key === "thickness") {
            if (!Number.isFinite(numeric))
                return { ok: false, code: "invalid-value", message: key === "height" ? "Invalid sidebar height" : "Invalid sidebar width" }
            const effective = key === "height" ? Math.round(Math.max(320, Math.min(2160, numeric)))
                : Math.round(Math.max(320, Math.min(900, numeric)))
            Config.setNestedValue(base + (key === "height" ? ".customHeight" : ".width"), effective)
            return { ok: true, effectiveValue: effective }
        }
        return { ok: false, code: "unsupported-property", message: "Unsupported sidebar property" }
    }

    function resetSurface(surfaceId: string, outputName: string): var {
        const role = root._roleKey(surfaceId)
        const slot = role === "feature" ? "left" : role === "system" ? "right" : surfaceId === "iiBar" ? "top"
            : surfaceId === "iiDock" ? "bottom" : ""
        if (slot.length === 0)
            return null
        const placement = ShellLayoutController.moveSurface(surfaceId, slot, outputName)
        if (!placement.ok || surfaceId === "iiBar")
            return placement
        if (role.length > 0) {
            const updates = {}
            updates["material.sidebar.shellLayout." + role + ".sizeMode"] = "full"
            updates["material.sidebar.shellLayout." + role + ".customHeight"] = 720
            updates["material.sidebar.shellLayout." + role + ".width"] = 460
            Config.setNestedValues(updates)
        } else {
            Config.setNestedValue("material.dock.height", 60)
        }
        Config.flushWrites()
        const result = JSON.parse(JSON.stringify(placement))
        result.reset = true
        return result
    }

    function desktopInsets(outputName: string, result: var): var {
        const barVertical = Config.options?.material?.bar?.vertical ?? false
        if (ShellLayoutController.panelEnabled(barVertical ? "iiVerticalBar" : "iiBar")
                && ShellLayoutController.outputEnabled(Config.options?.material?.bar?.screenList ?? [], outputName)
                && (GlobalStates.barOpen ?? true)) {
            const bar = root._state("iiBar", outputName)
            const style = Config.options?.material?.bar?.appearanceStyle ?? "classic"
            let thickness = 0
            if (style === "pill" && !barVertical) {
                const screen = Quickshell.screens.find(item => (item?.name ?? "") === outputName) ?? Quickshell.screens[0]
                const shortEdge = Math.min(screen?.width ?? 1920, screen?.height ?? 1080)
                const resolutionScale = Math.max(0.78, Math.min(1.6, shortEdge / 1080))
                const pill = Config.options?.material?.bar?.pill
                const scale = resolutionScale * 1.1 * (pill?.scale ?? 1)
                const restHeight = (pill?.barMode ?? false)
                    ? Math.max(58, pill?.expandedHeight ?? 66) * scale
                    : Math.max(38, pill?.restHeight ?? 44) * scale
                thickness = Math.max(0, restHeight + 8 * (pill?.topGap ?? 1) * scale - 12 * (1 - (pill?.appGap ?? 1)) * scale)
            } else if (barVertical) {
                thickness = Appearance.sizes.verticalBarWidth + Appearance.rounding.screenRounding
            } else if (style === "m3") {
                // M3Bar's layer surface includes the rounded screen decorator: its visual extent, not only the
                // exclusive zone.
                thickness = Appearance.sizes.barHeight + Appearance.rounding.screenRounding
            } else {
                const showBackground = Config.options?.material?.bar?.showBackground ?? true
                const cornerStyle = Config.options?.material?.bar?.cornerStyle ?? 0
                const detachedZzz = Appearance.zzzEverywhere && Appearance.zzz.round && style === "classic"
                    && showBackground && [1, 3].includes(cornerStyle)
                const hugCorners = !Appearance.zzzEverywhere && style === "classic" && showBackground && cornerStyle === 0
                thickness = detachedZzz ? Appearance.sizes.baseBarHeight + Appearance.sizes.elevationMargin * 2
                    : Appearance.sizes.barHeight + (hugCorners ? Appearance.rounding.screenRounding : 0)
            }
            result.barEdge = bar.ok ? bar.slot : ""
            result.barThickness = Math.max(0, Math.round(thickness))
            ShellLayoutController.applyInset(result, result.barEdge, thickness)
        }
        if (ShellLayoutController.panelEnabled("iiDock") && (Config.options?.material?.dock?.enable ?? true)
                && ShellLayoutController.outputEnabled(Config.options?.material?.dock?.screenList ?? [], outputName)) {
            const dock = root._state("iiDock", outputName)
            result.dockEdge = dock.ok ? dock.slot : ""
            result.dockThickness = Math.round((Config.options?.material?.dock?.height ?? 70)
                + Appearance.sizes.elevationMargin + Appearance.sizes.hyprlandGapsOut)
            ShellLayoutController.applyInset(result, result.dockEdge, result.dockThickness)
        }
        return result
    }
}
