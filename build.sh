#!/bin/sh
#Validate manfest.txt
#/usr/local/bin/rake --trace check_manifest 

#Local checking. Creates pkg/
#/usr/local/bin/rake gem

#create doc/
#/usr/local/bin/rake --trace docs  
#In directory docs/
#(cd doc; scp -r . rbur004@rubyforge.org:/var/www/gforge-projects/gedcom/)

#Copy up to rubygem.org
#/usr/local/bin/rake release VERSION=0.9.3
