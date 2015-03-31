#!/bin/bash

## Creates a new Feature branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# check arguments
FEATURE_NAME=$1

if [ -z "$FEATURE_NAME" ] ; then
	echo "Usage: new-feature FEATURE_NAME"
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
if [[ "$FEATURE_NAME" =~ ^$HOTFIX_PREFIX ]]; then
	echo "Error: feature name cannot start with either '$HOTFIX_PREFIX' or '$RELEASE_PREFIX'"
	exit 2
fi
if [[ "$FEATURE_NAME" =~ ^$RELEASE_PREFIX ]]; then
	echo "Error: feature name cannot start with either '$HOTFIX_PREFIX' or '$RELEASE_PREFIX'"
	exit 2
fi

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
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
if [[ "$(git branch | grep $DEV_BRANCH)" == "" ]]; then
	echo "Error: no development branch ('$DEV_BRANCH') exists."
	exit 10
fi
if [[ "$(git branch | grep $FEATURE_NAME)" != "" ]]; then
	echo "Error: a branch '$FEATURE_NAME' already exists.  Please select another name."
	exit 10
fi

# check user is ok to proceed
echo "I am about to run the following commands:"
echo ""
echo "  git checkout -b \"$FEATURE_NAME\" $DEV_BRANCH"
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    exit 1
fi

# do the commands
git checkout -b "$FEATURE_NAME" $DEV_BRANCH
if [ "$?" != "0" ]; then
    echo "git checkout -b \"$FEATURE_NAME\" $DEV_BRANCH:  Failed (with code $?), exiting"
    exit 5
fi

