#!/bin/sh
buildah bud --pull --layers --tag local/bitmessage-gui:latest --file Dockerfile .
