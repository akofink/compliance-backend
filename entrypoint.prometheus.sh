#!/bin/bash
set -e
bundle exec prometheus_exporter -c lib/graphql_collector.rb
