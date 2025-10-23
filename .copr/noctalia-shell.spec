%global commit0 76d3fda44d7b4862894860071a136ecb2f14351f
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})
%global bumpver 1

Name:           noctalia-shell
Version:        2.19.0%{?bumpver}^%{bumpver}.git%{shortcommit0}
Release:        %autorelease
Summary:        A Quickshell-based custom shell setup

License:        MIT
URL:            https://github.com/noctalia-dev/noctalia-shell
Source0:        https://github.com/noctalia-dev/noctalia-shell/archive/%{commit0}/noctalia-shell-%{shortcommit0}.tar.gz

BuildRequires:  rpm-build
BuildRequires:  git

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
%autosetup -n noctalia-shell-%{shortcommit0}

%build
# No build step; pure config package

%install
mkdir -p %{buildroot}/%{_datadir}/quickshell/noctalia-shell/
cp -a * %{buildroot}/%{_datadir}/quickshell/noctalia-shell/

%files
%license LICENSE
%doc README.md
%{_datadir}/quickshell/noctalia-shell

%changelog
%autochangelog
