#!/bin/bash
#
# cleans, compiles and local installs libbiostreams

echo ""

# defaults (if not in settings file)
DEBUG=0
CPUS=1
SHARED=1

# load settings file
FULLSCRIPTPATH=`readlink -f $0`
UTILFULLPATH=`dirname ${FULLSCRIPTPATH}`
source ${UTILFULLPATH}/settings.sh

# construct commands
CMAKEOPTS="-DCMAKE_INSTALL_PREFIX=${INSTALLDIR}"
MAKEOPTS="-j ${CPUS}"
if [ $DEBUG -eq 1 ]; then
    CMAKEOPTS="${CMAKEOPTS} -DCMAKE_BUILD_TYPE=Debug"
fi
if [ $SHARED -eq 1 ]; then
    CMAKEOPTS="${CMAKEOPTS} -DBUILD_SHARED_LIBS:BOOL=ON -DPOSITION_INDEPENDENT_CODE:BOOL=True"
else
    CMAKEOPTS="${CMAKEOPTS} -DBUILD_SHARED_LIBS:BOOL=OFF"
fi
if [ -n "$CMAKE_FIND_ROOT_PATH" ]; then
    CMAKEOPTS="${CMAKEOPTS} -DCMAKE_FIND_ROOT_PATH=$CMAKE_FIND_ROOT_PATH"
fi
if [[ "$1" == VERBOSE* ]]; then
    MAKEOPTS="${MAKEOPTS} $1"
fi

# Setup (and clean) build and install directories (if needed)
echo "Building in:  ${BUILDDIR}"
echo "Deploying to: ${INSTALLDIR}"

mkdir -p $BUILDDIR $INSTALLDIR
rm -r $BUILDDIR/* $INSTALLDIR/*

# build
cd $BUILDDIR
echo ""
echo "cmake $CMAKEOPTS .."
echo "make $MAKEOPTS install"
echo ""

cmake $CMAKEOPTS .. && make $MAKEOPTS install
