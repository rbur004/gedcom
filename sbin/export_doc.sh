#!/bin/sh
#Copy up to rubygem.org

#ensure the github code is up to date, and tagged as a release version
. version

cd gitdoc
git add .
git commit -m "#{PROJECT} Doc release ${VERSION}"
git push --set-upstream origin gh-pages
