# Maintainer: sabb4th <eliassabat2@gmail.com>
pkgname=omayt
pkgver=1.0.0
pkgrel=1
pkgdesc="Omarchy YouTube TUI with HD Sixel/Kitty thumbnails, inline terminal video, and YouTube 403 Ad-Wait bypass"
arch=('any')
url="https://github.com/sabb4th/omayt"
license=('MIT')
depends=('python' 'fzf' 'yt-dlp' 'mpv' 'ffmpeg' 'libsixel')
optdepends=(
  'chafa: fallback terminal graphics renderer'
  'wl-clipboard: copy video URLs to Wayland clipboard'
  'libnotify: desktop notifications when copying links'
)
source=("omayt" "LICENSE" "README.md")
sha256sums=('SKIP' 'SKIP' 'SKIP')

package() {
  install -Dm755 "$srcdir/omayt" "$pkgdir/usr/bin/omayt"
  install -Dm644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 "$srcdir/README.md" "$pkgdir/usr/share/doc/$pkgname/README.md"
}
