export STATIC_FLAG=
export BEGIN_LDFLAGS=
export IS_STATIC=0

# if you ever compile static and then want to compile dynamically again,
# you need to reinstall the following packages via pacman:
# mingw-w64-x86_64-brotli mingw-w64-x86_64-libunistring mingw-w64-x86_64-libpsl libidn2

if [ ! -z $1 ]; then
	if [ $1 == "static" ]; then
		export STATIC_FLAG="--enable-static --disable-shared"
		export BEGIN_LDFLAGS="-all-static -Wl,--allow-multiple-definition"
		export IS_STATIC=1
	fi
fi

mkdir ./futurerestore_compile
cd ./futurerestore_compile

set -e

#probably more packages than actually needed, but eh, better safe then sorry
pacman -S --needed --noconfirm mingw-w64-x86_64-clang mingw-w64-x86_64-libzip mingw-w64-x86_64-brotli mingw-w64-x86_64-libpng mingw-w64-x86_64-python mingw-w64-x86_64-libunistring mingw-w64-x86_64-curl mingw-w64-x86_64-cython mingw-w64-x86_64-pkg-config
pacman -S --needed --noconfirm make automake autoconf cmake pkg-config openssl libtool m4 libidn2 git libunistring libunistring-devel python cython python-devel

export CC=gcc
export CXX=g++

# TODO: fix liboffsetfinder64 and libipatcher on Windows

git clone --recursive https://github.com/planetbeing/xpwn
git clone --recursive https://github.com/lzfse/lzfse
git clone --recursive https://github.com/curl/curl
git clone --recursive https://github.com/libimobiledevice/libplist
git clone --recursive https://github.com/libimobiledevice/libusbmuxd
git clone --recursive https://github.com/libimobiledevice/libimobiledevice
git clone --recursive https://github.com/libimobiledevice/libirecovery
git clone --recursive https://github.com/tihmstar/libgeneral
git clone --recursive https://github.com/tihmstar/libfragmentzip
git clone --recursive https://github.com/tihmstar/img4tool
#git clone --recursive https://github.com/tihmstar/libinsn
#git clone --recursive https://github.com/tihmstar/liboffsetfinder64
#git clone --recursive https://github.com/tihmstar/libipatcher
git clone --recursive https://github.com/opa334/futurerestore

# xpwn windows fixes
sed -i'' 's|#include <unistd.h>||' ./xpwn/ipsw-patch/main.c
sed -i'' 's|char endianness;||' ./xpwn/ipsw-patch/main.c
sed -i'' 's|#include "common.h"|#include <unistd.h>\n#include "common.h"|' ./xpwn/ipsw-patch/main.c
sed -i'' 's|#include <hfs/hfslib.h>|#include <hfs/hfslib.h>\n#ifdef WIN32\n#include <windows.h>\n#endif|' ./xpwn/dripwn/dripwn.c

# libgeneral windows and general fixes
# (allocate memory manually because windows does not support vasprintf)
sed -i'' 's|vasprintf(&_err, err, ap);|_err=(char*)malloc(1024);vsprintf(_err, err, ap);|' ./libgeneral/libgeneral/exception.cpp
sed -i'' 's|#   include CUSTOM_LOGGING|//#   include CUSTOM_LOGGING|' ./libgeneral/include/libgeneral/macros.h

# img4tool windows fixes
sed -i'' 's|../include/img4tool/img4tool.hpp|#include "../include/img4tool/img4tool.hpp"|' ./img4tool/img4tool/img4tool.hpp
sed -i'' 's|../include/img4tool/ASN1DERElement.hpp|#include "../include/img4tool/ASN1DERElement.hpp"|' ./img4tool/img4tool/ASN1DERElement.hpp
# code borrowed from https://gist.github.com/foxik384/496928d2785e9007d2b838cfa6e019ee
sed -i'' 's|#include <arpa/inet.h>|#include <winsock2.h>\nvoid* memmem(const void* haystack, size_t haystackLen, const void* needle, size_t needleLen) { if (needleLen == 0 \|\| haystack == needle) { return (void*)haystack; } if (haystack == NULL \|\| needle == NULL) { return NULL; } const unsigned char* haystackStart = (const unsigned char*)haystack; const unsigned char* needleStart = (const unsigned char*)needle; const unsigned char needleEndChr = *(needleStart + needleLen - 1); ++haystackLen; for (; --haystackLen >= needleLen; ++haystackStart) { size_t x = needleLen; const unsigned char* n = needleStart; const unsigned char* h = haystackStart; if (*haystackStart != *needleStart \|\| *(haystackStart + needleLen - 1) != needleEndChr) { continue; } while (--x > 0) { if (*h++ != *n++) { break; } } if (x == 0) { return (void*)haystackStart; } } return NULL; }|' ./img4tool/img4tool/lzssdec.c
sed -i'' 's|#include <arpa/inet.h>|#include <winsock2.h>|' ./img4tool/img4tool/img4tool.cpp

# libirecovery windows fix for latest iphone driver (important)
sed -i'' 's|ret = DeviceIoControl(client->handle, 0x220195, data, length, data, length, (PDWORD) transferred, NULL);|ret = DeviceIoControl(client->handle, 0x2201B6, data, length, data, length, (PDWORD) transferred, NULL);|' ./libirecovery/src/libirecovery.c

# libinsn windows fixes
#sed -i'' 's|-fPIC||' ./libinsn/configure.ac # -fPIC flag not supported when compiling for windows
#sed -i'' 's|using namespace tihmstar::libinsn;|using namespace tihmstar::libinsn;\nvoid* memmem(const void* haystack, size_t haystackLen, const void* needle, size_t needleLen) { if (needleLen == 0 \|\| haystack == needle) { return (void*)haystack; } if (haystack == NULL \|\| needle == NULL) { return NULL; } const unsigned char* haystackStart = (const unsigned char*)haystack; const unsigned char* needleStart = (const unsigned char*)needle; const unsigned char needleEndChr = *(needleStart + needleLen - 1); ++haystackLen; for (; --haystackLen >= needleLen; ++haystackStart) { size_t x = needleLen; const unsigned char* n = needleStart; const unsigned char* h = haystackStart; if (*haystackStart != *needleStart \|\| *(haystackStart + needleLen - 1) != needleEndChr) { continue; } while (--x > 0) { if (*h++ != *n++) { break; } } if (x == 0) { return (void*)haystackStart; } } return NULL; }|' ./libinsn/libinsn/vsegment.cpp
#gcc fix
#sed -i'' 's|retcustomerror(out_of_range,\"memstr failed to find \\"%s\\"\",little);|retcustomerror(out_of_range,\"memstr failed to find something\");|' ./libinsn/libinsn/vmem.cpp

# liboffsetfinder windows fixes
#more needed for liboffsetfinder, can get mach-o headers from xnu kernel but mach headers are missing
#sed -i'' 's|#include <arpa/inet.h>|#include <winsock2.h>|' ./liboffsetfinder64/liboffsetfinder64/machopatchfinder64.cpp
#gcc fixes
#sed -i'' 's|bad level=%d\",level|bad level\"|' ./liboffsetfinder64/liboffsetfinder64/patchfinder64.cpp
#sed -i'' 's|failed to find cmd: %s\",cmd|failed to find cmd\"|' ./liboffsetfinder64/include/liboffsetfinder64/OFexception.hpp

cd ./xpwn
cmake -DCMAKE_SYSTEM_NAME=MSYS -S ./ -B ./compile
cd ./compile
make LDFLAGS="$BEGIN_LDFLAGS"
cp ./common/libcommon.a /mingw64/lib/libcommon.a
cp ./ipsw-patch/libxpwn.a /mingw64/lib/libxpwn.a
cp -r ../includes/* /mingw64/include
cd ..
cd ..

cd ./lzfse
make install LDFLAGS="$BEGIN_LDFLAGS" INSTALL_PREFIX=/mingw64
cd ..

if [ $IS_STATIC == 1 ]; then
	git clone --recursive https://github.com/google/brotli
	cd ./brotli
	autoreconf -fi
	./configure $STATIC_FLAG
	make install LDFLAGS="$BEGIN_LDFLAGS"
	cd ..

	wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.gz
	tar -zxvf ./libunistring-0.9.10.tar.gz
	cd ./libunistring-0.9.10
	autoreconf -fi
	./configure $STATIC_FLAG
	make install LDFLAGS="$BEGIN_LDFLAGS"
	cd ..

	wget https://ftp.gnu.org/gnu/libidn/libidn2-2.3.0.tar.gz
	tar -zxvf ./libidn2-2.3.0.tar.gz
	cd libidn2-2.3.0
	./configure $STATIC_FLAG
	make install LDFLAGS="$BEGIN_LDFLAGS"
	cd ..

	wget https://github.com/rockdaboot/libpsl/releases/download/0.21.1/libpsl-0.21.1.tar.gz
	tar -zxvf libpsl-0.21.1.tar.gz
	cd libpsl-0.21.1
	./configure $STATIC_FLAG
	make install LDFLAGS="$BEGIN_LDFLAGS"
	cd ..
fi

# custom curl build with schannel so ssl / https works out of the box on windows
cd ./curl
autoreconf -fi
./configure $STATIC_FLAG --with-schannel --without-ssl
cd lib
if [ $IS_STATIC == 1 ]; then
	make install CFLAGS="-DCURL_STATICLIB -DNGHTTP2_STATICLIB" LDFLAGS="$BEGIN_LDFLAGS"
else
	make install LDFLAGS="$BEGIN_LDFLAGS"
fi
cd ..
cd ..

cd ./libplist
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS"
cd ..

cd ./libusbmuxd
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS"
cd ..

cd ./libimobiledevice
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS"
cd ..

cd ./libirecovery
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS -ltermcap"
cd ..

cd ./libgeneral
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS"
cd ..


cd ./libfragmentzip
if [ $IS_STATIC == 1 ]; then
	export curl_LIBS="$(curl-config --static-libs)"
fi
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS"
cd ..

cd ./img4tool
./autogen.sh $STATIC_FLAG
make install LDFLAGS="$BEGIN_LDFLAGS -lws2_32"
cd ..

# libipatcher is only needed for odysseus, can be fixed later

#cd ./libinsn
#./autogen.sh $STATIC_FLAG
#make install
#cd ..

#cd ./liboffsetfinder64
#./autogen.sh $STATIC_FLAG
#make install
#cd ..

#cd ./libipatcher
#./autogen.sh $STATIC_FLAG
#make install
#cd ..

cd ./futurerestore
./autogen.sh $STATIC_FLAG

if [ $IS_STATIC == 1 ]; then
	#hacky workaround: replace libgeneral libs to append missing libraries at the end of the g++ command, works because libgeneral is the last lib to be linked
	make CFLAGS="-DCURL_STATICLIB" LDFLAGS="$BEGIN_LDFLAGS" libgeneral_LIBS="-lbcrypt -lws2_32 -llzma -lbz2 -liconv -lunistring -lnghttp2"
else
	make LDFLAGS="$BEGIN_LDFLAGS"
fi

make install
cd ..
