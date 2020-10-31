#!/bin/sh
#Need to run from command line.
. version

#Install the gem locally, so we can test all is well, before releasing the gem.
sudo /usr/local/bin/gem install pkg/${PROJECT}-${VERSION}.gem
