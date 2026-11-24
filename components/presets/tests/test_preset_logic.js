const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const logicPath = path.join(__dirname, "../logic/PresetLogic.js");
const source = fs.readFileSync(logicPath, "utf8");
const logicModule = { exports: {} };
// Strip the QML directive and run the same library code in Node.
vm.compileFunction(source.replace(/^\.pragma library\r?\n/, ""), ["module"], { filename: logicPath })(logicModule);
const { GROUPS, filterLook, groupsPresent, summarize, mergeUpdate, overlay, flatten, setValue, removeValue, parseValue, slug, uniqueName, parsePreset } = logicModule.exports;

function makeLook(config, extra = {}) {
    return { inirLook: 1, made: "2099-01-01T00:00:00Z", config, ...extra };
}

const tests = {
    "filters only the requested config paths and copies nested values"() {
        const look = makeLook({
            appearance: { theme: "synthetic", typography: { mainFont: "Test Sans" }, ungrouped: true },
            material: { bar: { modulesLayout: ["test-clock"] }, dock: { height: 40 } },
            iris: { bar: { design: "test-island" }, pieces: { icons: { accent: false }, ungrouped: true } },
            waffles: { bar: { activationWatermark: false } },
            ungrouped: { setting: true }
        }, { family: "waffle", wallpaper: { path: "/test/wallpaper.png" } });
        const selected = ["icons", "bar", "typography"];
        const preset = filterLook(look, selected);

        assert.deepEqual(preset, makeLook({
            appearance: { typography: { mainFont: "Test Sans" } },
            material: { bar: { modulesLayout: ["test-clock"] } },
            iris: { bar: { design: "test-island" }, pieces: { icons: { accent: false } } },
            waffles: { bar: { activationWatermark: false } }
        }, { presetGroups: selected }));
        preset.config.material.bar.modulesLayout.push("test-tray");
        preset.presetGroups.push("theme");
        assert.deepEqual(look.config.material.bar.modulesLayout, ["test-clock"]);
        assert.deepEqual(selected, ["icons", "bar", "typography"]);
    },

    "finds groups with settings in their configured order"() {
        const look = makeLook({
            material: { bar: { workspaces: [] }, dock: {} },
            waffles: { notifications: { scaleOnHover: false } },
            appearance: { theme: null, typography: { fonts: {} } },
            iris: Object.create({ dock: { iconSize: 50 } })
        }, { presetGroups: ["typography", "dock"] });

        assert.deepEqual(GROUPS.map(group => group.id), [
            "family", "bar", "theme", "typography", "icons", "wallpaper", "dock", "surfaces", "panels"
        ]);
        assert.deepEqual(groupsPresent(look), ["bar", "theme", "panels"]);
        assert.deepEqual(groupsPresent(makeLook({})), []);
        assert.deepEqual(filterLook(look, ["icons"]), makeLook({}, { presetGroups: ["icons"] }));
        assert.deepEqual(filterLook(look, []), makeLook({}, { presetGroups: [] }));
    },

    "captures family and wallpaper independently"() {
        const look = makeLook({ background: { fillMode: "test-fill" } }, {
            family: "iris", wallpaper: { path: "/test/another-wallpaper.png" }
        });

        assert.deepEqual(filterLook(look, ["family"]), makeLook({}, { family: "iris", presetGroups: ["family"] }));
        assert.deepEqual(filterLook(look, ["wallpaper"]), makeLook({ background: { fillMode: "test-fill" } }, {
            wallpaper: { path: "/test/another-wallpaper.png" }, presetGroups: ["wallpaper"]
        }));
        assert.deepEqual(groupsPresent(makeLook({}, { wallpaper: { path: "/test/image.png" } })), ["wallpaper"]);
        assert.deepEqual(groupsPresent(makeLook({ background: { fillMode: "test-fill" } })), ["wallpaper"]);
        assert.deepEqual(groupsPresent(makeLook({}, { wallpaper: { path: "" } })), []);
    },

    "summarizes config leaves, family and wallpaper"() {
        const look = makeLook({
            lock: { loginScreen: false, loginStyle: null },
            material: { bar: { modulesLayout: ["one", "two"], workspaces: {} } }
        }, { family: "ii", wallpaper: { path: "/test/image.png" }, presetGroups: ["theme"] });

        assert.deepEqual(summarize(look), {
            family: "ii", groups: ["family", "bar", "wallpaper", "panels"], settings: 3, hasWallpaper: true
        });
        assert.deepEqual(summarize(makeLook({ background: { fillMode: "test-fill" } })), {
            family: null, groups: ["wallpaper"], settings: 1, hasWallpaper: false
        });
    },

    "recaptures whole groups and keeps settings from the other groups"() {
        const old = makeLook({
            appearance: { theme: "before", palette: { harmony: "before" }, typography: { mainFont: "Keep Sans" } },
            background: { fillMode: "before" },
            material: { dock: { height: 36 } }
        }, { family: "ii", wallpaper: { path: "/test/old.png" } });
        const current = makeLook({
            appearance: { theme: "after", typography: { mainFont: "Ignore Sans" } },
            material: { bar: { modulesLayout: ["test-clock"] }, dock: { height: 48 } }
        }, { made: "2099-01-02T00:00:00Z", family: "waffle" });
        const updated = mergeUpdate(old, current, ["bar", "theme", "wallpaper"]);

        assert.deepEqual(updated, makeLook({
            appearance: { theme: "after", typography: { mainFont: "Keep Sans" } },
            material: { bar: { modulesLayout: ["test-clock"] }, dock: { height: 36 } }
        }, {
            made: current.made, family: "ii", presetGroups: ["family", "bar", "theme", "typography", "wallpaper", "dock"]
        }));
        updated.config.material.bar.modulesLayout.pop();
        updated.config.material.dock.height = 99;
        assert.deepEqual(current.config.material.bar.modulesLayout, ["test-clock"]);
        assert.equal(old.config.material.dock.height, 36);
        assert.equal(old.wallpaper.path, "/test/old.png");
    },

    "preserves saved selections and updates special fields"() {
        const old = makeLook({}, {
            family: "ii", wallpaper: { path: "/test/keep.png" }, presetGroups: ["icons", "wallpaper"]
        });
        const current = makeLook({}, { family: "iris", wallpaper: { path: "/test/replace.png" } });

        assert.deepEqual(mergeUpdate(old, current, ["family"]), makeLook({}, {
            family: "iris", wallpaper: { path: "/test/keep.png" }, presetGroups: ["family", "icons", "wallpaper"]
        }));
        assert.deepEqual(mergeUpdate(old, current, ["wallpaper"]), makeLook({}, {
            family: "ii", wallpaper: { path: "/test/replace.png" }, presetGroups: ["family", "icons", "wallpaper"]
        }));
    },

    "parses look files and rejects invalid envelopes"() {
        const preset = makeLook({}, { presetGroups: ["bar"] });
        assert.deepEqual(parsePreset(JSON.stringify(preset)), preset);
        assert.deepEqual(parsePreset('{"inirLook":2,"config":{}}'), { inirLook: 2, config: {} });

        for (const invalid of [
            undefined, null, "", "{bad JSON", "null", "[]", "{}", '{"config":{}}', '{"inirLook":1}',
            '{"inirLook":"1","config":{}}', '{"inirLook":0,"config":{}}', '{"inirLook":1.5,"config":{}}',
            '{"inirLook":1,"config":null}', '{"inirLook":1,"config":[]}', '{"inirLook":1,"config":"test"}'
        ]) {
            assert.equal(parsePreset(invalid), null, String(invalid));
        }
    },

    "overlays only the preset groups onto the current look"() {
        const current = makeLook({
            appearance: { theme: "now", typography: { mainFont: "Now Sans" } },
            material: { bar: { height: 1 }, dock: { height: 40 } },
            iris: { bar: { design: "now-island" }, pieces: { icons: { accent: true } } },
            other: { keep: true }
        }, { family: "material", wallpaper: { path: "/now.png" }, presetName: "Old" });
        const preset = makeLook({
            appearance: { typography: { mainFont: "Preset Sans" } },
            material: { bar: { height: 9, list: ["a"] } }
        }, { presetGroups: ["bar", "typography", "icons", "family"], family: "waffle", wallpaper: { path: "/preset.png" } });
        const before = JSON.stringify([current, preset]);
        const result = overlay(current, preset);

        assert.equal(JSON.stringify([current, preset]), before);
        assert.equal("presetName" in result, false);
        assert.equal(result.made, current.made);
        assert.equal(result.family, "waffle");
        assert.deepEqual(result.wallpaper, { path: "/now.png" });
        assert.deepEqual(result.config.material, { bar: { height: 9, list: ["a"] }, dock: { height: 40 } });
        assert.deepEqual(result.config.appearance, { theme: "now", typography: { mainFont: "Preset Sans" } });
        assert.equal("bar" in result.config.iris, false);
        assert.deepEqual(result.config.iris.pieces, {});
        assert.deepEqual(result.config.other, { keep: true });
        result.config.material.bar.list.push("b");
        assert.deepEqual(preset.config.material.bar.list, ["a"]);

        const withWallpaper = overlay(current, { ...preset, presetGroups: ["wallpaper"], config: { background: { x: 1 } }, wallpaper: { path: "/preset.png" } });
        assert.deepEqual(withWallpaper.wallpaper, { path: "/preset.png" });
        assert.deepEqual(withWallpaper.config.background, { x: 1 });
        assert.equal(overlay(current, makeLook({})).family, "material");
    },

    "flattens settings by group order and edits copies"() {
        const preset = makeLook({
            zeta: { flag: true },
            material: { dock: { height: 40, label: "x" }, bar: { modulesLayout: ["a"], extra: null } },
            appearance: { typography: { mainFont: "Test Sans" } },
            empty: {}
        }, { presetGroups: ["bar"], presetName: "Test" });
        const rows = flatten(preset);

        assert.deepEqual(rows.map(r => [r.text, r.group, r.kind]), [
            ["material.bar.extra", "bar", "json"], ["material.bar.modulesLayout", "bar", "json"],
            ["appearance.typography.mainFont", "typography", "string"],
            ["material.dock.height", "dock", "number"], ["material.dock.label", "dock", "string"],
            ["zeta.flag", "", "bool"]
        ]);
        assert.deepEqual(rows[0].path, ["material", "bar", "extra"]);
        assert.equal(rows[1].shown, '["a"]');
        assert.equal(rows[3].value, 40);
        assert.deepEqual(flatten(makeLook({})), []);

        const before = JSON.stringify(preset);
        const set = setValue(preset, ["material", "dock", "height"], 50);
        assert.equal(JSON.stringify(preset), before);
        assert.equal(set.config.material.dock.height, 50);
        assert.equal(set.presetName, "Test");
        assert.deepEqual(setValue(preset, ["new", "deep"], 1).config.new, { deep: 1 });

        const removed = removeValue(removeValue(preset, ["zeta", "flag"]), ["appearance", "typography", "mainFont"]);
        assert.equal(JSON.stringify(preset), before);
        assert.equal("zeta" in removed.config, false);
        assert.equal("appearance" in removed.config, false);
        assert.equal(removed.config.material.dock.height, 40);
        assert.deepEqual(removeValue(preset, ["material", "missing", "x"]), preset);
        assert.deepEqual(removeValue(makeLook({ a: { b: { c: 1 } } }), ["a", "b", "c"]).config, {});
    },

    "parses typed values from text"() {
        assert.deepEqual(parseValue("number", " 4.5 "), { ok: true, value: 4.5 });
        assert.equal(parseValue("number", "").ok, false);
        assert.equal(parseValue("number", "12px").ok, false);
        assert.equal(parseValue("number", "Infinity").ok, false);
        assert.deepEqual(parseValue("string", ""), { ok: true, value: "" });
        assert.deepEqual(parseValue("bool", "false"), { ok: true, value: false });
        assert.equal(parseValue("bool", "yes").ok, false);
        assert.deepEqual(parseValue("json", "[1]"), { ok: true, value: [1] });
        assert.equal(parseValue("json", "[1").ok, false);
    },

    "makes filename slugs and resolves name collisions"() {
        assert.equal(slug("  Café / Blue___Night!  "), "cafe-blue-night");
        assert.equal(slug("../"), "preset");
        assert.equal(uniqueName("  Blue Sky  ", []), "Blue Sky");
        assert.equal(uniqueName("Blue Sky", ["blue-sky", " BLUE SKY (2) "]), "Blue Sky (3)");
        assert.equal(uniqueName("  ", ["Preset"]), "Preset (2)");
    }
};

for (const [name, test] of Object.entries(tests)) {
    test();
    console.log(`PASS ${name}`);
}
console.log(`${Object.keys(tests).length} tests passed`);
