#!/bin/bash -el

cd autonoe_github
bundle install && bundle exec rspec
