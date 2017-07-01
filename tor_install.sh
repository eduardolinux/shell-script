#!/bin/sh -x

#
# Install TOR
#
export PKG_PATH=http://ftp.usa.openbsd.org/pub/OpenBSD/`uname -r`/packages/`arch -s` 
echo `pkg_add tor`


#
# Config TORRC in /etc/tor/torrc
#

# First, backup torrc
cp /etc/tor/torrc /etc/tor/torrc-$(date +%Y%M%d-%H%M%S.bkp)

echo "
AutomapHostsOnResolve 1
DNSPort 53
TransPort 9040" \
	>	/etc/tor/torrc

/etc/rc.d/tor restart
