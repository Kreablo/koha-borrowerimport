#!/bin/bash -e

sudo apt install inotify-tools
sudo apt install libtext-csv-perl liblog-dispatch-perl libgetopt-long-descriptive-perl libyaml-syck-perl libfile-bom-perl

sudo install -m0755 borrower-import.pl /usr/local/bin/borrower-import.pl
sudo install -m0755 watch-borrower-import.sh /usr/local/bin/watch-borrower-import.sh

sudo install watch-borrower-import.service /etc/systemd/system

sudo systemctl daemon-reload
sudo systemctl enable watch-borrower-import
sudo systemctl start watch-borrower-import
