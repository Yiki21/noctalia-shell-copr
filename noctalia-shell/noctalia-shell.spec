Name:           noctalia-shell
Version:		2.20.0

Release:        %autorelease
Summary:        A Quickshell-based custom shell setup

License:        MIT
URL:            https://github.com/noctalia-dev/noctalia-shell
Source0:        https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz

BuildRequires:  rpm-build
BuildRequires:  git
BuildRequires:  tar

Requires:       quickshell
Requires:       google-roboto-fonts
Requires:       rsms-inter-fonts
Requires:       brightnessctl
Requires:       gpu-screen-recorder

# Optional dependencies
Recommends:     cliphist
Recommends:     matugen
Recommends:     wlsunset
Recommends:     python3
Recommends:     evolution-data-server
Recommends:     polkit-kde

%description
A beautiful, minimal desktop shell for Wayland that actually gets out of your way. Built on Quickshell with a warm lavender aesthetic that you can easily customize to match your vibe.

%prep
mkdir -p srcdir
tar -xzf %{SOURCE0} -C srcdir --strip-components=1

%build
# No build step; pure config package

%install
mkdir -p %{buildroot}/%{_datadir}/quickshell/noctalia-shell/
cp -a srcdir/. %{buildroot}/%{_datadir}/quickshell/noctalia-shell/

# Install a helper CLI to set up user's config directory
install -d %{buildroot}%{_bindir}
cat > %{buildroot}%{_bindir}/noctalia-shell << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat <<USAGE
noctalia-shell - initialize or update Quickshell config

Usage:
	noctalia-shell [setup|init] [--symlink|--copy] [--force]

Options:
	--symlink   Create ~/.config/quickshell/noctalia-shell -> /usr/share/quickshell/noctalia-shell (default)
	--copy      Copy files into ~/.config/quickshell/noctalia-shell
	--force,-f  Replace existing target if present
	-h, --help  Show this help

This command helps set up your user config from the system package contents.
USAGE
}

main() {
	local mode="setup"
	local action="symlink"
	local force=0
	local src="/usr/share/quickshell/noctalia-shell"
	local conf_home="${XDG_CONFIG_HOME:-$HOME/.config}"
	local dest="$conf_home/quickshell/noctalia-shell"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			setup|init) mode="setup" ;;
			--symlink)  action="symlink" ;;
			--copy)     action="copy" ;;
			--force|-f) force=1 ;;
			-h|--help)  usage; exit 0 ;;
			*) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
		esac
		shift
	done

	if [[ ! -d "$src" ]]; then
		echo "Source not found: $src" >&2
		exit 1
	fi

	mkdir -p "$(dirname "$dest")"

	if [[ -e "$dest" || -L "$dest" ]]; then
		if [[ $force -eq 1 ]]; then
			rm -rf -- "$dest"
		else
			echo "Target exists: $dest" >&2
			echo "Use --force to replace, or choose --copy/--symlink as needed." >&2
			exit 1
		fi
	fi

	if [[ "$action" == "symlink" ]]; then
		ln -s "$src" "$dest"
		echo "Symlinked: $dest -> $src"
	else
		mkdir -p "$dest"
		cp -a "$src/." "$dest/"
		echo "Copied files to: $dest"
	fi

	echo "Done. Restart Quickshell or reload config if necessary."
}

main "$@"
EOF
chmod 0755 %{buildroot}%{_bindir}/noctalia-shell

# Install docs from source if present
install -d %{buildroot}%{_docdir}/%{name}
if [ -f srcdir/LICENSE ]; then install -m 0644 srcdir/LICENSE %{buildroot}%{_docdir}/%{name}/; fi
if [ -f srcdir/README.md ]; then install -m 0644 srcdir/README.md %{buildroot}%{_docdir}/%{name}/; fi

%post
cat <<'EOM'
noctalia-shell installed.

To set up for your user:
Run: noctalia-shell         (symlink system config into ~/.config - recommended)
Or:  noctalia-shell --copy  (copy files into ~/.config - manual updates later)
Tip: use --force to replace an existing config.

EOM

%files
%license %{_docdir}/%{name}/LICENSE
%doc %{_docdir}/%{name}/README.md
%{_datadir}/quickshell/noctalia-shell
%{_bindir}/noctalia-shell

%changelog
%autochangelog
