#!/bin/bash

## Merges release to master and deletes branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$HOTFIX_PREFIX" ] || [ -z "$RELEASE_PREFIX" ] || [ -z "$DEV_BRANCH" ] || [ -z "$PROD_BRANCH" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

CURRENT_BRANCH=$(git status | grep "^On branch " | awk '{print $3}')
RELEASE_NUMBER=$(${UTILFULLPATH}/get-version.sh PROD_FORMATTED)

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
    echo "------------"
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
if [[ "$(git branch | grep $PROD_BRANCH)" == "" ]]; then
	echo "Error: no production branch ('$PROD_BRANCH') exists."
	exit 10
fi
if [[ ! "$CURRENT_BRANCH" =~ ^${RELEASE_PREFIX} ]]; then
    echo "------------"
    echo "Warning: current branch ($CURRENT_BRANCH) does not appear to be a release branch."
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		exit 1
	fi
fi

# check a version was found
if [ "$RELEASE_NUMBER" == "" ]; then
	echo "Error: unable to identify version number"
	exit 10
fi

## update release version number (i.e. remove label)
# check user is ok to proceed
echo "I am about to run the following commands:"
echo ""
echo "  ${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER"
echo "  git commit -m \"Setting release v$RELEASE_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo ""
    echo "  # Merge into production (as version $RELEASE_NUMBER)"
    echo "  git checkout $PROD_BRANCH"
    echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $PROD_BRANCH\""
    echo "  git tag -a v$RELEASE_NUMBER -m \"Version $RELEASE_NUMBER\""
    echo ""
    echo "  # Merge back into DEV branch"
    echo "  git checkout $DEV_BRANCH"
    echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\""   # NOTE1: update
    echo ""
    echo "  # Delete release branch"
    echo "  git branch -d $CURRENT_BRANCH"
    
    exit 1
fi

# do the commands
${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER
RC=$?
if [ "$RC" != "0" ]; then
    echo "${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER:  Failed (with code $RC), exiting"
    exit 5
fi
git commit -m "Setting release v$RELEASE_NUMBER"
RC=$?
if [ "$RC" != "0" ]; then
    echo "git commit -m \"Setting release v$RELEASE_NUMBER\":  Failed (with code $RC), exiting"
    exit 5
fi

## merge into master (and tag)
# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Merge into production (as version $RELEASE_NUMBER)"
echo "  git checkout $PROD_BRANCH"
echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $PROD_BRANCH\""
echo "  git tag -a v$RELEASE_NUMBER -m \"Version $RELEASE_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo "  # Merge back into DEV branch"
    echo "  git checkout $DEV_BRANCH"
    echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\""   # NOTE1: update
    echo ""
    echo "  # Delete release branch"
    echo "  git branch -d $CURRENT_BRANCH"
    
    exit 1
fi

# do the commands
git checkout $PROD_BRANCH
RC=$?
if [ "$RC" != "0" ]; then
    echo "git checkout $PROD_BRANCH:  Failed (with code $RC), exiting"
    exit 5
fi
git merge --no-ff $CURRENT_BRANCH -m "Merge $CURRENT_BRANCH into $PROD_BRANCH"
RC=$?
if [ "$RC" != "0" ]; then
    echo "git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $PROD_BRANCH\":  Failed (with code $RC), exiting"
    exit 5
fi
git tag -a v$RELEASE_NUMBER -m "Version $RELEASE_NUMBER"
RC=$?
if [ "$RC" != "0" ]; then
    echo "git tag -a v$RELEASE_NUMBER -m \"Version $RELEASE_NUMBER\":  Failed (with code $RC), exiting"
    exit 5
fi

## merge back into dev
# NOTE1: if you want the release tags to show in the history of dev branch 
# then replace "$CURRENT_BRANCH" with "$PROD_BRANCH" (two instances below, and 
# one in pullout message above)

# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Merge back into DEV branch"
echo "  git checkout $DEV_BRANCH"
echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\""   # NOTE1: update
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo ""
    echo "  # Delete release branch"
    echo "  git branch -d $CURRENT_BRANCH"
    exit 1
fi

# do the commands
git checkout $DEV_BRANCH
RC=$?
if [ "$RC" != "0" ]; then
    echo "git checkout $DEV_BRANCH:  Failed (with code $RC), exiting"
    exit 5
fi
git merge --no-ff $CURRENT_BRANCH -m "Merge $CURRENT_BRANCH into $DEV_BRANCH"   # NOTE1: update
RC=$?
if [ "$RC" != "0" ]; then
    echo "git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $DEV_BRANCH\":  Failed (with code $RC), exiting"
    exit 5
fi

#TODO: if this repo is tracking need to push to remote before deleting

## delete the release branch
#TODO: if this repo is tracking then need to delete remote branch too (or not and issue pull request)
# check user is ok to proceed with merging dev
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
RC=$?
if [ "$RC" != "0" ]; then
    echo "git branch -d $CURRENT_BRANCH:  Failed (with code $RC), exiting"
    exit 5
fi


