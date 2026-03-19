%global debug_package %{nil}

Name:           noctalia-shell
Version:		4.7.0

Release:        %autorelease
Summary:        A Quickshell-based custom shell setup

License:        MIT
URL:            https://github.com/noctalia-dev/noctalia-shell
Source0:	    %{url}/releases/download/v%{version}/noctalia-v%{version}.tar.gz

BuildArch:      noarch

BuildRequires:  rpm-build
BuildRequires:  git
BuildRequires:  tar

Requires:       noctalia-qs
Requires:       google-roboto-fonts
Requires:       rsms-inter-fonts
Requires:       brightnessctl
Requires:	   	  ddcutil
Requires:       ImageMagick


# Optional dependencies
Recommends:     gpu-screen-recorder
Recommends:     cliphist
Recommends:     matugen
Recommends:     wlsunset
Recommends:     python3
Recommends:     evolution-data-server
Recommends:     polkit-kde
Recommends:     qt6-qtmultimedia

%description
A beautiful, minimal desktop shell for Wayland that actually gets out of your way. Built on Quickshell with a warm lavender aesthetic that you can easily customize to match your vibe.

%prep
%autosetup -n noctalia-release

%build
# No build step; pure config package

%install
mkdir -p %{buildroot}%{_sysconfdir}/xdg/quickshell/noctalia-shell
cp -rp * %{buildroot}%{_sysconfdir}/xdg/quickshell/noctalia-shell/

%files
%license LICENSE
%doc README.md
%{_sysconfdir}/xdg/quickshell/noctalia-shell/

%changelog
%autochangelog
