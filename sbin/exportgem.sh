#!/bin/sh
#Copy up to rubygem.org

#ensure the github code is up to date, and tagged as a release version
. version
git add .
git commit -m "#{PROJECT} release ${VERSION}"
git tag -a ${VERSION} -m "#{PROJECT} release ${VERSION}"
git push origin

/usr/local/bin/rake release VERSION=${VERSION} #--trace

sbin/export_doc.sh
