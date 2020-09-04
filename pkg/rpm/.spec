Name:           wikiman
Version:        2.11.1
Release:        1%{?dist}
Summary:        Offline interactive documentation search
BuildArch:      noarch
License:        MIT
URL:            https://github.com/filiparag/%{name}
Source0:        %{version}.tar.gz
Obsoletes:      %{name} <= %{version}-%{release}
Provides:       %{name} = %{version}-%{release}
BuildRequires:  make
Requires:       which man fzf ripgrep gawk w3m

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
/usr/share/wikiman/sources/man.sh
/usr/share/wikiman/sources/arch.sh
/usr/share/wikiman/sources/gentoo.sh
/usr/share/wikiman/sources/fbsd.sh
/usr/share/wikiman/sources/tldr.sh
/usr/share/wikiman/widgets/widget.bash
/usr/share/wikiman/widgets/widget.fish
/usr/share/wikiman/widgets/widget.zsh
/usr/share/man/man1/%{name}.1.gz
%config(noreplace) /etc/%{name}.conf