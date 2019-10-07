# frozen_string_literal: true

# This class imports pre-parsed datastream info into the compliance DB
class DatastreamImporter
  include Xccdf::Datastreams
  include Xccdf::Benchmarks
  include Xccdf::RuleReferences
  include Xccdf::Rules
  include Xccdf::Profiles

  def initialize(datastream_filenames)
    @op_benchmarks = datastream_filenames.map do |datastream_filename|
      op_datastream_file(datastream_filename).benchmark
    end
  end

  def import!
    @op_benchmarks.each do |op_benchmark|
      Xccdf::Benchmark.transaction do
        benchmark = save_benchmark(op_benchmark: op_benchmark)

        rule_references = save_rule_references(op_rule_references:
                                               benchmark.rule_references)

        rules = save_rules(benchmark: benchmark,
                           rule_references: rule_references,
                           op_rules: ds.benchmark.rules)

        profiles = save_profiles(benchmark: benchmark,
                                 rules: rules,
                                 op_profiles: ds.benchmark.profiles)
      end
    end
  end
end
