#!/bin/bash
set -e

/sbin/busybox --install -s /bin/

rm -rf ./usr/lib/locale/locale-*
find ./ -name *.pyc | xargs rm -rf

rm -rf ./usr/bin/dbus-cleanup-sockets
rm -rf ./usr/bin/dbus-run-session
rm -rf ./usr/bin/dbus-test-tool
rm -rf ./usr/bin/dbus-update-activation-environment
rm -rf ./usr/bin/dbus-uuidgen

