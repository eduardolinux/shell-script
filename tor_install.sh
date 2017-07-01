#!/bin/sh

ifconfig

echo "							"
echo "	Digite sua placa WAN	"
echo "							"
read wan
INTERFACE_WAN=$wan
#SE O RESULTADO = 1 ENTAO ESTA PRESENTE
#SE RESULTADO = 0 ENTAO NAO ESTA PRESENTE
CHECK=$(ifconfig -a | grep $INTERFACE_WAN|wc -l)
if [ $CHECK -eq 1  ]
	then
	echo "										"
	echo "A INTERFACE $INTERFACE_WAN ESTA ATIVA	"
	echo "										"
else
	echo "A INTERFACE $INTERFACE_WAN NAO ESTA ATIVA, TENTE NOVAMENTE" && exit
fi

echo "							"
echo "	Digite sua placa LAN	"
echo "							"
read lan

INTERFACE_LAN=$lan
#SE O RESULTADO = 1 ENTAO ESTA PRESENTE
#SE RESULTADO = 0 ENTAO NAO ESTA PRESENTE
CHECK=$(ifconfig -a | grep $INTERFACE_LAN|wc -l)

if [ $CHECK -eq 1  ]
then
	echo "										"
	echo "A INTERFACE $INTERFACE_LAN ESTA ATIVA	"
	echo "										"
else
	echo "A INTERFACE $INTERFACE_LAN NAO ESTA ATIVA" && exit
fi

#
# Install TOR
#
export PKG_PATH=http://ftp.usa.openbsd.org/pub/OpenBSD/`uname -r`/packages/`arch -s` 
echo `pkg_add tor`

#
# Config LAN in em1
#
echo "

inet 10.10.10.1 255.255.255.0
up"	\
	>	/etc/hostname.$lan

#
# Config /etc/pf.conf
#

echo "
# declare network variables
ext_if=\"$wan\"
int_if=\"$lan\"
lan_net = \"{ 10.10.10.0/24 }\"
set loginterface \$int_if
set ruleset-optimization basic
set skip on lo
antispoof for \$ext_if
set reassemble yes
set optimization normal

# default deny policy - Deny All Traffic By Default.
block in on \$ext_if all
block in on \$int_if all

# Tor transparent proxy settings - Here's the IMPORTANT Tor stuff!!
# All TCP traffic and DNS traffic only.
pass in quick on { \$int_if } proto tcp rdr-to 127.0.0.1 port 9040
pass in quick on { \$int_if } proto udp rdr-to 127.0.0.1 port 53

# --[[NAT Translation]]-- NECESSARY!!!!
# Here PF translates all packets from our 3 networks to the IP address of fxp0 so they're
# internet routable. The parentheses around fxp0 says to evaluate the current IP assigned to the interface.
# To view active NAT translations "pfctl -s state"
pass out on \$ext_if from { \$int_if } to any nat-to (\$ext_if)

# Normal traffic - Pass all traffic out of fxp0 (to WAN) after translation
pass out on \$ext_if from (\$ext_if) to any modulate state
pass in on \$ext_if proto tcp from any to any port {22} " \
	>	/etc/pf.conf


#
# Config TORRC in /etc/tor/torrc
#

echo "
AutomapHostsOnResolve 1
DNSPort 53
TransPort 9040" \
	>	/etc/tor/torrc

#
# Config DHCPD in /etc/dhcpd.conf
#

echo "
subnet 10.10.10.0 netmask 255.255.255.0 {
    option routers 10.10.10.1;
    range 10.10.10.100 10.10.10.200;
    option domain-name-servers 8.8.8.8;

}"	\
	>	/etc/dhcpd.conf

#
# AutoStart dhcpd and tor
#

echo "
dhcpd_flags=\"$ext_if\"
pkg_scripts=\"tor\"
"	\
	>	/etc/rc.conf.local

reboot
