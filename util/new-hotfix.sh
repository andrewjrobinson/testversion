#!/bin/bash

## Creates a new Release branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# check arguments
HOTFIX_NUMBER=$1

if [ -z "$HOTFIX_NUMBER" ] ; then
	echo "Usage: new-hotfix RELEASE_NUMBER"
	exit 1
fi

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$HOTFIX_PREFIX" ] || [ -z "$RELEASE_PREFIX" ] || [ -z "$DEV_BRANCH" ] || [ -z "$PROD_BRANCH" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

# verify naming standards
if [[ "$HOTFIX_NUMBER" =~ ^$RELEASE_PREFIX ]]; then
	echo "Error: feature name cannot start with '$RELEASE_PREFIX'"
	exit 2
fi

# format version number
if [[ ! "$HOTFIX_NUMBER" =~ ^$HOTFIX_PREFIX ]]; then
	HOTFIX_BRANCH="$HOTFIX_PREFIX$HOTFIX_NUMBER"
else
    HOTFIX_BRANCH=$HOTFIX_NUMBER
    HOTFIX_NUMBER=${HOTFIX_BRANCH#$HOTFIX_PREFIX}
fi
MAJOR_HOTFIX_NUMBER=${HOTFIX_NUMBER%%.*}

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
    echo "------------"
	echo "Warning: you should commit or stash all files before creating a new feature"
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		exit 1
	fi
fi

# verify branches exist/don't exist
if [[ "$(git branch | grep $PROD_BRANCH)" == "" ]]; then
	echo "Error: no production branch ('$PROD_BRANCH') exists."
	exit 10
fi
if [[ "$(git branch | grep $HOTFIX_NUMBER)" != "" ]]; then
	echo "Error: a hotfix '$HOTFIX_NUMBER' already exists.  Please select another number."
	exit 10
fi

# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  git checkout -b \"$HOTFIX_BRANCH\" $PROD_BRANCH"
echo "  ${UTILFULLPATH}/set-version.sh $HOTFIX_NUMBER"
echo "  git commit -m \"Preparing for hotfix v$HOTFIX_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    exit 1
fi

# do the commands
git checkout -b "$HOTFIX_BRANCH" $PROD_BRANCH
${UTILFULLPATH}/set-version.sh $HOTFIX_NUMBER
git commit -m "Preparing for hotfix v$HOTFIX_NUMBER"
