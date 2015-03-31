#!/bin/bash

## Merges feature to dev and deletes branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$HOTFIX_PREFIX" ] || [ -z "$RELEASE_PREFIX" ] || [ -z "$DEV_BRANCH" ] || [ -z "$PROD_BRANCH" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

CURRENT_BRANCH=$(git status | grep "^On branch " | awk '{print $3}')

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
    echo "------------"
	echo "Warning: you should commit or stash all files before completing a feature"
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
if [[ "$CURRENT_BRANCH" =~ ^${RELEASE_PREFIX} ]] || [[ "$CURRENT_BRANCH" =~ ^${HOTFIX_PREFIX} ]]; then
    echo "------------"
    echo "Warning: current branch ($CURRENT_BRANCH) does not appear to be a feature branch."
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		exit 1
	fi
fi

# confirm feature is up-to-date with dev branch
if [ "$(git branch --contains dev | grep "$CURRENT_BRANCH")" == "" ]; then
    echo "------------"
	echo "Warning: There are recent changes to the development branch which are not in your"
	echo "         feature.  You should merge the development ($DEV_BRANCH) branch into your feature"
	echo "         and re-test your changes before you complete the feature so you reduce"
	echo "         the chance of breaking the development branch!"
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		echo ""
		echo "To merge recent changes from development ($DEV_BRANCH) branch run:"
		echo "  git merge dev"
		exit 1
	fi
fi

## merge into master (and tag)
# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Merge into development"
echo "  git checkout $DEV_BRANCH"
echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo "  git branch -d $CURRENT_BRANCH"
    
    exit 1
fi

# do the commands
git checkout $DEV_BRANCH
if [ "$?" != "0" ]; then
    echo "git checkout $DEV_BRANCH:  Failed (with code $?), exiting"
    exit 5
fi
git merge --no-ff $CURRENT_BRANCH -m "Merge $CURRENT_BRANCH into $DEV_BRANCH"
if [ "$?" != "0" ]; then
    echo "git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\":  Failed (with code $?), exiting"
    exit 5
fi

## delete the release branch
# check user is ok to proceed with deleting the branch
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Delete release branch"
echo "  git branch -d $CURRENT_BRANCH"
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    exit 1
fi

# do the commands
git branch -d $CURRENT_BRANCH
if [ "$?" != "0" ]; then
    echo "git branch -d $CURRENT_BRANCH:  Failed (with code $?), exiting"
    exit 5
fi


