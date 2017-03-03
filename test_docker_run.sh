#!/usr/bin/env bash

docker run --rm=true \
    -v /var/www/test/.ssh:/etc/secret \
    -e ARG_GIT_SYNC_REPO="git@github.com:example.git" \
    -e ARG_GIT_SYNC_BRANCH="master" \
    -e ARG_GIT_FETCH_SLEEP=60 \
    -e ARG_DEBUG=1 \
    -e ARG_COMPOSER_BIN="composer" \
    -e ARG_SYMFONY_CP_PARAM_DIST=1 \
    -e ARG_SYMFONY_CP_PARAM_SECRET_FILE="/etc/secret/parameters.yml" \
    -e ARG_SYMFONY_CP_PARAM_TARGET_SUBPATH="../" \
    -e ARG_COMPOSER_INSTALL=1 \
    test/git-sync


