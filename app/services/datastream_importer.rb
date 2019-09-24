# frozen_string_literal: true

# This class imports pre-parsed datastream info into the compliance DB
class DatastreamImporter
  def initialize(datastream_filenames)
    @datastreams = datastream_filenames.map do |datastream_filename|
      OpenscapParser::Datastream.new(File.read(datastream_filename))
    end
  end

  def import!
    @datastreams.map do |ds|
      Xccdf::Benchmark.transaction do
        benchmark = save_benchmark(op_benchmark: ds.benchmark)

        rule_references = save_rule_references(
          op_rule_references: ds.benchmark.rule_references)

        rules = save_rules(
          benchmark: benchmark,
          rule_references: rule_references,
          op_rules: ds.benchmark.rules)

        profiles = save_profiles(
          benchmark: benchmark,
          rules: rules,
          op_profiles: ds.benchmark.profiles)
      end
    end
  end

  private

  def save_benchmark(op_benchmark: OpenscapParser::Benchmark.new)
    benchmark = Xccdf::Benchmark.find_or_initialize_by(
      ref_id: op_benchmark.id,
      version: op_benchmark.version
    )

    benchmark.update(
      title: op_benchmark.title,
      description: op_benchmark.description
    )

    benchmark
  end

  def save_rule_references(op_rule_references: [])
    op_rule_references.map do |op_rule_reference|
      save_rule_reference(op_rule_reference: op_rule_reference)
    end
  end

  def save_rule_reference(op_rule_reference: OpenscapParser::RuleRefernece)
    RuleReference.find_or_create_by(
      href: op_rule_reference.href,
      label: op_rule_reference.label
    )
  end

  def save_rules(benchmark: Xccdf::Benchmark.new,
                 rule_references: [],
                 op_rules: [])
    op_rules.map do |op_rule|
      save_rule(benchmark: benchmark,
                rule_references: rule_references,
                op_rule: op_rule)
    end
  end

  def save_rule(benchmark: Xccdf::Benchmark.new,
                rule_references: [],
                op_rule: OpenscapParser::Rule.new)
    selected_rule_references = rule_references.select do |rule_reference|
      op_rule.rule_reference_strings.
        include?("#{rule_reference.label}#{rule_reference.href}")
    end

    rule = find_rule(benchmark: benchmark, op_rule: op_rule)

    rule_identifier = create_rule_identifier(
      op_rule_identifier: op_rule.rule_identifier)

    update_rule(rule: rule,
                rule_references: selected_rule_references,
                rule_identifier: rule_identifier,
                op_rule: op_rule)
  end

  def create_rule_identifier(
    op_rule_identifier: OpenscapParser::RuleIdentifier.new)
    RuleIdentifier.find_or_create_by(
      label: op_rule_identifier.label,
      system: op_rule_identifier.system
    )
  end

  def find_rule(benchmark: Xccdf::Benchmark.new,
                op_rule: OpenscapParser::Rule.new)
    Rule.find_or_initialize_by(
      ref_id: op_rule.id,
      benchmark_id: benchmark.id
    )
  end

  def update_rule(rule: Rule.new,
                  rule_references: [],
                  rule_identifier: RuleIdentifier.new,
                  op_rule: OpenscapParser::Rule.new)
    rule.update(
      title: op_rule.title,
      description: op_rule.description,
      severity: op_rule.severity,
      rationale: op_rule.rationale,
      rule_references: rule_references,
      rule_identifier: rule_identifier
    )

    rule
  end

  def save_profiles(benchmark: Xccdf::Benchmark.new,
                    op_profiles: [],
                    rules: [])
    op_profiles.map do |op_profile|
      save_profile(benchmark: benchmark, op_profile: op_profile, rules: rules)
    end
  end

  def save_profile(benchmark: Xccdf::Benchmark.new,
                   op_profile: OpenscapParser::Profile.new,
                   rules: [])
    selected_rules = rules.select do |rule|
      op_profile.selected_rule_ids.include?(rule.ref_id)
    end

    update_profile(benchmark: benchmark,
                   op_profile: op_profile,
                   rules: selected_rules,
                   profile: find_profile(benchmark: benchmark,
                                         op_profile: op_profile))
  end

  def find_profile(benchmark: Xccdf::Benchmark.new,
                   op_profile: OpenscapParser::Profile.new)
    Profile.find_or_initialize_by(
      ref_id: op_profile.id,
      name: op_profile.title,
      account_id: nil,
      benchmark_id: benchmark.id
    )
  end

  def update_profile(benchmark: Xccdf::Benchmark.new,
                     op_profile: OpenscapParser::Profile.new,
                     rules: [],
                     profile: Profile.new)
    profile.update(
      description: op_profile.description,
      rules: rules
    )
  end
end
