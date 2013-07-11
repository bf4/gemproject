#!/usr/bin/env bash
echo 'license_results.rtf' | xargs perl -pi -w -e 's/ \d+ \w+ ago//g;'
