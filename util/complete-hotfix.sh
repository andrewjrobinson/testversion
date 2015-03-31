#!/bin/bash

## Merges hotfix to master and deletes branch as per: http://nvie.com/posts/a-successful-git-branching-model/

# load settings file
FULLSCRIPTPATH=$(readlink -f $0)
UTILFULLPATH=$(dirname ${FULLSCRIPTPATH})
source ${UTILFULLPATH}/defaults
if [ -z "$HOTFIX_PREFIX" ] || [ -z "$RELEASE_PREFIX" ] || [ -z "$DEV_BRANCH" ] || [ -z "$PROD_BRANCH" ]; then
	echo "Error: missing or incomplete settings file"
	exit 10
fi

CURRENT_BRANCH=$(git status | grep "^On branch " | awk '{print $3}')
HOTFIX_NUMBER=$(${UTILFULLPATH}/get-version.sh PROD_FORMATTED)
MAJOR_RELEASE_NUMBER=${RELEASE_NUMBER%%.*}

# check for clean slate
if [[ "$(git status | grep "nothing to commit, working directory clean")" == "" ]]; then
    echo "------------"
	echo "Warning: you should commit or stash all files before creating a new hotfix"
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
if [[ ! "$CURRENT_BRANCH" =~ ^${HOTFIX_PREFIX} ]]; then
    echo "------------"
    echo "Warning: current branch ($CURRENT_BRANCH) does not appear to be a hotfix branch."
	echo ""
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo ""
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo "User got scared and pulled out"
		exit 1
	fi
fi

# check a version was found
if [ "$HOTFIX_NUMBER" == "" ]; then
	echo "Error: unable to identify version number"
	exit 10
fi

# check for release branch
RELEASE_BRANCH=$(git branch | grep "$RELEASE_PREFIX" | sed 's/[\* ]*//g' | sort -V | tail -1)
RELEASE_VERSION=$(echo "$RELEASE_BRANCH" | sed 's/'$RELEASE_PREFIX'//g')
TARGET_DEV_BRANCH=$DEV_BRANCH
if [ "$RELEASE_BRANCH" != "" ]; then
    echo "------------"
    echo "A release branch exists ($RELEASE_BRANCH) so I should merge with this instead"
    echo "of dev branch so that the hotfix makes it into the next release too."
    echo ""
    read -p "Should I merge with release branch? [Y/n] " -n 1 -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        TARGET_DEV_BRANCH=$RELEASE_BRANCH
    fi
fi

## merge into master (and tag)
# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Merge into production (as version $HOTFIX_NUMBER)"
echo "  git checkout $PROD_BRANCH"
echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $PROD_BRANCH\""
echo "  git tag -a v$HOTFIX_NUMBER -m \"Version $HOTFIX_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "------------"
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo "  # Merge back into DEV branch"
    echo "  git checkout $TARGET_DEV_BRANCH"
    if [ "$RELEASE_BRANCH" != "" ]; then
        echo "  ${UTILFULLPATH}/set-version.sh $RELEASE_VERSION"
        echo "  git commit -m \"Restoring release version number (v$RELEASE_VERSION)\""
    fi
    echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $TARGET_DEV_BRANCH\""   # NOTE1: update
    echo ""
    echo "  # Delete hotfix branch"
    echo "  git branch -d $CURRENT_BRANCH"
    
    exit 1
fi

# do the commands
git checkout $PROD_BRANCH
git merge --no-ff $CURRENT_BRANCH -m "Merge $CURRENT_BRANCH into $PROD_BRANCH"
git tag -a v$HOTFIX_NUMBER -m "Version $HOTFIX_NUMBER"

## merge back into dev
# NOTE1: if you want the release tags to show in the history of dev branch 
# then replace "$CURRENT_BRANCH" with "$PROD_BRANCH" (two instances below, and 
# one in pullout message above)

# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Merge back into DEV branch"
echo "  git checkout $TARGET_DEV_BRANCH"
echo "  git merge --no-ff $CURRENT_BRANCH -m \"Merge $CURRENT_BRANCH into $TARGET_DEV_BRANCH\""   # NOTE1: update
if [ "$RELEASE_BRANCH" != "" ]; then
    echo "  ${UTILFULLPATH}/set-version.sh $RELEASE_VERSION"
    echo "  git commit -m \"Restoring release version number (v$RELEASE_VERSION)\""
fi
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "------------"
	echo "User got scared and pulled out"
    echo ""
    echo "After this I would have run these commands:"
    echo ""
    echo "  # Delete hotfix branch"
    echo "  git branch -d $CURRENT_BRANCH"
    exit 1
fi

# do the commands
git checkout $TARGET_DEV_BRANCH
git merge --no-ff $CURRENT_BRANCH -m "Merge $CURRENT_BRANCH into $TARGET_DEV_BRANCH"   # NOTE1: update
if [ "$RELEASE_BRANCH" != "" ]; then
    ${UTILFULLPATH}/set-version.sh $RELEASE_VERSION
    git commit -m "Restoring release version number (v$RELEASE_VERSION)"
fi

## delete the hotfix branch
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
    echo "------------"
	echo "User got scared and pulled out"
    exit 1
fi

# do the commands
git branch -d $CURRENT_BRANCH


