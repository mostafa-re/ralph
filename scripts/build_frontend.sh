#!/bin/bash
set -eux

npm install
node_modules/bower/bin/bower --allow-root install
node_modules/gulp/bin/gulp.js
