.pragma library

var GROUPS = [
    { id: "family", label: "Shell family", paths: [], special: "family" },
    { id: "bar", label: "Bar", paths: ["material.bar", "iris.bar", "waffles.bar"] },
    { id: "theme", label: "Theme", paths: [
        "appearance.theme", "appearance.palette", "appearance.customTheme",
        "appearance.wallpaperTheming", "iris.appearance"
    ] },
    { id: "typography", label: "Typography", paths: ["appearance.typography"] },
    { id: "icons", label: "Icons", paths: ["iris.pieces.icons"] },
    { id: "wallpaper", label: "Wallpaper", paths: ["background"], special: "wallpaper" },
    { id: "dock", label: "Dock", paths: ["material.dock", "iris.dock"] },
    { id: "surfaces", label: "Surfaces", paths: [
        "iris.widgets", "iris.surround", "material.settingsUi", "waffles.theming", "waffles.background"
    ] },
    { id: "panels", label: "Panels", paths: [
        "material.sidebar", "material.notifications", "iris.sidebars", "iris.bubbles",
        "iris.controlCenter", "iris.notifications", "iris.lock", "waffles.taskView",
        "waffles.notifications", "lock"
    ] }
];

function isObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function ownValue(object, key) {
    if (isObject(object) && Object.prototype.hasOwnProperty.call(object, key))
        return object[key];
    return undefined;
}

function readPath(object, parts) {
    return parts.reduce(ownValue, object);
}

function copyGroup(target, source, group) {
    if (group.special) {
        const value = ownValue(source, group.special);
        if (value !== undefined)
            target[group.special] = JSON.parse(JSON.stringify(value));
    }

    for (const path of group.paths) {
        const parts = path.split(".");
        const value = readPath(ownValue(source, "config"), parts);
        if (value === undefined)
            continue;

        let parent = target.config;
        const key = parts.pop();
        for (const part of parts) {
            if (!Object.prototype.hasOwnProperty.call(parent, part))
                parent[part] = {};
            parent = parent[part];
        }
        parent[key] = JSON.parse(JSON.stringify(value));
    }
}

function filterLook(look, groupIds) {
    const result = { inirLook: look.inirLook, made: look.made, config: {}, presetGroups: groupIds.slice() };
    for (const group of GROUPS) {
        if (groupIds.includes(group.id))
            copyGroup(result, look, group);
    }
    return result;
}

function countSettings(value) {
    if (isObject(value))
        return Object.keys(value).reduce((count, key) => count + countSettings(value[key]), 0);
    // Arrays are whole setting values in a look file.
    return value === undefined ? 0 : 1;
}

function hasWallpaper(look) {
    const path = ownValue(ownValue(look, "wallpaper"), "path");
    return typeof path === "string" && path.length > 0;
}

function familyOf(look) {
    const family = ownValue(look, "family");
    return typeof family === "string" && family.length > 0 ? family : null;
}

function groupsPresent(look) {
    const config = ownValue(look, "config");
    return GROUPS.filter(group => {
        if (group.special === "family" && familyOf(look) !== null)
            return true;
        if (group.special === "wallpaper" && hasWallpaper(look))
            return true;
        return group.paths.some(path => countSettings(readPath(config, path.split("."))) > 0);
    }).map(group => group.id);
}

function summarize(look) {
    return {
        family: familyOf(look),
        groups: groupsPresent(look),
        settings: countSettings(ownValue(look, "config")),
        hasWallpaper: hasWallpaper(look)
    };
}

function mergeUpdate(oldPreset, currentLook, groupIds) {
    const oldGroups = groupsPresent(oldPreset);
    const savedGroups = ownValue(oldPreset, "presetGroups");
    const result = { inirLook: currentLook.inirLook, made: currentLook.made, config: {}, presetGroups: [] };
    for (const group of GROUPS) {
        const recapture = groupIds.includes(group.id);
        copyGroup(result, recapture ? currentLook : oldPreset, group);
        if (recapture || oldGroups.includes(group.id) || (Array.isArray(savedGroups) && savedGroups.includes(group.id)))
            result.presetGroups.push(group.id);
    }
    return result;
}

// The current look with the preset's groups laid over it; everything else stays as it is now.
function overlay(currentLook, preset) {
    const result = JSON.parse(JSON.stringify(currentLook));
    delete result.presetName;
    if (!isObject(result.config))
        result.config = {};
    const ids = ownValue(preset, "presetGroups");
    for (const group of GROUPS) {
        if (!Array.isArray(ids) || !ids.includes(group.id))
            continue;
        if (group.special) {
            const value = ownValue(preset, group.special);
            if (value !== undefined)
                result[group.special] = JSON.parse(JSON.stringify(value));
            else
                delete result[group.special];
        }
        for (const path of group.paths) {
            const parts = path.split(".");
            const key = parts.pop();
            const value = readPath(ownValue(preset, "config"), parts.concat(key));
            let parent = result.config;
            for (const part of parts) {
                if (!isObject(ownValue(parent, part))) {
                    if (value === undefined) { parent = null; break; }
                    parent[part] = {};
                }
                parent = parent[part];
            }
            if (parent === null)
                continue;
            if (value === undefined)
                delete parent[key];
            else
                parent[key] = JSON.parse(JSON.stringify(value));
        }
    }
    return result;
}

function cloneValue(value) {
    return JSON.parse(JSON.stringify(value));
}

function groupIndexOf(text) {
    for (let i = 0; i < GROUPS.length; i += 1) {
        if (GROUPS[i].paths.some(p => text === p || text.indexOf(p + ".") === 0))
            return i;
    }
    return -1;
}

// Every setting of the preset's config as one row: path (keys under config), dotted text, group id, kind, value.
// shown is the text of a value that cannot be edited here (arrays, null).
function flatten(preset) {
    const rows = [];
    const walk = (node, path) => {
        if (isObject(node)) {
            Object.keys(node).forEach(key => walk(node[key], path.concat([key])));
            return;
        }
        if (node === undefined)
            return;
        const text = path.join(".");
        const index = groupIndexOf(text);
        const kind = typeof node === "boolean" ? "bool" : typeof node === "number" ? "number" : typeof node === "string" ? "string" : "json";
        rows.push({
            path: path, text: text, group: index < 0 ? "" : GROUPS[index].id, kind: kind, value: node,
            shown: kind === "json" ? JSON.stringify(node) : "", order: index < 0 ? GROUPS.length : index
        });
    };
    walk(ownValue(preset, "config"), []);
    rows.sort((a, b) => a.order !== b.order ? a.order - b.order : a.text < b.text ? -1 : a.text > b.text ? 1 : 0);
    return rows.map(row => ({ path: row.path, text: row.text, group: row.group, kind: row.kind, value: row.value, shown: row.shown }));
}

// A copy of the preset with one config setting set (parents are made when missing).
function setValue(preset, path, value) {
    const result = cloneValue(preset);
    if (path.length === 0)
        return result;
    if (!isObject(result.config))
        result.config = {};
    let parent = result.config;
    for (const key of path.slice(0, -1)) {
        if (!isObject(ownValue(parent, key)))
            parent[key] = {};
        parent = parent[key];
    }
    parent[path[path.length - 1]] = value === undefined ? value : cloneValue(value);
    return result;
}

// A copy of the preset without one config setting; parents left empty are removed too.
function removeValue(preset, path) {
    const result = cloneValue(preset);
    if (path.length === 0 || !isObject(ownValue(result, "config")))
        return result;
    const chain = [result.config];
    for (const key of path.slice(0, -1)) {
        const next = ownValue(chain[chain.length - 1], key);
        if (!isObject(next))
            return result;
        chain.push(next);
    }
    delete chain[chain.length - 1][path[path.length - 1]];
    for (let i = chain.length - 1; i > 0 && Object.keys(chain[i]).length === 0; i -= 1)
        delete chain[i - 1][path[i - 1]];
    return result;
}

function parseValue(kind, text) {
    if (kind === "string")
        return { ok: true, value: text };
    if (kind === "number") {
        const value = Number(text);
        return text.trim() !== "" && isFinite(value) ? { ok: true, value: value } : { ok: false, value: undefined };
    }
    if (kind === "bool") {
        const value = text.trim();
        return value === "true" || value === "false" ? { ok: true, value: value === "true" } : { ok: false, value: undefined };
    }
    try {
        return { ok: true, value: JSON.parse(text) };
    } catch (error) {
        return { ok: false, value: undefined };
    }
}

function slug(name) {
    return name.normalize("NFKD").replace(/[\u0300-\u036f]/g, "")
        .toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "") || "preset";
}

function uniqueName(name, existingNames) {
    const base = name.trim() || "Preset";
    const used = new Set(existingNames.map(slug));
    let candidate = base;
    for (let suffix = 2; used.has(slug(candidate)); suffix += 1)
        candidate = `${base} (${suffix})`;
    return candidate;
}

function parsePreset(text) {
    if (typeof text !== "string")
        return null;

    try {
        const look = JSON.parse(text);
        const version = ownValue(look, "inirLook");
        if (Number.isInteger(version) && version > 0 && isObject(ownValue(look, "config")))
            return look;
    } catch (error) {
        return null;
    }
    return null;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { GROUPS, filterLook, groupsPresent, summarize, mergeUpdate, overlay, flatten, setValue, removeValue, parseValue, slug, uniqueName, parsePreset };
