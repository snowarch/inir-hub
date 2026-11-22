#!/usr/bin/env bash
# Writes ~/.config/inir/plugins/rmpc/theme.ron from the iNiR palette and the chosen cava shape, colour and symbols, then tells a running
# rmpc to reload it. Runs on its own: the colour module and the Hub page (choices.sh) both call it.
set -euo pipefail

command -v rmpc >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || { echo "rmpc theme: jq is not installed" >&2; exit 0; }

PALETTE="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/user/generated/palette.json"
OWN="${XDG_CONFIG_HOME:-$HOME/.config}/inir/plugins"
OUT="$OWN/rmpc/theme.ron"
SETTINGS="$OWN/rmpc.json"        # {"cava": "<shape>", "color": "gradient|solid|layers", "symbols": "blocks|braille|shades", "layout": "full|compact", "progress": "plain|line|dots|rounded", "dirs": "columns|tree"}
[[ -s "$PALETTE" ]] || exit 0

key() { sed -n 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true; }
shape="$(key cava)"
colormode=""
# Before the colour had its own choice, `solid` and `layers` were saved as the style.
case "$shape" in solid|layers) colormode="$shape"; shape=spectrum ;; esac
case "$shape" in spectrum|mirror|top|dense|chunky|densemirror) ;; *) shape=spectrum ;; esac
[[ -n "$colormode" ]] || colormode="$(key color)"
case "$colormode" in gradient|solid|layers) ;; *) colormode=gradient ;; esac
progress="$(key progress)"
case "$progress" in plain|line|dots|rounded) ;; *) progress=plain ;; esac
dirs="$(key dirs)"
case "$dirs" in columns|tree) ;; *) dirs=columns ;; esac
symbols="$(sed -n 's/.*"symbols"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true)"
case "$symbols" in blocks|braille|shades) ;; *) symbols=blocks ;; esac
layout="$(sed -n 's/.*"layout"[[:space:]]*:[[:space:]]*"\([a-z]*\)".*/\1/p' "$SETTINGS" 2>/dev/null | head -1 || true)"
case "$layout" in full|compact) ;; *) layout=full ;; esac

c() { jq -r --arg k "$1" '.[$k] // empty' "$PALETTE"; }
bg=$(c surface); fg=$(c on_surface); surf=$(c surface_container_high)
prim=$(c primary); onprim=$(c on_primary); sec=$(c secondary); tert=$(c tertiary)
err=$(c error); succ=$(c success); outv=$(c outline_variant)

extra=""
case "$shape" in
  mirror) extra="        orientation: Horizontal," ;;
  top)    extra="        orientation: Top," ;;
  dense)  extra="        bar_spacing: 0," ;;
  densemirror) extra="        orientation: Horizontal,
        bar_spacing: 0," ;;
  chunky) extra="        bar_width: 2," ;;
esac
case "$colormode" in
  solid)  color="        bar_color: Single(\"$prim\")," ;;
  layers) color="        bar_color: Rows([\"$sec\", \"$prim\", \"$tert\"])," ;;
  *)      color="        bar_color: Gradient({
            0: \"$sec\",
            50: \"$prim\",
            100: \"$tert\",
        })," ;;
esac
symlines=""
case "$symbols" in
  braille) symlines="        bar_symbols: ['⡀', '⣀', '⣄', '⣤', '⣦', '⣶', '⣷', '⣿'],
        inverted_bar_symbols: ['⠁', '⠉', '⠋', '⠛', '⠟', '⠿', '⡿', '⣿']," ;;
  shades)  symlines="        bar_symbols: ['░', '░', '▒', '▒', '▓', '▓', '█', '█'],
        inverted_bar_symbols: ['░', '░', '▒', '▒', '▓', '▓', '█', '█']," ;;
esac
CAVA="    cava: (
        bg_color: \"$bg\",
${extra:+$extra
}${symlines:+$symlines
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
                                (size: "1", pane: Pane(Property(content: [(kind: Property(Status(QueueLength()))), (kind: Text(" songs / ")), (kind: Property(Status(QueueTimeTotal()))), (kind: Text(" total"))], align: Center))),
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
                        (size: "3", borders: "ALL", border_symbols: Rounded, border_title: [(kind: Text(" ")), (kind: Property(Status(Elapsed))), (kind: Text(" / ")), (kind: Property(Status(Duration))), (kind: Group([(kind: Text(" (")), (kind: Property(Status(Bitrate))), (kind: Text(" kbps)"))])), (kind: Text(" "))], border_title_alignment: Left, pane: Pane(ProgressBar)),
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

LAYOUT_COMPACT=$(cat <<'LAYOUT_END'
    layout: Split(
        direction: Horizontal,
        panes: [
            (
                size: "24",
                pane: Split(
                    direction: Vertical,
                    panes: [
                        (size: "12", borders: "ALL", border_symbols: Rounded, pane: Pane(AlbumArt)),
                        (size: "100%", borders: "ALL", border_symbols: Rounded, pane: Split(
                            direction: Vertical,
                            panes: [
                                (size: "1", pane: Component("title")),
                                (size: "1", pane: Component("artist_and_album")),
                                (size: "1", pane: Pane(Property(content: [(kind: Property(Status(QueueLength()))), (kind: Text(" songs / ")), (kind: Property(Status(QueueTimeTotal()))), (kind: Text(" total"))], align: Center))),
                            ],
                        )),
                    ],
                ),
            ),
            (
                size: "100%",
                pane: Split(
                    direction: Vertical,
                    panes: [
                        (size: "5", borders: "ALL", border_symbols: Rounded, pane: Pane(Cava)),
                        (size: "1", pane: Pane(Tabs)),
                        (
                            size: "100%",
                            pane: Split(
                                direction: Horizontal,
                                panes: [
                                    (size: "20", borders: "ALL", border_symbols: Rounded, pane: Pane(Lyrics)),
                                    (size: "100%", pane: Pane(TabContent)),
                                ],
                            ),
                        ),
                        (size: "3", borders: "ALL", border_symbols: Rounded, border_title: [(kind: Text(" ")), (kind: Property(Status(Elapsed))), (kind: Text(" / ")), (kind: Property(Status(Duration))), (kind: Group([(kind: Text(" (")), (kind: Property(Status(Bitrate))), (kind: Text(" kbps)"))])), (kind: Text(" "))], border_title_alignment: Left, pane: Pane(ProgressBar)),
                    ],
                ),
            ),
        ],
    ),
LAYOUT_END
)
[[ "$layout" == compact ]] && LAYOUT="$LAYOUT_COMPACT"

case "$progress" in
  line)    pbsyms='["━", "━", "●", "─", "─"]' ;;
  dots)    pbsyms='["●", "●", "●", "○", "○"]' ;;
  rounded) pbsyms='["", "█", "█", "░", ""]' ;;
  *)       pbsyms='["█", "█", "█", " ", "█"]' ;;
esac
DIRBLOCK=""
if [[ "$dirs" == tree ]]; then
  DIRBLOCK="    browser_column_widths: [18, 32, 50],
    symbols: (
        song: \"├─ 󰎆 \",
        dir: \" \",
        playlist: \"P\",
        marker: \"M\",
        ellipsis: \"...\",
        song_style: None,
        dir_style: (fg: \"$sec\"),
        playlist_style: None,
    ),"
fi

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
        symbols: $pbsyms,
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
$DIRBLOCK
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
