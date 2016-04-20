#!/bin/bash

yum install autoconf automake cmake freetype-devel openssl-devel gcc gcc-c++ git libtool make mercurial nasm pkgconfig zlib-devel

mkdir -p ~/ffmpeg_source

cp -rf * ~/ffmpeg_source

cd ~/ffmpeg_source

tar -zxvf fdk-aac.tar.gz
tar -zxvf lame-3.99.5.tar.gz
tar -zxvf libogg-1.3.2.tar.gz
tar -zxvf libvorbis-1.3.4.tar.gz
tar -zxvf libvpx.tar.gz
tar -zxvf opus.tar.gz
tar -zxvf rtmpdump-2.3.tar.gz
tar -zxvf x264.tar.gz
tar -zxvf x265.tar.gz
tar -zxvf yasm.tar.gz
xz -d ffmpeg-3.0.1.tar.xz
tar -xvf ffmpeg-3.0.1.tar

cd ~/ffmpeg_source/yasm && autoreconf -fiv && ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" && make && make install && make distclean

PATH=$PATH:$HOME/bin/

cd ~/ffmpeg_source/x264 && PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static && make && make install && make distclean

cd ~/ffmpeg_source/x265/build/linux && cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && make && make install

cd ~/ffmpeg_source/fdk-aac && autoreconf -fiv && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && make && make install && make distclean

cd ~/ffmpeg_source/lame-3.99.5 && ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm && make && make install && make distclean

cd ~/ffmpeg_source/opus && autoreconf -fiv && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && make && make install && make distclean

cd ~/ffmpeg_source/libogg-1.3.2 && ./configure --prefix="$HOME/ffmpeg_build" --disable-shared && make && make install && make distclean

cd ~/ffmpeg_source/libvorbis-1.3.4 && LDFLAGS="-L$HOME/ffmeg_build/lib" CPPFLAGS="-I$HOME/ffmpeg_build/include" ./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared && make && make install && make distclean

cd ~/ffmpeg_source/libvpx && ./configure --prefix="$HOME/ffmpeg_build" --disable-examples --as=yasm && make && make install && make clean

cd ~/ffmpeg_source/rtmpdump-2.3/librtmp && sed -i 's#prefix=/usr/local#prefix=$(HOME)/ffmpeg_build#' Makefile && sed -i 's/SHARED=yes/SHARED=no/' Makefile && make && make install && make clean

cd ~/ffmpeg_source/ffmpeg-3.0.1 && PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --bindir="$HOME/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-openssl --enable-protocol=rtmp --enable-librtmp --enable-demuxer=rtsp --enable-muxer=rtsp --enable-libfreetype --enable-libfdk-aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --disable-shared --enable-static --disable-debug && make && make install && make distclean

mkdir -p /usr/local/ffmpeg/bin
cd ~/bin
cp -rf ff* /usr/local/ffmpeg/bin
echo 'PATH=/usr/local/ffmpeg/bin:$PATH' >> /etc/bashrc && source /etc/bashrc
