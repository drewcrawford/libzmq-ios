#!/bin/sh
# A script to download and build libzmq for iOS, including arm64
# Adapted from https://raw2.github.com/seb-m/CryptoPill/master/libsodium.sh

set -e

LIBNAME="libzmq.a"
ROOTDIR=`pwd`

#libsodium
LIBSODIUM_DIST="${ROOTDIR}/libsodium-ios/libsodium_dist/"

ARCHS=${ARCHS:-"armv7 armv7s arm64 i386 x86_64"}
DEVELOPER=$(xcode-select -print-path)
LIPO=$(xcrun -sdk iphoneos -find lipo)
#LIPO=lipo
# Script's directory
SCRIPTDIR=$( (cd -P $(dirname $0) && pwd) )
# libsodium root directory
LIBDIR="libzeromq"
mkdir -p $LIBDIR
LIBDIR=$( (cd "${LIBDIR}"  && pwd) )
# Destination directory for build and install
DSTDIR=${SCRIPTDIR}
BUILDDIR="${DSTDIR}/libzmq_build"
DISTDIR="${DSTDIR}/libzmq_dist"
DISTLIBDIR="${DISTDIR}/lib"
TARNAME="zeromq-4.0.3"
TARFILE=${TARNAME}.tar.gz
TARURL=http://download.zeromq.org/$TARFILE

# http://libwebp.webm.googlecode.com/git/iosbuild.sh
# Extract the latest SDK version from the final field of the form: iphoneosX.Y
SDK=$(xcodebuild -showsdks \
    | grep iphoneos | sort | tail -n 1 | awk '{print substr($NF, 9)}'
    )

OTHER_LDFLAGS=""
OTHER_CPPFLAGS="-I${LIBSODIUM_DIST}/include"


rm -rf $LIBDIR
set -e
curl -O -L $TARURL
tar xzf $TARFILE
rm $TARFILE
mv $TARNAME $LIBDIR



# Cleanup
if [ -d $BUILDDIR ]
then
    rm -rf $BUILDDIR
fi
if [ -d $DISTDIR ]
then
    rm -rf $DISTDIR
fi
mkdir -p $BUILDDIR $DISTDIR

# Generate autoconf files
cd ${LIBDIR}
#cd ${LIBDIR}; ./autogen.sh

# Iterate over archs and compile static libs
for ARCH in $ARCHS
do
    BUILDARCHDIR="$BUILDDIR/$ARCH"
    mkdir -p ${BUILDARCHDIR}

    case ${ARCH} in
        armv7)
	    PLATFORM="iPhoneOS"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
	    export CPPFLAGS="-Os -mthumb -Qunused-arguments -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
            ;;
        armv7s)
	    PLATFORM="iPhoneOS"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
	    export CPPFLAGS="-Os -mthumb -Qunused-arguments -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
            ;;
        arm64)
	    PLATFORM="iPhoneOS"
	    HOST="arm-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
	    export CPPFLAGS="-Os -mthumb -Qunused-arguments -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_CPPFLAGS}"
	    export LDFLAGS="-mthumb -arch ${ARCH} -isysroot ${ISDKROOT} ${OTHER_LDFLAGS}"
            ;;
        i386)
	    PLATFORM="iPhoneSimulator"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
	    export CPPFLAGS="-Os -m32 -Qunused-arguments -arch ${ARCH} -isysroot ${ISDKROOT} -miphoneos-version-min=${SDK} ${OTHER_CPPFLAGS}"
	    export LDFLAGS="-m32 -arch ${ARCH} ${OTHER_LDFLAGS}"
            ;;
        x86_64)
	    PLATFORM="iPhoneSimulator"
	    HOST="${ARCH}-apple-darwin"
	    export BASEDIR="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	    export ISDKROOT="${BASEDIR}/SDKs/${PLATFORM}${SDK}.sdk"
	    export CPPFLAGS="-Os -Qunused-arguments -arch ${ARCH} ${OTHER_LDFLAGS}  -isysroot ${ISDKROOT} -miphoneos-version-min=${SDK} ${OTHER_CPPFLAGS}"
	    export LDFLAGS="-arch ${ARCH} ${OTHER_LDFLAGS}"
	    echo "LDFLAGS $LDFLAGS"
            ;;
        *)
            echo "Unsupported architecture ${ARCH}"
            exit 1
            ;;
    esac

    export PATH="${BASEDIR}/usr/bin:$BASEDIR/usr/sbin:$PATH"

    echo "Configuring for ${ARCH}..."
    set +e
    cd ${LIBDIR} && make distclean
    set -e
    ${LIBDIR}/configure \
	--prefix=${BUILDARCHDIR} \
	--disable-shared \
	--enable-static \
	--host=${HOST}\
	--with-libsodium=${LIBSODIUM_DIST}

    echo "Building ${LIBNAME} for ${ARCH}..."
    cd ${LIBDIR}/src
    
    make -j8 V=0
    make install

    LIBLIST+="${BUILDARCHDIR}/lib/${LIBNAME} "
done

# Copy headers and generate a single fat library file
mkdir -p ${DISTLIBDIR}
${LIPO} -create ${LIBLIST} -output ${DISTLIBDIR}/${LIBNAME}
for ARCH in $ARCHS
do
    cp -R $BUILDDIR/$ARCH/include ${DISTDIR}
    break
done

# Cleanup
rm -rf ${BUILDDIR}
