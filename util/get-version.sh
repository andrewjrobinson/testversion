#!/bin/bash

## gets current version number as per: http://nvie.com/posts/a-successful-git-branching-model/

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$VERSION_HEADER_FILE" ] || [ -z "$VERSION_CMAKE_FILE" ] || [ -z "$VERSION_DEFINE_PREFIX" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

# canonicalise the paths
VERSION_HEADER_FILE=$(readlink -m $UTILFULLPATH/../${VERSION_HEADER_FILE})
VERSION_CMAKE_FILE=$(readlink -m $UTILFULLPATH/../${VERSION_CMAKE_FILE})

# parse version files for version information
if [ -e "${VERSION_HEADER_FILE}" ]; then
    MAJOR=$(grep "^#define ${VERSION_DEFINE_PREFIX}_VERSION_MAJOR" ${VERSION_HEADER_FILE} | sed 's/^#define '${VERSION_DEFINE_PREFIX}'_VERSION_MAJOR \([0-9]*\).*$/\1/g')
    MINOR=$(grep "^#define ${VERSION_DEFINE_PREFIX}_VERSION_MINOR" ${VERSION_HEADER_FILE} | sed 's/^#define '${VERSION_DEFINE_PREFIX}'_VERSION_MINOR \([0-9]*\).*$/\1/g')
    PATCH=$(grep "^#define ${VERSION_DEFINE_PREFIX}_VERSION_PATCH" ${VERSION_HEADER_FILE} | sed 's/^#define '${VERSION_DEFINE_PREFIX}'_VERSION_PATCH \([0-9]*\).*$/\1/g')
    LABEL=$(grep "^#define ${VERSION_DEFINE_PREFIX}_VERSION_LABEL" ${VERSION_HEADER_FILE} | sed 's/^#define '${VERSION_DEFINE_PREFIX}'_VERSION_LABEL \([a-zA-Z0-9]*\).*$/\1/g')
    DATE=$(grep "^#define ${VERSION_DEFINE_PREFIX}_VERSION_DATE" ${VERSION_HEADER_FILE} | sed 's/^#define '${VERSION_DEFINE_PREFIX}'_VERSION_DATE "\([-0-9]*\)".*$/\1/g')
elif [ -e "${VERSION_CMAKE_FILE}" ]; then
    MAJOR=$(grep "^set (${VERSION_DEFINE_PREFIX}_VERSION_MAJOR" ${VERSION_CMAKE_FILE} | sed 's/^set ('${VERSION_DEFINE_PREFIX}'_VERSION_MAJOR \([0-9]*\).*)$/\1/g')
    MINOR=$(grep "^set (${VERSION_DEFINE_PREFIX}_VERSION_MINOR" ${VERSION_CMAKE_FILE} | sed 's/^set ('${VERSION_DEFINE_PREFIX}'_VERSION_MINOR \([0-9]*\).*)$/\1/g')
    PATCH=$(grep "^set (${VERSION_DEFINE_PREFIX}_VERSION_PATCH" ${VERSION_CMAKE_FILE} | sed 's/^set ('${VERSION_DEFINE_PREFIX}'_VERSION_PATCH \([0-9]*\).*)$/\1/g')
    LABEL=$(grep "^set (${VERSION_DEFINE_PREFIX}_VERSION_LABEL" ${VERSION_CMAKE_FILE} | sed 's/^set ('${VERSION_DEFINE_PREFIX}'_VERSION_LABEL \([a-zA-Z0-9]*\).*)$/\1/g')
    DATE=$(grep "^set (${VERSION_DEFINE_PREFIX}_VERSION_DATE" ${VERSION_CMAKE_FILE} | sed 's/^set ('${VERSION_DEFINE_PREFIX}'_VERSION_DATE "\([-0-9]*\)".*)$/\1/g')
else
	echo "Error: Neither version.h OR a CMakeLists.txt file existed so no where to look for version information"
	exit 1
fi

# print required fields out
case $1 in
MAJOR)
	echo $MAJOR
	;;
MINOR)
	echo $MINOR
	;;
PATCH)
	echo $PATCH
	;;
LABEL)
	echo $LABEL
	;;
DATE)
	echo $DATE
	;;
FORMATTED)
    if [ -z "$LABEL" ]; then
        echo "$MAJOR.$MINOR.$PATCH"
    else
        echo "$MAJOR.$MINOR.$PATCH-$LABEL"
    fi
    ;;
PROD_FORMATTED)
    echo "$MAJOR.$MINOR.$PATCH"
    ;;
*)
	echo "$MAJOR $MINOR $PATCH \"$LABEL\" $DATE"
	;;
esac

