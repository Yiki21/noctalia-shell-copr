# Spec file based on:
#   https://github.com/ErrorNoInternet/rpm-packages
#   COPR: https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell
#
# This spec file is redistributed without modification
# for use in COPR build environment of noctalia-shell.
#
# Maintainer of this repackaged build:
#   Zhang Yi <zy1772696711@gmail.com>
#   COPR: https://copr.fedorainfracloud.org/coprs/zhangyi6324/noctalia-shell/
#   Source: https://github.com/Yiki21/noctalia-shell-copr

%bcond_with         asan

Name:               noctalia-qs
Version:            0.0.3
Release:            %autorelease
Summary:            Flexible QtQuick based desktop shell toolkit

License:            LGPL-3.0-only AND GPL-3.0-only
URL:                https://github.com/noctalia-dev/noctalia-qs
Source0:            %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

%if 0%{fedora} >= 43
BuildRequires:      breakpad-static
%endif
BuildRequires:      cmake
BuildRequires:      cmake(Qt6Core)
BuildRequires:      cmake(Qt6Qml)
BuildRequires:      cmake(Qt6ShaderTools)
BuildRequires:      cmake(Qt6WaylandClient)
BuildRequires:      gcc-c++
BuildRequires:      ninja-build
BuildRequires:      pkgconfig(breakpad)
BuildRequires:      pkgconfig(CLI11)
BuildRequires:      pkgconfig(gbm)
BuildRequires:      pkgconfig(jemalloc)
BuildRequires:      pkgconfig(libdrm)
BuildRequires:      pkgconfig(libpipewire-0.3)
BuildRequires:      pkgconfig(pam)
BuildRequires:      pkgconfig(wayland-client)
BuildRequires:      pkgconfig(wayland-protocols)
BuildRequires:      qt6-qtbase-private-devel
BuildRequires:      spirv-tools

%if %{with asan}
BuildRequires:      libasan
%endif

Conflicts:          quickshell
Provides:           desktop-notification-daemon

%description
Flexible toolkit for making desktop shells with QtQuick, targeting
Wayland and X11.

%prep
%autosetup

%build
%cmake  -GNinja \
%if %{with asan}
        -DASAN=ON \
%endif
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr noctalia-qs \
        -DDISTRIBUTOR="Fedora COPR (zhangyi6324/noctalia-shell)" \
        -DDISTRIBUTOR_DEBUGINFO_AVAILABLE=YES \
        -DGIT_REVISION=%{commit} \
        -DINSTALL_QML_PREFIX=%{_lib}/qt6/qml
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%license LICENSE-GPL
%doc BUILD.md
%doc CONTRIBUTING.md
%doc README.md
%doc changelog/v%{version}.md
%{_bindir}/qs
%{_bindir}/quickshell
%{_datadir}/applications/dev.noctalia.%{name}.desktop
%{_datadir}/icons/hicolor/scalable/apps/dev.noctalia.%{name}.svg
%{_libdir}/qt6/qml/Quickshell

%changelog
%autochangelog
