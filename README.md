Configuration
-------------

Create the files /etc/koha/sites/<instance name>/borrowerimport.conf
and /etc/koha/sites/<instance name>/borrowerimport-instance-map.yaml
based on the example files.

Installation
------------

Run the script install.sh.

If borrowerimport.conf is updated, you will need to restart the service:

    sudo systemctl restart watch-borrower-import

Instance map
------------

The instance map is a yaml file that maps the source branch-code to
koha-instance and koha branchcode. Place this file under
/etc/koha/sites/<koha instance>/borrowerimport-instance-map.yaml

In this example, the branchcode in the source data file may contain
the values code1 and code2, which will both be mapped to the koha
instance kolib and the branccodes branchcode1 and branchcode2.

    code1:
	   instance: kolib
       branchcode: branchcode1
    code2:
	   instance: kolib
       branchcode: branchcode2

It is possible to map the imported borrowers to different
koha-instances, although the configuration files needs to be placed in
the configuration directory of a specific instance.


FTP upload mode
---------------

In FTP upload mode (with KOHA_UPLOAD=no), just set the FILENAME
parameter to the full path of the file that is expected to be
uploaded.

Upload tool mode
----------------

In the koha administrative view go to administration -> authorized
values.  Add the category 'UPLOAD' if it does not already exist. Add
the value 'BORROWERS' in the category 'UPLOAD'.

The FILENAME parameter must be set to just the filename (no directory).

