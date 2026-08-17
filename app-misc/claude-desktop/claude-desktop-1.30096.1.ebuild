# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop linux-info optfeature unpacker xdg

DESCRIPTION="Desktop application for Claude.ai"
HOMEPAGE="https://claude.com/download"

# Upstream publishes an apt repository rather than plain tarballs; the pool
# paths are stable, so they can be used directly as SRC_URI.
CLAUDE_POOL="https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/${PN}"
SRC_URI="
	amd64? ( ${CLAUDE_POOL}/${PN}_${PV}_amd64.deb )
	arm64? ( ${CLAUDE_POOL}/${PN}_${PV}_arm64.deb )
"
S="${WORKDIR}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="suid"

RESTRICT="bindist mirror splitdebug strip test"
QA_PREBUILT="usr/lib/${PN}/*"

RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	virtual/libudev
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
"
BDEPEND="${UNPACKER_BDEPEND}"

CLAUDE_HOME="/usr/lib/${PN}"

pkg_setup() {
	if [[ ${MERGE_TYPE} != binary ]] && ! use suid; then
		CONFIG_CHECK="~USER_NS"
		ERROR_USER_NS="CONFIG_USER_NS is required for the Electron namespace"
		ERROR_USER_NS+=" sandbox. Enable it, or build with USE=suid to fall"
		ERROR_USER_NS+=" back to the setuid-root chrome-sandbox helper."
		linux-info_pkg_setup
	fi
}

src_install() {
	# Upstream's Debian maintainer scripts register an apt repository, write
	# an apt keyring and drop an AppArmor userns profile. None of that is
	# wanted here; unpacker never runs them, so nothing to strip out but the
	# Debian-only metadata below.
	rm -r usr/share/lintian || die

	dodir /usr/lib
	cp -a "usr/lib/${PN}" "${ED}/usr/lib/" || die

	fperms 0755 "${CLAUDE_HOME}/${PN}"
	fperms 0755 "${CLAUDE_HOME}/chrome_crashpad_handler"

	if use suid; then
		fperms 4711 "${CLAUDE_HOME}/chrome-sandbox"
	else
		# Namespace sandbox is used instead; the helper stays non-setuid.
		fperms 0755 "${CLAUDE_HOME}/chrome-sandbox"
	fi

	# Thin launcher instead of upstream's bare symlink: picks the right Ozone
	# backend on Wayland and reads an optional user flags file, in the same
	# spirit as chromium-flags.conf.
	newbin - "${PN}" <<-EOF
		#!/bin/sh
		# Installed by ${CATEGORY}/${PN}-${PVR}
		flags_file="\${XDG_CONFIG_HOME:-\${HOME}/.config}/${PN}-flags.conf"

		: "\${ELECTRON_OZONE_PLATFORM_HINT:=auto}"
		export ELECTRON_OZONE_PLATFORM_HINT

		user_flags=""
		if [ -r "\${flags_file}" ]; then
		    user_flags=\$(sed -e 's/#.*//' "\${flags_file}" | tr '\n' ' ')
		fi

		# Intentionally unquoted: the flags file is whitespace separated.
		# shellcheck disable=SC2086
		exec "${CLAUDE_HOME}/${PN}" \${user_flags} "\$@"
	EOF

	domenu usr/share/applications/com.anthropic.Claude.desktop

	local size
	for size in 16 32 48 128 256; do
		doicon -s ${size} "usr/share/icons/hicolor/${size}x${size}/apps/${PN}.png"
	done

	newdoc "usr/share/doc/${PN}/copyright" copyright
}

pkg_postinst() {
	xdg_pkg_postinst

	if ! use suid; then
		elog "chrome-sandbox is installed without the setuid bit; the app"
		elog "relies on the kernel's user namespace sandbox instead. If it"
		elog "refuses to start with a sandbox error, rebuild with USE=suid."
	fi

	elog "Extra command line flags can be placed one per line in"
	elog "  \${XDG_CONFIG_HOME:-~/.config}/${PN}-flags.conf"

	optfeature "file pickers and screen sharing via desktop portals" \
		sys-apps/xdg-desktop-portal-gtk kde-plasma/xdg-desktop-portal-kde \
		gui-libs/xdg-desktop-portal-hyprland gui-libs/xdg-desktop-portal-wlr
	optfeature "storing credentials in a system keyring" \
		gnome-base/gnome-keyring kde-frameworks/kwallet
	optfeature "moving files to trash from within the app" \
		kde-apps/kde-cli-tools app-misc/trash-cli gnome-base/gvfs
	optfeature "the sandboxed VM features of Claude Code" app-emulation/qemu
}
