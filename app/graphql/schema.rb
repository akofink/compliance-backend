# frozen_string_literal: true

require 'prometheus_exporter/client' unless Rails.env.test?

# Definition for the GraphQL schema - read the
# GraphQL-ruby documentation to find out what to add or
# remove here.
class Schema < GraphQL::Schema
  use GraphQL::Tracing::PrometheusTracing unless Rails.env.test?
  query Types::Query
  mutation Types::Mutation
end
