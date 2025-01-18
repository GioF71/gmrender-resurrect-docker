# gmrender-resurrect-docker

A docker image for [gmrender-resurrect](https://github.com/hzeller/gmrender-resurrect)

## References

This is based on [this project](https://github.com/hzeller/gmrender-resurrect) by [hzeller](https://github.com/hzeller).  

## Links

REPOSITORY|DESCRIPTION
:---|:---
Source code|[GitHub](https://github.com/GioF71/gmrender-resurrect-docker)
Docker images|[Docker Hub](https://hub.docker.com/r/giof71/gmrender-resurrect)

## Build

Simply build the docker image running the provided script `build.sh`:

```text
./build.sh
```

## Configuration

### Environment Variables

NAME|DESCRIPTION
:---|:---
FRIENDLY_NAME|Player friendly name
UUID|Specify the UUID of the player
GSTOUT_AUDIOSINK|Can be `alsa`, `alsasink`, `pulse`, `pulsesink`, defaults to `alsa`
GSTOUT_AUDIODEVICE|Specified the audio device. Recommended to user `CARD_NAME` (or `CARD_INDEX`) instead
GSTOUT_INITIAL_VOLUME_DB|Initial attenuation, in db, example `-10`
USER_MODE|Run as a user, defaults to `no`
PUID|Used as the `uid`
PGID|Used as the `gid`
AUDIO_GID|Set it to the gid of the `audio` group of the host system if running in user mode with alsa
CARD_NAME|Specify the alsa card name, example `D10`, `DAC`, `X20`
CARD_INDEX|Specify the alsa card index

### Volumes

VOLUME|DESCRIPTION
:---|:---
/config|Location of the configuration files

## Run

### Sample alsa compose

A very simple `alsa` configuration:

```text
---
version: "3"

volumes:
  config:

services:
  renderer:
    image: giof71/gmrender-resurrect:latest
    container_name: gmrender-alsa
    network_mode: host
    devices:
      - /dev/snd:/dev/snd
    environment:
      - PUID=${PUID:-1000}
      - AUDIO_GID=${AUDIO_GID:-29}
      - CARD_NAME=DAC
      - FRIENDLY_NAME=GMRender (DAC)
    volumes:
      - config:/config
    restart: unless-stopped
```

### Examples

Find a few sample configurations [here](https://github.com/GioF71/gmrender-resurrect-docker/tree/master/examples/).  

## Changelog

DATE|DESCRIPTION
:---|:---
2025-01-18|Rebuild using upstream version [0.3](https://github.com/hzeller/gmrender-resurrect/releases/tag/v0.3)
2023-12-22|Initial Release
