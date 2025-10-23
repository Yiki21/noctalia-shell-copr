Name: noctalia-shell
Version:        2.18.0
Release:        %autorelease
Summary: A Quickshell-based custom shell setup

License: MIT
URL: https://github.com/noctalia-dev/noctalia-shell
Source0:        noctalia-shell-2.19.0.tar.gz

Requires:       quickshell
Requires:       google-roboto-fonts
Requires:       rsms-inter-fonts
Requires:       brightnessctl
Requires:       gpu-screen-recorder

# Optional deps (use weak deps if possible)
Recommends:     cliphist
Recommends:     matugen
Recommends:     wlsunset
Recommends:     python3
Recommends:     evolution-data-server
Recommends:     polkit-kde

# External repos used during build
# Copr: errornointernet/quickshell
# Copr: solopasha/hyprland
# Copr: brycensranch/gpu-screen-recorder-git


%description
A beautiful, minimal desktop shell for Wayland that actually gets out of your way. Built on Quickshell with a warm lavender aesthetic that you can easily customize to match your vibe.


%prep
%autosetup


%build
# no build step, it's a config package

%install
mkdir -p %{buildroot}/%{_datadir}/quickshell/noctalia-shell/
cp -a * %{buildroot}/%{_datadir}/quickshell/noctalia-shell/

%check


%files
%license LICENSE

%config(noreplace) /etc/quickshell/noctalia-shell
%changelog
%autochangelog
