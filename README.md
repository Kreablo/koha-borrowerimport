Configuration
=============

Create the files /etc/koha/sites/&lt;instance name&gt;/borrowerimport.conf
and /etc/koha/sites/&lt;instance name&gt;/borrowerimport-instance-map.yaml
based on the example files.

Installation
============

Run the script install.sh.

If borrowerimport.conf is updated, you will need to restart the service:

    sudo systemctl restart watch-borrower-import

Instance map
============

The instance map is a yaml file that maps the source branch-code to
koha instance and koha branchcode. Place this file under
/etc/koha/sites/&lt;koha instance&gt;/borrowerimport-instance-map.yaml

In this example, the branchcode in the source data file may contain
the values code1 and code2, which will both be mapped to the koha
instance kolib and the branccodes branchcode1 and branchcode2.

    code1:
	   instance: kolib
       branchcode: branchcode1
    code2:
	   instance: kolib
       branchcode: branchcode2
	_default:
	    instance: kolib
		branchcode: defaultbranchcode

It is possible to map the imported borrowers to different
koha-instances, although the configuration files needs to be placed in
the configuration directory of a specific instance.

If there is a _default mapping it will be used when no other mapping
is matched.

Category map
============

The category map is a yaml file that maps source borrower category to
koha borrower categorycode.  The file is optional.  If it does not
exist the source branchcode will be used as is.  Place this file under
/etc/koha/sites/&lt;koha instance&gt;/borrowerimport-category-map.yaml

     category1: categorycode1
     category2: categorycode2
	 _default: defaultcategorycode

If there is a _default mapping it is used if no other mapping matches.

If nothing matches, the original category code is used unmodified.

FTP upload mode
===============

In FTP upload mode (with KOHA_UPLOAD=no), just set the FILENAME
parameter to the full path of the file that is expected to be
uploaded.

Upload tool mode
================

In the koha administrative view go to administration -&gt; authorized
values.  Add the category 'UPLOAD' if it does not already exist. Add
the value 'BORROWERS' in the category 'UPLOAD'.

The FILENAME parameter must be set to just the filename (no directory).

Scripting upload
----------------

When scripting the upload, the authentication have to be made using a
session cookie.  A separate authentication request have to be made to
acquire the cookie.  The authentication has to be made to an account
that have staff access and file upload permissions.

To upload the file end a request using the POST method and basic
authentication to https://<domainnamne of staff interface>/cgi-bin/koha/tools/upload-file.pl
with form-data of type multipart/form-data and the following data-fields:

uploadcategory: BORROWERS
fileToUpload: borrowers.csv (file upload with filename borrowers.csv)

Example with curl:


      domainname=<domain name of staff interface>
	  username=<username>
	  password=<password>

      # Create a temporary file for the session cookie

      cookiejar=$(mktemp)
      trap 'rm -f "$cookiejar"' EXIT INT TERM HUP

      # Authenticate

      curl --silent --cookie-jar "$cookiejar" -F userid="$username" -F password="$password" https://$domainname > /dev/null

      # Upload file

      curl --silent --cookie "$cookiejar" -F uploadcategory=BORROWERS -F fileToUpload=@borrowers.csv https://$domainname/cgi-bin/koha/tools/upload-file.pl?category=BORROWERS

Examle with curl for Windows:

      @ECHO off
      REM
      SET domainname="site"
      SET username="userid"
      SET password="passwprd"

      set cookiejar=.\cookiejar.tmp
      REM type nul > %cookiejar%
      REM Authenticate
      curl.exe -v -c %cookiejar% -F userid=%username% -F password=%password% http://%domainname% > $NUL 2>&1
      REM echo curl.exe -v -c "%cookiejar%" -F userid=%username% -F password=%password% http://%domainname%

      REM Upload file
      curl.exe -v --cookie "%cookiejar%" -F "fileToUpload=@borrowers.csv" "http://%domainname%/cgi-bin/koha/tools/upload-file.pl?category=BORROWERS&
      REM
      del %cookiejar%
