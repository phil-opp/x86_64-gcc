#!/bin/sh

# Exit if anything fails
set -e

if [ $TRAVIS_BRANCH != 'master' ]; then
  exit 0
fi

if [ $HOST != 'x86_64-unknown-linux-gnu' ]; then
  exit 0
fi

latest_version=$(curl "ftp://ftp.gnu.org/gnu/gcc/" 2>/dev/null | grep -oP "gcc-[0-9.]+" | tail -1 | grep -oP "[0-9][0-9.]+[0-9]")
latest_release=$(curl -s https://api.github.com/repos/phil-opp/x86_64-gcc/releases | grep browser_download_url | grep "$TARGET" | head -n 1 | cut -d '"' -f 4 | grep -oP "[0-9][0-9.]+[0-9]" | head -1)

if [ $latest_version = $latest_release ]; then
  echo "up to date"
  exit 0
fi

# clone repo again to update it
git clone https://github.com/phil-opp/x86_64-gcc.git
cd x86_64-gcc

# update source
rm -rf src

filename="gcc-$latest_version.tar.gz"

# download and extract it
curl "ftp://ftp.gnu.org/gnu/gcc/gcc-$latest_version/$filename" > "$filename"
tar xf $filename
rm $filename
mv "gcc-$latest_version" src

# git config
git config user.name "travis-update-bot"
git config user.email "travis-update-bot@phil-opp.com"
git config --global push.default simple

# commit new files
cd src
git add --all .
git commit -m "Update to version $latest_version" || exit 0
git tag "v$latest_version"
cd ..

# push changes
eval SSH_KEY_TRAVIS_ID=018db8648fcd
eval key=\$encrypted_${SSH_KEY_TRAVIS_ID}_key
eval iv=\$encrypted_${SSH_KEY_TRAVIS_ID}_iv

mkdir -p ~/.ssh
openssl aes-256-cbc -K $key -iv $iv -in update.enc -out ~/.ssh/id_rsa -d
chmod 600 ~/.ssh/id_rsa

git remote add upstream git@github.com:phil-opp/x86_64-gcc.git
git push upstream
git push upstream "v$latest_version"
