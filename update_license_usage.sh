#!/usr/bin/env bash
\
 ruby license_issue.rb license_stats &&\
 git commit -am 'Update license usage' &&\
 git push
