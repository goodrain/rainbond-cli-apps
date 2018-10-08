#!/bin/bash
set -e

# prepare
base=${1:-./.release}
releasedir=$base
rm -fr $releasedir
mkdir -p $releasedir

# build files
program=cni:k8s
vers=v3.7.2


cp -a bin $releasedir
cp -a cni $releasedir


#### add to docker images####
#### DONT MODIFY ####
cd $base
tar zcf pkg.tgz `find . -maxdepth 1|sed 1d`

cat >Dockerfile <<EOF
FROM alpine:3.6
COPY pkg.tgz /
EOF

docker build -t rainbond/${program}_${vers} .
docker push rainbond/${program}_${vers}

cd ..

rm -fr $base

echo "run <docker run --rm -v /srv/salt/misc/file:/sysdir rainbond/${program}_${vers} tar zxf /pkg.tgz -C /sysdir> for install"
