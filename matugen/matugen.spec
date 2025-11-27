# Spec file based on:
#   https://github.com/solopasha/hyprlandRPM
#   COPR: copr.fedorainfracloud.org/solopasha/hyprland
#
# This spec file is redistributed without modification
# for use in COPR build environment of noctalia-shell.
#
# Maintainer of this repackaged build:
#   Zhang Yi <zy1772696711@gmail.com>
#   COPR: https://copr.fedorainfracloud.org/coprs/zhangyi6324/noctalia-shell/
#   Source: https://github.com/Yiki21/noctalia-shell-copr

%global cargo_novendor 1
%undefine __cargo
%global __cargo /usr/bin/cargo
%bcond_with check


Name:           matugen
Version:        3.1.0
Release:        %autorelease
Summary:        A material you color generation tool with templates
License:        GPL-2.0-only

URL:            https://github.com/InioX/matugen
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo-rpm-macros >= 24

%global _description %{expand:
%{summary}.}

%description %{_description}

%prep
%autosetup -p1
%cargo_prep

%build
%cargo_build
%{cargo_license_summary}
%{cargo_license} > LICENSE.dependencies
%{cargo_vendor_manifest}

%install
install -Dpm755 target/release/matugen %{buildroot}%{_bindir}/matugen

%if %{with check}
%check
%cargo_test
%endif

%files
%license LICENSE
%license LICENSE.dependencies
%license cargo-vendor.txt
%doc CHANGELOG.md
%doc README.md
%{_bindir}/matugen

%changelog
%autochangelog