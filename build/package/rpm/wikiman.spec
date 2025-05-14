%define pkgver %(printenv PKGVER)
%define pkgrel %(printenv PKGREL)

Name:           wikiman
Version:        %{pkgver}
Release:        %{pkgrel}%{?dist}
Summary:        Offline interactive documentation search
BuildArch:      noarch
License:        MIT
URL:            https://github.com/filiparag/%{name}
Source0:        %{version}.tar.gz
Obsoletes:      %{name} <= %{version}-%{release}
Provides:       %{name} = %{version}-%{release}
BuildRequires:  make
Requires:       man fzf ripgrep gawk w3m findutils sed grep parallel
AutoReq:        no

%description
Offline search engine for manual pages, Arch Wiki, Gentoo Wiki and other documentation.

%prep
%setup -q

%install
make
make prefix=%{buildroot} install

%files
%doc README.md
%license LICENSE
/usr/bin/%{name}
/usr/share/%{name}/sources/man.sh
/usr/share/%{name}/sources/arch.sh
/usr/share/%{name}/sources/devdocs.sh
/usr/share/%{name}/sources/fbsd.sh
/usr/share/%{name}/sources/gentoo.sh
/usr/share/%{name}/sources/tldr.sh
/usr/share/%{name}/widgets/widget.bash
/usr/share/%{name}/widgets/widget.fish
/usr/share/%{name}/widgets/widget.zsh
/etc/bash_completion.d/%{name}-completion.bash
/usr/share/fish/completions/%{name}.fish
/usr/share/zsh/site-functions/_%{name}
/usr/share/man/man1/%{name}.1.gz
%config(noreplace) /etc/%{name}.conf
