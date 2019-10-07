# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      include Xccdf::RuleIdentifiers

      def rules_already_saved
        return @rules_already_saved if @rules_already_saved.present?

        rule_ref_ids = @test_result_file.rule_objects.map(&:id)
        @rules_already_saved = Rule.select(:id, :ref_id)
                                   .where(ref_id: rule_ref_ids)
                                   .includes(:profiles)
      end

      def add_profiles_to_old_rules(rules, new_profiles)
        preexisting_profiles = ProfileRule.select(:profile_id)
                                          .where(rule_id: rules.pluck(:id))
                                          .pluck(:profile_id).uniq
        rules.find_each do |rule|
          new_profiles.each do |profile|
            unless preexisting_profiles.include?(profile.id)
              ProfileRule.create(rule_id: rule.id, profile_id: profile.id)
            end
          end
        end
      end

      def new_rules
        return @new_rules if @new_rules

        ref_ids = rules_already_saved.pluck(:ref_id)
        @new_rules = @test_result_file.rule_objects.reject do |rule|
          ref_ids.include? rule.id
        end
      end

      def save_rules
        add_profiles_to_old_rules(rules_already_saved, new_profiles)
        associate_rule_references
        Rule.import!(new_rule_records, recursive: true)
      end

      def save_rules(benchmark: Xccdf::Benchmark.new,
                     rule_references: [],
                     op_rules: [])
        rules = op_rules.map do |op_rule|
          update_rule(benchmark: benchmark,
                      rule_references: rule_references,
                      op_rule: op_rule)
        end

        Rule.import(rules, ignore: true)

        rules
      end

      def update_rule(benchmark: Xccdf::Benchmark.new,
                      rule_references: [],
                      op_rule: OpenscapParser::Rule.new)
        rule = find_rule(benchmark: benchmark, op_rule: op_rule)
        save_rule_identifier(op_rule_identifier: op_rule.rule_identifier,
                             rule: rule)

        rule.assign_attributes(
          title: op_rule.title, description: op_rule.description,
          severity: op_rule.severity, rationale: op_rule.rationale,
          rule_references: rule_references.select do |rule_reference|
            op_rule.rule_reference_strings
              .include?("#{rule_reference.label}#{rule_reference.href}")
          end
        )

        rule
      end

      def find_rule(benchmark: Xccdf::Benchmark.new,
                    op_rule: OpenscapParser::Rule.new)
        Rule.find_or_initialize_by(
          ref_id: op_rule.id,
          benchmark_id: benchmark.id
        )
      end

      private

      def new_profiles
        @new_profiles ||= Profile.where(ref_id: @test_result_file.profiles.keys,
                                        account_id: @account.id)
      end

      def new_rule_records
        @new_rule_records ||= new_rules.each_with_object([])
                                       .map do |oscap_rule, _new_rules|
          rule_object = Rule.new(profiles: new_profiles)
                            .from_oscap_object(oscap_rule)
          rule_object.rule_identifier = RuleIdentifier
                                        .from_oscap_rule(oscap_rule)
          rule_object
        end
      end
    end
  end
end
