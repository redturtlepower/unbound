#!/bin/sh

set -xe

# set timezone with TZ (eg. TZ=America/Toronto)
if [ -n "${TZ}" ]
then
	ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
	echo "${TZ}" > /etc/timezone
fi

if [ ! -d /opt/unbound/etc/unbound/dev ]
then
	mkdir -p /opt/unbound/etc/unbound/dev
	cp -a /dev/random /dev/urandom /opt/unbound/etc/unbound/dev/
fi

if [ ! -d /opt/unbound/etc/unbound/var ]
then
	mkdir -p -m 700 /opt/unbound/etc/unbound/var
	chown unbound:unbound /opt/unbound/etc/unbound/var
fi

# download the list of primary root servers.
# unbound ships its own list but we can also download the most recent list and
# update it whenever we think it is a good idea.
# note: there is no point in doing it more often then every 6 months.
curl -fsSL https://www.internic.net/domain/named.root -o /opt/unbound/etc/unbound/var/root.hints

# update the root trust anchor for DNSSEC validation.
# this tool exits with value 1 if the root anchor was updated using the
# certificate or if the builtin root-anchor was used.
# it exits with code 0 if no update was necessary, if the update was
# possible with RFC5011 tracking, or if an error occurred.
/opt/unbound/sbin/unbound-anchor -a /opt/unbound/etc/unbound/var/root.key || true

if [ $# -eq 0 ]
then
	exec /opt/unbound/sbin/unbound -d -c /opt/unbound/etc/unbound/unbound.conf
else
	exec "$@"
fi