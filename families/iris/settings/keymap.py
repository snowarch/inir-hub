#!/usr/bin/env python3
"""What each key of a keyboard layout types, for Settings' drawn keyboard; and every layout by its name.

Arguments: layout, variant, options (the compositor's XKB lines), the layout in use (index), the shell's language, and
the names the compositor gives its layouts now, tab-separated (with no layout line it runs the system's, said by name).
Prints one JSON object: keys (key name -> what its first four levels type), iso (the key beside left Shift types
something of its own), using (each layout in use as layout and variant), layouts (every layout and variant, named in
the shell's language), suggested (the ones for the person's country). Reads libxkbcommon, which every Wayland desktop has, and xkeyboard-config's list; nothing else.
"""
import ctypes
import ctypes.util
import gettext
import json
import os
import sys
import xml.etree.ElementTree as ET

# A dead key is drawn as the mark it puts on the next letter.
DEAD = {
    "dead_grave": "`", "dead_acute": "´", "dead_circumflex": "^", "dead_tilde": "~", "dead_macron": "¯",
    "dead_breve": "˘", "dead_abovedot": "˙", "dead_diaeresis": "¨", "dead_abovering": "˚", "dead_doubleacute": "˝",
    "dead_caron": "ˇ", "dead_cedilla": "¸", "dead_ogonek": "˛", "dead_iota": "ͺ", "dead_belowdot": ".",
    "dead_hook": "̉", "dead_horn": "̛", "dead_stroke": "/", "dead_greek": "µ", "dead_currency": "¤",
}


class Names(ctypes.Structure):
    _fields_ = [(field, ctypes.c_char_p) for field in ("rules", "model", "layout", "variant", "options")]


def keys_of(layout, variant, options, group):
    lib = ctypes.CDLL(ctypes.util.find_library("xkbcommon") or "libxkbcommon.so.0")
    lib.xkb_context_new.restype = ctypes.c_void_p
    lib.xkb_context_unref.argtypes = [ctypes.c_void_p]
    lib.xkb_keymap_new_from_names.restype = ctypes.c_void_p
    lib.xkb_keymap_new_from_names.argtypes = [ctypes.c_void_p, ctypes.POINTER(Names), ctypes.c_int]
    lib.xkb_keymap_unref.argtypes = [ctypes.c_void_p]
    lib.xkb_keymap_key_get_name.restype = ctypes.c_char_p
    lib.xkb_keymap_key_get_name.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
    lib.xkb_keymap_min_keycode.argtypes = [ctypes.c_void_p]
    lib.xkb_keymap_max_keycode.argtypes = [ctypes.c_void_p]
    lib.xkb_keymap_num_layouts.argtypes = [ctypes.c_void_p]
    lib.xkb_keymap_num_levels_for_key.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_uint32]
    lib.xkb_keymap_key_get_syms_by_level.argtypes = [ctypes.c_void_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32,
                                                     ctypes.POINTER(ctypes.POINTER(ctypes.c_uint32))]
    lib.xkb_keysym_to_utf8.argtypes = [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t]
    lib.xkb_keysym_get_name.argtypes = [ctypes.c_uint32, ctypes.c_char_p, ctypes.c_size_t]

    context = lib.xkb_context_new(0)
    names = Names(None, None, layout.encode() or None, variant.encode() or None, options.encode() or None)
    keymap = lib.xkb_keymap_new_from_names(context, ctypes.byref(names), 0)
    if not keymap:
        lib.xkb_context_unref(context)
        return None
    group = max(0, min(group, lib.xkb_keymap_num_layouts(keymap) - 1))
    buf = ctypes.create_string_buffer(64)
    keys = {}
    for code in range(lib.xkb_keymap_min_keycode(keymap), lib.xkb_keymap_max_keycode(keymap) + 1):
        name = lib.xkb_keymap_key_get_name(keymap, code)
        if not name:
            continue
        levels = []
        for level in range(min(4, lib.xkb_keymap_num_levels_for_key(keymap, code, group))):
            syms = ctypes.POINTER(ctypes.c_uint32)()
            text = ""
            if lib.xkb_keymap_key_get_syms_by_level(keymap, code, group, level, ctypes.byref(syms)) > 0:
                if lib.xkb_keysym_to_utf8(syms[0], buf, 64) > 0:
                    text = buf.value.decode("utf-8", "replace")
                if not text or not text.isprintable():
                    lib.xkb_keysym_get_name(syms[0], buf, 64)
                    text = DEAD.get(buf.value.decode("ascii", "replace"), "")
            levels.append(text)
        if any(levels):
            keys[name.decode()] = levels
    lib.xkb_keymap_unref(keymap)
    lib.xkb_context_unref(context)
    return keys


def rules_file():
    roots = [os.environ.get("XKB_CONFIG_ROOT", ""), "/usr/share/X11/xkb", "/usr/share/xkeyboard-config-2",
             "/usr/local/share/X11/xkb", "/run/current-system/sw/share/X11/xkb"]
    for root in roots:
        for name in ("evdev.xml", "base.xml"):
            path = os.path.join(root, "rules", name) if root else ""
            if path and os.path.exists(path):
                return path
    return ""


def layouts_of(language):
    path = rules_file()
    if not path:
        return []
    wanted = [language, language.split("_")[0]] if language else []
    books = [gettext.translation(domain, languages=wanted, fallback=True)
             for domain in ("xkeyboard-config-2", "xkeyboard-config")] if wanted else []

    def say(text):
        for book in books:
            said = book.gettext(text)
            if said != text:
                return said
        return text

    out = []
    for layout in ET.parse(path).getroot().iter("layout"):
        item = layout.find("configItem")
        name = item.findtext("name") or ""
        countries = [c.text for c in item.iter("iso3166Id")]
        said = item.findtext("description") or name
        out.append({"layout": name, "variant": "", "name": say(said), "said": said, "countries": countries})
        for variant in layout.findall("variantList/variant"):
            vitem = variant.find("configItem")
            said = vitem.findtext("description") or ""
            out.append({"layout": name, "variant": vitem.findtext("name") or "", "name": say(said), "said": said,
                        "countries": [c.text for c in vitem.iter("iso3166Id")] or countries})
    return out


def main():
    args = sys.argv[1:] + [""] * 6
    layout, variant, options, group, language, live = args[:6]
    layouts = layouts_of(language)
    if layout:
        layout_list, variant_list = layout.split(","), variant.split(",")
    else:
        # No layout line: the compositor runs the system's; its names (English, as xkeyboard-config writes them) say which.
        found = [next((e for e in layouts if e["said"] == name), None) for name in live.split("\t") if name]
        layout_list = [e["layout"] for e in found if e] or ["us"]
        variant_list = [e["variant"] for e in found if e] or [""]
    variant_list += [""] * (len(layout_list) - len(variant_list))
    keys = keys_of(",".join(layout_list), ",".join(variant_list[:len(layout_list)]), options, int(group or 0))
    if keys is None:
        print("no keymap for that layout", file=sys.stderr)
        sys.exit(1)
    plain = {text for name, levels in keys.items() if name != "LSGT" for text in levels[:2] if text}
    side = keys.get("LSGT", [])[:2]
    # The person's country: its own layouts first, then the US ones.
    # The shell's language when it names one (pt_BR), else the session's locale (es_AR.UTF-8).
    locale = os.environ.get("LC_ALL") or os.environ.get("LC_CTYPE") or os.environ.get("LANG") or ""
    country = ""
    for said in (language, locale.split(".")[0]):
        part = said.split("_")[1].upper() if "_" in said else ""
        if len(part) == 2:
            country = part
            break
    own = [entry for entry in layouts if country and entry["variant"] == "" and country in entry["countries"]][:2]
    usual = [entry for entry in layouts if entry["layout"] == "us" and entry["variant"] in ("intl", "")]
    suggested = []
    for entry in own + sorted(usual, key=lambda e: e["variant"] != "intl"):
        if entry not in suggested:
            suggested.append(entry)
    print(json.dumps({
        "keys": keys,
        "iso": any(text and text not in plain for text in side),
        "using": [{"layout": l, "variant": v} for l, v in zip(layout_list, variant_list)],
        "layouts": [{k: entry[k] for k in ("layout", "variant", "name")} for entry in layouts],
        "suggested": [{k: entry[k] for k in ("layout", "variant", "name")} for entry in suggested[:3]],
    }, ensure_ascii=False))


main()
