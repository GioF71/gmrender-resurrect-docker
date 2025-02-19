ARG SELECT_BASE_IMAGE=${BASE_IMAGE:-debian:stable-slim}
FROM ${SELECT_BASE_IMAGE} AS base

RUN apt-get update
# RUN apt-get install -y build-essential autoconf automake libtool pkg-config
RUN apt-get install -y build-essential autoconf automake libtool pkg-config \
                libupnp-dev libgstreamer1.0-dev \
                gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
                gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
                gstreamer1.0-libav \
                git \
                uuid-runtime

RUN apt-get install -y gstreamer1.0-alsa gstreamer1.0-pulseaudio

RUN apt-get install -y --no-install-recommends alsa-utils pulseaudio-utils

# RUN apt-get install -y git

# RUN apt-get install -y uuid-runtime

RUN mkdir -p /app/source
WORKDIR /app/source

RUN git clone https://github.com/hzeller/gmrender-resurrect.git

WORKDIR /app/source/gmrender-resurrect

RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

WORKDIR /

RUN rm -rf /app/source

RUN apt-get remove -y build-essential autoconf automake libtool pkg-config \
        libgstreamer1.0-dev \
        git

RUN apt-get autoremove -y

RUN rm -rf /var/lib/apt/lists/*

FROM scratch
COPY --from=base / /

LABEL maintainer="GioF71"
LABEL source="https://github.com/GioF71/gmrender-resurrect-docker"

VOLUME /config
VOLUME /fifo

ENV FRIENDLY_NAME=""
ENV UUID=""
ENV GSTOUT_AUDIOSINK=""
ENV GSTOUT_AUDIODEVICE=""
ENV GSTOUT_AUDIOPIPE=""
ENV GSTOUT_INITIAL_VOLUME_DB=""
ENV NETWORK_INTERFACE=""

ENV USER_MODE=""
ENV PUID=""
ENV PGID=""
ENV AUDIO_GID=""

ENV CARD_NAME=""
ENV CARD_INDEX=""

RUN mkdir -p /app/assets
COPY app/assets/pulse-client-template.conf /app/assets/pulse-client-template.conf

RUN mkdir -p /app/bin
COPY app/bin/run.sh /app/bin
RUN chmod 755 /app/bin/*sh

ENTRYPOINT ["/app/bin/run.sh"]

