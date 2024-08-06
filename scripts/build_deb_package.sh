#! /bin/bash

set -uex

move_files() {
    BUILD_DIR="build/"
    OUTPUT_FILES="debian/files"

    echo "Moving the built files:"
    cat $OUTPUT_FILES
    while IFS= read -r LINE; do
        FILE="../$(echo $LINE | awk '{print $1}')"
        if [[ -f $FILE ]]; then
            mv $FILE $BUILD_DIR
        fi
    done < $OUTPUT_FILES
    echo "All built files placed in $BUILD_DIR"
}

usage() {
    echo "Usage: $0 [snapshot|release]"
    exit 1
}

if [ -z "$1" ]; then
    echo "Error: No build type provided."
    usage
fi
case $1 in
    snapshot)
        BUILD_TYPE="--snapshot"
        ;;
    release)
        BUILD_TYPE="--release"
        ;;
    *)
        echo "Error: Invalid build type."
        usage
        ;;
esac

cd $(dirname "${BASH_SOURCE[0]}")/.. && pwd

VERSION=${VERSION:-""}
if [[ -z $VERSION ]]; then
    VERSION=$(./get_version.sh generate)
fi

npm install
node_modules/bower/bin/bower --allow-root install
node_modules/gulp/bin/gulp.js

gbp dch --ignore-branch --git-author --spawn-editor=never --new-version $VERSION $BUILD_TYPE

export PIP_CACHE_DIR="pip_cache/"
mkdir -p $PIP_CACHE_DIR
dpkg-buildpackage -us -uc
move_files
