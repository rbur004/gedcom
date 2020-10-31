#!/bin/sh

#create history.txt from the git history
git log --pretty=format:"%an%x09%ad%x0a%x09%s" > History.txt

#we build the git docs in docs, and then copy it over the github local version
/usr/local/bin/rake docs
cp -r doc/* gitdoc
#clean up the docs/ dir for next time
rm -rf doc/*

#( cd gitdoc; git add . ; git commit -a --allow-empty-message -m ""; git push origin gh-pages )
