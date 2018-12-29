#!/bin/bash

bundle exec rake kindlegen:download:linux && bundle exec rails s -b localhost -p $PORT -e production
