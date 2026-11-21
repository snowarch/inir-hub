#!/usr/bin/env bash
# Writes ~/.config/inir/plugins/rmpc/theme.ron from the current iNiR palette.
set -euo pipefail
source "${INIR_COLOR_RUNTIME:?run by iNiR: scripts/colors/apply-targets.sh rmpc}"
COLOR_MODULE_ID="rmpc"

command -v rmpc >/dev/null 2>&1 || { log_module "rmpc not installed, skipping"; exit 0; }
command -v jq >/dev/null 2>&1 || { log_module "jq not installed, skipping"; exit 0; }
PALETTE="$STATE_DIR/user/generated/palette.json"
[[ -f "$PALETTE" ]] || { log_module "palette.json not found, skipping"; exit 0; }
OUT="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins/rmpc/theme.ron"
mkdir -p "$(dirname "$OUT")"

c() { jq -r --arg k "$1" '.[$k] // empty' "$PALETTE"; }
bg=$(c surface); fg=$(c on_surface); surf=$(c surface_container_high)
prim=$(c primary); onprim=$(c on_primary); sec=$(c secondary); tert=$(c tertiary)
err=$(c error); succ=$(c success); outv=$(c outline_variant)

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

cat <<EOF | write_if_changed "$OUT" && { log_module "theme written to $OUT"; timeout 5 rmpc remote set theme "$OUT" >/dev/null 2>&1 || true; }
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
$LAYOUT
)
EOF
exit 0
