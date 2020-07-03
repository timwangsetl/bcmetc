#!/bin/sh
[ -z "$2" ] && echo "Error: should be run by c6udhcp" && exit 1

update_resolv() {
	local device="$1"
	local dns="$2"
	
	(
		#flock -n 9
		grep -v "#c6udhcp:$device:" /etc/resolv.conf > /tmp/resolv.conf.tmp
		for c in $dns; do
			echo "nameserver $c #c6udhcp:$device:" >> /tmp/resolv.conf.tmp
		done
		for c in $ADDRESSES; do
			echo "addr $c " >> /tmp/resolv.conf.tmp
		done
		mv /tmp/resolv.conf.tmp /etc/resolv.conf
	) 9>/tmp/resolv.conf.lock
	rm -f /tmp/resolv.conf.lock /tmp/resolv.conf.tmp
}

setup_interface () {
	local device="$1"

	# Merge RA-DNS
	#for radns in $RA_DNS; do
	#	local duplicate=0
	#	for dns in $RDNSS; do
	#		[ "$radns" = "$dns" ] && duplicate=1
	#	done
	#	[ "$duplicate" = 0 ] && RDNSS="$RDNSS $radns"
	#done

	#local dnspart=""
	#for dns in $RDNSS; do
	#	if [ -z "$dnspart" ]; then
	#		dnspart="\"$dns\""
	#	else
	#		dnspart="$dnspart, \"$dns\""
	#	fi
	#done

	update_resolv "$device" "$dns"

	#local prefixpart=""
	#for entry in $PREFIXES; do
	#	local addr="${entry%%,*}"
    #            entry="${entry#*,}"
    #            local preferred="${entry%%,*}"
    #            entry="${entry#*,}"
    #            local valid="${entry%%,*}"
    #            entry="${entry#*,}"
	#	[ "$entry" = "$valid" ] && entry=

	#	local class=""
	#	local excluded=""

	#	while [ -n "$entry" ]; do
	#		local key="${entry%%=*}"
    #            	entry="${entry#*=}"
	#		local val="${entry%%,*}"
    #            	entry="${entry#*,}"
	#		[ "$entry" = "$val" ] && entry=

	#		if [ "$key" = "class" ]; then
	#			class=", \"class\": $val"
	#		elif [ "$key" = "excluded" ]; then
	#			excluded=", \"excluded\": \"$val\""
	#		fi
	#	done

	#	local prefix="{\"address\": \"$addr\", \"preferred\": $preferred, \"valid\": $valid $class $excluded}"
		
	#	if [ -z "$prefixpart" ]; then
	#		prefixpart="$prefix"
	#	else
	#		prefixpart="$prefixpart, $prefix"
	#	fi

		# TODO: delete this somehow when the prefix disappears
	#	ip -6 route add unreachable "$addr"
	#done

	#ip -6 route flush dev "$device"
	#ip -6 address flush dev "$device" scope global

	# Merge addresses
	#for entry in $RA_ADDRESSES; do
	#	local duplicate=0
	#	local addr="${entry%%/*}"
	#	for dentry in $ADDRESSES; do
	#		local daddr="${dentry%%/*}"
	#		[ "$addr" = "$daddr" ] && duplicate=1
	#	done
	#	[ "$duplicate" = "0" ] && ADDRESSES="$ADDRESSES $entry"
	#done
	ifconfig $device up
	for entry in $ADDRESSES; do
		local addr="${entry%%,*}"
		entry="${entry#*,}"
		local preferred="${entry%%,*}"
		entry="${entry#*,}"
		local valid="${entry%%,*}"
		ifconfig "$device" "$addr"
		#ip -6 address add "$addr" dev "$device" preferred_lft "$preferred" valid_lft "$valid" 
	done
	#for entry in $ADDRESSES; do
	#	local addr="${entry%%/*}"
	#	entry="${entry#*,}"
		#route add 3000::1 dev eth2
		#ip -6 address add "$addr" dev "$device" preferred_lft "$preferred" valid_lft "$valid" 
	#done
	
	
	#for entry in $RA_ROUTES; do
	#	local addr="${entry%%,*}"
	#	entry="${entry#*,}"
	#	local gw="${entry%%,*}"
	#	entry="${entry#*,}"
	#	local valid="${entry%%,*}"
	#	entry="${entry#*,}"
	#	local metric="${entry%%,*}"

	#	if [ -n "$gw" ]; then
	#		ip -6 route add "$addr" via "$gw" metric "$metric" dev "$device" from "::/64"
	#	else
	#		ip -6 route add "$addr" metric "$metric" dev "$device"
	#	fi

	#	for prefix in $PREFIXES; do
	#		local paddr="${prefix%%,*}"
	#		[ -n "$gw" ] && ip -6 route add "$addr" via "$gw" metric "$metric" dev "$device" from "$paddr"
	#	done
	#done
}

teardown_interface() {
	local device="$1"
	#ifconfig $device down
	update_resolv "$device" ""
}

case "$2" in
	bound)
		teardown_interface "$1"
		setup_interface "$1"
	;;
#	informed|updated|rebound|ra-updated)
#		setup_interface "$1"
#	;;
#	stopped|unbound)
#		teardown_interface "$1"
#	;;
#	started)
#		teardown_interface "$1"
#	;;
esac

# user rules
#[ -f /etc/odhcp6c.user ] && . /etc/odhcp6c.user

exit 0
