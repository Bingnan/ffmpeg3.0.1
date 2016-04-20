#FFMPEG编译指南

此指南基于我们服务器的CentOS操作系统，内容涵盖了官方的 [Compile FFmpeg on CentOS](https://trac.ffmpeg.org/wiki/CompilationGuide/Centos) ，在此基础上增加了对rtmp,rtsp等协议的支持，并且替换了直接下载不到的库的git地址（libvpx库，ffmpeg源码库)。

我已经把用到的各个库打包上传到了这里。

##1.安装依赖

```
# yum install autoconf automake cmake freetype-devel openssl-devel gcc gcc-c++ git libtool make mercurial nasm pkgconfig zlib-devel
```

带"#"符号表示需要sudo权限执行。

然后在你的HOME目录下创建一个新的文件夹，存放所有编译用到的文件：

```
mkdir ~/ffmpeg_source
```

##2.编译需要用到的库或工具
用到哪些库，编译ffmpeg时候就enable哪些库

###2.1 Yasm
汇编器，编译x264,ffmpeg会用到

```
cd ~/ffmpeg_sources
git clone --depth 1 git://github.com/yasm/yasm.git
cd yasm
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make
make install
make distclean
```
然后把$HOME/bin加入系统PATH路径:

```
PATH=$PATH:$HOME/bin/
```

###2.2 libx264

H264编码库,开启需要在FFmpeg的configure中指定： --enable-gpl 和 --enable-libx264

```
cd ~/ffmpeg_sources
git clone --depth 1 git://git.videolan.org/x264
cd x264
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
make
make install
make distclean
```
###2.3 libx265

H265编码库,开启需要在FFmpeg的configure中指定： --enable-gpl 和 --enable-libx265

```
cd ~/ffmpeg_sources
hg clone https://bitbucket.org/multicoreware/x265
cd ~/ffmpeg_sources/x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
make
make install
```

###2.4 libfdk_aac

AAC编码库,开启需要在FFmpeg的configure中指定： --enable-libfdk-aac

```
cd ~/ffmpeg_sources
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean
```

###2.5 libmp3lame

MP3编码库,开启需要在FFmpeg的configure中指定： --enable-libmp3lame

```
cd ~/ffmpeg_sources
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm
make
make install
make distclean
```

###2.6 libopus

Opus音频编解码库,开启需要在FFmpeg的configure中指定： --enable-libopus

```
cd ~/ffmpeg_sources
git clone git://git.opus-codec.org/opus.git
cd opus
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean
```

###2.7 libogg

Ogg是一种容器格式，如果要enable下面的libvorbis就需要这个

```
cd ~/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
tar xzvf libogg-1.3.2.tar.gz
cd libogg-1.3.2
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean
```

###2.8 libvorbis

Vorbis音频编码库，开启需要在FFmpeg的configure中指定： --enable-libvorbis

```
cd ~/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
tar xzvf libvorbis-1.3.4.tar.gz
cd libvorbis-1.3.4
LDFLAGS="-L$HOME/ffmeg_build/lib" CPPFLAGS="-I$HOME/ffmpeg_build/include" ./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared
make
make install
make distclean
```

###2.9 libvpx

VP8/VP9视频编码库，开启需要在FFmpeg的configure中指定： --enable-libvpx

```
cd ~/ffmpeg_sources
git clone --depth 1 https://github.com/webmproject/libvpx.git
cd libvpx
./configure --prefix="$HOME/ffmpeg_build" --disable-examples --as=yasm
make
make install
make clean
```

###2.10 librtmp

rtmp协议库，ffmpeg中原生的rtmp库支持不太好，所以一般使用这个第三方rtmp库。 开启需要在FFmpeg的configure中指定： --enable-librtmp

这个librtmp库居然没有configure文件，无法像其他库一样指定只编译static的库和修改prefix路径，需要自己改Makefile

前面的所有库都没问题，就这个librtmp折腾了半天，一开始没有去改它的Makefile把SHARED置成no, 这样make会编译出静态和动态库，然后make install会把静态和动态库都拷贝到$(HOME)/ffmpeg_build/lib下,然后后面在编译ffmpeg的时候，即使configure时指定了--pkg-config-flags="--static"这样的让链接器链接静态库的参数, 可是等链接器链接时却发现lib下有动态库，还是会优先链接动态库，这样编译出来的ffmpeg中librtmp是动态链接的，但是没有正确设置LD_LIBRARY_PATH参数的话就找不到这个库，从而导致无法运行。

```
cd ~/ffmpeg_sources
curl -O http://rtmpdump.mplayerhq.hu/download/rtmpdump-2.3.tgz
tar xzvf rtmpdump-2.3.tgz
cd rtmpdump-2.3/librtmp
sed -i 's#prefix=/usr/local#prefix=$(HOME)/ffmpeg_build#' Makefile
sed -i 's/SHARED=yes/SHARED=no/' Makefile
make
make install
make clean
```

##3.编译FFmpeg

我们目前用的是ffmpeg最新的稳定版本3.0.1 "Einstein"

```
cd ~/ffmpeg_sources
git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg
cd ffmpeg
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib" --bindir="$HOME/bin" --pkg-config-flags="--static" --enable-gpl --enable-nonfree --enable-openssl --enable-protocol=rtmp --enable-librtmp --enable-demuxer=rtsp --enable-muxer=rtsp --enable-libfreetype --enable-libfdk-aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264 --enable-libx265 --disable-shared --enable-static --disable-debug
make
make install
make distclean
```
编译好的ffmpeg在$HOME/bin下

##4.升级库


先删除之前编译出来的程序

```
rm -rf ~/ffmpeg_build ~/bin/{ffmpeg,ffprobe,ffserver,lame,vsyasm,x264,x265,yasm,ytasm}
```
然后进入各个库的git目录运行 git pull即可，不过一般情况下，我们优先使用各个库的某一个稳定版本，不一定会使用最新版本，所以一般情况下不需要频繁的升级库。

