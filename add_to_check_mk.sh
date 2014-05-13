#!/bin/bash

## Original Script: https://gist.github.com/anonymous/7008399
## Original Author: Chris Bennett chris at ceegeebee.com
## Heavily Modified by: https://github.com/Sammitch

## eg: add_to_check_mk.sh -s prod -h host.domain.tld -f myfolder -t 'tag1|tag2|tag3'

## user must be root to be allowed to su to omd user without a password
if [ $(whoami) != 'root' ]; then
	echo "ERR: Must be run as root" 1>&2
	exit 1
fi

function usage() {
	cat <<_EOI_
Usage: $0 -s SITENAME -h HOSTNAME [-f FOLDERNAME] [-t 'tag1|tag2|tag3']

    -s    Specifies the omd 'site' to add the host to, eg: prod
    -h    Specifies the hostname to be added
    -f    Optional. Specifies the name of the check_mk folder the
	  host is to be added to.
    -t    Optional. WATO tags to add to the host.
    -?    This message.
_EOI_
}

## previous functionality required 'num_hosts' to be on its own line
## below fucntionality interprets .wato as python dict as intended and
## does not rely on peculiarities of formatting.
function increment_num_hosts () {
	if [ ! -f $1 ]; then
		echo "ERR: specified .wato file does not exist!" 1>&2
		exit 1
	fi
	cat <<_E_ | python
dotwato = eval(open('${1}', 'r').read())
if not isinstance(dotwato, dict):
	import sys
	sys.exit(1)
dotwato['num_hosts'] += 1
open('${1}', 'w').write(str(dotwato))
_E_
	if [ $? -ne 0 ]; then
		echo "ERR: Could not process .wato file, host count was not incremented." 1>&2
	fi
}

## parse arguments
while getopts s:f:h:t:? ARG; do
	case $ARG in
		s)
			site=$OPTARG
			;;
		f)
			folder=$OPTARG
			;;
		h)
			hostname=$OPTARG
			;;
		t)
			hosttags=$OPTARG
			;;
		?)
			usage
			exit
			;;
	esac
done

## Check arg presence
if [ -z "$site" ]; then
	echo "ERR: no site name specified" 1>&2
	usage
	exit 1
fi
if [ -z "$hostname" ]; then
	echo "ERR: no hostname specified" 1>&2
	usage
	exit 1
fi
if [ -z "$hosttags" ]; then
	hosttags='wato'
else
	## remove leading, trailing, and repeated pipes from tag spec
	hosttags=$(echo -n "$hosttags" | sed -e 's/|\+/|/g' -e 's/^|//' -e 's/|$//')
fi
if [ -z "$folder" ]; then
	mk_file="/opt/omd/sites/${site}/etc/check_mk/conf.d/wato/hosts.mk"
else
	mk_file="/opt/omd/sites/${site}/etc/check_mk/conf.d/wato/${folder}/hosts.mk"
fi

## Check file existence
if [ ! -f "$mk_file" ]; then
	echo "WARN: File $mk_file does not currently exist, it will be created."
	touch $mk_file && chown ${site}:${site} $mk_file
fi
wato_file="$(dirname $mk_file)/.wato"

## Check if host exists in config
res=$((
cat <<EOT
GET hosts
Columns: host_name
Filter: host_name = $hostname
EOT
) | su - $site -c "lq")

if [ ! -z "$res" ]; then
	echo "ERR: $hostname already added" 1>&2
	exit 1
fi

# Check if host exists on network
host $hostname &> /dev/null
if [[ $? != 0 ]]; then
	echo "ERR: $hostname failed to resolve" 1>&2
	exit 1
fi

## add host to base wato hosts.mk
(
cat <<EOT

all_hosts += [ "${hostname}|${hosttags}|/" + FOLDER_PATH + "/" ]
host_attributes.update({'${hostname}': {}})
EOT
) >> $mk_file

## update num_hosts var for wato
increment_num_hosts $wato_file

## inventory host and reload check_mk
su - $site -c "cmk -II ${hostname}; cmk -O"

exit 0
