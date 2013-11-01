#!/usr/bin/env bash
\
    # ./update_stats.sh && \
    ruby license_issue.rb && \
    git commit -am 'Update license issues' &&\
    git push &&\
    ruby license_issue.rb license_stats &&\
    git commit -am 'Update license usage' &&\
    git push
