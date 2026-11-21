#!/usr/bin/env bash
# Writes ~/.config/inir/plugins/rmpc/theme.ron from the iNiR palette and the chosen cava style, then tells a running
# rmpc to reload it. Runs on its own: the colour module and the Hub page (choices.sh) both call it.
set -euo pipefail

command -v rmpc >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || { echo "rmpc theme: jq is not installed" >&2; exit 0; }

PALETTE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/palette.json"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
OUT="$OWN/rmpc/theme.ron"
SETTINGS="$OWN/rmpc.json"        # {"cava": "spectrum" | "mirror" | "top" | "solid" | "dense" | "chunky"}
[[ -s "$PALETTE" ]] || exit 0

style="$(sed -n 's/.*"cava"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true)"
case "$style" in spectrum|mirror|top|solid|dense|chunky) ;; *) style=spectrum ;; esac

c() { jq -r --arg k "$1" '.[$k] // empty' "$PALETTE"; }
bg=$(c surface); fg=$(c on_surface); surf=$(c surface_container_high)
prim=$(c primary); onprim=$(c on_primary); sec=$(c secondary); tert=$(c tertiary)
err=$(c error); succ=$(c success); outv=$(c outline_variant)

extra=""
color="        bar_color: Gradient({
            0: \"$sec\",
            50: \"$prim\",
            100: \"$tert\",
        }),"
case "$style" in
  mirror) extra="        orientation: Horizontal," ;;
  top)    extra="        orientation: Top," ;;
  dense)  extra="        bar_spacing: 0," ;;
  chunky) extra="        bar_width: 2," ;;
  solid)  color="        bar_color: Single(\"$prim\")," ;;
esac
CAVA="    cava: (
        bg_color: \"$bg\",
${extra:+$extra
}$color
    ),"

LAYOUT=$(cat <<'LAYOUT_END'
    layout: Split(
        direction: Horizontal,
        panes: [
            (
                size: "38",
                pane: Split(
                    direction: Vertical,
                    panes: [
                        (size: "16", borders: "ALL", border_symbols: Rounded, pane: Pane(AlbumArt)),
                        (size: "5", borders: "ALL", border_symbols: Rounded, pane: Split(
                            direction: Vertical,
                            panes: [
                                (size: "1", pane: Component("title")),
                                (size: "1", pane: Component("artist_and_album")),
                                (size: "1", pane: Component("elapsed_and_bitrate")),
                            ],
                        )),
                        (size: "100%", borders: "ALL", border_symbols: Rounded, pane: Pane(Lyrics)),
                    ],
                ),
            ),
            (
                size: "100%",
                pane: Split(
                    direction: Vertical,
                    panes: [
                        (size: "3", borders: "ALL", border_symbols: Rounded, pane: Pane(ProgressBar)),
                        (size: "1", pane: Pane(Tabs)),
                        (size: "100%", pane: Pane(TabContent)),
                        (size: "6", borders: "ALL", border_symbols: Rounded, pane: Pane(Cava)),
                    ],
                ),
            ),
        ],
    ),
LAYOUT_END
)

render_theme() {
cat <<EOF
#![enable(implicit_some)]
#![enable(unwrap_newtypes)]
#![enable(unwrap_variant_newtypes)]
(
    background_color: "$bg",
    text_color: "$fg",
    header_background_color: "$bg",
    modal_background_color: "$surf",
    preview_label_style: (fg: "$tert"),
    preview_metadata_group_style: (fg: "$tert", modifiers: "Bold"),
    highlighted_item_style: (fg: "$prim", modifiers: "Bold"),
    current_item_style: (fg: "$onprim", bg: "$prim", modifiers: "Bold"),
    borders_style: (fg: "$outv"),
    highlight_border_style: (fg: "$prim"),
    level_styles: (
        info: (fg: "$prim", bg: "$bg"),
        warn: (fg: "$tert", bg: "$bg"),
        error: (fg: "$err", bg: "$bg"),
        debug: (fg: "$succ", bg: "$bg"),
        trace: (fg: "$sec", bg: "$bg"),
    ),
    progress_bar: (
        symbols: ["█", "█", "█", " ", "█"],
        track_style: (fg: "$outv"),
        elapsed_style: (fg: "$prim"),
        thumb_style: (fg: "$prim"),
        use_track_when_empty: true,
    ),
    scrollbar: (
        symbols: ["│", "█", "▲", "▼"],
        track_style: (fg: "$outv"),
        ends_style: (fg: "$outv"),
        thumb_style: (fg: "$prim"),
    ),
    tab_bar: (
        active_style: (fg: "$onprim", bg: "$prim", modifiers: "Bold"),
        inactive_style: (fg: "$fg"),
    ),
$CAVA
$LAYOUT
)
EOF
}

mkdir -p "$(dirname "$OUT")"
tmp="$(mktemp "$OUT.XXXXXX")"
render_theme > "$tmp"
if [[ -f "$OUT" ]] && cmp -s "$tmp" "$OUT"; then
  rm -f "$tmp"
  exit 0
fi
chmod 644 "$tmp"
mv -f "$tmp" "$OUT"
timeout 5 rmpc remote set theme "$OUT" >/dev/null 2>&1 || true
exit 0
