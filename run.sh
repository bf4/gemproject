#!/usr/bin/env bash
\
    ./update_stats.sh && \
    ruby license_issue.rb && \
    git commit -am 'Update license issues' &&\
    git push &&\
    ./update_license_usage.sh
