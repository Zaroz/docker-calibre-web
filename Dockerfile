FROM lsiobase/alpine.python:3.6
MAINTAINER sparklyballs,chbmb

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	file \
	fontconfig-dev \
	freetype-dev \
	g++ \
	gcc \
	ghostscript-dev \
	lcms2-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	libtool \
	libwebp-dev \
	libxml2-dev \
	make \
	perl-dev \
	python2-dev \
	tiff-dev \
	xz \
	zlib-dev && \

# install runtime packages
 apk add --no-cache \
	fontconfig \
	freetype \
	ghostscript \
	lcms2 \
	libjpeg-turbo \
	libltdl \
	libpng \
	libwebp \
	libxml2 \
	tiff \
	zlib && \

# compile imagemagic
 IMAGEMAGICK_VER=$(curl --silent http://www.imagemagick.org/download/digest.rdf \
	| grep ImageMagick-6.*tar.xz | sed 's/\(.*\).tar.*/\1/' \
	| sed 's/^.*ImageMagick-/ImageMagick-/') && \
 mkdir -p \
	/tmp/imagemagick && \
 curl -o \
 /tmp/imagemagick-src.tar.xz -L \
	"http://www.imagemagick.org/download/${IMAGEMAGICK_VER}.tar.xz" && \
 tar xf \
 /tmp/imagemagick-src.tar.xz -C \
	/tmp/imagemagick --strip-components=1 && \
 cd /tmp/imagemagick && \
 sed -i -e \
	's:DOCUMENTATION_PATH="${DATA_DIR}/doc/${DOCUMENTATION_RELATIVE_PATH}":DOCUMENTATION_PATH="/usr/share/doc/imagemagick":g' \
	configure && \
 ./configure \
	--infodir=/usr/share/info \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/etc \
	--with-gs-font-dir=/usr/share/fonts/Type1 \
	--with-gslib \
	--with-lcms2 \
	--with-modules \
	--without-threads \
	--without-x \
	--with-tiff \
	--with-xml && \
# attempt to set number of cores available for make to use
 set -ex && \
 CPU_CORES=$( < /proc/cpuinfo grep -c processor ) || echo "failed cpu look up" && \
 if echo $CPU_CORES | grep -E  -q '^[0-9]+$'; then \
	: ;\
 if [ "$CPU_CORES" -gt 7 ]; then \
	CPU_CORES=$(( CPU_CORES  - 3 )); \
 elif [ "$CPU_CORES" -gt 5 ]; then \
	CPU_CORES=$(( CPU_CORES  - 2 )); \
 elif [ "$CPU_CORES" -gt 3 ]; then \
	CPU_CORES=$(( CPU_CORES  - 1 )); fi \
 else CPU_CORES="1"; fi && \

 make -j $CPU_CORES && \
 set +ex && \
 make install && \
 find / -name '.packlist' -o -name 'perllocal.pod' \
	-o -name '*.bs' -delete && \

# install calibre-web
 mkdir -p \
	/app/calibre-web && \
 curl -o \
 /tmp/calibre-web.tar.gz -L \
	https://github.com/janeczku/calibre-web/archive/master.tar.gz && \
 tar xf \
 /tmp/calibre-web.tar.gz -C \
	/app/calibre-web --strip-components=1 && \
 cd /app/calibre-web && \
 pip install --no-cache-dir -U -r \
	requirements.txt && \
 pip install --no-cache-dir -U -r \
	optional-requirements.txt && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/*

# add local files
COPY root/ /

# ports and volumes
EXPOSE 8083
VOLUME /books /config
