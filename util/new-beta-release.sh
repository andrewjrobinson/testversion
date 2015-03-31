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
#RELEASE_NUMBER=$(${UTILFULLPATH}/get-version.sh PROD_FORMATTED)
#MAJOR_RELEASE_NUMBER=${RELEASE_NUMBER%%.*}

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
    echo "Error: current branch ($CURRENT_BRANCH) does not appear to be a release branch."
	echo ""
	exit 1
fi

# find release version
RELEASE_NUMBER=$(git branch | grep "^* " | sed 's/* '$RELEASE_PREFIX'//g')
if [ "$RELEASE_NUMBER" == "" ]; then
	echo "Error: unable to identify version number"
	exit 10
fi

# get next beta version number
RELSEG=($(${UTILFULLPATH}/get-version.sh))
BETA_NUM=$(git tag | grep -E "v${RELEASE_NUMBER}(\.[0-9]+)?-beta" | sed 's/.*-beta\([0-9]*\).*/\1/g' | sort -n | tail -1)
if [ "$BETA_NUM" == "" ]; then
    BETA_NUM="0"
fi
NEXT_BETA_NUM=$((BETA_NUM+1))
RELEASE_NUMBER="$RELEASE_NUMBER-beta$NEXT_BETA_NUM"


## make version number and tag
# check user is ok to proceed
echo "------------"
echo "I am about to run the following commands:"
echo ""
echo "  # Update version number (to $RELEASE_NUMBER) and tag"
echo "  ${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER"
echo "  git commit -m \"Beta release v$RELEASE_NUMBER\""
echo "  git tag -a v$RELEASE_NUMBER -m \"Version $RELEASE_NUMBER\""
echo ""
read -p "Are you happy to proceed? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "User got scared and pulled out"
    
    exit 1
fi

# do the commands
${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER
if [ "$?" != "0" ]; then
    echo "${UTILFULLPATH}/set-version.sh $RELEASE_NUMBER:  Failed (with code $?), exiting"
    exit 5
fi
git commit -m "Beta release v$RELEASE_NUMBER"
if [ "$?" != "0" ]; then
    echo "git commit -m \"Beta release v$RELEASE_NUMBER\":  Failed (with code $?), exiting"
    exit 5
fi
git tag -a v$RELEASE_NUMBER -m "Version $RELEASE_NUMBER"
if [ "$?" != "0" ]; then
    echo "git tag -a v$RELEASE_NUMBER -m \"Version $RELEASE_NUMBER\":  Failed (with code $?), exiting"
    exit 5
fi



