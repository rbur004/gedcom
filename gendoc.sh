#!/bin/sh
#create doc
/usr/local/bin/rake docs
cp -r doc/* ../doc
rm -rf doc
( cd ../doc; git add . ; git commit -a --allow-empty-message -m ""; git push origin gh-pages )
