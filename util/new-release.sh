#!/bin/bash

## Creates a new Release branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# check arguments
RELEASE_NUMBER=$1

if [ -z "$RELEASE_NUMBER" ] ; then
	echo "Usage: new-release RELEASE_NUMBER"
	exit 1
fi

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$HOTFIX_PREFIX" ] || [ -z "$RELEASE_PREFIX" ] || [ -z "$DEV_BRANCH" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

# verify naming standards
if [[ "$RELEASE_NUMBER" =~ ^$HOTFIX_PREFIX ]]; then
	echo "Error: release number cannot start with '$HOTFIX_PREFIX'"
	exit 2
fi

# format version number
if [[ ! "$RELEASE_NUMBER" =~ ^$RELEASE_PREFIX ]]; then
	RELEASE_BRANCH="$RELEASE_PREFIX$RELEASE_NUMBER"
else
    RELEASE_BRANCH=$RELEASE_NUMBER
    RELEASE_NUMBER=${RELEASE_BRANCH#$RELEASE_PREFIX}
fi
MAJOR_RELEASE_NUMBER=${RELEASE_NUMBER%%.*}

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
	echo "Warning: you should commit or stash all files before creating a new release"
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		exit 1
	fi
fi

# verify branches exist/don't exist
if [[ "$(git branch | grep $DEV_BRANCH)" == "" ]]; then
	echo "Error: no development branch ('$DEV_BRANCH') exists."
	exit 10
fi
if [[ "$(git branch | grep $RELEASE_BRANCH)" != "" ]]; then
	echo "Error: a branch '$RELEASE_BRANCH' already exists.  Please select another name."
	exit 10
fi

# check version doesn't exist and is increasing (within major)
if [[ "$(git tag | grep "^v$RELEASE_NUMBER$")" != "" ]]; then
    echo "Error: release $RELEASE_NUMBER already exists."
    exit 10
fi
HIGHEST_VERSION=$(echo $(git tag) $RELEASE_NUMBER | sed 's/v//g' | sed 's/ /\n/g' | grep "^${MAJOR_RELEASE_NUMBER}\." | sort -V | tail -1)
if [[ "$HIGHEST_VERSION" != "$RELEASE_NUMBER" ]]; then
    echo "Error: your new version number isn't the highest version (\"$RELEASE_NUMBER\" !> \"$HIGHEST_VERSION\")."
	exit 10
fi

# append -prerelease if needed
RELEASE_LABEL=$(echo $RELEASE_NUMBER | sed 's/^[0-9.]*\(-[0-9a-zA-Z]*\)\?$/\1/g')
if [ "$RELEASE_LABEL" == "" ]; then
    RELEASE_LABEL="-prerelease"
else
    RELEASE_NUMBER=$(echo $RELEASE_NUMBER | sed 's/^\([0-9.]*\)\(-[0-9a-zA-Z]*\)\?$/\1/g')
fi

# check user is ok to proceed
echo "I am about to run the following commands:"
echo ""
echo "  git checkout -b \"$RELEASE_BRANCH\" $DEV_BRANCH"
echo "  ${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER$RELEASE_LABEL"
echo "  git commit -m \"Preparing for release v$RELEASE_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    exit 1
fi

# do the commands
git checkout -b "$RELEASE_BRANCH" $DEV_BRANCH
if [ "$?" != "0" ]; then
    echo "git checkout -b \"$RELEASE_BRANCH\" $DEV_BRANCH:  Failed (with code $?), exiting"
    exit 5
fi
${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER$RELEASE_LABEL
if [ "$?" != "0" ]; then
    echo "${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER$RELEASE_LABEL:  Failed (with code $?), exiting"
    exit 5
fi
git commit -m "Preparing for release v$RELEASE_NUMBER"
if [ "$?" != "0" ]; then
    echo "git commit -m \"Preparing for release v$RELEASE_NUMBER\":  Failed (with code $?), exiting"
    exit 5
fi


