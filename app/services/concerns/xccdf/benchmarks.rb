# frozen_string_literal: true

module Xccdf
  # Methods related to saving xccdf benchmarks
  module Benchmarks
    extend ActiveSupport::Concern

    included do
      include Xccdf::Datastreams

      def save_benchmark(op_benchmark: OpenscapParser::Benchmark.new)
        benchmark = Xccdf::Benchmark.find_or_initialize_by(ref_id: op_benchmark.id,
                                                           version:
                                                           op_benchmark.version)

        benchmark.update(title: op_benchmark.title,
                         description: op_benchmark.description)

        benchmark
      end
    end
  end
end
