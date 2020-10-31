#!/bin/sh
#Local checking. Creates pkg/

#Package project name and version, which needs to match the VERSION in the class declaration (as a safety check)
. version

sbin/gendoc.sh #Ensure History file is uptodate, and use yard to generate html docs.
/usr/local/bin/rake --trace gem
