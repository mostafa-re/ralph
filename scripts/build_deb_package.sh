#! /bin/bash

set -uex

cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd

npm install
node_modules/bower/bin/bower --allow-root install
node_modules/gulp/bin/gulp.js

export PIP_CACHE_DIR="pip_cache/"
mkdir -p $PIP_CACHE_DIR
dpkg-buildpackage -us -uc

# rm -rdf debian/.debhelper/ debian/*.debhelper* debian/*.substvars
# rm -rdf pakcage-lock.json bower_components/ node_modules/ pip_cache/
