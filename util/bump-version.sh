#!/bin/bash
#
# bump-version.sh
# Created on: 4 Nov 2014
#     Author: arobinson
#
# Increases the version number by 1 and adds as a git tag.  It also updates
# version.h and CMakeLists.txt files to reflect the change
#
# usage: bump-version.sh MAJOR|MINOR|PATCH [--dry-run]
#
# where:
#   - MAJOR = increase major version by 1 (and reset minor & patch to 0)
#   - MINOR = increase minor version by 1 (and reset patch to 0, major remains same)
#   - PATCH = increase patch version by 1 (and leave major and minor the same)
#

## settings ##
# the only branch that should have versions
BRANCH_NAME=master

# the prefix before MAJOR,MINOR,PATCH in the version header file
VERSION_PREFIX=LIB_BIO_STREAMS

# the name of the version header file (relative to git repo root)
VERSION_HEADER="cppsrc/libbiostreams/version.h"
VERSION_CMAKE="cppsrc/libbiostreams/CMakeLists.txt"


## status check ##
echo "[Performing status checks]"

# version part check
if [ "$1" = "" ]; then
	echo "Please specify which part of version to increment"
	echo ""
	echo "Usage: $0 MAJOR|MINOR|PATCH [--dry-run]"
	exit 1
fi

# check correct branch
echo -n "1) Checking correct local branch ...               "
STATUS=`git status | grep "On branch ${BRANCH_NAME}"`
if [ $? -ne 0 ]; then
    echo "FAILED"
	echo "ERROR: Not using the local '${BRANCH_NAME}' branch"
	exit 2
fi
echo "OK (${BRANCH_NAME})"

# check local needs commit
echo -n "2) Checking for local updates ...                  "
STATUS=`git status | grep "nothing to commit, working directory clean"`
if [ $? -ne 0 ]; then
    echo "FAILED"
	echo "ERROR: uncommitted changes/additions"
	echo ${STATUS}
	exit 3
fi
echo "OK"

# fetch remote status
echo -n "3) Fetching remote updates ...                     " 
STATUS=`git fetch 2>&1`
if [ $? -ne 0 ]; then
    echo "FAILED"
	echo "ERROR: while attempting to fetch updates"
	echo $STATUS
    exit 4
fi
echo "OK"

# check local and remote are level
echo -n "4) Checking local and remote are equal ...         "
STATUS=`git status | grep "Your branch is up-to-date with 'origin/${BRANCH_NAME}'"`
if [ $? -ne 0 ]; then
    echo "FAILED"
	echo "ERROR: local branch is not up-to-date with remote"
	
	# print the actual status information
	git status | grep "Your branch is "
	git status | grep "Your branch and "
	exit 5
fi
echo "OK"

# check there are changes since last version (and extract the version)
echo -n "5) Checking for new commits since last version ... "
NO_TAGS=`git describe 2> /dev/null`
if [ $? -ne 0 ]; then
    echo "OK (first version)"
    MAJOR=0
    MINOR=0
    PATCH=0
else
    NEW_UPDATES=(`git describe 2> /dev/null | sed 's/^v[0-9]*\.[0-9]*\.[0-9]*\(.*\)$/\1/g'`)
    echo $?
    if [ "$NEW_UPDATES" == "" ]; then
        echo "FAILED"
        echo "ERROR: no updates appear to have been committed since last version"
        exit 6
    fi
    echo "OK"
    
    CURRENT_VERSION=(`git describe | sed 's/^v\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*$/\1 \2 \3/g'`)
    MAJOR=${CURRENT_VERSION[0]}
    MINOR=${CURRENT_VERSION[1]}
    PATCH=${CURRENT_VERSION[2]}
fi

## perform version increment ##
case $1 in
MAJOR)
	MAJOR=$((MAJOR+1))
	MINOR=0
	PATCH=0
	;;
MINOR)
	MINOR=$((MINOR+1))
	PATCH=0
	;;
PATCH)
	PATCH=$((PATCH+1))
	;;
*)
	echo "Unknown version part"
	echo ""
	echo "Usage: $0 MAJOR|MINOR|PATCH"
	exit 7
	;;
esac

echo ""
echo "New version will be v${MAJOR}.${MINOR}.${PATCH}"
echo ""

if [ "$2" = "--dry-run" ]; then
    DRYRUN=1
else
    DRYRUN=0
fi

function SED_UPDATE {
    echo " sed" "'$1'" --in-place$3 $2
    if [ $DRYRUN -ne 1 ]; then
        sed "$1" --in-place$3 $2
    fi
}

function GIT_CMD {
    echo " git" "$@"
    if [ $DRYRUN -ne 1 ]; then
        git "$@"
    fi
}

DATE=`date '+%Y-%m-%d'`

SED_UPDATE "s/^\(#define ${VERSION_PREFIX}_MAJOR\).*$/\1 ${MAJOR}/g" ${VERSION_HEADER} "=.bak"
SED_UPDATE "s/^\(#define ${VERSION_PREFIX}_MINOR\).*$/\1 ${MINOR}/g" ${VERSION_HEADER}
SED_UPDATE "s/^\(#define ${VERSION_PREFIX}_PATCH\).*$/\1 ${PATCH}/g" ${VERSION_HEADER}
SED_UPDATE "s/^\(#define ${VERSION_PREFIX}_VERSION_DATE\).*$/\1 ${DATE}/g" ${VERSION_HEADER}

SED_UPDATE "s/^\(set (${VERSION_PREFIX}_MAJOR\).*)$/\1 ${MAJOR})/g" ${VERSION_CMAKE} "=.bak"
SED_UPDATE "s/^\(set (${VERSION_PREFIX}_MINOR\).*)$/\1 ${MINOR})/g" ${VERSION_CMAKE}
SED_UPDATE "s/^\(set (${VERSION_PREFIX}_PATCH\).*)$/\1 ${PATCH})/g" ${VERSION_CMAKE}
SED_UPDATE "s/^\(set (${VERSION_PREFIX}_VERSION_DATE\).*)$/\1 ${DATE})/g" ${VERSION_CMAKE}

GIT_CMD "commit" "-a" "-m" "Version ${MAJOR}.${MINOR}.${PATCH}"
GIT_CMD "tag" "-a" "v${MAJOR}.${MINOR}.${PATCH}" "-m" "Version ${MAJOR}.${MINOR}.${PATCH}"

echo ""
echo "[To undo changes run the following commands]"
echo " git tag -d v${MAJOR}.${MINOR}.${PATCH};"
echo " git reset --soft HEAD^;"
echo " mv ${VERSION_HEADER} ${VERSION_HEADER}.new;"
echo " mv ${VERSION_HEADER}.bak ${VERSION_HEADER};"
echo " mv ${VERSION_CMAKE} ${VERSION_CMAKE}.new;"
echo " mv ${VERSION_CMAKE}.bak ${VERSION_CMAKE};"

