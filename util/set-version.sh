#!/bin/bash

## sets current version number as per: http://nvie.com/posts/a-successful-git-branching-model/

# check arguments
VERSION_NUMBER=$1

if [ -z "$VERSION_NUMBER" ] ; then
	echo "Usage: set-version VERSION_NUMBER"
	exit 1
fi

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

# check version number was found correctly (and extract parts)
if [[ "$VERSION_NUMBER" =~ ^([0-9]+).([0-9]+).([0-9]+)-([a-zA-Z0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} "-${BASH_REMATCH[4]}")
elif [[ "$VERSION_NUMBER" =~ ^([0-9]+).([0-9]+).([0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]} "")
elif [[ "$VERSION_NUMBER" =~ ^([0-9]+).([0-9]+)-([a-zA-Z0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]} "0" "-${BASH_REMATCH[3]}")
elif [[ "$VERSION_NUMBER" =~ ^([0-9]+).([0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} ${BASH_REMATCH[2]} "0" "")
elif [[ "$VERSION_NUMBER" =~ ^([0-9]+)-([a-zA-Z0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} "0" "0" "-${BASH_REMATCH[2]}")
elif [[ "$VERSION_NUMBER" =~ ^([0-9]+)$ ]]; then
    VERSION=(${BASH_REMATCH[1]} "0" "0" "")
else
	echo "Error: unknown version format.  Expecteding MAJOR[.MINOR[.PATCH]][-LABEL]"
	exit 1
fi


## perform the updates
DATE=`date '+%Y-%m-%d'`
UPDATESDONE=0

# update version.h
if [ -e "${VERSION_HEADER_FILE}" ]; then
    sed 's/^\(#define '${VERSION_DEFINE_PREFIX}'_VERSION_MAJOR\).*$/\1 '${VERSION[0]}'/g' --in-place=.bak ${VERSION_HEADER_FILE}
    sed 's/^\(#define '${VERSION_DEFINE_PREFIX}'_VERSION_MINOR\).*$/\1 '${VERSION[1]}'/g' --in-place ${VERSION_HEADER_FILE}
    sed 's/^\(#define '${VERSION_DEFINE_PREFIX}'_VERSION_PATCH\).*$/\1 '${VERSION[2]}'/g' --in-place ${VERSION_HEADER_FILE}
    sed 's/^\(#define '${VERSION_DEFINE_PREFIX}'_VERSION_LABEL\).*$/\1 "'${VERSION[3]}'"/g' --in-place ${VERSION_HEADER_FILE}
    sed 's/^\(#define '${VERSION_DEFINE_PREFIX}'_VERSION_DATE\).*$/\1 "'${DATE}'"/g' --in-place ${VERSION_HEADER_FILE}
    git add ${VERSION_HEADER_FILE}
    UPDATESDONE=1
fi

# update CMakeLists.txt
if [ -e "${VERSION_CMAKE_FILE}" ]; then
    sed 's/^\(set ('${VERSION_DEFINE_PREFIX}'_VERSION_MAJOR\).*)$/\1 '${VERSION[0]}')/g' --in-place=.bak ${VERSION_CMAKE_FILE}
    sed 's/^\(set ('${VERSION_DEFINE_PREFIX}'_VERSION_MINOR\).*)$/\1 '${VERSION[1]}')/g' --in-place ${VERSION_CMAKE_FILE}
    sed 's/^\(set ('${VERSION_DEFINE_PREFIX}'_VERSION_PATCH\).*)$/\1 '${VERSION[2]}')/g' --in-place ${VERSION_CMAKE_FILE}
    sed 's/^\(set ('${VERSION_DEFINE_PREFIX}'_VERSION_LABEL\).*)$/\1 "'${VERSION[3]}'")/g' --in-place ${VERSION_CMAKE_FILE}
    sed 's/^\(set ('${VERSION_DEFINE_PREFIX}'_VERSION_DATE\).*)$/\1 "'${DATE}'")/g' --in-place ${VERSION_CMAKE_FILE}
    git add ${VERSION_CMAKE_FILE}
    UPDATESDONE=1
fi

if [ $UPDATESDONE == 0 ]; then
    echo "Warning: Neither version.h OR a CMakeLists.txt file existed so nothing changed"
    exit 2
fi

exit 0
