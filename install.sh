#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

echo "󰗃 Instalando omayt (Omarchy YouTube TUI)..."

# 1. Instalar binário omayt em ~/.local/bin/omayt
mkdir -p "$BIN_DIR"
chmod +x "$PROJECT_DIR/omayt"
cp -f "$PROJECT_DIR/omayt" "$BIN_DIR/omayt"
chmod +x "$BIN_DIR/omayt"
echo "  ✓ Binário instalado em: $BIN_DIR/omayt"

# 2. Configurar correção global do yt-dlp (evita bloqueio 403 de anúncio no cliente tv_samsung)
mkdir -p "$HOME/.config/yt-dlp"
YTDLP_CONFIG="$HOME/.config/yt-dlp/config"
if ! grep -q -- "-tv_samsung" "$YTDLP_CONFIG" 2>/dev/null; then
    {
        echo ""
        echo "# Evita bloqueio HTTP 403 de anúncio de 5s no cliente tv_samsung"
        echo '--extractor-args "youtube:player_client=default,-tv_samsung"'
    } >> "$YTDLP_CONFIG"
    echo "  ✓ Correção do cliente tv_samsung aplicada em: $YTDLP_CONFIG"
else
    echo "  ✓ Correção do cliente tv_samsung já presente em: $YTDLP_CONFIG"
fi

# 3. Também configurar thumbnails Sixel + fix tv_samsung no ytfzf (caso utilize ytfzf)
mkdir -p "$HOME/.config/ytfzf/thumbnail-viewers"
cat << 'EOF' > "$HOME/.config/ytfzf/thumbnail-viewers/sixel-inline"
#!/usr/bin/env sh
case "$1" in
    view)
        thumb_path="$2"
        preview_cols="${7:-${5:-40}}"
        [ ! -f "$thumb_path" ] && exit 0
        px_w=$(( preview_cols * 7 ))
        [ "$px_w" -lt 220 ] && px_w=280
        [ "$px_w" -gt 480 ] && px_w=480
        printf "\n"
        if [ -x "$HOME/.local/bin/omayt" ]; then
            "$HOME/.local/bin/omayt" --sixel "$thumb_path" "$px_w" 2>/dev/null
        elif command -v chafa >/dev/null 2>&1; then
            chafa -s "${preview_cols}x$(( ${8:-20} / 2 ))" "$thumb_path" 2>/dev/null
            printf "\n"
        fi
        ;;
esac
EOF
chmod +x "$HOME/.config/ytfzf/thumbnail-viewers/sixel-inline"

cat << 'EOF' > "$HOME/.config/ytfzf/conf.sh"
show_thumbnails=1
fzf_preview_side="left"
preview_window_width="50%"
thumbnail_viewer="$HOME/.config/ytfzf/thumbnail-viewers/sixel-inline"
url_handler_opts='--ytdl-raw-options-append=extractor-args="youtube:player_client=default,-tv_samsung"'

download_thumbnails() {
    [ "$skip_thumb_download" -eq 1 ] && return 0
    curl_config_file="${session_temp_dir}/curl_config"
    [ -z "$*" ] && return 0
    : >"$curl_config_file"
    for line in "$@"; do
        video_id="${line##*';'}"
        thumb_url="https://i.ytimg.com/vi/${video_id}/hqdefault.jpg"
        printf "url=\"%s\"\noutput=\"%s/%s.jpg\"\n" "$thumb_url" "$thumb_dir" "$video_id"
    done >>"$curl_config_file"
    curl -s -fLZ -K "$curl_config_file"
}

thumbnail_video_info_text() {
    [ -n "$title" ] && printf "\n ${c_bold}${c_cyan}%s${c_reset}" "$title"
    [ -n "$channel" ] && printf "\n ${c_blue}Canal    ${c_green}%s${c_reset}" "$channel"
    [ -n "$duration" ] && printf "\n ${c_blue}Duração  ${c_yellow}%s${c_reset}" "$duration"
    [ -n "$views" ] && printf "\n ${c_blue}Views    ${c_magenta}%s${c_reset}" "$views"
    [ -n "$date" ] && printf "\n ${c_blue}Data     ${c_cyan}%s${c_reset}\n" "$date"
}
EOF
echo "  ✓ Configuração de thumbnails Sixel + fix tv_samsung aplicada no ytfzf (~/.config/ytfzf/conf.sh)"

echo ""
echo "🎉 Instalação concluída! Agora basta rodar:"
echo "   omayt"
echo "   ou: omayt \"sua pesquisa\""
