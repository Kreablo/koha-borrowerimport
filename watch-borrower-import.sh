#!/bin/bash

DEBUG=no

debug () {
    local msg="$1"
    if [[ "$DEBUG" == "yes" ]]; then
        echo "watch-borrower-import: $msg" 1>&2 
    fi
}

for instance in $(/usr/sbin/koha-list --enabled) ; do

    debug "checking instance '$instance'"
    
    if [[ -e /etc/koha/sites/$instance/borrowerimport.conf ]]; then

	debug "instance '$instance' have borrowerimport.conf"

	FILENAME=borrowers.csv
	FLAGS=

	. /etc/koha/sites/$instance/borrowerimport.conf

	if [[ -n "$DATEFORMAT" ]]; then
	    FLAGS+=" --dateformat='$DATEFORMAT'"
	fi
	
	if [[ "$KOHA_UPLOAD" = "yes" ]]; then
	    debug "instance '$instance' have KOHA_UPLOAD=yes"
	   (while true; do

		debug "instance '$instance' checking '/var/lib/koha/$instance/uploads/$CATEGORY/*$FILENAME'"

		if [ ! -e "/var/lib/koha/$instance/uploads/$CATEGORY/"*"$FILENAME" ]; then
		    if [ ! -e "/var/lib/koha/$instance/uploads/$CATEGORY/" ]; then
			inotifywait "/var/lib/koha/$instance/uploads/"
		    else
			inotifywait "/var/lib/koha/$instance/uploads/$CATEGORY/"
		    fi
		fi

		debug "instance '$instance' directory change"

		bash -c "PERL5LIB=/usr/share/koha/lib KOHA_CONF=/etc/koha/sites/$instance/koha-conf.xml /usr/local/bin/borrower-import.pl $FLAGS --logfile /var/log/koha/$instance/borrower-import.log --koha-upload --input '$FILENAME' --config /etc/koha/sites/$instance/"

		find "/var/lib/koha/$instance/uploads/$CATEGORY/" -ctime '+7' -name \*.done -print0 | sudo xargs -0 rm
	    done) &

	elif [[ -n "$FILENAME" ]]; then
	    debug "instance '$instance' running in ftp upload mode"
	    if [[ ! -e "$(dirname "$FILENAME")" ]]; then
		echo "The directory '$(dirname "$FILENAME")' does not exist!" 1>&2
		exit 1
	    fi
	    (while true; do
		if [[ ! -e "$FILENAME" ]]; then
		    inotifywait "$(dirname "$FILENAME")"
		fi

		debug "instance '$instance' directory change"

		bash -c "PERL5LIB=/usr/share/koha/lib KOHA_CONF=/etc/koha/sites/$instance/koha-conf.xml /usr/local/bin/borrower-import.pl $FLAGS --logfile /var/log/koha/$instance/borrower-import.log --input '$FILENAME' --config /etc/koha/sites/$instance/"
		find /home/$user/upload -ctime '+7' -name $FILENAME\* -print0 | sudo xargs -0 rm
	    done) &
	fi
	   

    fi
done

debug "waiting"

wait

debug "exiting"
