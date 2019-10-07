# frozen_string_literal: true

module Xccdf
  # Methods related to saving profiles and finding which hosts
  # they belong to
  module Profiles
    extend ActiveSupport::Concern

    included do
      def host_new_profiles
        save_profiles.select do |profile| # rubocop:disable Style/InverseMethods
          Rails.cache.delete("#{profile.id}/#{@host.id}/results")
          !profile.hosts.map(&:id).include? @host.id
        end
      end

      def save_profiles(benchmark: Xccdf::Benchmark.new,
                        op_profiles: [],
                        rules: [])
        profiles = op_profiles.map do |op_profile|
          update_profile(benchmark: benchmark, op_profile: op_profile, rules: rules)
        end

        Profile.import(profiles, ignore: true)

        profiles
      end

      def update_profile(benchmark: Xccdf::Benchmark.new,
                         op_profile: OpenscapParser::Profile.new,
                         rules: [])
        selected_rules = rules.select do |rule|
          op_profile.selected_rule_ids.include?(rule.ref_id)
        end

        profile = find_profile(benchmark: benchmark, op_profile: op_profile)

        profile.assign_attributes(
          description: op_profile.description,
          rules: selected_rules
        )

        profile
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
    end
  end
end
