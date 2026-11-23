# 󰗃 omayt — Omarchy YouTube TUI

[![Version](https://img.shields.io/badge/version-v1.3.0-89b4fa?style=for-the-badge)](https://github.com/sabb4th/omayt/releases)
[![Platform](https://img.shields.io/badge/platform-Omarchy%20%7C%20Arch%20Linux-a6e3a1?style=for-the-badge)](https://omarchy.org)
[![License](https://img.shields.io/badge/license-MIT-f9e2af?style=for-the-badge)](./LICENSE)

O **`omayt`** (**Omarchy YouTube TUI**) é um cliente de YouTube para terminal rápido, leve e visual, construído especialmente para o ecossistema **Omarchy Linux** (Hyprland + terminal Foot, Ghostty ou Kitty).

Com ele você pesquisa vídeos diretamente no YouTube **sem precisar de chave de API oficial** e **sem depender de instâncias instáveis do Invidious**, visualiza **thumbnails em alta resolução** (via Sixel ou Kitty Graphics Protocol) dentro do terminal e assiste aos vídeos tanto no `mpv` quanto **renderizados dentro da própria janela do terminal**.

---

## ✨ Principais Recursos

### 1. 🛡️ Proteção Tripla contra o Bloqueio `HTTP 403 Forbidden` de Anúncios (`tv_samsung` & Ad-Wait Guard)
Clientes de terminal tradicionais (`ytfzf`, `mpv` puro) frequentemente falham ao abrir vídeos do YouTube com erro `HTTP 403 Forbidden` porque o `yt-dlp` usa por padrão o perfil `tv_samsung` (Smart TV), no qual o YouTube aplica um bloqueio temporário de ~3 a 5 segundos (`available_at`) equivalente ao tempo de "pular anúncio". Enquanto o `yt-dlp` em modo download aguarda esse tempo (`Sleeping 3.00 seconds as required by the site...`), o `mpv` apenas extrai a URL com `yt-dlp -J` e tenta abrir imediatamente no `ffmpeg`, recebendo `403 Forbidden`.

O **`omayt`** resolve isso em **3 camadas**:
1. **Bypass do cliente `tv_samsung`:** Injeta `--extractor-args "youtube:player_client=default,-tv_samsung"` no `yt-dlp` e no `mpv` (`--ytdl-raw-options-append`), selecionando automaticamente o cliente `visionos`/`default` sem bloqueio.
2. **Interceptador `Ad-Wait Guard` no `ytdl_hook` do `mpv`:** O `omayt` atua como wrapper do `yt-dlp` para o `mpv`, inspecionando o timestamp `available_at` de todos os streams no JSON retornado. Caso o YouTube exija espera de anúncio, o `omayt` exibe uma **contagem regressiva visual no terminal** e aguarda a liberação exata antes de entregar o stream ao `ffmpeg`.
3. **Auto-Reconnect HTTP 4xx:** Configura o `mpv`/`ffmpeg` com `reconnect_on_http_error=4xx` e retry automático.

### 2. 󰥶 Thumbnails Sixel & Kitty em Alta Definição (com fix para `gdk-pixbuf2`/`glycin` no Arch)
- **Motor Sixel Direto (`ffmpeg` + `libsixel.so.1` via `ctypes`):** No Arch Linux recente, o binário `/usr/bin/img2sixel` pode retornar `0 bytes` devido a uma incompatibilidade do `libsixel` com o novo loader `glycin` do `gdk-pixbuf2`. O `omayt` contorna isso decodificando a imagem com `ffmpeg` (`rawvideo rgb24`) e invocando `sixel_encoder_encode_bytes` diretamente na biblioteca C `libsixel.so.1` em memória, garantindo thumbnails Sixel perfeitas no terminal **Foot**.
- **Suporte Nativo a Kitty & Ghostty:** Detecta automaticamente `$KITTY_WINDOW_ID` e `$GHOSTTY_RESOURCES_DIR` para usar `kitten icat` quando disponível, além de fallback para `chafa`.
- **Prefetch Paralelo:** Baixa as thumbnails em background com `ThreadPoolExecutor` diretamente do CDN oficial do YouTube (`i.ytimg.com`).

### 3. 🎨 Integração Nativa com os Temas do Omarchy
- Lê automaticamente o tema ativo em `~/.local/state/omarchy/current/theme/colors.toml` e aplica a paleta exata do seu Omarchy nas bordas, textos, ícones e painel de preview da TUI.

### 4. 🎬 Menu Inicial Estilizado, Busca Paginada (30 em 30) & 4 Modos de Reprodução
- **Menu Principal Interativo (`omayt`):** Tela inicial com logo animado em gradiente TrueColor do tema Omarchy, busca rápida, retomada da última sessão, histórico, modo música, reprodução de link direto (com auto-detecção do clipboard), biblioteca de downloads e painel de diagnóstico.
- **Busca Paginada de 30 em 30 (`Alt+M` / `Ctrl+E`):** Cada pesquisa carrega os primeiros **30 resultados** e permite pressionar `Alt+M` (ou `Ctrl+E`, ou selecionar `[+ Carregar mais 30 resultados]` no fim da lista) para carregar **+30** sob demanda, mantendo a ordem dos vídeos anteriores.
- **Janela MPV (`Enter`):** Abre o vídeo em alta resolução no `mpv` (Wayland + aceleração de hardware **VA-API**) e retorna automaticamente para a TUI ao fechar.
- **Vídeo Inline em Pixels no Terminal (`Alt+I` ou `Ctrl+T`):** Reproduz o vídeo **dentro da própria janela do terminal** usando `mpv --vo=sixel` (no Foot) ou `mpv --vo=kitty` (no Kitty/Ghostty).
- **Vídeo em Blocos TrueColor (`Alt+B`):** Reproduz o vídeo no terminal em modo pixel-art/blocos (`mpv --vo=tct`).
- **Modo Só Áudio / Música + Visualizador Cava (`Alt+A`):** Reproduz o áudio no terminal com um **visualizador de espectro FFT 60 FPS estilo Cava** sincronizado via PipeWire/PulseAudio.

---

## 📦 Dependências

No **Omarchy / Arch Linux**:
- `python` (Python 3 padrão do sistema, sem necessidade de pacotes `pip` externos)
- `fzf` (`>= 0.50`)
- `yt-dlp`
- `mpv`
- `ffmpeg`
- `libsixel`

```bash
omarchy pkg add fzf yt-dlp mpv ffmpeg libsixel
```

---

## 🚀 Instalação

### Opção 1: Script Instalador (`install.sh`)

```bash
git clone https://github.com/sabb4th/omayt.git
cd omayt
chmod +x install.sh omayt
./install.sh
```

O `install.sh`:
1. Instala o executável `omayt` em `~/.local/bin/omayt`;
2. Configura `~/.config/yt-dlp/config` com `--extractor-args "youtube:player_client=default,-tv_samsung"`;
3. Configura o `~/.config/ytfzf/conf.sh` para usar o renderizador Sixel do `omayt` (`omayt --sixel`).

### Opção 2: Pacote Arch Linux (`PKGBUILD`)

```bash
makepkg -si
```

---

## ⌨️ Como Usar e Atalhos

```bash
# Abrir o Menu Principal interativo
omayt

# Pular o menu inicial e abrir direto a TUI (fzf)
omayt --no-menu

# Abrir já pesquisando um termo no YouTube (30 resultados iniciais)
omayt "omarchy linux"

# Abrir direto no histórico de vídeos assistidos
omayt -H

# Renderizar qualquer imagem em Sixel no terminal Foot
omayt --sixel caminho/para/imagem.jpg 360
```

### Atalhos dentro da TUI

| Atalho | Ação |
| :--- | :--- |
| **`Enter`** | Assistir ao vídeo no **`mpv`** *(ou buscar no YouTube na 1ª linha `` / carregar +30 na última linha `󰐕`)* |
| **`Ctrl+S`** | **Pesquisar no YouTube** o texto digitado na barra do topo *(30 resultados)* |
| **`Alt+M`** *(ou `Ctrl+E`)* | **Carregar mais 30 resultados** para a busca atual *(30 em 30)* |
| **`Alt+I`** *(ou `Ctrl+T`)* | Assistir ao vídeo **DENTRO do próprio terminal** em pixels reais (`--vo=sixel` / `--vo=kitty`) |
| **`Alt+B`** | Assistir ao vídeo dentro do terminal em **blocos TrueColor** (`--vo=tct`) |
| **`Alt+A`** | Tocar **apenas o áudio / música** com **visualizador Cava 60 FPS** no terminal |
| **`Alt+W`** | Forçar abertura na **janela MPV** *(útil quando no Modo Música)* |
| **`Alt+D`** | Baixar o vídeo (MP4) ou áudio (MP3) para `~/Videos/omayt` |
| **`Alt+L`** | Copiar o link do vídeo para a área de transferência (`wl-copy`) |
| **`Ctrl+H`** | Abrir o **Histórico** de vídeos assistidos (com thumbnails) |
| **`Ctrl+F`** | Alternar filtro local na lista atual |
| **`Esc` / `Ctrl+C`** | Voltar ao Menu Principal *(ou sair)* |

---

## 🗂️ Armazenamento Local

O `omayt` armazena apenas cache local e histórico no seu computador (nenhum vídeo é baixado para o disco ao assistir via streaming):
- **`~/.cache/omayt/thumbs/`**: Cache local das miniaturas `.jpg`.
- **`~/.config/omayt/watch_history.json`**: Histórico local dos últimos vídeos assistidos (`Ctrl+H`).
- **`~/.config/omayt/search_history.json`**: Histórico local das últimas pesquisas.
- **`~/Videos/omayt/`**: Criado apenas quando você baixa um vídeo ou áudio manualmente com `Alt+D`.

Para limpar todo o cache e histórico local:
```bash
rm -rf ~/.cache/omayt ~/.config/omayt
```

---

## 📄 Licença

Distribuído sob a licença [MIT](./LICENSE).
