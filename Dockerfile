FROM debian:stable-slim AS BASE

RUN apt-get update
RUN apt-get install -y build-essential autoconf automake libtool pkg-config
RUN apt-get install -y libupnp-dev libgstreamer1.0-dev \
                gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
                gstreamer1.0-libav

RUN apt-get install -y gstreamer1.0-alsa
RUN apt-get install -y gstreamer1.0-pulseaudio

RUN apt-get install -y git

RUN mkdir -p /app/source
WORKDIR /app/source

RUN git clone https://github.com/hzeller/gmrender-resurrect.git

WORKDIR /app/source/gmrender-resurrect

RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

FROM debian:stable-slim AS INTERMEDIATE
COPY --from=BASE /usr/local/bin/gmediarender /usr/local/bin/gmediarender

RUN apt-get update
RUN apt-get install -y --no-install-recommends alsa-utils
RUN apt-get install -y --no-install-recommends pulseaudio-utils
RUN rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=INTERMEDIATE / /

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/gmrenderer-resurrect-docker"


