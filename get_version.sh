#!/bin/bash

set -eu

ACTION=${1:-"show"}

if git tag | grep -q .; then
    LATEST_TAG=$(git describe --tags --abbrev=0)
else
    echo "Error: No tags found in the repository."
    echo "* Run 'git tag $(date +'%Y%m%d').0' to create a new tag with today's date."
    exit 1
fi

generate() {
    CURR_VERSION=$(echo $LATEST_TAG | cut -d '.' -f1)
    CURR_PATCH=$(echo $LATEST_TAG | cut -d '.' -f2)

    NEXT_VERSION=$(date +"%Y%m%d")
    if [[ $CURR_VERSION ==  $NEXT_VERSION ]]; then
        NEXT_PATCH=$((CURR_PATCH+1))
    else
        NEXT_PATCH="0"
    fi
    echo "${NEXT_VERSION}.${NEXT_PATCH}"
}

case $ACTION in
    show)
        echo $LATEST_TAG
        ;;
    generate)
        generate
        ;;
    *)
        echo "Error: Invalid argument."
        echo "Usage: $0 [show|generate]"
        exit 1
esac
