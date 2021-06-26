#!/bin/bash
set -ex

echo "Configure image: [${kiwi_iname}]..."

test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# install busybox
/sbin/busybox --install -s /bin/

profile=$(baseGetProfilesUsed)
#################################### some conf ###########################################
# security enforce
export OPENEULEROS_SECURITY=0
echo "export TMOUT=300" >> /etc/bashrc
# change password privilege
chmod 644 /etc/passwd
chmod 644 /etc/group

if [[ $profile = "docker" ]]; then
    #################################### some packge remove ##################################
    # =temp pam
    cp -af /etc/pam.d /etc/pam.d.bak
    # perl related package
    perlarr=$(rpm -qa | grep "^perl") || perlarr=""
    for line in $perlarr; do
        rpm -e --nodeps $line
    done
    # pack
    rpmlist="shadow security-tool sudo vim-minimal openssh openssh-clients openssh-server logrotate fipscheck-lib \
        fipscheck crontabs cronie-anacron cronie libedit at elfutils-extra"
    for i in $rpmlist;do
        rpm -e --nodeps $i 2>/dev/null || continue
    done
    # =recover pam
    rm -rf /etc/pam.d
    mv /etc/pam.d.bak /etc/pam.d

    #################################### some file remove ##################################
    # rpm/yum cache db 
    [[ -d /var/lib/rpm ]] && rm -rf /var/lib/rpm/__db.*
    [[ -d /var/cache/yum ]] && rm -rf /var/cache/yum/*
    [[ -d /var/lib/yum ]] && rm -rf /var/lib/yum/*
    [[ -d /var/lib/dnf ]] && rm -rf /var/lib/dnf/*
    # ld
    rm -rf /etc/ld.so.cache
    rm -rf /var/cache/ldconfig/aux-cache
    [[ -d /var/cache/ldconfig ]] && rm -rf /var/cache/ldconfig/*
    [[ -d /var/lib/systemd ]] && rm -rf /var/lib/systemd/random-seed
    # systemd
    rm -rf /var/lib/systemd/catalog/database
    rm -rf /usr/bin/systemd-analyze
    rm -rf /usr/lib/systemd/catalog
    rm -rf /usr/lib/systemd/systemd-coredmup
    rm -rf /usr/lib/systemd/system/multi-user.target.wants/getty.target
    rm -rf /usr/lib/systemd/system/multi-user.target.wants/systemd-logind.service
    rm -rf /usr/lib/systemd/system-generators/systemd-bless-boot-generator
    rm -rf /usr/lib/systemd/system-generators/systemd-debug-generator
    rm -rf /usr/lib/systemd/system-generators/systemd-run-generator
    rm -rf /usr/lib/systemd/system-generators/systemd-system-update-generator
    rm -rf /usr/lib/systemd/system-generators/systemd-sysv-generator
    rm -rf /usr/lib/systemd/system-generators/systemd-veritysetup-generator
    # share dir
    rm -rf /usr/share/{man,doc,info,mime,licenses}
    rm -rf /usr/share/{misc,zoneinfo,zsh,crypto-policies}
    pushd /usr/share/i18n/charmaps;rm -rf $(ls | grep -v ^UTF-8.gz$ | xargs); popd
    pushd /usr/share/i18n/locales;rm -rf $(ls | grep -v ^en_US$ | xargs); popd
    # locales
    rm -rf /usr/lib/locale
    rm -rf /usr/share/locale/*

    # comon
    [[ -d /var/log ]] && rm -rf /var/log/*.log
    rm -rf /etc/machine-id
    rm -rf /etc/services
    rm -rf /boot
    rm -rf /sbin/sln
    rm -rf /bin/bz*
    rm -rf /bin/*attr*
    rm -rf /bin/bunzip2

    rm -rf /usr/bin/eu-strip
    rm -rf /usr/bin/gio
    # dbus
    rm -rf /usr/bin/dbus-cleanup-sockets
    rm -rf /usr/bin/dbus-run-session
    rm -rf /usr/bin/dbus-test-tool
    rm -rf /usr/bin/dbus-update-activation-environment
    rm -rf /usr/bin/dbus-uuidgen

    rm -rf /usr/sbin/cracklib*
    rm -rf /usr/sbin/glibc_post_upgrade.aarch64

    rm -rf /usr/lib64/gconv
    rm -rf /usr/lib64/security

    rm -rf /usr/libexec/getconf/POSIX*
    rm -rf /usr/libexec/p11-kit

    rm -rf /etc/pki/ca-trust/extracted/java/cacerts
    rm -rf /var/cache/ldconfig/aux-cache

    # python script cache
    find / -name *.pyc | xargs rm -rf
    # empty
    find / -type d | grep -v -E '^(/$)|(/root)|(/sys)|(/proc)|(/dev)' | xargs -n 1 -t rmdir --ignore-fail-on-non-empty
fi
###########################################
exit

