#!/bin/bash

DEBUG=no
LOGLEVEL=info

debug () {
    local msg="$1"
    if [[ "$DEBUG" == "yes" ]]; then
        echo "watch-borrower-import: $msg" 1>&2 
    fi
}

for instance in $(/usr/sbin/koha-list --enabled) ; do

    debug "checking instance '$instance'"

    declare -a config_files=()

    if [[ -e /etc/koha/sites/$instance/borrowerimport.conf ]]; then
        config_files[${#config_files[@]}]=/etc/koha/sites/$instance/borrowerimport.conf
    fi

    if [[ -d /etc/koha/sites/$instance/borrowerimport.conf.d ]]; then
        for f in /etc/koha/sites/$instance/borrowerimport.conf.d/*.conf; do
            if [[ -e "$f" ]]; then
                config_files[${#config_files[@]}]="$f"
            fi
        done
    fi

    for config_file in "${config_files[@]}"; do

	debug "instance '$instance' have config file $config_file"

	FILENAME=borrowers.csv
	FLAGS=

	. "$config_file"

	if [[ -n "$DATEFORMAT" ]]; then
	    FLAGS+=" --dateformat='$DATEFORMAT'"
	fi
	
	if [[ "$KOHA_UPLOAD" = "yes" ]]; then
	    debug "instance '$instance' have KOHA_UPLOAD=yes"
	   (while true; do

		debug "instance '$instance' checking '/var/lib/koha/$instance/uploads/$CATEGORY/*$FILENAME'"

		while [[ ! -e "/var/lib/koha/$instance/uploads/$CATEGORY/"*"$FILENAME" ]]; do
		    if [[ ! -e "/var/lib/koha/$instance/uploads/$CATEGORY/" ]]; then
			inotifywait -e close_write "/var/lib/koha/$instance/uploads/"
		    else
			inotifywait -e close_write "/var/lib/koha/$instance/uploads/$CATEGORY/"
		    fi
		done

		debug "instance '$instance' directory change"

		bash -c "PERL5LIB=/usr/share/koha/lib KOHA_CONF=/etc/koha/sites/$instance/koha-conf.xml /usr/local/bin/borrower-import.pl $FLAGS --loglevel $LOGLEVEL --logfile /var/log/koha/$instance/borrower-import.log --koha-upload --input '$FILENAME' --config /etc/koha/sites/$instance/"

		find "/var/lib/koha/$instance/uploads/$CATEGORY/" -ctime '+7' -name \*.done -print0 | sudo xargs -0 rm
	    done) &

	elif [[ -n "$FILENAME" ]]; then
	    debug "instance '$instance' running in ftp upload mode"
	    if [[ ! -e "$(dirname "$FILENAME")" ]]; then
		echo "The directory '$(dirname "$FILENAME")' does not exist!" 1>&2
		exit 1
	    fi
	    (while true; do
		while [[ ! -e "$FILENAME" ]]; do
		    inotifywait -e close_write "$(dirname "$FILENAME")"
		done

		debug "instance '$instance' directory change"

		bash -c "PERL5LIB=/usr/share/koha/lib KOHA_CONF=/etc/koha/sites/$instance/koha-conf.xml /usr/local/bin/borrower-import.pl $FLAGS --loglevel $LOGLEVEL --logfile /var/log/koha/$instance/borrower-import.log --input '$FILENAME' --config /etc/koha/sites/$instance/"
		find "$(dirname "$FILENAME")" -ctime '+7' -name $FILENAME\* -print0 | sudo xargs -r -0 rm
	    done) &
	fi
	   

    done
done

debug "waiting"

wait

debug "exiting"
