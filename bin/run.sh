#!/bin/bash

set -e

bundle install
bundle exec rake kindlegen:download:linux
bundle exec rails s -b localhost -p $PORT -e production
